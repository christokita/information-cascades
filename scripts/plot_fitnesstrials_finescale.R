########################################
#
# PLOT: Fitness trials done before and after model simulation--fine scale statistics
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
cascade_data <- read.csv(fit_cascade_path, header = TRUE) %>% 
  gather(metric, value, -trial, -gamma) %>% 
  mutate(trial = factor(trial, levels = c("pre", "post"))) %>% 
  mutate(gamma = round(gamma, digits = 2)) #weird representation of the numbers that aren't precise


####################
# Plot: Avg.cascade size 
####################
# Filter
avgsize <- cascade_data %>% 
  filter(metric == "avg_cascade_size") %>% 
  filter(gamma %in% c(-1, -0.8, 0, 0.8, 1))
  

# Plot
gg_sizedist <- ggplot(avgsize, aes(fill = trial)) +
  geom_histogram(aes(x = value)) +
  ylab("Frequency") +
  xlab("Avg. cascade size") +
  scale_x_continuous(breaks = c(0, 1, 2, 3, 4, 5, 10), trans="log1p", expand=c(0,0)) +
  scale_y_continuous(breaks =c(0, 10, 100), trans="log1p", expand=c(0,0)) +
  theme_ctokita() +
  facet_grid(trial~gamma)
gg_sizedist #show plot before saving
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
  scale_color_gradientn(colors = pal, name = expression(paste("Information\necosystem", gamma))) +
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
behav_data <- read.csv(fit_behavior_path, header = TRUE) %>% 
  gather(metric, value, -gamma, -trial) %>% 
  mutate(trial = factor(trial, levels = c("pre", "post")))

