##############################
#
# PLOT: Compare threshold-adjusting model outputs for fitness anc cascades
#
##############################

##########
# Load packages
##########
library(ggplot2)
library(dplyr)

##########
# Plot parameters
##########
# Plot out
out_path <- "output/thresh_adjust/"

# Plot variables
dodge_width = 0.05
pal <- c("#e66101", "#bababa", "#5e3c99")
labs <- c(expression(paste("Care more about being right")), 
          expression(paste("Care equally")), 
          expression(paste("Care more about being wrong")))
key_name <- "Threshold\ndynamics"

####################
# Load and process data
####################
# Cascade data
cascade_files <- list.files("data_derived/thresh_adjust/cascades/", full.names = TRUE)
cascade_data <- lapply(cascade_files, function(file) {
  run_data <-  read.csv(file, header = TRUE)
  parameters <- gsub(".*_([a-z]+)\\.csv", "\\1", file, perl = TRUE)
  run_sum <- run_data %>% 
    select(gamma, total_active) %>% 
    group_by(gamma) %>% 
    summarise_each(list(size_mean = mean, 
                        size_sd = sd, 
                        rep_count = length)) %>% 
    mutate(size_95ci = qnorm(0.975) * size_sd / sqrt(rep_count),
           run = parameters)
  cascade_diff <- run_data %>% 
    select(gamma, active_diff_prop) %>% 
    group_by(gamma) %>% 
    summarise_each(list(bias_mean = mean, 
                        bias_sd = sd, 
                        rep_count = length)) %>% 
    mutate(bias_95ci = qnorm(0.975) * bias_sd / sqrt(rep_count))
  run_sum <- merge(run_sum, cascade_diff)
  return(run_sum)
})
cascade_data <- do.call('rbind', cascade_data)
cascade_data$run <- factor(cascade_data$run, levels = c("muchlargerphi", "equal", "muchlargeromega"))

# Fitness data
fitness_files <- list.files("data_derived/thresh_adjust/fitness/", pattern = ".*allbehavior.*",  full.names = TRUE)
fitness_data <- lapply(fitness_files, function(file) {
  run_data <-  read.csv(file, header = TRUE)
  parameters <- gsub(".*_([a-z]+)\\.csv", "\\1", file, perl = TRUE)
  run_data$run <- parameters
  run_sum <- run_data %>% 
    select(-replicate) %>% 
    mutate(fitness = sensitivity + specificity + precision) %>% 
    gather(metric, value, -gamma, -threshold, -run) %>% 
    group_by(run, gamma, metric) %>% 
    summarise(mean = mean(value, na.rm = TRUE),
              sd = sd(value, na.rm = TRUE),
              ci95 = qnorm(0.975) * sd(value, na.rm = TRUE) / sqrt( sum(!is.na(value)) )) #denominator removes NA values from count
  return(run_sum)
})
fitness_data <- do.call('rbind', fitness_data)
fitness_data$run <- factor(fitness_data$run, levels = c("muchlargerphi", "equal", "muchlargeromega"))

####################
# My preferred theme
####################
theme_ctokita <- function() {
  theme_classic() +
    theme(axis.text       = element_text(size = 6, color = "black"),
          axis.title      = element_text(size = 7, color = "black"),
          axis.ticks = element_line(size = 0.3, color = "black"),
          axis.line = element_line(size = 0.3),
          legend.title    = element_text(size = 7, face = "bold", vjust = -1),
          legend.text     = element_text(size = 6, color = "black"),
          strip.text      = element_text(size = 7, color = "black"),
          legend.key.size = unit(3, "mm"),
          aspect.ratio = 1)
}


########## Cascades #########

##########
# Plot: Cascade size
##########
gg_size <- ggplot(cascade_data, aes(x = gamma, y = size_mean, color = run)) +
  geom_ribbon(aes(ymin = size_mean - size_95ci, 
                    ymax = size_mean + size_95ci, 
                  fill = run), 
                alpha = 0.4,
                color = NA,
                position = position_dodge(width = dodge_width)) +
  geom_line(size = 0.3,
            position = position_dodge(width = dodge_width)) +
  geom_point(size = 0.8,
             position = position_dodge(width = dodge_width)) +
  ylab("Cascade size ") +
  xlab(expression(paste("Information correlation ", italic(gamma) ))) +
  scale_color_manual(values = pal,
                     label = labs,
                     name = key_name) +
  scale_fill_manual(values = pal,
                     label = labs,
                     name = key_name) +
  theme_ctokita() +
  theme(legend.text.align = 0)

gg_size

ggsave(plot = gg_size,
       filename = paste0(out_path, "cascades/Comparison_CascadeSize.png"),
       width = 90,
       height = 45,
       units = "mm",
       dpi = 600)

##########
# Plot: Cascade bias
##########
gg_bias <- ggplot(cascade_data, aes(x = gamma, y = bias_mean, color = run)) +
  geom_ribbon(aes(ymin = bias_mean - bias_95ci, 
                  ymax = bias_mean + bias_95ci, 
                  fill = run), 
              alpha = 0.4,
              color = NA,
              position = position_dodge(width = dodge_width)) +
  geom_line(size = 0.3,
            position = position_dodge(width = dodge_width)) +
  geom_point(size = 0.8,
             position = position_dodge(width = dodge_width)) +
  ylab(expression( "Cascade bias" )) +
  xlab(expression(paste("Information correlation ", italic(gamma) ))) +
  scale_color_manual(values = pal,
                     label = labs,
                     name = key_name) +
  scale_fill_manual(values = pal,
                    label = labs,
                    name = key_name) +
  theme_ctokita() +
  theme(legend.text.align = 0)

gg_bias

ggsave(plot = gg_bias,
       filename = paste0(out_path, "cascades/Comparison_CascadeBias.png"),
       width = 90,
       height = 45,
       units = "mm",
       dpi = 600)


########## Fitness #########

##########
# Plot: Sensitivity, the proportion of important (i.e., greater than threshold) news stories individual reacted to
##########
sensitivity_data <- fitness_data %>% 
  filter(metric == "sensitivity")

gg_sens <- ggplot(data = sensitivity_data, aes(x = gamma, y = mean, color = run)) +
  geom_ribbon(aes(ymin = mean - ci95,
                  ymax =  mean + ci95,
                  fill = run),
              alpha = 0.4,
              color = NA,
              position = position_dodge(width = dodge_width)) +
  geom_line(size = 0.3,
            position = position_dodge(width = dodge_width)) +
  geom_point(size = 0.8,
             position = position_dodge(width = dodge_width)) +
  ylab("Behavioral sensitivity") +
  xlab(expression( paste("Information correlation ", italic(gamma)) )) +
  scale_color_manual(values = pal,
                     label = labs,
                     name = key_name) +
  scale_fill_manual(values = pal,
                    label = labs,
                    name = key_name) +
  theme_ctokita() 

gg_sens
ggsave(plot = gg_sens,
       filename = paste0(out_path, "fitness/Comparison_sensitivity.png"),
       width = 90,
       height = 45,
       units = "mm",
       dpi = 600)

##########
# Plot: Specificity, the proportion of "unimportant" (i.e, less than threshold) stories an individual did *not* react to
##########
specificity_data <- fitness_data %>% 
  filter(metric == "specificity")

gg_spec <- ggplot(data = specificity_data, aes(x = gamma, y = mean, color = run)) +
  geom_ribbon(aes(ymin = mean - ci95,
                  ymax =  mean + ci95,
                  fill = run),
              alpha = 0.4,
              color = NA,
              position = position_dodge(width = dodge_width)) +
  geom_line(size = 0.3,
            position = position_dodge(width = dodge_width)) +
  geom_point(size = 0.8,
             position = position_dodge(width = dodge_width)) +
  ylab("Behavioral specificity") +
  xlab(expression( paste("Information correlation ", italic(gamma)) )) +
  scale_color_manual(values = pal,
                     label = labs,
                     name = key_name) +
  scale_fill_manual(values = pal,
                    label = labs,
                    name = key_name) +
  theme_ctokita() 

gg_spec
ggsave(plot = gg_spec,
       filename = paste0(out_path, "fitness/Comparison_specificity.png"),
       width = 90,
       height = 45,
       units = "mm",
       dpi = 600)

##########
# Plot: Precision, the proportion of activity (x_i = 1) that is due to "important" news.
##########
prevision_data <- fitness_data %>% 
  filter(metric == "precision")

gg_precis <- ggplot(data = prevision_data, aes(x = gamma, y = mean, color = run)) +
  geom_ribbon(aes(ymin = mean - ci95,
                  ymax =  mean + ci95,
                  fill = run),
              alpha = 0.4,
              color = NA,
              position = position_dodge(width = dodge_width)) +
  geom_line(size = 0.3,
            position = position_dodge(width = dodge_width)) +
  geom_point(size = 0.8,
             position = position_dodge(width = dodge_width)) +
  ylab("Behavioral precision") +
  xlab(expression( paste("Information correlation ", italic(gamma)) )) +
  scale_color_manual(values = pal,
                     label = labs,
                     name = key_name) +
  scale_fill_manual(values = pal,
                    label = labs,
                    name = key_name) +
  theme_ctokita() 

gg_precis
ggsave(plot = gg_precis,
       filename = paste0(out_path, "fitness/Comparison_precision.png"),
       width = 90,
       height = 45,
       units = "mm",
       dpi = 600)

##########
# Plot: Individual fitness 
##########
total_fitness_data <- fitness_data %>% 
  filter(metric == "fitness")

gg_fitness <- ggplot(data = total_fitness_data, aes(x = gamma, y = mean, color = run)) +
  geom_ribbon(aes(ymin = mean - ci95,
                  ymax =  mean + ci95,
                  fill = run),
              alpha = 0.4,
              color = NA,
              position = position_dodge(width = dodge_width)) +
  geom_line(size = 0.3,
            position = position_dodge(width = dodge_width)) +
  geom_point(size = 0.8,
             position = position_dodge(width = dodge_width)) +
  ylab("Information use fitness") +
  xlab(expression( paste("Information correlation ", italic(gamma)) )) +
  scale_color_manual(values = pal,
                     label = labs,
                     name = key_name) +
  scale_fill_manual(values = pal,
                    label = labs,
                    name = key_name) +
  theme_ctokita() 

gg_fitness
ggsave(plot = gg_fitness,
       filename = paste0(out_path, "fitness/Comparison_fitness.png"),
       width = 90,
       height = 45,
       units = "mm",
       dpi = 600)
