########################################
#
# PLOT: Fitness trials done before and after model simulation
#
########################################

####################
# Load packages
####################
library(ggplot2)
library(dplyr)
library(tidyr)
library(RColorBrewer)
source("scripts/_plot_themes/theme_ctokita.R")

####################
# Paramters for analysis: paths to data, paths for output, and filename
####################
fit_cascade_path <- 'data_derived/network_break/fitness_trials/fitness_cascadestats.csv' #path to fitness cascade data
fit_behavior_path <- "data_derived/network_break/fitness_trials/fitness_behavior.csv" #path to fitness behavior data
out_path <- "output/network_break/fitness_trials/" #directory you wish to save plots
plot_tag <- "" #extra info to add onto end of plot name (if supplemental analysis)
if (plot_tag != "") {
  plot_tag <- paste0("_", plot_tag)
}

# Plot color
plot_color <- "#1B3B6F"
pal <- brewer.pal(4, "PuOr")


############################## Ftiness trials: Cascade dynamics ##############################

####################
# Load data 
####################
# Read in data
cascade_data <- read.csv(fit_cascade_path, header = TRUE)

# Summarize by gamma
cascade_sum <- cascade_data %>% 
  gather(metric, value, -trial, -gamma) %>% 
  mutate(trial = factor(trial, levels = c("pre", "post"))) %>% 
  group_by(trial, gamma, metric) %>% 
  summarise(mean = mean(value, na.rm = TRUE),
            sd = sd(value, na.rm = TRUE),
            ci95 = qnorm(0.975) * sd(value, na.rm = TRUE) / sqrt( sum(!is.na(value)) )) #denominator removes NA values from count

####################
# Plot: Total cascade activity
####################
# Filter
activity <- cascade_sum %>% 
  filter(metric == "total_active")

# Plot
gg_activity <- ggplot(activity, aes(x = trial, y = mean, color = gamma, group = gamma)) +
  geom_line(size = 0.3, alpha = 0.8) +
  geom_point(size = 0.8) +
  scale_color_gradientn(colors = pal, name = expression(paste("Information\ncorrelation", gamma))) +
  scale_x_discrete(labels = c("Pre", "Post")) +
  scale_y_continuous(breaks = seq(0, 100, 10), limits = c(10, 60)) +
  ylab("Total cascade activity") +
  xlab("Fitness trial") +
  theme_ctokita()
gg_activity #show plot before saving
ggsave(plot = gg_activity, filename = paste0(out_path, "cascadeactivity", plot_tag ,".png"), width = 75, height = 45, units = "mm", dpi = 400)

####################
# Plot: Avg.cascade size 
####################
# Filter
avgsize <- cascade_sum %>% 
  filter(metric == "avg_cascade_size")

# Plot
gg_size <- ggplot(avgsize, aes(x = trial, y = mean, color = gamma, group = gamma)) +
  geom_line(size = 0.3, alpha = 0.8) +
  geom_point(size = 0.8) +
  scale_color_gradientn(colors = pal, name = expression(paste("Information\ncorrelation", gamma))) +
  scale_x_discrete(labels = c("Pre", "Post")) +
  scale_y_continuous(breaks = seq(0, 6, 1), limits = c(0, 6)) +
  ylab("Avg. cascade size") +
  xlab("Fitness trial") +
  theme_ctokita()
gg_size #show plot before saving
ggsave(plot = gg_size, filename = paste0(out_path, "cascadesize", plot_tag ,".png"), width = 75, height = 45, units = "mm", dpi = 400)

####################
# Plot: Cascade bias
####################
# Filter
bias <- cascade_sum %>% 
  filter(metric == "cascade_bias")

# Plot
gg_bias <- ggplot(bias, aes(x = trial, y = mean, color = gamma, group = gamma)) +
  geom_line(size = 0.3, alpha = 0.8) +
  geom_point(size = 0.8) +
  scale_color_gradientn(colors = pal, name = expression(paste("Information\ncorrelation", gamma))) +
  scale_x_discrete(labels = c("Pre", "Post")) +
  scale_y_continuous(limits = c(0.1, 0.7), breaks = seq(0.1, 0.7, 0.1)) +
  ylab("Cascade bias") +
  xlab("Fitness trial") +
  theme_ctokita()
gg_bias #show plot before saving
ggsave(plot = gg_bias, filename = paste0(out_path, "cascadebias", plot_tag ,".png"), width = 75, height = 45, units = "mm", dpi = 400)


############################## Ftiness trials: Behavior ##############################

####################
# Load data 
####################
# Read in data
behav_data <- read.csv(fit_behavior_path, header = TRUE)

# Summarise
behav_sum <- behav_data %>% 
  gather(metric, value, -gamma, -trial) %>% 
  mutate(trial = factor(trial, levels = c("pre", "post"))) %>% 
  group_by(trial, gamma, metric) %>% 
  summarise(mean = mean(value, na.rm = TRUE),
            sd = sd(value, na.rm = TRUE),
            ci95 = qnorm(0.975) * sd(value, na.rm = TRUE) / sqrt( sum(!is.na(value)) )) #denominator removes NA values from count

####################
# Plot: Base behavior rates
####################
# Filter
behavrates <- behav_sum %>% 
  filter(metric %in% c("true_positive", "true_negative", "false_positive", "false_negative")) %>% 
  mutate(metric = factor(metric, levels = c("true_positive", "false_positive", "false_negative", "true_negative"))) %>% 
  mutate(news = NA, 
         reaction = NA)
levels(behavrates$metric) <- c("True positive", "False positive", "False negative", "True negative")

# Plot
gg_behavrates <- ggplot(behavrates, aes(x = trial, y = mean, color = gamma, group = gamma)) +
  geom_line(size = 0.3, alpha = 0.8) +
  geom_point(size = 0.8) +
  scale_color_gradientn(colors = pal, name = expression(paste("Information\ncorrelation", gamma))) +
  scale_x_discrete(labels = c("Pre", "Post")) +
  ylab("Behavior frequency") +
  xlab("Fitness trial") +
  theme_ctokita() +
  theme(strip.background = element_rect(color = NA, fill = "grey90"),
        axis.line = element_line()) +
  facet_wrap(~metric, scales = "free_x")
gg_behavrates #show plot before saving
ggsave(plot = gg_behavrates, filename = paste0(out_path, "behaviorrates", plot_tag ,".png"), width = 120, height = 90, units = "mm", dpi = 400)
ggsave(plot = gg_behavrates + facet_wrap(~metric, scales = "free"), filename = paste0(out_path, "behaviorrates_rescaled", plot_tag ,".png"), width = 120, height = 90, units = "mm", dpi = 400)



####################
# Plot: Sensitivity
####################
# Filter
sensitivity <- behav_sum %>% 
  filter(metric == "sensitivity") 

# Plot
gg_sens <- ggplot(sensitivity, aes(x = trial, y = mean, color = gamma, group = gamma)) +
  geom_line(size = 0.3, alpha = 0.8) +
  geom_point(size = 0.8) +
  scale_color_gradientn(colors = pal, name = expression(paste("Information\ncorrelation", gamma))) +
  scale_x_discrete(labels = c("Pre", "Post")) +
  scale_y_continuous(breaks = seq(0, 1, 0.05), limits = c(0.1, 0.4)) +
  ylab("Sensitivity") +
  xlab("Fitness trial") +
  theme_ctokita()
gg_sens #show plot before saving
ggsave(plot = gg_sens, filename = paste0(out_path, "sensitivity", plot_tag ,".png"), width = 75, height = 45, units = "mm", dpi = 400)

####################
# Plot: Specificity
####################
# Filter
specificity <- behav_sum %>% 
  filter(metric == "specificity") 

# Plot
gg_spec <- ggplot(specificity, aes(x = trial, y = mean, color = gamma, group = gamma)) +
  geom_line(size = 0.3, alpha = 0.8) +
  geom_point(size = 0.8) +
  scale_color_gradientn(colors = pal, name = expression(paste("Information\ncorrelation", gamma))) +
  scale_x_discrete(labels = c("Pre", "Post")) +
  scale_y_continuous(breaks = seq(0, 1, 0.05), limits = c(0.75, 1), expand = c(0, 0.005)) +
  ylab("Specificity") +
  xlab("Fitness trial") +
  theme_ctokita()
gg_spec #show plot before saving
ggsave(plot = gg_spec, filename = paste0(out_path, "specificity", plot_tag ,".png"), width = 75, height = 45, units = "mm", dpi = 400)

####################
# Plot: Precision
####################
# Filter
precision <- behav_sum %>% 
  filter(metric == "precision")

# Plot
gg_prec <- ggplot(precision, aes(x = trial, y = mean, color = gamma, group = gamma)) +
  geom_line(size = 0.3, alpha = 0.8) +
  geom_point(size = 0.8) +
  scale_color_gradientn(colors = pal, name = expression(paste("Information\ncorrelation", gamma))) +
  scale_x_discrete(labels = c("Pre", "Post")) +
  scale_y_continuous(breaks = seq(0, 1, 0.05), limits = c(0.85, 1), expand = c(0, 0.005)) +
  ylab("Precision") +
  xlab("Fitness trial") +
  theme_ctokita()
gg_prec #show plot before saving
ggsave(plot = gg_prec, filename = paste0(out_path, "precision", plot_tag ,".png"), width = 75, height = 45, units = "mm", dpi = 400)
