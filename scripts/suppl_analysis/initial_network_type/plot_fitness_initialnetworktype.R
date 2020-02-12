##############################
#
# PLOT: How initial network type affects network-breaking model results 
#
##############################

##########
# Load packages
##########
library(ggplot2)
library(dplyr)
source("scripts/plot_theme_ctokita.R")

##########
# Plot parameters
##########
pal <- c("#e41a1c", "#377eb8", "#4daf4a", "#984ea3")



############################## Fitness ##############################

##########
# Load fitness data and summarise
##########
# Normal sim (random network)
rand_data <- read.csv('data_derived/network_break/cascades/n200_fitness_allbehavior_gammasweep.csv', header = TRUE)
rand_sum <- rand_data %>% 
  select(-replicate) %>% 
  mutate(fitness = correct_message - incorrect_message ) %>% 
  # mutate(fitness = ifelse(fitness == Inf, 10, fitness)) %>% #need to figure out how to deal with Inf values
  group_by(gamma) %>% 
  summarise_each(funs(mean(., na.rm = TRUE), sd(., na.rm = TRUE))) %>% 
  mutate(correct_message_95ci = qnorm(0.975) * correct_message_sd/sqrt(100 * 200),
         incorrect_message_95ci = qnorm(0.975) * incorrect_message_sd/sqrt(100 * 200),
         fitness_95ci = qnorm(0.975) * fitness_sd/sqrt(100 * 200),
         network_type = "Random (default)")
# Scale-free network
sf_data <- read.csv('data_derived/network_break/other_network_types/n200_fitness_allbehavior_scalefree.csv', header = TRUE)
sf_sum <- sf_data %>% 
  select(-replicate) %>% 
  mutate(fitness = correct_message - incorrect_message ) %>% 
  # mutate(fitness = ifelse(fitness == Inf, 10, fitness)) %>% #need to figure out how to deal with Inf values
  group_by(gamma) %>% 
  summarise_each(funs(mean(., na.rm = TRUE), sd(., na.rm = TRUE))) %>% 
  mutate(correct_message_95ci = qnorm(0.975) * correct_message_sd/sqrt(100 * 200),
         incorrect_message_95ci = qnorm(0.975) * incorrect_message_sd/sqrt(100 * 200),
         fitness_95ci = qnorm(0.975) * fitness_sd/sqrt(100 * 200),
         network_type = "Scale-free")

# Regular network
reg_data <- read.csv('data_derived/network_break/other_network_types/n200_fitness_allbehavior_regular.csv', header = TRUE)
reg_sum <- reg_data %>% 
  select(-replicate) %>% 
  mutate(fitness = correct_message - incorrect_message ) %>% 
  # mutate(fitness = ifelse(fitness == Inf, 10, fitness)) %>% #need to figure out how to deal with Inf values
  group_by(gamma) %>% 
  summarise_each(funs(mean(., na.rm = TRUE), sd(., na.rm = TRUE))) %>% 
  mutate(correct_message_95ci = qnorm(0.975) * correct_message_sd/sqrt(100 * 200),
         incorrect_message_95ci = qnorm(0.975) * incorrect_message_sd/sqrt(100 * 200),
         fitness_95ci = qnorm(0.975) * fitness_sd/sqrt(100 * 200),
         network_type = "Regular")

# Bind
behav_sum <- rbind(rand_sum, reg_sum, sf_sum)
rm(rand_data, rand_sum, reg_data, reg_sum, sf_data, sf_sum)

# Normalize fitness relative to gamma = 0
gamma_zero_fitness <- behav_sum$fitness_mean[behav_sum$gamma == 0]
behav_sum <- behav_sum %>% 
  mutate(fitness_mean_norm = (fitness_mean - gamma_zero_fitness) / gamma_zero_fitness)

##########
# Plot fitness 
##########
pal <- c("#e41a1c", "#377eb8", "#4daf4a")

# Proportion of messages received that an individual would want (i.e., greater than threshold)
gg_correct <- ggplot(data = behav_sum, aes(x = gamma, 
                                           y = correct_message_mean,
                                           color = network_type, 
                                           group = network_type)) +
  geom_errorbar(aes(ymin = correct_message_mean - correct_message_95ci,
                    ymax = correct_message_mean + correct_message_95ci),
                size = 0.2,
                width = 0) +
  geom_point(size = 0.8) +
  ylab("Freq. correct message received") +
  xlab(expression( paste("Information correlation, ", italic(gamma)) )) +
  scale_color_manual(name = "Network type", values = pal) +
  theme_ctokita() 
gg_correct
ggsave(plot = gg_correct, 
       filename = "output/network_break/suppl_analysis/MessageCorrect_networktype.png", 
       width = 90, 
       height = 45, 
       units = "mm", 
       dpi = 400)


# Proportion of incorrect messages received
gg_incorrect <- ggplot(data = behav_sum, aes(x = gamma, 
                                             y = incorrect_message_mean,
                                             color = network_type, 
                                             group = network_type)) +
  geom_errorbar(aes(ymin = incorrect_message_mean - incorrect_message_95ci,
                    ymax = incorrect_message_mean + incorrect_message_95ci),
                size = 0.2,
                width = 0) +
  geom_point(size = 0.8) +
  ylab("Freq. incorrect message received") +
  xlab(expression( paste("Information correlation, ", italic(gamma)) )) +
  scale_color_manual(name = "Network type", values = pal) +
  theme_ctokita() 
gg_incorrect
ggsave(plot = gg_incorrect, 
       filename = "output/network_break/suppl_analysis/MessageInorrect_netowrktype.png", 
       width = 90, 
       height = 45, 
       units = "mm", 
       dpi = 400)

# Individual fitness (i.e., ratio of correct/incorrect messages received)
gg_fitness <- ggplot(data = behav_sum, aes(x = gamma, 
                                           y = fitness_mean,
                                           color = network_type, 
                                           group = network_type)) +
  # geom_errorbar(aes(ymin = fitness_mean - fitness_95ci,
  #                   ymax = fitness_mean + fitness_95ci),
  #               size = 0.2,
  #               width = 0) +
  geom_point(size = 0.8) +
  geom_hline(yintercept = 0) +
  ylab("Individual fitness") +
  xlab(expression( paste("Information correlation, ", italic(gamma)) )) +
  scale_color_manual(name = "Network type", values = pal) +
  theme_ctokita() 
gg_fitness
