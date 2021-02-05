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
# Load and prep data
####################
# Read in data
initial_threshold_data <- read.csv('model/data_derived/network_break/social_networks/initial_neighbor_thresh_data.csv') %>% 
  pivot_longer(cols = n_neighbors:n_higher,
               names_to = "metric") %>% 
  mutate(metric = paste0(metric, "_initial")) %>% 
  pivot_wider(names_from = metric, 
              values_from = value)

final_threshold_data <- read.csv('model/data_derived/network_break/social_networks/final_neighbor_thresh_data.csv') %>% 
  pivot_longer(cols = n_neighbors:n_higher,
               names_to = "metric") %>% 
  mutate(metric = paste0(metric, "_final")) %>% 
  pivot_wider(names_from = metric, 
              values_from = value)

# Prep
threshold_data <- merge(initial_threshold_data, final_threshold_data, by = c("gamma", "replicate", "individual", "type", "threshold")) 
rm(initial_threshold_data, final_threshold_data)

####################
# Plot: threshold vs mean neighbor threshold
####################
gg_neighborthresh <-
  # Prep data
  threshold_data %>% 
  select(gamma, threshold, mean_neighbor_thresh_initial, mean_neighbor_thresh_final) %>% 
  rename(Initial_network = mean_neighbor_thresh_initial, Final_network = mean_neighbor_thresh_final) %>% 
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
  threshold_data %>% 
  mutate(threshold_type = ifelse(threshold > 0.75, "High threshold", ifelse(threshold < 0.25, "Low Threshold", NA))) %>% 
  mutate(change_mean_neighbor = mean_neighbor_thresh_final - mean_neighbor_thresh_initial) %>% 
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
  threshold_data %>% 
  mutate(threshold_type = ifelse(threshold > 0.75, "High threshold", ifelse(threshold < 0.25, "Low Threshold", NA))) %>% 
  mutate(change_neighbor_similarity = mean_thresh_sim_final - mean_thresh_sim_initial) %>% 
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


######################################## Focusing in on gamma == 1 ####################

# Prep high-level stat data
threshold_gamma1_data <- threshold_data %>% 
  filter(gamma == 1)

# Load in raw neighbor thresholds
final_neighbor_thersholds <- read.csv('model/data_derived/network_break/social_networks/threshold_sorting/final_raw_neighbor_thresholds.csv')

####################
# Plot: threshold vs low-threshold neighbors
####################
gg_lowthresh_neighbors <- 
  # Prep data
  threshold_gamma1_data %>% 
  mutate(frac_lowthresh_final = n_low_thresh_final / n_neighbors_final,
         frac_lowthresh_initial = n_low_thresh_initial / n_neighbors_initial) %>% 
  mutate(change_frac_lowthresh = frac_lowthresh_final - frac_lowthresh_initial) %>% 
  # Plot
  ggplot(data = ., aes(x = threshold, y = change_frac_lowthresh)) +
  geom_hline(aes(yintercept = 0), size = 0.3, linetype = "dotted") +
  geom_point(color = plot_color, alpha = 0.2, size = 0.2, stroke = 0) +
  xlab(expression( paste("Threshold ", theta[i]) )) +
  ylab(expression( paste(Delta, " frac. neighbors with ", theta[j], " < 0.25")  )) +
  theme_ctokita() +
  theme(legend.position = "none")
gg_lowthresh_neighbors

ggsave(gg_lowthresh_neighbors, filename = paste0(out_path, "gamma1_change_lowthresh_neighbors.pdf"), width = 50, height = 45, units = "mm", dpi = 400)


####################
# Plot: distribution of raw neighbor thresholds by individual threshold
####################
library(ggridges)
gg_neighbor_thresholds <- 
  ggplot(data = final_neighbor_thersholds, aes(x = neighbor_threshold, y = as.factor(threshold_bin))) +
  geom_density_ridges(binwidth = 0.1, 
                      center = 0.45, 
                      colour = "white", 
                      fill = plot_color, 
                      size = 0.3) +
  scale_x_continuous(breaks = seq(0, 1, 0.2)) +
  xlab(expression( paste("Neighbor threshold ", theta[j]) )) +
  ylab(expression( paste("Threshold ", theta[i]) )) +
  theme_ctokita() +
  theme(legend.position = "none",
        axis.line.y = element_blank())
gg_neighbor_thresholds

ggsave(gg_neighbor_thresholds, filename = paste0(out_path, "gamma1_neighbor_thresholds.pdf"), width = 45, height = 45, units = "mm", dpi = 400)
