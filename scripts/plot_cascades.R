##############################
#
# PLOT: Cascade dynamics figures
#
##############################

##########
# Load packages
##########
library(ggplot2)
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

############## Cascade difference among types ##############

##########
# Load data 
##########
# Read in data
cascade_data <- read.csv('output/network_break/data_derived/cascades/n200_rollingavg.csv', header = TRUE)

# Set aside group for plots with less data
cascade_look <- cascade_data %>% 
  filter(gamma %in% c(0.9, 0.5, 0, -0.5, -0.9))

# Data set for end points on graph
end_time <- max(cascade_data$start)
cascade_ends <- cascade_data %>% 
  filter(start == end_time)

# Data set for emphasis lines
cascade_emph <- cascade_data %>% 
  filter(gamma %in% c(1, -1))
cascade_emph_ends <- cascade_emph %>% 
  filter(start == end_time)


# Set color palette
pal <- brewer.pal(length(unique(cascade_look$gamma)), "PuOr")

##########
# Plot: Rolling averages
##########
# Cascade size
gg_size <- ggplot() +
  # Plot all data
  geom_line(data = cascade_data, 
            aes(group = gamma, x = start, y = active_mean, color = gamma), 
            size = 0.2, 
            alpha = 0.5) +
  geom_point(data = cascade_ends,
             aes(group = gamma, x = start, y = active_mean, color = gamma),
             size = 0.1) +
  # Plot emphasis lines
  geom_line(data = cascade_emph, 
            aes(group = gamma, x = start, y = active_mean, color = gamma), 
            size = 0.3) +
  geom_point(data = cascade_emph_ends,
             aes(group = gamma, x = start, y = active_mean, color = gamma),
             size = 0.6) +
  # General plotting controls
  scale_color_gradientn(colors = pal, 
                        name = expression(paste("Information\ncorrelation (", italic(gamma), ")"))) +
  scale_x_continuous(labels = comma) +
  ylab(expression( paste("Cascade size, ", italic(X[A] + X[B])))) +
  xlab(expression(paste("Time step, ", italic(t) ))) +
  theme_ctokita() + 
  theme(legend.key.height = unit(5, "mm"))

gg_size + theme(legend.position = "none")
ggsave("output/network_break/plots/CascadeSize_gamma.png", width = 90, height = 45, units = "mm", dpi = 400)

# Plot just legend
gg_legend <- get_legend(gg_size)
as_ggplot(gg_legend)
ggsave("output/network_break/plots/Cascade_legend.png", width = 20, height = 45, units = "mm", dpi = 400)

# Cascade bias
gg_diff <- ggplot() +
  # Plot all data
  geom_line(data = cascade_data,
            aes(group = gamma, x = start, y = actdiff_mean, color = gamma),
            size = 0.2, 
            alpha = 0.5) +
  geom_point(data = cascade_ends,
             aes(group = gamma, x = start, y = actdiff_mean, color = gamma),
             size = 0.1) +
  # Plot emphasis lines
  geom_line(data = cascade_emph, 
            aes(group = gamma, x = start, y = actdiff_mean, color = gamma), 
            size = 0.3) +
  geom_point(data = cascade_emph_ends,
             aes(group = gamma, x = start, y = actdiff_mean, color = gamma),
             size = 0.6) +
  # General plotting controls
  scale_color_gradientn(colors = pal, 
                        name = expression(paste("Information\ncorrelation (", gamma, ")"))) +
  scale_y_continuous(breaks = seq(0, 0.4, 0.05)) +
  scale_x_continuous(labels = comma) +
  ylab(expression( paste("Cascade bias, |", italic(X[A] - X[B]), "|"))) +
  xlab(expression(paste("Time step, ", italic(t) ))) +
  theme_ctokita() +
  theme(legend.position = "none")

gg_diff
ggsave("output/network_break/plots/CascadeDiff_gamma.png", width = 90, height = 45, units = "mm", dpi = 400)
