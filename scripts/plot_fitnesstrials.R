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
  scale_color_gradientn(colors = pal, name = expression(paste("Information\necosystem", gamma))) +
  scale_x_discrete(labels = c("Initial network", "Final network")) +
  scale_y_continuous(breaks = seq(0, 100, 10), limits = c(10, 60)) +
  ylab("Total cascade activity") +
  theme_ctokita() +
  theme(axis.title.x = element_blank())
gg_activity #show plot before saving
ggsave(plot = gg_activity, filename = paste0(out_path, "cascadeactivity", plot_tag ,".png"), width = 75, height = 45, units = "mm", dpi = 400)
ggsave(plot = gg_activity + theme(legend.position = "none"), filename = paste0(out_path, "cascadeactivity", plot_tag ,".svg"), width = 45, height = 45, units = "mm", dpi = 400)

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
  scale_color_gradientn(colors = pal, name = expression(paste("Information\necosystem", gamma))) +
  scale_x_discrete(labels = c("Initial network", "Final network")) +
  scale_y_continuous(breaks = seq(0, 6, 1), limits = c(0, 6)) +
  ylab("Avg. cascade size") +
  theme_ctokita() +
  theme(axis.title.x = element_blank())
gg_size #show plot before saving
ggsave(plot = gg_size, filename = paste0(out_path, "cascadesize", plot_tag ,".png"), width = 75, height = 45, units = "mm", dpi = 400)
ggsave(plot = gg_size + theme(legend.position = "none"), filename = paste0(out_path, "cascadesize", plot_tag ,".svg"), width = 45, height = 45, units = "mm", dpi = 400)


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
  scale_color_gradientn(colors = pal, name = expression(paste("Information\necosystem", gamma))) +
  scale_x_discrete(labels = c("Initial network", "Final network")) +
  scale_y_continuous(limits = c(0.1, 0.7), breaks = seq(0.1, 0.7, 0.1)) +
  ylab("Cascade bias") +
  theme_ctokita() +
  theme(axis.title.x = element_blank())
gg_bias #show plot before saving
ggsave(plot = gg_bias, filename = paste0(out_path, "cascadebias", plot_tag ,".png"), width = 75, height = 45, units = "mm", dpi = 400)
ggsave(plot = gg_bias + theme(legend.position = "none"), filename = paste0(out_path, "cascadebias", plot_tag ,".svg"), width = 45, height = 45, units = "mm", dpi = 400)



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
  scale_color_gradientn(colors = pal, name = expression(paste("Information\necosystem", gamma))) +
  scale_x_discrete(labels = c("Initial network", "Final network")) +
  ylab("Behavior frequency") +
  theme_ctokita() +
  theme(axis.line = element_line(),
        axis.title.x = element_blank()) +
  facet_wrap(~metric, scales = "free")
gg_behavrates #show plot before saving
ggsave(plot = gg_behavrates, filename = paste0(out_path, "behaviorrates", plot_tag ,".png"), width = 120, height = 90, units = "mm", dpi = 400)
ggsave(plot = gg_behavrates, filename = paste0(out_path, "behaviorrates", plot_tag ,".svg"), width = 120, height = 90, units = "mm", dpi = 400)
ggsave(plot = gg_behavrates + facet_wrap(~metric, scales = "fixed"), filename = paste0(out_path, "behaviorrates_fixedscale", plot_tag ,".png"), width = 120, height = 90, units = "mm", dpi = 400)



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
  scale_color_gradientn(colors = pal, name = expression(paste("Information\necosystem", gamma))) +
  scale_x_discrete(labels = c("Initial network", "Final network")) +
  scale_y_continuous(breaks = seq(0, 1, 0.05), limits = c(0.1, 0.4)) +
  ylab("Sensitivity") +
  theme_ctokita() +
  theme(axis.title.x = element_blank())
gg_sens #show plot before saving
ggsave(plot = gg_sens, filename = paste0(out_path, "sensitivity", plot_tag ,".png"), width = 75, height = 45, units = "mm", dpi = 400)
ggsave(plot = gg_sens + theme(legend.position = "none"), filename = paste0(out_path, "sensitivity", plot_tag ,".svg"), width = 45, height = 45, units = "mm")

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
  scale_color_gradientn(colors = pal, name = expression(paste("Information\necosystem", gamma))) +
  scale_x_discrete(labels = c("Initial network", "Final network")) +
  scale_y_continuous(breaks = seq(0, 1, 0.05), limits = c(0.75, 1), expand = c(0, 0.005)) +
  ylab("Specificity") +
  theme_ctokita() +
  theme(axis.title.x = element_blank())
gg_spec #show plot before saving
ggsave(plot = gg_spec, filename = paste0(out_path, "specificity", plot_tag ,".png"), width = 75, height = 45, units = "mm", dpi = 400)
ggsave(plot = gg_spec + theme(legend.position = "none"), filename = paste0(out_path, "specificity", plot_tag ,".svg"), width = 45, height = 45, units = "mm")

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
  scale_color_gradientn(colors = pal, name = expression(paste("Information\necosystem", gamma))) +
  scale_x_discrete(labels = c("Initial network", "Final network")) +
  scale_y_continuous(breaks = seq(0, 1, 0.05), limits = c(0.85, 1), expand = c(0, 0.005)) +
  ylab("Precision") +
  theme_ctokita() +
  theme(axis.title.x = element_blank())
gg_prec #show plot before saving
ggsave(plot = gg_prec, filename = paste0(out_path, "precision", plot_tag ,".png"), width = 75, height = 45, units = "mm", dpi = 400)
ggsave(plot = gg_prec + theme(legend.position = "none"), filename = paste0(out_path, "precision", plot_tag ,".svg"), width = 45, height = 45, units = "mm")



############################## Ftiness trials: Behavior, by high and low threshold ##############################

####################
# Load data 
####################
# Read in data
behav_data <- read.csv(fit_behavior_path, header = TRUE)

# Summarise
behav_sum_lowthresh <- behav_data %>% 
  filter(threshold < 0.25) %>% 
  gather(metric, value, -gamma, -trial) %>% 
  mutate(trial = factor(trial, levels = c("pre", "post"))) %>% 
  group_by(trial, gamma, metric) %>% 
  summarise(mean = mean(value, na.rm = TRUE),
            sd = sd(value, na.rm = TRUE),
            ci95 = qnorm(0.975) * sd(value, na.rm = TRUE) / sqrt( sum(!is.na(value)) )) #denominator removes NA values from count

behav_sum_highthresh <- behav_data %>% 
  filter(threshold > 0.75) %>% 
  gather(metric, value, -gamma, -trial) %>% 
  mutate(trial = factor(trial, levels = c("pre", "post"))) %>% 
  group_by(trial, gamma, metric) %>% 
  summarise(mean = mean(value, na.rm = TRUE),
            sd = sd(value, na.rm = TRUE),
            ci95 = qnorm(0.975) * sd(value, na.rm = TRUE) / sqrt( sum(!is.na(value)) )) #denominator removes NA values from count

####################
# Plot: Base behavior rates, low threshold
####################
# Filter
behavrates_lowthresh <- behav_sum_lowthresh %>% 
  filter(metric %in% c("true_positive", "true_negative", "false_positive", "false_negative")) %>% 
  mutate(metric = factor(metric, levels = c("true_positive", "false_positive", "false_negative", "true_negative"))) %>% 
  mutate(news = NA, 
         reaction = NA)
levels(behavrates_lowthresh$metric) <- c("TP", "FP", "FN", "TN")

# Plot
gg_behavrates_lowthresh <- ggplot(behavrates_lowthresh, aes(x = trial, y = mean, color = gamma, group = gamma)) +
  geom_line(size = 0.3, alpha = 0.8) +
  geom_point(size = 0.8) +
  scale_color_gradientn(colors = pal, name = expression(paste("Information\necosystem", gamma))) +
  scale_x_discrete(labels = c("Initial", "Final")) +
  ylab("Behavior frequency") +
  theme_ctokita() +
  theme(strip.text = element_blank(),
        legend.position = "none",
        axis.line = element_line(),
        axis.title.x = element_blank()) +
  facet_wrap(~metric, scales = "free")
gg_behavrates_lowthresh #show plot before saving
ggsave(plot = gg_behavrates_lowthresh, filename = paste0(out_path, "behaviorrates_lowthresh", plot_tag ,".png"), width = 55, height = 45, units = "mm", dpi = 400)
ggsave(plot = gg_behavrates_lowthresh, filename = paste0(out_path, "behaviorrates_lowthresh", plot_tag ,".svg"), width = 55, height = 45, units = "mm")


####################
# Plot: Base behavior rates, high threshold
####################
# Filter
behavrates_highthresh <- behav_sum_highthresh %>% 
  filter(metric %in% c("true_positive", "true_negative", "false_positive", "false_negative")) %>% 
  mutate(metric = factor(metric, levels = c("true_positive", "false_positive", "false_negative", "true_negative"))) %>% 
  mutate(news = NA, 
         reaction = NA)
levels(behavrates_highthresh$metric) <- c("TP", "FP", "FN", "TN")

# Plot
gg_behavrates_highthresh <- ggplot(behavrates_highthresh, aes(x = trial, y = mean, color = gamma, group = gamma)) +
  geom_line(size = 0.3, alpha = 0.8) +
  geom_point(size = 0.8) +
  scale_color_gradientn(colors = pal, name = expression(paste("Information\necosystem", gamma))) +
  scale_x_discrete(labels = c("Initial", "Final")) +
  ylab("Behavior frequency") +
  theme_ctokita() +
  theme(strip.text = element_blank(),
        axis.line = element_line(),
        axis.title.x = element_blank(),
        legend.position = "none") +
  facet_wrap(~metric, scales = "free")
gg_behavrates_highthresh #show plot before saving
ggsave(plot = gg_behavrates_highthresh, filename = paste0(out_path, "behaviorrates_highthresh", plot_tag ,".png"), width = 55, height = 45, units = "mm", dpi = 400)
ggsave(plot = gg_behavrates_highthresh, filename = paste0(out_path, "behaviorrates_highthresh", plot_tag ,".svg"), width = 55, height = 45, units = "mm")
