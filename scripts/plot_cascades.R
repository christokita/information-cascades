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
# Paramters for analysis
####################
data_path <- 'data_derived/network_break/cascades/n200_cascadestats_gammasweep.csv' #path to data
out_path <- "output/network_break/cascades/" #directory you wish to save plots
plot_tag <- "gamma" #extra info to add onto end of plot name
if (plot_tag != "") {
  plot_tag <- paste0("_", plot_tag)
}

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
cascade_data <- read.csv(data_path, header = TRUE)

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
  # scale_y_continuous(limits = c(0.0, 28), breaks = seq(16, 28, 2)) +
  ylab(expression( paste("Cascade size, ", italic(X[t]) ))) +
  xlab(expression(paste("Information correlation, ", italic(gamma) ))) +
  theme_ctokita() 

gg_size 
ggsave(paste0(out_path, "CascadeSize", plot_tag ,".png"), width = 45, height = 45, units = "mm", dpi = 400)


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
ggsave(paste0(out_path, "CascadeBias", plot_tag,".png"), width = 45, height = 45, units = "mm", dpi = 400)


