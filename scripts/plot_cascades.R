##############################
#
# PLOT: Cascade dynamics figures
#
##############################

##########
# Load packages
##########
library(ggplot2)
library(tidyr)
library(dplyr)
library(RColorBrewer)
library(scales)
library(ggpubr)

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
          legend.key.size = unit(3, "mm"))
}


########## Ftiness trials ##########

##########
# Load data 
##########
# Read in data
cascade_data <- read.csv('output/network_break/data_derived/cascades/n200_fitness_cascadesize_gammasweep.csv', header = TRUE)

##########
# Plot: Cascade size
##########
# Summarise by gamma
cascade_size <- cascade_data %>% 
  select(gamma, total_active) %>% 
  group_by(gamma) %>% 
  summarise_each(list(size_mean = mean, 
                      size_sd = sd, 
                      rep_count = length)) %>% 
  mutate(size_95ci = qnorm(0.975) * size_sd / sqrt(rep_count))

# Plot
gg_size <- ggplot(cascade_size, aes(x = gamma, y = size_mean)) +
  # Plot all data
  geom_errorbar(aes(ymin = size_mean - size_95ci, 
                    ymax = size_mean + size_95ci), 
                size = 0.2, 
                width = 0) +
  geom_point(size = 0.8) +
  # General plotting controls
  scale_y_continuous(limits = c(18, 28), breaks = seq(16, 28, 2)) +
  ylab(expression( paste("Cascade size, ", italic(X[t]) ))) +
  xlab(expression(paste("Information correlation, ", italic(gamma) ))) +
  theme_ctokita() 

gg_size 
ggsave("output/network_break/plots/CascadeSize_gamma.png", width = 45, height = 45, units = "mm", dpi = 400)


##########
# Plot: Cascade bias
##########
# Summarise by gamma
cascade_diff <- cascade_data %>% 
  select(gamma, active_diff_prop) %>% 
  group_by(gamma) %>% 
  summarise_each(list(bias_mean = mean, 
                      bias_sd = sd, 
                      rep_count = length)) %>% 
  mutate(bias_95ci = qnorm(0.975) * bias_sd / sqrt(rep_count))

# Summarizing plot
gg_diff <- ggplot(cascade_diff, aes(x = gamma, y = bias_mean)) +
  # Plot all data
  geom_errorbar(aes(ymin = bias_mean - bias_95ci, ymax = bias_mean + bias_95ci),
                size = 0.2,
                width = 0) +
  geom_point(size = 0.8) +
  # General plotting controls
  # scale_y_continuous(limits = c(0, 0.16)) +
  ylab(expression( paste("Cascade bias" ))) +
  xlab(expression(paste("Information correlation, ", italic(gamma) ))) +
  theme_ctokita() 

gg_diff
ggsave("output/network_break/plots/CascadeBias_gamma.png", width = 45, height = 45, units = "mm", dpi = 400)


# ########## Cacades during simuilation ##########
# 
# ##########
# # Load data 
# ##########
# # Read in data
# cascade_data <- read.csv('output/network_break/data_derived/cascades/n200_gammasweep.csv', header = TRUE)
# 
# ##########
# # Plot: Change in cascade size
# ##########
# ########## Overall change ##########
# # Summarise by gamma
# cascade_size <- cascade_data %>% 
#   mutate(size_diff_norm = (size_end - size_begin) / size_begin) %>% 
#   group_by(gamma) %>% 
#   summarise(size_diff_mean = mean(size_diff),
#             size_diff_sd = sd(size_diff),
#             size_diff_95error = qnorm(0.975)*sd(size_diff)/sqrt(length(size_diff)),
#             size_diff_norm_mean = mean(size_diff_norm),
#             size_diff_norm_sd = sd(size_diff_norm),
#             size_diff_norm_95error = qnorm(0.975)*sd(size_diff_norm)/sqrt(length(size_diff_norm)))
# 
# # Plot
# gg_size <- ggplot(cascade_size, aes(x = gamma, y = size_diff_norm_mean)) +
#   # Plot all data
#   geom_errorbar(aes(ymin = size_diff_norm_mean - size_diff_norm_95error, 
#                     ymax = size_diff_norm_mean + size_diff_norm_95error), 
#                 size = 0.2, 
#                 width = 0) +
#   geom_point(size = 0.8) +
#   # General plotting controls
#   scale_y_continuous(limits = c(-0.5, 0)) +
#   ylab(expression( paste(Delta, " cascade size" ))) +
#   xlab(expression(paste("Information correlation, ", italic(gamma) ))) +
#   theme_ctokita() 
# 
# gg_size 
# ggsave("output/network_break/plots/CascadeSize_gamma.png", width = 45, height = 45, units = "mm", dpi = 400)
# 
# 
# ##########
# # Plot: Change in cascade bias
# ##########
# # Summarise by gamma
# cascade_diff <- cascade_data %>% 
#   mutate(bias_diff_norm = (bias_end - bias_begin) / bias_begin) %>% 
#   group_by(gamma) %>% 
#   summarise(bias_diff_mean = mean(bias_diff),
#             bias_diff_sd = sd(bias_diff),
#             bias_diff_95error = qnorm(0.975)*sd(bias_diff)/sqrt(length(bias_diff)))
# 
# # Summarizing plot
# gg_diff <- ggplot(cascade_diff, aes(x = gamma, y = bias_diff_mean)) +
#   # Plot all data
#   geom_errorbar(aes(ymin = bias_diff_mean - bias_diff_95error, ymax = bias_diff_mean + bias_diff_95error),
#                 size = 0.2,
#                 width = 0) +
#   geom_point(size = 0.8) +
#   # General plotting controls
#   scale_y_continuous(limits = c(0, 0.16)) +
#   ylab(expression( paste(Delta, " cascade bias" ))) +
#   xlab(expression(paste("Information correlation, ", italic(gamma) ))) +
#   theme_ctokita() 
# 
# gg_diff
# ggsave("output/network_break/plots/CascadeDiff_gamma.png", width = 45, height = 45, units = "mm", dpi = 400)
# 
# 
# ########## Bias, beginning and emnd ##########
# # Summarise by gamma, time point
# cascade_diff_time <- cascade_data %>% 
#   select(gamma, bias_begin, bias_end) %>% 
#   gather(time, bias, -gamma) %>% 
#   group_by(gamma, time) %>% 
#   summarise(diff_mean = mean(bias),
#             diff_sd = sd(bias),
#             diff_95error = qnorm(0.975)*sd(bias)/sqrt(length(bias)))
# 
# # Raw plot
# gg_diff_time <- ggplot(cascade_diff_time, aes(x = gamma, y = diff_mean, color = time)) +
#   geom_errorbar(aes(ymin = diff_mean - diff_95error, ymax = diff_mean + diff_95error),
#                 position = position_dodge(width = 0.05),
#                 size = 0.2,
#                 width = 0) +
#   geom_point(position = position_dodge(width = 0.05),
#              size = 0.8) +
#   # scale_y_continuous(limits = c(0, 0.4)) +
#   scale_color_manual(name = "",
#                      labels = c("Simulation start",
#                                 "Simulation end"),
#                      values = c("#969696", "#6e016b")) +
#   ylab(expression( paste("Cascade bias" ))) +
#   xlab(expression(paste("Information correlation, ", italic(gamma) ))) +
#   theme_ctokita() +
#   theme(legend.position = c(0.75, 0.98),
#         legend.key.height = unit(2, "mm"),
#         legend.background = element_blank())
# 
# gg_diff_time
# ggsave("output/network_break/plots/CascadeDiff_GammaAndTime.png", width = 45, height = 45, units = "mm", dpi = 400)
