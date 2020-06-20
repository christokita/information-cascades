########################################
#
# PLOT: Fitness trials done before and after model simulation, with same gamma in all fitness trials
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
###################
# Path to data and for output
highcorr_fit_cascade_path <- 'data_derived/network_break/fitness_trials/fitness_cascadestats_highcorr.csv' #path to fitness cascade data
highcorr_fit_behavior_path <- "data_derived/network_break/fitness_trials/fitness_behavior_highcorr.csv" #path to fitness behavior data
lowcorr_fit_cascade_path <- 'data_derived/network_break/fitness_trials/fitness_cascadestats_lowcorr.csv' #path to fitness cascade data
lowcorr_fit_behavior_path <- "data_derived/network_break/fitness_trials/fitness_behavior_lowcorr.csv" #path to fitness behavior data
out_path <- "output/network_break/fitness_trials/same_gamma_trials/" #directory you wish to save plots

# Plot color
plot_color <- "#1B3B6F"
pal <- brewer.pal(4, "PuOr")

# Facet labels
facet_labels <- c("High info.\ncorrelation", "Low info.\ncorrelation")

# Modify theme
theme_ctokita() <- theme_ctokita() +
  theme(strip.background = element_blank())


############################## Ftiness trials: Cascade dynamics ##############################

####################
# Load data 
####################
# Read in data
highcorr_cascade_data <- read.csv(highcorr_fit_cascade_path, header = TRUE) %>% 
  mutate(info = "High correlation\ninfo.ecosystem")
lowcorr_cascade_data <- read.csv(lowcorr_fit_cascade_path, header = TRUE) %>% 
  mutate(info = "Low correlation\ninfo.ecosystem")
cascade_data <- rbind(highcorr_cascade_data, lowcorr_cascade_data)

# Summarize by gamma
cascade_sum <- cascade_data %>% 
  gather(metric, value, -trial, -gamma, -info) %>% 
  mutate(trial = factor(trial, levels = c("pre", "post"))) %>% 
  group_by(info, trial, gamma, metric) %>% 
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
  scale_color_gradientn(colors = pal, name = expression(paste("Model simulation\ninfo. ecosystem ", gamma))) +
  scale_x_discrete(labels = c("Pre", "Post")) +
  scale_y_continuous(breaks = seq(0, 100, 10), limits = c(10, 60)) +
  ylab("Total cascade activity") +
  xlab("Fitness trial") +
  theme_ctokita() +
  facet_wrap(~info)
gg_activity #show plot before saving
ggsave(gg_activity, filename = paste0(out_path, "cascadeactivity_samegamma.png"), width = 90, height = 45, units = "mm")

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
  scale_color_gradientn(colors = pal, name = expression(paste("Model simulation\ninfo. ecosystem ", gamma))) +
  scale_x_discrete(labels = c("Pre", "Post")) +
  scale_y_continuous(breaks = seq(0, 6, 1), limits = c(0, 6)) +
  ylab("Avg. cascade size") +
  xlab("Fitness trial") +
  theme_ctokita() +
  facet_wrap(~info)
gg_size #show plot before saving
ggsave(gg_size, filename = paste0(out_path, "cascadesize_samegamma.png"), width = 90, height = 45, units = "mm")

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
  scale_color_gradientn(colors = pal, name = expression(paste("Model simulation\ninfo. ecosystem ", gamma))) +
  scale_x_discrete(labels = c("Pre", "Post")) +
  scale_y_continuous(limits = c(0.1, 0.7), breaks = seq(0.1, 0.7, 0.1)) +
  ylab("Cascade bias") +
  xlab("Fitness trial") +
  theme_ctokita() +
  facet_wrap(~info)
gg_bias #show plot before saving
ggsave(gg_bias, filename = paste0(out_path, "cascadebias_samegamma.png"), width = 90, height = 45, units = "mm")



############################## Ftiness trials: Behavior ##############################

####################
# Load data 
####################
# Read in data
highcorr_behav_data <- read.csv(highcorr_fit_behavior_path, header = TRUE) %>% 
  mutate(info = "High correlation\ninfo.ecosystem")
lowcorr_behav_data <- read.csv(lowcorr_fit_behavior_path, header = TRUE) %>% 
  mutate(info = "Low correlation\ninfo.ecosystem")
behav_data <- rbind(highcorr_behav_data, lowcorr_behav_data)

# Summarise
behav_sum <- behav_data %>% 
  gather(metric, value, -gamma, -trial, -info) %>% 
  mutate(trial = factor(trial, levels = c("pre", "post"))) %>% 
  group_by(info, trial, gamma, metric) %>% 
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
  scale_color_gradientn(colors = pal, name = expression(paste("Model simulation\ninfo. ecosystem ", gamma))) +
  scale_x_discrete(labels = c("Pre", "Post")) +
  ylab("Behavior frequency") +
  xlab("Fitness trial") +
  theme_ctokita() +
  theme(strip.background = element_rect(color = NA, fill = "grey90"),
        axis.line = element_line()) +
  facet_wrap(info~metric, ncol = 4, scales = "free")
gg_behavrates #show plot before saving
ggsave(gg_behavrates, filename = paste0(out_path, "behaviorrates_samegamma.png"), width = 180, height = 90, units = "mm")

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
  scale_color_gradientn(colors = pal, name = expression(paste("Model simulation\ninfo. ecosystem ", gamma))) +
  scale_x_discrete(labels = c("Pre", "Post")) +
  scale_y_continuous(breaks = seq(0, 1, 0.05)) +
  ylab("Sensitivity") +
  xlab("Fitness trial") +
  theme_ctokita() +
  facet_wrap(~info, scales = "free_y")
gg_sens #show plot before saving
ggsave(gg_sens, filename = paste0(out_path, "sensitivity_samegamma.png"), width = 90, height = 45, units = "mm")

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
  scale_color_gradientn(colors = pal, name = expression(paste("Model simulation\ninfo. ecosystem ", gamma))) +
  scale_x_discrete(labels = c("Pre", "Post")) +
  scale_y_continuous(breaks = seq(0, 1, 0.05), expand = c(0, 0.005)) +
  ylab("Specificity") +
  xlab("Fitness trial") +
  theme_ctokita() +
  facet_wrap(~info, scales = "free_y")
gg_spec #show plot before saving
ggsave(gg_spec, filename = paste0(out_path, "specificity_samegamma.png"), width = 90, height = 45, units = "mm")

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
  scale_color_gradientn(colors = pal, name = expression(paste("Model simulation\ninfo. ecosystem ", gamma))) +
  scale_x_discrete(labels = c("Pre", "Post")) +
  scale_y_continuous(breaks = seq(0, 1, 0.05), limits = c(0.85, 1), expand = c(0, 0.005)) +
  ylab("Precision") +
  xlab("Fitness trial") +
  theme_ctokita() +
  facet_wrap(~info, scales = "free_y")
gg_prec #show plot before saving
ggsave(gg_prec, filename = paste0(out_path, "precision_samegamma.png"), width = 90, height = 45, units = "mm")
