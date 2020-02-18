########################################
#
# PLOT: Cascade dynamics during fitness trials given simluation length
#
########################################

####################
# Load packages
####################
library(ggplot2)
library(dplyr)
source("scripts/_plot_themes/theme_ctokita.R")

####################
# Plot parameteres
####################
pal <- c("#225ea8", "#41b6c4", "#a1dab4")



############################## Fitness trials: cascades ##############################

####################
# Load data and summarise
####################
# Normal sim length (10^5)
norm_data <- read.csv('data_derived/network_break/cascades/n200_cascadestats_gammasweep.csv', header = TRUE) %>% 
  mutate(run_time = "10^5")

# Long sim data (10^6)
long_data <- read.csv('data_derived/network_break/__suppl_analysis/sim_length/n200_cascadestats_10^6steps.csv', header = TRUE) %>% 
  mutate(run_time = "10^6")

# Bind
cascade_data <- rbind(norm_data, long_data) %>% 
  tidyr::gather()

####################
# Plot: Cascade size
####################
# Summarise by gamma
cascade_size <- cascade_data %>% 
  select(run_time, gamma, total_active) %>% 
  group_by(run_time, gamma) %>% 
  summarise_each(list(size_mean = mean, 
                      size_sd = sd, 
                      rep_count = length)) %>% 
  mutate(size_95ci = qnorm(0.975) * size_sd / sqrt(rep_count))

# Plot
pal <- c("#225ea8", "#41b6c4", "#a1dab4")
gg_size <- ggplot(cascade_size, aes(x = gamma, y = size_mean, color = run_time)) +
  # Plot all data
  geom_ribbon(aes(ymin = size_mean - size_95ci, 
                  ymax = size_mean + size_95ci,
                  fill = run_time), 
              alpha = 0.4,
              color = NA) +
  geom_line(size = 0.3) +
  geom_point(size = 0.8) +
  # General plotting controls
  scale_color_manual(name = "Simulation\nsteps", 
                     values = pal,
                     labels = c(expression(10^5),
                                expression(10^6))) +
  scale_fill_manual(name = "Simulation\nsteps", 
                    values = pal,
                    labels = c(expression(10^5),
                               expression(10^6))) +
  ylab("Cascade size") +
  xlab(expression(paste("Information correlation ", italic(gamma) ))) +
  theme_ctokita() +
  theme(aspect.ratio = 1)
gg_size
ggsave(plot = gg_size, filename = "output/network_break/suppl_analysis/CasacadeSize_simlength.png", width = 65, height = 45, units = "mm", dpi = 400)

####################
# Plot: Cascade bias
####################
# Summarise by gamma
cascade_bias <- cascade_data %>% 
  select(run_time, gamma, active_diff_prop) %>% 
  group_by(run_time, gamma) %>% 
  summarise_each(list(bias_mean = mean, 
                      bias_sd = sd, 
                      rep_count = length)) %>% 
  mutate(bias_95ci = qnorm(0.975) * bias_sd / sqrt(rep_count))

# Summarizing plot
gg_diff <- ggplot(cascade_bias, aes(x = gamma, y = bias_mean, color = run_time)) +
  # Plot all data
  geom_ribbon(aes(ymin = bias_mean - bias_95ci, 
                  ymax = bias_mean + bias_95ci,
                  fill = run_time),
              alpha = 0.4,
              color = NA) +
  geom_line(size = 0.3) +
  geom_point(size = 0.8) +
  # General plotting controls
  # scale_y_continuous(limits = c(0, 0.16)) +
  scale_color_manual(name = "Simulation\nsteps", 
                     values = pal,
                     labels = c(expression(10^5),
                                expression(10^6))) +
  scale_fill_manual(name = "Simulation\nsteps", 
                    values = pal,
                    labels = c(expression(10^5),
                               expression(10^6))) +
  ylab(expression( paste("Cascade bias" ))) +
  xlab(expression(paste("Information correlation ", italic(gamma) ))) +
  theme_ctokita() +
  theme(aspect.ratio = 1)
gg_diff
ggsave(plot = gg_diff, filename = "output/network_break/suppl_analysis/CasacadeBias_simlength.png", width = 65, height = 45, units = "mm", dpi = 400)

