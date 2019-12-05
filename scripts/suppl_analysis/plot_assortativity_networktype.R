##############################
#
# PLOT: Assortativity given initial network type
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
# Normal sim (random network)
rand_data <- read.csv('data_derived/network_break/social_networks/n200_assortativity_gammasweep.csv', header = TRUE)
rand_sum <- rand_data %>% 
  mutate(delta_assort = assort_final - assort_initial) %>% 
  group_by(gamma) %>% 
  summarise(assort_mean = mean(assort_final),
            assort_sd = sd(assort_final),
            assort_95error = qnorm(0.975)*sd(assort_final)/sqrt(length(assort_final)),
            assortchange_mean = mean(delta_assort),
            assortchange_sd = sd(delta_assort),
            assortchange_95error = qnorm(0.975)*sd(delta_assort)/sqrt(length(delta_assort))) %>% 
  mutate(network_type = "Random (default)")

# Scale-free network
sf_data <- read.csv('data_derived/network_break/other_network_types/n200_scalefree_assortativity.csv', header = TRUE)
sf_sum <- sf_data %>% 
  mutate(delta_assort = assort_final - assort_initial) %>% 
  group_by(gamma) %>% 
  summarise(assort_mean = mean(assort_final),
            assort_sd = sd(assort_final),
            assort_95error = qnorm(0.975)*sd(assort_final)/sqrt(length(assort_final)),
            assortchange_mean = mean(delta_assort),
            assortchange_sd = sd(delta_assort),
            assortchange_95error = qnorm(0.975)*sd(delta_assort)/sqrt(length(delta_assort))) %>% 
  mutate(network_type = "Scale-free")

# Regular network
reg_data <- read.csv('data_derived/network_break/other_network_types/n200_regular_assortativity.csv', header = TRUE)
reg_sum <- reg_data %>% 
  mutate(delta_assort = assort_final - assort_initial) %>% 
  group_by(gamma) %>% 
  summarise(assort_mean = mean(assort_final),
            assort_sd = sd(assort_final),
            assort_95error = qnorm(0.975)*sd(assort_final)/sqrt(length(assort_final)),
            assortchange_mean = mean(delta_assort),
            assortchange_sd = sd(delta_assort),
            assortchange_95error = qnorm(0.975)*sd(delta_assort)/sqrt(length(delta_assort))) %>% 
  mutate(network_type = "Regular")

# Bind
assort_sum <- rbind(rand_sum, sf_sum, reg_sum)
rm(rand_data, rand_sum, sf_data, sf_sum, reg_data, reg_sum)

##########
# Plot
##########
# Raw final assortativity values
pal <- c("#e41a1c", "#377eb8", "#4daf4a")
gg_assort_networktype <- ggplot(data = assort_sum, 
                                aes(x = gamma, 
                                    y = assort_mean, 
                                    color = network_type, 
                                    group = network_type, 
                                    fill = network_type)) +
  geom_hline(aes(yintercept = 0), 
             size = 0.3, 
             linetype = "dotted") +
  geom_ribbon(aes(ymin = assort_mean - assort_95error, ymax = assort_mean + assort_95error), 
              alpha = 0.4,
              color = NA) +
  geom_line(size = 0.3) +
  geom_point(size = 0.8) +
  scale_color_manual(name = "Network type", values = pal) +
  scale_fill_manual(name = "Network type", values = pal) +
  ylab(expression( paste("Assortativity, ", italic(r[global])) )) +
  xlab(expression( paste("Information correlation ", italic(gamma)) )) +
  theme_ctokita() +
  theme(aspect.ratio = 1)

gg_assort_networktype
ggsave(plot = gg_assort_networktype, filename = "output/network_break/suppl_analysis/Assortativity_by_networktype.png", height = 45, width = 90, units = "mm", dpi = 400)
