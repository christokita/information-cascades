##############################
#
# PLOT: Network structure given simluation length
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
# Normal sim (10^5 steps)
norm_data <- read.csv('data_derived/network_break/social_networks/n200_assortativity_gammasweep.csv', header = TRUE)
norm_data <- norm_data %>% 
  mutate(delta_assort = assort_final - assort_initial) %>% 
  group_by(gamma) %>% 
  summarise(assort_mean = mean(assort_final),
            assort_sd = sd(assort_final),
            assort_95error = qnorm(0.975)*sd(assort_final)/sqrt(length(assort_final)),
            assortchange_mean = mean(delta_assort),
            assortchange_sd = sd(delta_assort),
            assortchange_95error = qnorm(0.975)*sd(delta_assort)/sqrt(length(delta_assort))) %>% 
  mutate(run_time = "10^5")

# Long sim (10^6)
long_data <- read.csv('data_derived/network_break/__suppl_analysis/sim_length/n200_assortativity_10^6steps.csv', header = TRUE)
long_data <- long_data %>% 
  mutate(delta_assort = assort_final - assort_initial) %>% 
  group_by(gamma) %>% 
  summarise(assort_mean = mean(assort_final),
            assort_sd = sd(assort_final),
            assort_95error = qnorm(0.975)*sd(assort_final)/sqrt(length(assort_final)),
            assortchange_mean = mean(delta_assort),
            assortchange_sd = sd(delta_assort),
            assortchange_95error = qnorm(0.975)*sd(delta_assort)/sqrt(length(delta_assort))) %>% 
  mutate(run_time = "10^6")

# Bind
assort_sum <- rbind(norm_data, long_data)
rm(norm_data, long_data)

##########
# Plot
##########
# Raw final assortativity values
pal <- c("#225ea8", "#41b6c4", "#a1dab4")
gg_assort_simlength <- ggplot(data = assort_sum, 
                                aes(x = gamma, 
                                    y = assort_mean, 
                                    color = run_time, 
                                    group = run_time, 
                                    fill = run_time)) +
  geom_hline(aes(yintercept = 0), 
             size = 0.3, 
             linetype = "dotted") +
  geom_ribbon(aes(ymin = assort_mean - assort_95error, ymax = assort_mean + assort_95error), 
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
  ylab(expression( paste("Assortativity ", italic(r[global])) )) +
  xlab(expression( paste("Information correlation ", italic(gamma)) )) +
  theme_ctokita() +
  theme(aspect.ratio = 1)

gg_assort_simlength
ggsave(plot = gg_assort_simlength, 
       filename = "output/network_break/suppl_analysis/Assortativity_by_simlength.png", 
       height = 45, 
       width = 90, units = "mm", dpi = 400)


############## Network change ##############
