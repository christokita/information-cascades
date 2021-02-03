########################################
#
# PLOT: Average difference in threshold values between an individual in their social network
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
# Set parameters
####################
# Paths
out_path <- "model/output/network_break/social_networks/threshold_sorting/" #directory you wish to save plots

# Plot color
plot_color <- "#1B3B6F"
pal <- brewer.pal(4, "PuOr")


####################
# Load data
####################
threshold_diff_data <- read.csv('model/data_derived/network_break/social_networks/threshold_distance_data.csv')


####################
# Plot: threshold vs mean neighbor threshold
####################
gg_neighborthresh <-
  # Prep data
  threshold_diff_data %>% 
  select(gamma, threshold, initial_mean_neighbor, final_mean_neighbor) %>% 
  rename(Initial_network = initial_mean_neighbor, Final_network = final_mean_neighbor) %>% 
  pivot_longer(cols = c(Initial_network, Final_network), names_to = "metric") %>% 
  mutate(metric = gsub("_", " ", metric),
         metric = factor(metric, levels = c("Initial network", "Final network"))) %>% 
  filter(gamma %in% seq(-1, 1, 1)) %>% 
  # Plot
  ggplot(., aes(x = threshold, y = value, color = gamma)) +
  geom_hline(aes(yintercept = 0.5), size = 0.3, linetype = "dotted") +
  geom_point(size = 0.4, alpha = 0.1, stroke = 0) +
  xlab(expression( paste("Threshold ", theta[i]) )) +
  ylab("Avg. neighbor threshold") +
  scale_x_continuous(breaks = seq(0, 1, 0.5)) +
  scale_y_continuous(breaks = seq(0, 1, 0.5), limits = c(0, 1)) +
  scale_color_gradientn(colors = pal, name = expression(paste("Information\necosystem", gamma))) +
  theme_ctokita() +
  theme(legend.position = "none",
        plot.background = element_blank()) +
  facet_grid(metric~gamma,
             labeller = label_bquote(cols = gamma == .(gamma)))
gg_neighborthresh

ggsave(gg_neighborthresh, filename = paste0(out_path, "avg_neighbor_threshold.png"), width = 90, height = 90, units = "mm", dpi = 400, bg = "transparent")


####################
# Plot: Change in mean neigbhor threshold by threshold type (low vs. high) & info ecosystem
####################
gg_change_neighbor_thresh <- 
  # Prep data
  threshold_diff_data %>% 
  mutate(threshold_type = ifelse(threshold > 0.75, "High threshold", ifelse(threshold < 0.25, "Low Threshold", NA))) %>% 
  mutate(change_mean_neighbor = final_mean_neighbor - initial_mean_neighbor) %>% 
  filter(!is.na(threshold_type)) %>% 
  group_by(gamma, threshold_type) %>% 
  summarise(avg_change = mean(change_mean_neighbor, na.rm = TRUE)) %>% 
  # Plot
  ggplot(data = ., aes(x = gamma, y = avg_change, shape = threshold_type, alpha = threshold_type)) +
  geom_hline(aes(yintercept = 0), size = 0.3, linetype = "dotted") +
  geom_point(size = 1,
             stroke = 0, 
             fill = plot_color) +
  xlab(expression( paste("Information ecosystem ", italic(gamma)) )) +
  ylab(expression( paste(Delta, " avg. neighbor threshold")  )) +
  scale_y_continuous(breaks = seq(0, 0.25, 0.05), 
                     limits = c(0, 0.22)) +
  scale_shape_manual(name = "", 
                     values = c(24, 25)) +
  scale_alpha_manual(name = "", 
                     values = c(1, 0.6)) +
  theme_ctokita() +
  theme(legend.position = "none")
gg_change_neighbor_thresh

ggsave(gg_change_neighbor_thresh, filename = paste0(out_path, "change_in_neighbor_threshold.pdf"), width = 45, height = 45, units = "mm", dpi = 400)

####################
# Plot: threshold vs change in mean neighbor threshold similarity
####################
gg_change_neighbor_sim <- 
  # Prep data
  threshold_diff_data %>% 
  mutate(threshold_type = ifelse(threshold > 0.75, "High threshold", ifelse(threshold < 0.25, "Low Threshold", NA))) %>% 
  mutate(change_neighbor_similarity = final_thresh_sim - initial_thresh_sim) %>% 
  filter(!is.na(threshold_type)) %>% 
  group_by(gamma, threshold_type) %>% 
  summarise(avg_change = mean(change_neighbor_similarity, na.rm = TRUE)) %>% 
  # Plot
  ggplot(data = ., aes(x = gamma, y = avg_change, shape = threshold_type, alpha = threshold_type)) +
  geom_hline(aes(yintercept = 0), size = 0.3, linetype = "dotted") +
  geom_point(size = 1,
             stroke = 0, 
             fill = plot_color) +
  xlab(expression( paste("Information ecosystem ", italic(gamma)) )) +
  ylab(expression( atop(paste(Delta, " avg. neighbor"), "threshold similarity")  )) +
  scale_y_continuous(limits = c(-0.2, 0.1)) +
  scale_shape_manual(name = "", 
                     values = c(24, 25)) +
  scale_alpha_manual(name = "", 
                     values = c(1, 0.6)) +
  theme_ctokita() +
  theme(legend.position = "none")
gg_change_neighbor_sim

ggsave(gg_change_neighbor_sim, filename = paste0(out_path, "change_in_neighbor_similarity.pdf"), width = 50, height = 45, units = "mm", dpi = 400)

