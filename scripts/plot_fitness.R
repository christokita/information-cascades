##############################
#
# PLOT: Individual fitness as inferred from behavior
#
##############################

##########
# Load packages
##########
library(ggplot2)
library(dplyr)

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

##########
# Load data and summarise
##########
behav_data <- read.csv('output/network_break/data_derived/cascades/n200allbehavior_gammasweep.csv', header = TRUE)
behav_sum <- behav_data %>% 
  select(-replicate) %>% 
  mutate(fitness = correct_message - incorrect_message ) %>% 
  # mutate(fitness = ifelse(fitness == Inf, 10, fitness)) %>% #need to figure out how to deal with Inf values
  group_by(gamma) %>% 
  summarise_each(funs(mean(., na.rm = TRUE), sd(., na.rm = TRUE))) %>% 
  mutate(correct_message_95ci = qnorm(0.975) * correct_message_sd/sqrt(100 * 200),
         incorrect_message_95ci = qnorm(0.975) * incorrect_message_sd/sqrt(100 * 200),
         fitness_95ci = qnorm(0.975) * fitness_sd/sqrt(100 * 200))

gamma_zero_fitness <- behav_sum$fitness_mean[behav_sum$gamma == 0]
behav_sum <- behav_sum %>% 
  mutate(fitness_mean_norm = (fitness_mean - gamma_zero_fitness) / gamma_zero_fitness)
      
##########
# Plot
##########
# Proportion of messages received that an individual would want (i.e., greater than threshold)
gg_correct <- ggplot(data = behav_sum, aes(x = gamma, y = correct_message_mean)) +
  geom_errorbar(aes(ymin = correct_message_mean - correct_message_95ci,
                    ymax = correct_message_mean + correct_message_95ci),
                size = 0.2,
                width = 0) +
  geom_point(size = 0.8) +
  ylab("Freq. correct message received") +
  xlab(expression( paste("Information correlation, ", italic(gamma)) )) +
  theme_ctokita() 

gg_correct

ggsave(plot = gg_correct, 
       filename = "output/network_break/plots/MessageCorrect_gamma.png", 
       width = 45, 
       height = 45, 
       units = "mm", 
       dpi = 400)


# Proportion of incorrect messages received
gg_incorrect <- ggplot(data = behav_sum, aes(x = gamma, y = incorrect_message_mean)) +
  geom_errorbar(aes(ymin = incorrect_message_mean - incorrect_message_95ci,
                    ymax = incorrect_message_mean + incorrect_message_95ci),
                size = 0.2,
                width = 0) +
  geom_point(size = 0.8) +
  ylab("Freq. incorrect message received") +
  xlab(expression( paste("Information correlation, ", italic(gamma)) )) +
  theme_ctokita() 

gg_incorrect

ggsave(plot = gg_incorrect, 
       filename = "output/network_break/plots/MessageInorrect_gamma.png", 
       width = 45, 
       height = 45, 
       units = "mm", 
       dpi = 400)

# Individual fitness (i.e., ratio of correct/incorrect messages received)
gg_fitness <- ggplot(data = behav_sum, aes(x = gamma, y = fitness_mean_norm)) +
  # geom_errorbar(aes(ymin = fitness_mean - fitness_95ci,
  #                   ymax = fitness_mean + fitness_95ci),
  #               size = 0.2,
  #               width = 0) +
  geom_point(size = 0.8) +
  geom_hline(yintercept = 0) +
  ylab("Individual fitness") +
  xlab(expression( paste("Information correlation, ", italic(gamma)) )) +
  theme_ctokita() 

gg_fitness
