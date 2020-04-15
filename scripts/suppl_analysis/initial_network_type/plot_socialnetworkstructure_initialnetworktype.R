########################################
#
# PLOT: How initial network type affects network-breaking model results 
#
########################################

####################
# Load packages
####################
library(ggplot2)
library(dplyr)
source("scripts/_plot_themes/theme_ctokita.R")

####################
# Plot parameters
####################
pal <- c("#377eb8", "#e41a1c", "#4daf4a", "#984ea3")



############################## Assortatiity ##############################

####################
# Load data and summarise
####################
# Normal sim (random network)
rand_data <- read.csv('data_derived/network_break/social_networks/assortativity_gammasweep.csv', header = TRUE) %>% 
  mutate(delta_assort = assort_final - assort_initial,
         network_type = "Random (default)") 

# Scale-free network
sf_data <- read.csv('data_derived/network_break/__suppl_analysis/other_network_types/social_networks/assortativity_scalefree.csv', header = TRUE) %>% 
  mutate(delta_assort = assort_final - assort_initial,
         network_type = "Scale-free") 

# Complete network
sw_data <- read.csv('data_derived/network_break/__suppl_analysis/other_network_types/social_networks/assortativity_smallworld.csv', header = TRUE) %>% 
  mutate(delta_assort = assort_final - assort_initial,
         network_type = "Small world")

# Regular network
reg_data <- read.csv('data_derived/network_break/__suppl_analysis/other_network_types/social_networks/assortativity_regular.csv', header = TRUE) %>% 
  mutate(delta_assort = assort_final - assort_initial,
         network_type = "Regular")

# Bind and summarize
assort_data <- rbind(rand_data, sf_data, sw_data, reg_data) %>% 
  mutate(network_type = factor(network_type, 
                               levels = c("Random (default)", "Regular", "Small world", "Scale-free")))
rm(rand_data, sf_data, sw_data, reg_data)
assort_sum <- assort_data %>% 
  tidyr::gather(metric, value, -gamma, -network_type) %>% 
  group_by(gamma, network_type, metric) %>% 
  summarise(mean = mean(value),
            sd = sd(value),
            ci95 = qnorm(0.975) * sd(value) / sqrt( sum(!is.na(value)) ))
  

####################
# Plot assortativity
####################
# Raw final assortativity values
assort_raw <- assort_sum %>% 
  filter(metric == "assort_final")
gg_assort_networktype <- ggplot(data = assort_raw, 
                                aes(x = gamma, 
                                    y = mean, 
                                    color = network_type, 
                                    group = network_type, 
                                    fill = network_type)) +
  geom_hline(aes(yintercept = 0), 
             size = 0.3, 
             linetype = "dotted") +
  geom_hline(yintercept = seq(0.1, 0.4, 0.1), 
             size = 0.3, 
             linetype = "dotted",
             color = "grey90") +
  geom_ribbon(aes(ymin = mean - sd, ymax = mean + sd),
              alpha = 0.4,
              color = NA) +
  geom_line(size = 0.3) +
  geom_point(size = 0.8) +
  scale_color_manual(name = "Network type", values = pal) +
  scale_fill_manual(name = "Network type", values = pal) +
  scale_x_continuous(breaks = seq(-1, 1, 1)) +
  ylab(expression( paste("Assortativity ", italic(r[global])) )) +
  xlab(expression( paste("Information correlation ", italic(gamma)) )) +
  theme_ctokita() +
  facet_grid(~network_type) +
  theme(aspect.ratio = 1,
        legend.position = "none",
        strip.background = element_blank(),
        strip.text = element_text(face = "bold", size = 6))
gg_assort_networktype
ggsave(plot = gg_assort_networktype, filename = "output/network_break/__suppl_analysis/network_type/assortativity_by_newtorktype.png", height = 45, width = 140, units = "mm", dpi = 400)


