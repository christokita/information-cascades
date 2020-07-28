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
source("_plot_themes/theme_ctokita.R")

####################
# Paramters for analysis: paths to data, paths for output, and filename
####################
fit_cascade_path <- "model/data_derived/network_break/fitness_trials/fitness_cascadestats.csv" #path to fitness cascade data
fit_behavior_path <- "model/data_derived/network_break/fitness_trials/fitness_behavior.csv" #path to fitness behavior data
out_path <- "model/output/network_break/fitness_trials/" #directory you wish to save plots
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
  mutate(trial = recode(trial,"pre" = "Pre-NB", "post" = "post-NB"),
         gamma = round(gamma, digits = 2)) #weird representation of the numbers that aren't precise


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

####################
# Plot: Cascade bias
####################
# Filter
bias <- cascade_data %>% 
  filter(metric == "cascade_bias",
         gamma %in% seq(-1, 1, 0.5))

# Plot
gg_bias <- ggplot(bias, aes(fill = trial)) +
  geom_histogram(aes(x = value)) +
  ylab("Cascade bias") +
  xlab("Fitness trial") +
  theme_ctokita() +
  facet_grid(trial~gamma)
gg_bias #show plot before saving



############################## Ftiness trials: Behavior, compare to thresholds ##############################

####################
# Load data 
####################
# Read in data
behav_data <- read.csv(fit_behavior_path, header = TRUE) %>% 
  mutate(active = true_positive + false_positive) %>% 
  gather(metric, value, -gamma, -trial, -threshold) %>% 
  mutate(trial = factor(trial, levels = c("pre", "post"))) %>% 
  mutate(trial = recode(trial,"pre" = "Initial network", "post" = "Final network"))

# Select gammas
gamma_vals <- c(-1, -0.4, 0.0, 0.4, 0.9, 1)


####################
# Plot: Total activity rates vs threshold
####################
# Filter
activity <- behav_data %>% 
  filter(metric == "active",
         gamma %in% gamma_vals)

# Plot
gg_act <- ggplot(activity, aes(x = threshold, y = value, color = gamma)) +
  geom_point(size = 0.2, alpha = 0.2, stroke = 0) +
  scale_x_continuous(breaks = seq(0, 1, 1)) +
  scale_color_gradientn(colors = pal, name = expression(paste("Information\necosystem", gamma))) +
  ylab("Activity") +
  xlab(expression(paste("Threshold, ", theta[i]))) +
  theme_ctokita() +
  theme(legend.position = "none",
        aspect.ratio = 2,
        strip.text.y = element_text(face = "bold")) +
  facet_grid(trial~gamma, 
             labeller = label_bquote(cols = gamma == .(gamma)))
gg_act
ggsave(gg_act, filename = paste0(out_path, "threshold-activity.png"), width = 90, height = 60, units = "mm")

####################
# Plot: Base behavior rates vs threshold
####################
# Filter
baserates <- behav_data %>% 
  filter(metric %in% c("false_positive", "false_negative", "true_positive", "true_negative"),
         gamma %in% gamma_vals)

# True Positive
gg_tp <- ggplot(baserates %>% filter(metric == "true_positive"), aes(x = threshold, y = value, color = gamma)) +
  geom_point(size = 0.2, alpha = 0.2, stroke = 0) +
  scale_x_continuous(breaks = seq(0, 1, 1)) +
  scale_color_gradientn(colors = pal, name = expression(paste("Information\necosystem", gamma))) +
  ylab("True positive") +
  xlab(expression(paste("Threshold, ", theta[i]))) +
  theme_ctokita() +
  theme(legend.position = "none",
        aspect.ratio = 2) +
  facet_grid(trial~gamma, 
             labeller = label_bquote(cols = gamma == .(gamma)))
gg_tp #show plot before saving
ggsave(gg_tp, filename = paste0(out_path, "threshold-truepositive.png"), width = 90, height = 60, units = "mm")

# False Positive
gg_fp <- ggplot(baserates %>% filter(metric == "false_positive"), aes(x = threshold, y = value, color = gamma)) +
  geom_point(size = 0.2, alpha = 0.2, stroke = 0) +
  scale_x_continuous(breaks = seq(0, 1, 1)) +
  scale_color_gradientn(colors = pal, name = expression(paste("Information\necosystem", gamma))) +
  ylab("False positive") +
  xlab(expression(paste("Threshold, ", theta[i]))) +
  theme_ctokita() +
  theme(legend.position = "none",
        aspect.ratio = 2,
        strip.text.y = element_text(face = "bold")) +
  facet_grid(trial~gamma, 
             labeller = label_bquote(cols = gamma == .(gamma)))
gg_fp #show plot before saving
ggsave(gg_fp, filename = paste0(out_path, "threshold-falsepositive.png"), width = 90, height = 60, units = "mm")

# True Negative
gg_tn <- ggplot(baserates %>% filter(metric == "true_negative"), aes(x = threshold, y = value, color = gamma)) +
  geom_point(size = 0.2, alpha = 0.2, stroke = 0) +
  scale_x_continuous(breaks = seq(0, 1, 1)) +
  scale_color_gradientn(colors = pal, name = expression(paste("Information\necosystem", gamma))) +
  ylab("True negative") +
  xlab(expression(paste("Threshold, ", theta[i]))) +
  theme_ctokita() +
  theme(legend.position = "none",
        aspect.ratio = 2,
        strip.text.y = element_text(face = "bold")) +
  facet_grid(trial~gamma, 
             labeller = label_bquote(cols = gamma == .(gamma)))
gg_tn #show plot before saving
ggsave(gg_tn, filename = paste0(out_path, "threshold-truenegative.png"), width = 90, height = 60, units = "mm")

# False Negative
gg_fn <- ggplot(baserates %>% filter(metric == "false_negative"), aes(x = threshold, y = value, color = gamma)) +
  geom_point(size = 0.2, alpha = 0.2, stroke = 0) +
  scale_x_continuous(breaks = seq(0, 1, 1)) +
  scale_color_gradientn(colors = pal, name = expression(paste("Information\necosystem", gamma))) +
  ylab("False negative") +
  xlab(expression(paste("Threshold, ", theta[i]))) +
  theme_ctokita() +
  theme(legend.position = "none",
        aspect.ratio = 2,
        strip.text.y = element_text(face = "bold")) +
  facet_grid(trial~gamma, 
             labeller = label_bquote(cols = gamma == .(gamma)))
gg_fn #show plot before saving
ggsave(gg_fn, filename = paste0(out_path, "threshold-falsenegative.png"), width = 90, height = 60, units = "mm")


####################
# Plot: Sensitivity vs threshold
####################
# Filter
sens <- behav_data %>% 
  filter(metric == "sensitivity",
         gamma %in% gamma_vals)

# Plot
gg_sens <- ggplot(sens, aes(x = threshold, y = value, color = gamma)) +
  geom_point(size = 0.2, alpha = 0.2, stroke = 0) +
  scale_x_continuous(breaks = seq(0, 1, 1)) +
  scale_color_gradientn(colors = pal, name = expression(paste("Information\necosystem", gamma))) +
  ylab("Sensitivity") +
  xlab(expression(paste("Threshold, ", theta[i]))) +
  theme_ctokita() +
  theme(legend.position = "none",
        aspect.ratio = 2,
        strip.text.y = element_text(face = "bold")) +
  facet_grid(trial~gamma, 
             labeller = label_bquote(cols = gamma == .(gamma)))
gg_sens #show plot before saving
ggsave(gg_sens, filename = paste0(out_path, "threshold-sensitivity.png"), width = 90, height = 60, units = "mm")


####################
# Plot: Specificity vs threshold
####################
# Filter
spec <- behav_data %>% 
  filter(metric == "specificity",
         gamma %in% gamma_vals)

# Plot
gg_spec <- ggplot(spec, aes(x = threshold, y = value, color = gamma)) +
  geom_point(size = 0.2, alpha = 0.2, stroke = 0) +
  scale_x_continuous(breaks = seq(0, 1, 1)) +
  scale_color_gradientn(colors = pal, name = expression(paste("Information\necosystem", gamma))) +
  ylab("Specificity") +
  xlab(expression(paste("Threshold, ", theta[i]))) +
  theme_ctokita() +
  theme(legend.position = "none",
        aspect.ratio = 2,
        strip.text.y = element_text(face = "bold")) +
  facet_grid(trial~gamma, 
             labeller = label_bquote(cols = gamma == .(gamma)))
gg_spec #show plot before saving
ggsave(gg_spec, filename = paste0(out_path, "threshold-specificity.png"), width = 90, height = 60, units = "mm")


####################
# Plot: Precision vs threshold
####################
# Filter
prec <- behav_data %>% 
  filter(metric == "precision",
         gamma %in% gamma_vals)

# Plot
gg_prec <- ggplot(prec, aes(x = threshold, y = value, color = gamma)) +
  geom_point(size = 0.2, alpha = 0.2, stroke = 0) +
  scale_x_continuous(breaks = seq(0, 1, 1)) +
  scale_color_gradientn(colors = pal, name = expression(paste("Information\necosystem", gamma))) +
  ylab("Precision") +
  xlab(expression(paste("Threshold, ", theta[i]))) +
  theme_ctokita() +
  theme(legend.position = "none",
        aspect.ratio = 2,
        strip.text.y = element_text(face = "bold")) +
  facet_grid(trial~gamma, 
             labeller = label_bquote(cols = gamma == .(gamma)))
gg_prec #show plot before saving
ggsave(gg_prec, filename = paste0(out_path, "threshold-precision.png"), width = 90, height = 60, units = "mm")

