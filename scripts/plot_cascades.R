########################################
#
# PLOT: Dynamics of cacsades during simulations
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
beginend_path <- 'data_derived/network_break/cascades/cascades_beginendsim_gammasweep.csv' #path to begin/end of simulation cascade data
cascadesum_path <- 'data_derived/network_break/cascades/cascades_summarizedsim_gammasweep.csv' #path to begin/end of simulation cascade data
out_path <- "output/network_break/cascades/" #directory you wish to save plots
plot_tag <- "gammasweep" #extra info to add onto end of plot name
if (plot_tag != "") {
  plot_tag <- paste0("_", plot_tag)
}



############################## Cascades: Average dynamics at beginning and end of simulation ##############################

####################
# Load data and summarize
####################
# Read in data
beginend_data <- read.csv(beginend_path, header = TRUE) %>% 
  tidyr::gather("metric", "value", -gamma, -replicate)
beginend_sum <- beginend_data %>% 
  group_by(gamma, metric) %>% 
  summarise(mean = mean(value),
            sd = sd(value),
            ci95 = qnorm(0.975)*sd(value)/sqrt( sum(!is.na(value)) ))

####################
# Raw plot
####################
sample_data <- beginend_data %>% 
  filter(metric %in% c("size_begin", "size_end")) %>% 
  mutate(time = factor(metric))
ggplot(data = sample_data, aes(x = time, y = value, color = gamma, group = replicate)) +
  geom_line(alpha = 0.1) +
  scale_color_gradient2() + 
  theme_ctokita() 

####################
# Plot: Cascade size at the beginning and end of the simulation
####################
# Filter
beginend_size <- beginend_sum %>% 
  filter(metric %in% c("size_begin", "size_end")) %>% 
  mutate(time = factor(metric))

# Plot
pal <- brewer.pal(6, "PuOr")
gg_beginend_size <- ggplot(beginend_size, aes(x = time, y = mean, color = gamma, group = gamma)) +
  # geom_ribbon(aes(ymin = mean - sd,
  #                 ymax = mean + sd,
  #                 fill = gamma),
  #                 alpha = 0.1,
  #             color = NA) +
  geom_line(size = 0.3, alpha = 0.8) +
  geom_point(size = 0.8) +
  scale_color_gradientn(colors = pal) +
  scale_x_discrete(labels = c("First 5,000", "Last 5,000")) +
  ylab("Cascade size") +
  xlab("Time steps") +
  theme_ctokita()
gg_beginend_size #show plot before saving
ggsave(plot = gg_beginend_size, filename = paste0(out_path, "beginend_size", plot_tag ,".png"), width = 75, height = 45, units = "mm", dpi = 400)
# ggsave(plot = gg_size, filename = paste0(out_path, "cascadesize", plot_tag ,".svg"), width = 45, height = 45, units = "mm")

####################
# Plot: Cascade bias at beginning and end of cascdae
####################
# Filter
beginend_bias <- beginend_sum %>% 
  filter(metric %in% c("bias_begin", "bias_end")) %>% 
  mutate(time = factor(metric))

# Plot
pal <- brewer.pal(6, "PuOr")
gg_beginend_bias <- ggplot(beginend_bias, aes(x = time, y = mean, color = gamma, group = gamma)) +
  # geom_ribbon(aes(ymin = mean - sd,
  #                 ymax = mean + sd,
  #                 fill = gamma),
  #                 alpha = 0.1,
  #             color = NA) +
  geom_line(size = 0.3, alpha = 0.8) +
  geom_point(size = 0.8) +
  scale_color_gradientn(colors = pal) +
  scale_x_discrete(labels = c("First 5,000", "Last 5,000")) +
  ylab("Cascade bias") +
  xlab("Time steps") +
  theme_ctokita() 
gg_beginend_bias #show plot before saving
ggsave(plot = gg_beginend_bias, filename = paste0(out_path, "beginend_bias", plot_tag ,".png"), width = 75, height = 45, units = "mm", dpi = 400)



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
