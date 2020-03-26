########################################
#
# PLOT: Network structure given small probability of tie formation
#
########################################

####################
# Load packages
####################
library(ggplot2)
library(dplyr)
source("scripts/_plot_themes/theme_ctokita.R")

# Palette for plotting
pal <- c("#225ea8", "#41b6c4", "#9DDBDA")



############################## Assortatiity ##############################

####################
# Load data and summarise
####################
# Normal sim (uniform threshold distribution)
psmall_data <- read.csv('data_derived/network_break/__suppl_analysis/psmall/social_networks/assortativity_psmall.csv', header = TRUE) %>% 
  mutate(model = "p = 0.0005")

# No new ties formed
p0_data <- read.csv('data_derived/network_break/__suppl_analysis/p0_longsim/social_networks/assortativity_p0_10^6steps.csv', header = TRUE) %>% 
  mutate(model = "p = 0")

# Bind
assort_sum <- rbind(psmall_data, p0_data) %>% 
  mutate(delta_assort = assort_final - assort_initial,
         model = factor(model, levels = c("p = 0.0005", "p = 0"))) %>% 
  select(-replicate) %>% 
  tidyr::gather(metric, value, -gamma, -model) %>% 
  group_by(gamma, model, metric) %>% 
  summarise(mean = mean(value, na.rm = TRUE),
            sd = sd(value, na.rm = TRUE),
            ci95 = qnorm(0.975) * sd(value, na.rm = TRUE) / sqrt( sum(!is.na(value)) )) #denominator removes NA values from count
rm(psmall_data, p0_data)

####################
# Plot
####################
# Raw final assortativity values
final_assort_sum <- assort_sum %>% 
  filter(metric == "assort_final")

gg_assort_threhsolds <- ggplot(data = final_assort_sum, 
                               aes(x = gamma, 
                                   y = mean, 
                                   color = model, 
                                   group = model, 
                                   fill = model)) +
  geom_hline(aes(yintercept = 0), 
             size = 0.3, 
             linetype = "dotted") +
  geom_ribbon(aes(ymin = mean - sd, ymax = mean + sd), 
              alpha = 0.4,
              color = NA) +
  geom_line(size = 0.3) +
  geom_point(size = 0.8) +
  scale_color_manual(name = "Model", 
                     values = pal) +
  scale_fill_manual(name = "Model", 
                    values = pal) +
  ylab(expression( paste("Assortativity ", italic(r[global])) )) +
  xlab(expression( paste("Information correlation ", italic(gamma)) )) +
  theme_ctokita() +
  theme(aspect.ratio = 1)

gg_assort_threhsolds
ggsave(plot = gg_assort_threhsolds, 
       filename = "output/network_break/__suppl_analysis/psmall/assortativity_by_probtieformation.png", 
       height = 45, 
       width = 70, units = "mm", dpi = 400)


# Raw final assortativity values, just p=0.0005 model
assort_raw <- assort_sum %>% 
  filter(metric == "assort_final", model == "p = 0.0005")
gg_assort <- ggplot(data = assort_raw, aes(x = gamma, y = mean, color = model, fill = model)) +
  geom_hline(aes(yintercept = 0), 
             size = 0.3, 
             linetype = "dotted") +
  geom_ribbon(aes(ymin = mean - sd, ymax = mean + sd),
              alpha = 0.4,
              color = NA) +
  geom_line(size = 0.3) +
  geom_point(size = 0.8) +
  scale_color_manual(values = pal) +
  scale_fill_manual(values = pal) +
  scale_y_continuous(breaks = seq(-0.05, 0.4, 0.05)) +
  ylab(expression( paste("Assortativity ", italic(r[global])) )) +
  xlab(expression( paste("Information correlation ", italic(gamma)) )) +
  theme_ctokita()  +
  theme(legend.position = "none")
gg_assort #show plot before saving
ggsave(plot = gg_assort, 
       filename = "output/network_break/__suppl_analysis/psmall/assortativity_psmall.png", 
       height = 45, 
       width = 45, units = "mm", dpi = 700)

