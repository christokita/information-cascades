########################################
#
# PLOT: Network structure given no new tie formation, for different simulation run time.
#
########################################

####################
# Load packages
####################
library(ggplot2)
library(dplyr)
source("scripts/_plot_themes/theme_ctokita.R")

# Palette for plotting
pal <- rev(RColorBrewer::brewer.pal(5, "YlGn"))



############################## Assortatiity ##############################

####################
# Load data and summarise
####################
# No new ties formed, 10^5 steps
p0_data <- read.csv('data_derived/network_break/__suppl_analysis/p0/social_networks/assortativity_p0.csv', header = TRUE) %>% 
  mutate(threshold_dist = "10^5")

# No new ties formed, 10^6 steps
p0_longdata <- read.csv('data_derived/network_break/__suppl_analysis/p0_longsim/social_networks/assortativity_p0_10^6steps.csv', header = TRUE) %>% 
  mutate(threshold_dist = "10^6")

# No new ties formed, 10^7 steps
p0_longerdata <- read.csv('data_derived/network_break/__suppl_analysis/p0_longersim/social_networks/assortativity_p0_10^7steps.csv', header = TRUE) %>% 
  mutate(threshold_dist = "10^7")

# Bind
assort_sum <- rbind(p0_data, p0_longdata, p0_longerdata) %>% 
  mutate(delta_assort = assort_final - assort_initial,
         threshold_dist = factor(threshold_dist, levels = c("10^7", "10^6", "10^5"))) %>% 
  select(-replicate) %>% 
  tidyr::gather(metric, value, -gamma, -threshold_dist) %>% 
  group_by(gamma, threshold_dist, metric) %>% 
  summarise(mean = mean(value, na.rm = TRUE),
            sd = sd(value, na.rm = TRUE),
            ci95 = qnorm(0.975) * sd(value, na.rm = TRUE) / sqrt( sum(!is.na(value)) )) #denominator removes NA values from count
rm(p0_data, p0_longdata, p0_longerdata)

####################
# Plot
####################
# Raw final assortativity values
final_assort_sum <- assort_sum %>% 
  filter(metric == "assort_final")

gg_assort_threhsolds <- ggplot(data = final_assort_sum, 
                               aes(x = gamma, 
                                   y = mean, 
                                   color = threshold_dist, 
                                   group = threshold_dist, 
                                   fill = threshold_dist)) +
  geom_hline(aes(yintercept = 0), 
             size = 0.3, 
             linetype = "dotted") +
  geom_ribbon(aes(ymin = mean - ci95, ymax = mean + ci95), 
              alpha = 0.4,
              color = NA) +
  geom_line(size = 0.3) +
  geom_point(size = 0.8) +
  scale_color_manual(name = "No tie formation", 
                     values = pal,
                     labels = c(expression(paste(10^7, " time steps")),
                                expression(paste(10^6, " time steps")),
                                expression(paste(10^5, " time steps")))) +
  scale_fill_manual(name = "No tie formation", 
                    values = pal,
                    labels = c(expression(paste(10^7, " time steps")),
                               expression(paste(10^6, " time steps")),
                               expression(paste(10^5, " time steps")))) +
  ylab(expression( paste("Assortativity ", italic(r[global])) )) +
  xlab(expression( paste("Information correlation ", italic(gamma)) )) +
  theme_ctokita() +
  theme(aspect.ratio = 1)

gg_assort_threhsolds
ggsave(plot = gg_assort_threhsolds, 
       filename = "output/network_break/__suppl_analysis/p0/assortativity_simlength_nonewties.png", 
       height = 45, 
       width = 100, units = "mm", dpi = 400)
