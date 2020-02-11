##############################
#
# PLOT: Individual fitness given simluation length
#
##############################

##########
# Load packages
##########
library(ggplot2)
library(dplyr)
source("scripts/plot_theme_ctokita.R")

##########
# Plot parameteres
##########
pal <- c("#225ea8", "#41b6c4", "#a1dab4")



############################## Fitness trials: individual behavior/information use ##############################

##########
# Load data and summarise
##########
# Normal sims (10^5 steps)
norm_data <- read.csv("data_derived/network_break/fitness/n200_fitness_behaviorsum_gamma.csv", header = TRUE) %>% 
  mutate(run_time = "10^5",
         fitness = sensitivity + specificity + precision)

# Long sims (10^6 steps)
long_data <- read.csv("data_derived/network_break/__suppl_analysis/sim_length/n200_fitness_behaviorsum_10^6steps.csv", header = TRUE) %>% 
  mutate(run_time = "10^6",
         fitness = sensitivity + specificity + precision)

# Bind and summarise
fitness_data <- rbind(norm_data, long_data) %>% 
  select(-replicate) %>% 
  tidyr::gather(metric, value, -gamma, -run_time)
rm(norm_data, long_data)
fitness_sum <- fitness_data  %>% 
  group_by(gamma, metric, run_time) %>% 
  summarise(mean = mean(value, na.rm = TRUE),
            sd = sd(value, na.rm = TRUE),
            ci95 = qnorm(0.975) * sd(value, na.rm = TRUE) / sqrt( sum(!is.na(value)) )) #denominator removes NA values from count

##########
# Plot
##########
# Sensitivity: proportion of important (i.e., greater than threshold) news stories individual reacted to
sensitivity_data <- fitness_sum %>% 
  filter(metric == "sensitivity")
gg_sens <- ggplot(data = sensitivity_data, aes(x = gamma, y = mean, color = run_time)) +
  geom_ribbon(aes(ymin = mean - ci95,
                  ymax =  mean + ci95,
                  fill = run_time),
              alpha = 0.4,
              color = NA) +
  geom_line(size = 0.3) +
  geom_point(size = 0.8) +
  scale_color_manual(name = "Simulation\nsteps", 
                     values = pal,
                     labels = c(expression(10^5),
                                expression(10^6))) +
  scale_fill_manual(name = "Simulation\nsteps", 
                    values = pal,
                    labels = c(expression(10^5),
                               expression(10^6))) +
  ylab("Behavioral sensitivity") +
  xlab(expression( paste("Information correlation ", italic(gamma)) )) +
  theme_ctokita() 
gg_sens #show plot before saving

# Specificity: proportion of "unimportant" (i.e, less than threshold) stories an individual did *not* react to
specificity_data <- fitness_sum %>% 
  filter(metric == "specificity")
gg_specif <- ggplot(data = specificity_data, aes(x = gamma, y = mean, color = run_time)) +
  geom_ribbon(aes(ymin = mean - ci95,
                  ymax =  mean + ci95,
                  fill = run_time),
              alpha = 0.4,
              color = NA) +
  geom_line(size = 0.3) +
  geom_point(size = 0.8) +
  scale_color_manual(name = "Simulation\nsteps", 
                     values = pal,
                     labels = c(expression(10^5),
                                expression(10^6))) +
  scale_fill_manual(name = "Simulation\nsteps", 
                    values = pal,
                    labels = c(expression(10^5),
                               expression(10^6))) +
  ylab("Behavioral specificity") +
  xlab(expression( paste("Information correlation ", italic(gamma)) )) +
  theme_ctokita() 
gg_specif #show plot before saving

# Precision: proportion of activity (x_i = 1) that is due to "important" news.
precision_data <- fitness_data %>% 
  filter(metric == "precision")
gg_precis <- ggplot(data = precision_data, aes(x = gamma, y = mean, color = run_time)) +
  geom_ribbon(aes(ymin = mean - ci95,
                  ymax =  mean + ci95,
                  fill = run_time),
              alpha = 0.4,
              color = NA) +
  geom_line(size = 0.3) +
  geom_point(size = 0.8) +
  scale_color_manual(name = "Simulation\nsteps", 
                     values = pal,
                     labels = c(expression(10^5),
                                expression(10^6))) +
  scale_fill_manual(name = "Simulation\nsteps", 
                    values = pal,
                    labels = c(expression(10^5),
                               expression(10^6))) +
  ylab("Behavioral precision") +
  xlab(expression( paste("Information correlation ", italic(gamma)) )) +
  theme_ctokita() 
gg_precis #show plot before saving
