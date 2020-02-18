########################################
#
# PLOT: Individual fitness as inferred from behavior
#
########################################

####################
# Load packages
####################
library(ggplot2)
library(dplyr)
library(tidyr)
source("scripts/_plot_themes/theme_ctokita.R")

####################
# Paramters for analysis: paths to data, paths for output, and filename
####################
data_path <- "data_derived/network_break/fitness/n200_fitness_allbehavior_gamma.csv" #path to data
out_path <- "output/network_break/fitness/" #directory you wish to save plots
plot_tag <- "gamma" #extra info to add onto end of plot name
if (plot_tag != "") {
  plot_tag <- paste0("_", plot_tag)
}



############################## Fitness trials: individual behavior/information use ##############################

####################
# Load data and summarise
####################
behav_data <- read.csv(data_path, header = TRUE)
behav_sum <- behav_data %>% 
  select(-replicate) %>% 
  mutate(fitness = sensitivity + specificity + precision) %>% 
  gather(metric, value, -gamma, -threshold) %>% 
  group_by(gamma, metric) %>% 
  summarise(mean = mean(value, na.rm = TRUE),
            sd = sd(value, na.rm = TRUE),
            ci95 = qnorm(0.975) * sd(value, na.rm = TRUE) / sqrt( sum(!is.na(value)) )) #denominator removes NA values from count

####################
# Plot
####################
# Sensitivity: proportion of important (i.e., greater than threshold) news stories individual reacted to
sensitivity_data <- behav_sum %>% 
  filter(metric == "sensitivity")
gg_sens <- ggplot(data = sensitivity_data, aes(x = gamma, y = mean)) +
  geom_ribbon(aes(ymin = mean - ci95,
                  ymax =  mean + ci95),
                  alpha = 0.4) +
  geom_line(size = 0.3) +
  geom_point(size = 0.8) +
  ylab("Behavioral sensitivity") +
  xlab(expression( paste("Information correlation ", italic(gamma)) )) +
  theme_ctokita() 
gg_sens #show plot before saving
ggsave(plot = gg_sens, filename = paste0(out_path, "sensitvity", plot_tag, ".png"), width = 45, height = 45, units = "mm", dpi = 600)
ggsave(plot = gg_sens, filename = paste0(out_path, "sensitvity", plot_tag, ".svg"), width = 45, height = 45, units = "mm")


# Specificity: proportion of "unimportant" (i.e, less than threshold) stories an individual did *not* react to
specificity_data <- behav_sum %>% 
  filter(metric == "specificity")
gg_specif <- ggplot(data = specificity_data, aes(x = gamma, y = mean)) +
  geom_ribbon(aes(ymin = mean - ci95,
                  ymax =  mean + ci95),
              alpha = 0.4) +
  geom_line(size = 0.3) +
  geom_point(size = 0.8) +
  ylab("Behavioral specificity") +
  xlab(expression( paste("Information correlation ", italic(gamma)) )) +
  theme_ctokita() 
gg_specif #show plot before saving
ggsave(plot = gg_specif, filename = paste0(out_path, "specificity", plot_tag, ".png"), width = 45, height = 45, units = "mm", dpi = 600)
ggsave(plot = gg_specif, filename = paste0(out_path, "specificity", plot_tag, ".svg"), width = 45, height = 45, units = "mm")


# Precision: proportion of activity (x_i = 1) that is due to "important" news.
precision_data <- behav_sum %>% 
  filter(metric == "precision")
gg_precis <- ggplot(data = precision_data, aes(x = gamma, y = mean)) +
  geom_ribbon(aes(ymin = mean - ci95,
                  ymax =  mean + ci95),
              alpha = 0.4) +
  geom_line(size = 0.3) +
  geom_point(size = 0.8) +
  ylab("Behavioral precision") +
  xlab(expression( paste("Information correlation ", italic(gamma)) )) +
  theme_ctokita() 
gg_precis #show plot before saving
ggsave(plot = gg_precis, filename = paste0(out_path, "precision", plot_tag, ".png"), width = 45, height = 45, units = "mm", dpi = 600)
ggsave(plot = gg_precis, filename = paste0(out_path, "precision", plot_tag, ".svg"), width = 45, height = 45, units = "mm")


# Individual fitness 
fitness_data <- behav_sum %>% 
  filter(metric == "fitness")
gg_fitness <- ggplot(data = fitness_data, aes(x = gamma, y = mean)) +
  geom_ribbon(aes(ymin = mean - ci95,
                  ymax =  mean + ci95),
              alpha = 0.4) +
  geom_line(size = 0.3) +
  geom_point(size = 0.8) +
  ylab("Information use fitness") +
  xlab(expression( paste("Information correlation ", italic(gamma)) )) +
  theme_ctokita() 
gg_fitness #show plot before saving
ggsave(plot = gg_fitness, filename = paste0(out_path, "fitness", plot_tag, ".png"), width = 45, height = 45, units = "mm", dpi = 600)

