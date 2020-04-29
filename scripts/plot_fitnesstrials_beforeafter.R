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
# Raw plot
####################

####################
# Plot: Total cascade activity
####################
# Filter
activity <- cascade_sum %>% 
  filter(metric == "total_active") %>% 
  mutate(time = factor(metric))

# Plot
pal <- brewer.pal(6, "PuOr")
gg_activity <- ggplot(activity, aes(x = trial, y = mean, color = gamma, group = gamma)) +
  geom_line(size = 0.3, alpha = 0.8) +
  geom_point(size = 0.8) +
  scale_color_gradientn(colors = pal) +
  scale_x_discrete(labels = c("Pre", "Post")) +
  ylab("Total cascade activity") +
  xlab("Fitness trial") +
  theme_ctokita()
gg_activity #show plot before saving


####################
# Plot: Avg.cascade size 
####################
# Filter
avgsize <- cascade_sum %>% 
  filter(metric == "avg_cascade_size") %>% 
  mutate(time = factor(metric))

# Plot
pal <- brewer.pal(6, "PuOr")
gg_size <- ggplot(avgsize, aes(x = trial, y = mean, color = gamma, group = gamma)) +
  geom_line(size = 0.3, alpha = 0.8) +
  geom_point(size = 0.8) +
  scale_color_gradientn(colors = pal) +
  scale_x_discrete(labels = c("Pre", "Post")) +
  scale_y_continuous(limits = c(0, 6)) +
  ylab("Avg. cascade size") +
  xlab("Fitness trial") +
  theme_ctokita()
gg_size #show plot before saving


####################
# Plot: Cascade bias
####################
# Filter
bias <- cascade_sum %>% 
  filter(metric == "cascade_bias") %>% 
  mutate(time = factor(metric))

# Plot
pal <- brewer.pal(8, "PuOr")
gg_bias <- ggplot(bias, aes(x = trial, y = mean, color = gamma, group = gamma)) +
  geom_line(size = 0.3, alpha = 0.8) +
  geom_point(size = 0.8) +
  scale_color_gradientn(colors = pal) +
  scale_x_discrete(labels = c("Pre", "Post")) +
  scale_y_continuous(limits = c(0.1, 0.7), 
                     breaks = seq(0.1, 0.7, 0.1)) +
  ylab("Cascade bias") +
  xlab("Fitness trial") +
  theme_ctokita()
gg_bias #show plot before saving



############################## Cascades: Average cascade over course of simulation for each gamma value ##############################

####################
# Load data and summarize
####################
# Read in data
avgcasc_data <- read.csv(cascadesum_path, header = TRUE) %>% 
  tidyr::gather("metric", "value", -gamma, -t)
avgcasc_sum <- avgcasc_data %>% 
  group_by(t, gamma, metric) %>% 
  summarise(mean = mean(value),
            sd = sd(value),
            ci95 = qnorm(0.975)*sd(value)/sqrt( sum(!is.na(value)) ))

####################
# Plot: Cascade size over course of simulation
####################
test <- avgcasc_data %>% 
  filter(gamma == 0.5, metric == "cascade_bias")
gg_sim_size <- ggplot(data = test, aes(x = t, y = value)) +
  geom_line()
gg_sim_size
