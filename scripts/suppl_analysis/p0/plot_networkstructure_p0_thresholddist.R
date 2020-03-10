########################################
#
# PLOT: Network structure given no new tie formation and different threshold distributions
#
########################################

####################
# Load packages
####################
library(ggplot2)
library(dplyr)
source("scripts/_plot_themes/theme_ctokita.R")

# Palette for plotting
pal <- c("#225ea8", "#41b6c4", "#9DDBDA", "#a1dab4")



############################## Assortatiity ##############################

####################
# Load data and summarise
####################
# Uniform threshold distribution
uniform_data <- read.csv('data_derived/network_break/__suppl_analysis/p0/social_networks/assortativity_p0.csv', header = TRUE) %>% 
  mutate(threshold_dist = "Uniform dist.")

# Identical thresholds
iden_data <- read.csv('data_derived/network_break/__suppl_analysis/identical_thresholds_p0/social_networks/assortativity_identicalthresh_p0.csv', header = TRUE) %>% 
  mutate(threshold_dist = "Identical")

# Identical thresholds
iden_long_data <- read.csv('data_derived/network_break/__suppl_analysis/identical_thresholds_p0_longsim/social_networks/assortativity_identicalthresh_p0_10^6steps.csv', header = TRUE) %>% 
  mutate(threshold_dist = "Identical_10^6steps")

# Narrow thresholds (uniform dist on range [0.25, 0.75])
narrow_dist_data <- read.csv('data_derived/network_break/__suppl_analysis/narrow_threshold_dist/social_networks/assortativity_narrowthreshdist.csv', header = TRUE) %>% 
  mutate(threshold_dist = "Narrow dist.")

# Bind
assort_sum <- rbind(uniform_data, iden_data, iden_long_data, narrow_dist_data) %>% 
  mutate(delta_assort = assort_final - assort_initial,
         threshold_dist = factor(threshold_dist, levels = c("Uniform dist.", "Identical", "Identical_10^6steps", "Narrow dist."))) %>% 
  select(-replicate) %>% 
  tidyr::gather(metric, value, -gamma, -threshold_dist) %>% 
  group_by(gamma, threshold_dist, metric) %>% 
  summarise(mean = mean(value, na.rm = TRUE),
            sd = sd(value, na.rm = TRUE),
            ci95 = qnorm(0.975) * sd(value, na.rm = TRUE) / sqrt( sum(!is.na(value)) )) #denominator removes NA values from count
rm(uniform_data, iden_data, iden_long_data)

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
  scale_color_manual(name = "Thresholds,\nno new tie formation", 
                     values = pal,
                     labels = c("Uniform dist.",
                                "Identical",
                                expression(paste("Identical (", 10^6, " time steps)")),
                                "Narrow dist.")) +
  scale_fill_manual(name = "Thresholds,\nno new tie formation", 
                    values = pal,
                    labels = c("Uniform dist.",
                               "Identical",
                               expression(paste("Identical (", 10^6, " time steps)")),
                               "Narrow dist.")) +
  ylab(expression( paste("Assortativity ", italic(r[global])) )) +
  xlab(expression( paste("Information correlation ", italic(gamma)) )) +
  theme_ctokita() +
  theme(aspect.ratio = 1) 

gg_assort_threhsolds
ggsave(plot = gg_assort_threhsolds, 
       filename = "output/network_break/__suppl_analysis/p0/assortativity_by_thresholddistribution_nonewties.png", 
       height = 45, 
       width = 100, units = "mm", dpi = 400)

