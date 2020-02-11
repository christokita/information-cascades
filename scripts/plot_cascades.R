##############################
#
# PLOT: Cascade dynamics figures
#
##############################

##########
# Load packages
##########
library(ggplot2)
library(dplyr)
library(tidyr)
source("scripts/plot_theme_ctokita.R")

####################
# Paramters for analysis
####################
data_path <- 'data_derived/network_break/cascades/n200_cascadestats_gammasweep.csv' #path to data
out_path <- "output/network_break/cascades/" #directory you wish to save plots
plot_tag <- "gamma" #extra info to add onto end of plot name
if (plot_tag != "") {
  plot_tag <- paste0("_", plot_tag)
}



############################## Ftiness trials: Cascade dynamics ##############################

##########
# Load data 
##########
# Read in data
cascade_data <- read.csv(data_path, header = TRUE)

##########
# Plot: Cascade size
##########
# Summarise by gamma
cascade_size <- cascade_data %>% 
  select(gamma, total_active) %>% 
  gather(metric, value, -gamma) %>% 
  group_by(gamma, metric) %>% 
  summarise(mean = mean(value, na.rm = TRUE),
            sd = sd(value, na.rm = TRUE),
            ci95 = qnorm(0.975) * sd(value, na.rm = TRUE) / sqrt( sum(!is.na(value)) )) #denominator removes NA values from count

# Plot
gg_size <- ggplot(cascade_size, aes(x = gamma, y = mean)) +
  geom_ribbon(aes(ymin = mean - ci95, 
                    ymax = mean + ci95), 
                alpha = 0.4) +
  geom_line(size = 0.3) +
  geom_point(size = 0.8) +
  ylab("Cascade size") +
  xlab(expression(paste("Information correlation ", italic(gamma) ))) +
  theme_ctokita() 
gg_size #show plot before saving
ggsave(paste0(out_path, "CascadeSize", plot_tag ,".png"), width = 45, height = 45, units = "mm", dpi = 400)
ggsave(paste0(out_path, "CascadeSize", plot_tag ,".svg"), width = 45, height = 45, units = "mm")

##########
# Plot: Cascade bias
##########
# Summarise by gamma
cascade_diff <- cascade_data %>% 
  select(gamma, active_diff_prop) %>% 
  gather(metric, value, -gamma) %>% 
  group_by(gamma, metric) %>% 
  summarise(mean = mean(value),
            sd = sd(value),
            ci95 = qnorm(0.975) * sd(value, na.rm = TRUE) / sqrt( sum(!is.na(value)) ))

# Summarizing plot
gg_diff <- ggplot(cascade_diff, aes(x = gamma, y = mean)) +
  geom_ribbon(aes(ymin = mean - ci95, 
                    ymax = mean + ci95),
                alpha = 0.4) +
  geom_line(size = 0.3) +
  geom_point(size = 0.8) +
  # scale_y_continuous(limits = c(0, 0.16)) +
  ylab(expression( paste("Cascade bias" ))) +
  xlab(expression(paste("Information correlation ", italic(gamma) ))) +
  theme_ctokita() 
gg_diff #show plot before saving
ggsave(paste0(out_path, "CascadeBias", plot_tag,".png"), width = 45, height = 45, units = "mm", dpi = 400)
ggsave(paste0(out_path, "CascadeBias", plot_tag,".svg"), width = 45, height = 45, units = "mm")


