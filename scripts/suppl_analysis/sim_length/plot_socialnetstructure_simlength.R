########################################
#
# PLOT: Network structure given simluation length
#
########################################

####################
# Load packages
####################
library(ggplot2)
library(dplyr)
source("scripts/_plot_themes/theme_ctokita.R")

####################
# Plot parameteres
####################
pal <- c("#225ea8", "#41b6c4", "#a1dab4")



############################## Assortatiity ##############################

####################
# Load data and summarise
####################
# Normal sim (10^5 steps)
norm_data <- read.csv('data_derived/network_break/social_networks/n200_assortativity_gammasweep.csv', header = TRUE) %>% 
  mutate(delta_assort = assort_final - assort_initial) %>% 
  mutate(run_time = "10^5")

# Long sim (10^6)
long_data <- read.csv('data_derived/network_break/__suppl_analysis/sim_length/n200_assortativity_10^6steps.csv', header = TRUE) %>% 
  mutate(delta_assort = assort_final - assort_initial) %>% 
  mutate(run_time = "10^6")

# Bind
assort_data <- rbind(norm_data, long_data)
rm(norm_data, long_data)
assort_sum <- assort_data %>% 
  tidyr::gather(metric, value, -gamma, -run_time) %>% 
  group_by(gamma, run_time, metric) %>% 
  summarise(mean = mean(value),
            sd = sd(value),
            ci95 = qnorm(0.975) * sd(value) / sqrt( sum(!is.na(value)) ))

####################
# Plot
####################
# Raw final assortativity values
assort_raw <- assort_sum %>% 
  filter(metric == "assort_final")
gg_assort_simlength <- ggplot(data = assort_raw, 
                                aes(x = gamma, 
                                    y = mean, 
                                    color = run_time, 
                                    group = run_time, 
                                    fill = run_time)) +
  geom_hline(aes(yintercept = 0), 
             size = 0.3, 
             linetype = "dotted") +
  geom_ribbon(aes(ymin = mean - ci95, ymax = mean + ci95), 
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
ggsave(plot = gg_assort_simlength, filename = "output/network_break/suppl_analysis/Assortativity_by_simlength.png", height = 45, width = 90, units = "mm", dpi = 400)



############################## Changes in network structure ##############################

####################
# Load data and summarise
####################
# Normal sim length (10^5)
normal_files <- list.files("data_derived/network_break/social_networks/network_change/", full.names = TRUE)
norm_data <- lapply(normal_files, function(x) {
  # Read in file 
  run_file <- read.csv(x)
  # Create extra metrics
  run_data <- run_file %>% 
    mutate(net_same = same_type_adds - same_type_breaks,
           net_diff = diff_type_adds - diff_type_breaks,
           net_out_degree = out_degree - out_degree_initial,
           net_in_degree = in_degree - in_degree_initial,
           sim_length = "10^5") 
  return(run_data)
})
norm_data <- do.call("rbind", norm_data)

# Long sim length (10^6)
long_files <- list.files("data_derived/network_break/__suppl_analysis/sim_length/network_change/", full.names = TRUE)
long_data <- lapply(long_files, function(x) {
  # Read in file 
  run_file <- read.csv(x)
  # Create extra metrics
  run_data <- run_file %>% 
    mutate(net_same = same_type_adds - same_type_breaks,
           net_diff = diff_type_adds - diff_type_breaks,
           net_out_degree = out_degree - out_degree_initial,
           net_in_degree = in_degree - in_degree_initial,
           sim_length = "10^6") 
  return(run_data)
})
long_data <- do.call("rbind", long_data)

# Bind and sum
network_change_data <- rbind(norm_data, long_data)
rm(norm_data, long_data)
network_change_sum <- network_change_data %>% 
  select(-replicate, -individual) %>% 
  tidyr::gather(metric, value, -gamma, -sim_length) %>% 
  group_by(sim_length, gamma, metric) %>% 
  summarise(mean = mean(value), 
            sd = sd(value),
            error = sd(value)/sqrt(length(value)))

####################
# Plot raw data to inspect
####################
sample_data <- network_change_data %>% 
  filter(gamma %in% seq(-1, 1, 0.5))
ggplot(data = sample_data, aes(x = as.factor(same_type_adds), y = as.factor(diff_type_adds))) +
  geom_bin2d() +
  theme_ctokita() +
  facet_grid(gamma ~ sim_length)

####################
# Plot summarized data
####################
# Change in connections by type
net_type_data <- network_change_sum %>% 
  filter(metric %in% c("net_same", "net_diff")) %>% 
  mutate(metric = factor(metric, levels = c("net_same", "net_diff")))
gg_type_change <- ggplot(net_type_data, aes(x = gamma, y = mean, color = sim_length)) +
  geom_hline(yintercept = 0, 
             size = 0.3, 
             linetype = "dotted") +
  geom_errorbar(aes(ymax = mean + error, ymin = mean - error),
                size = 0.3,
                width = 0) +
  geom_point(aes(shape = metric, fill = metric),
             size = 0.8) +
  ylab(expression( paste(Delta, " social ties")) ) +
  xlab(expression( paste("Information correlation ", italic(gamma)) )) +
  scale_shape_manual(values = c(19, 21),
                     labels = c("Same ideology",
                                "Diff. ideology"),
                     name = "Connetion type") +
  scale_fill_manual(values = c("black", "white"),
                    labels = c("Same ideology",
                               "Diff. ideology"),
                    name = "Connetion type") +
  theme_ctokita() +
  theme(aspect.ratio = 1)
gg_type_change
ggsave(plot = gg_type_change, 
       filename = "output/network_break/social_networks/tiechange_gamma.png", 
       width = 75, 
       height = 45, 
       units = "mm", 
       dpi = 400)


# Breaks/new ties by gamma
ties_data <- network_change_sum %>% 
  filter(metric %in% c("diff_type_adds", "diff_type_breaks", "same_type_adds", "same_type_breaks")) %>% 
  mutate(set = paste0(sim_length, "-", metric),
         metric = factor(metric, levels = c("same_type_adds", "same_type_breaks", "diff_type_adds", "diff_type_breaks")))
gg_ties <- ggplot(ties_data, aes(x = gamma, y = mean, group = metric, color = sim_length)) +
  geom_line(aes(group = set),
            size = 0.3) +
  geom_errorbar(aes(ymax = mean + error, ymin = mean - error),
                size = 0.3,
                width = 0) +
  geom_point(aes(shape = metric, fill = metric),
             size = 0.8) +
  ylab("Count") +
  xlab(expression( paste("Information correlation ", italic(gamma)) )) +
  scale_shape_manual(values = c(19, 17, 21, 24),
                     labels = c("New tie, same ideology",
                                "Broken tie, same ideology",
                                "New tie, diff. ideology",
                                "Broken tie, diff. ideology"),
                     name = "") +
  scale_fill_manual(values = c("black", "black", "white", "white"),
                    labels = c("New tie, same ideology",
                               "Broken tie, same ideology",
                               "New tie, diff. ideology",
                               "Broken tie, diff. ideology"),
                    name = "") +
  theme_ctokita() +
  theme(aspect.ratio = 1)
gg_ties
ggsave(plot = gg_ties, filename = "output/network_break/suppl_analysis/Breaksandadds_simlength.png", width = 90, height = 45, units = "mm", dpi = 400)

gg_ties <- gg_ties +
  scale_y_continuous(limits = c(0, 1.5))
ggsave(plot = gg_ties, filename = "output/network_break/suppl_analysis/Breaksandadds_simlength_zoom.png", width = 90, height = 45, units = "mm", dpi = 400)

# Change in degree
net_degree_data <- network_change_sum %>% 
  filter(metric %in% c("net_out_degree"))
gg_degree_change <- ggplot(net_degree_data, aes(x = gamma, y = mean, color = sim_length)) +
  geom_errorbar(aes(ymax = mean + error, ymin = mean - error),
                size = 0.3,
                width = 0) +
  geom_point(aes(shape = metric, fill = metric),
             size = 0.8) +
  ylab(expression( paste(Delta, " out-degree"))) +
  xlab(expression( paste("Information correlation ", italic(gamma)) )) +
  # scale_y_continuous(limits = c(0, 1.5), 
  #                    expand = c(0, 0)) +
  theme_ctokita() +
  theme(aspect.ratio = 1,
        legend.position = "none")
gg_degree_change

