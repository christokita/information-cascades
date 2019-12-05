##############################
#
# PLOT: Effect of initial social network structure on ending network structure
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

############## Assortatiity ##############

##########
# Load data and summarise
##########
assort_data <- read.csv('data_derived/network_break/social_networks/n200_assortativity_gammasweep.csv', header = TRUE)
assort_sum <- assort_data %>% 
  mutate(delta_assort = assort_final - assort_initial) %>% 
  group_by(gamma) %>% 
  summarise(assort_mean = mean(assort_final),
            assort_sd = sd(assort_final),
            assort_95error = qnorm(0.975)*sd(assort_final)/sqrt(length(assort_final)),
            assortchange_mean = mean(delta_assort),
            assortchange_sd = sd(delta_assort),
            assortchange_95error = qnorm(0.975)*sd(delta_assort)/sqrt(length(delta_assort)))

##########
# Plot
##########
# Raw final assortativity values
gg_assort <- ggplot(data = assort_sum, aes(x = gamma, y = assort_mean)) +
  geom_hline(aes(yintercept = 0), 
             size = 0.3, 
             linetype = "dotted") +
  geom_ribbon(aes(ymin = assort_mean - assort_95error, ymax = assort_mean + assort_95error), 
              alpha = 0.4,  
              fill = "#525252") +
  geom_line(color = "#000000", 
            size = 0.3) +
  geom_point(color = "#000000", 
             size = 0.8) +
  ylab(expression( paste("Assortativity, ", italic(r[global])) )) +
  xlab(expression( paste("Information correlation, ", italic(gamma)) )) +
  theme_ctokita() 

gg_assort
ggsave(plot = gg_assort, filename = "output/network_break/social_networks/SocialNet_assortativity_gamma.png", width = 45, height = 45, units = "mm", dpi = 400)

# Change in assortativity
gg_assortchange <- ggplot(data = assort_sum, aes(x = gamma, y = assortchange_mean)) +
  geom_hline(aes(yintercept = 0), 
             size = 0.3, 
             linetype = "dotted") +
  # geom_errorbar(aes(ymin = assortchange_mean - assortchange_95error, ymax = assortchange_mean + assortchange_95error),
  #               size = 0.3,
  #               width = 0) +
  geom_ribbon(aes(ymin = assortchange_mean - assortchange_95error, ymax = assortchange_mean + assortchange_95error), 
              alpha = 0.4,  
              fill = "#525252") +
  geom_line(color = "#000000", 
            size = 0.3) +
  geom_point(color = "#000000", 
             size = 0.8) +
  ylab(expression( paste("Change in assortativity, ", italic(r[global])) )) +
  xlab(expression( paste("Information correlation, ", italic(gamma)) )) +
  theme_ctokita() 

gg_assortchange
ggsave(plot = gg_assortchange, filename = "output/network_break/networks/SocialNet_assortchange_gamma.png", width = 45, height = 45, units = "mm", dpi = 400)
