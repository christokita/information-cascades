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



############################## Assortatiity ##############################

####################
# Load data and summarise
####################
# Normal sim (uniform threshold distribution)
norm_data <- read.csv('data_derived/network_break/social_networks/assortativity_gammasweep.csv', header = TRUE)
norm_data <- norm_data %>% 
  mutate(delta_assort = assort_final - assort_initial) %>% 
  group_by(gamma) %>% 
  summarise(assort_mean = mean(assort_final),
            assort_sd = sd(assort_final),
            assort_95error = qnorm(0.975)*sd(assort_final)/sqrt(length(assort_final)),
            assortchange_mean = mean(delta_assort),
            assortchange_sd = sd(delta_assort),
            assortchange_95error = qnorm(0.975)*sd(delta_assort)/sqrt(length(delta_assort))) %>% 
  mutate(threshold_dist = "Uniform dist.")

# Identical thresholds
iden_data <- read.csv('data_derived/network_break/__suppl_analysis/identical_thresholds/social_networks/assortativity_identicalthresh.csv', header = TRUE)
iden_data <- iden_data %>% 
  mutate(delta_assort = assort_final - assort_initial) %>% 
  group_by(gamma) %>% 
  summarise(assort_mean = mean(assort_final),
            assort_sd = sd(assort_final),
            assort_95error = qnorm(0.975)*sd(assort_final)/sqrt(length(assort_final)),
            assortchange_mean = mean(delta_assort),
            assortchange_sd = sd(delta_assort),
            assortchange_95error = qnorm(0.975)*sd(delta_assort)/sqrt(length(delta_assort))) %>% 
  mutate(threshold_dist = "Identical")

# Bind
assort_sum <- rbind(norm_data, iden_data) %>% 
  mutate(threshold_dist = factor(threshold_dist, levels = c("Uniform dist.", "Identical")))
rm(norm_data, iden_data)

####################
# Plot
####################
# Raw final assortativity values
pal <- c("#225ea8", "#41b6c4", "#a1dab4")
gg_assort_threhsolds <- ggplot(data = assort_sum, 
                                aes(x = gamma, 
                                    y = assort_mean, 
                                    color = threshold_dist, 
                                    group = threshold_dist, 
                                    fill = threshold_dist)) +
  geom_hline(aes(yintercept = 0), 
             size = 0.3, 
             linetype = "dotted") +
  geom_ribbon(aes(ymin = assort_mean - assort_95error, ymax = assort_mean + assort_95error), 
              alpha = 0.4,
              color = NA) +
  geom_line(size = 0.3) +
  geom_point(size = 0.8) +
  scale_color_manual(name = "Thresholds", 
                     values = pal) +
  scale_fill_manual(name = "Thresholds", 
                    values = pal) +
  ylab(expression( paste("Assortativity ", italic(r[global])) )) +
  xlab(expression( paste("Information correlation ", italic(gamma)) )) +
  theme_ctokita() +
  theme(aspect.ratio = 1)

gg_assort_threhsolds
ggsave(plot = gg_assort_threhsolds, 
       filename = "output/network_break/suppl_analysis/Assortativity_by_thresholddistribution.png", 
       height = 45, 
       width = 90, units = "mm", dpi = 400)



############################## Changes in network structure ##############################

####################
# Load data and summarise
####################
# Normal simulation (uniform disturbion)
uniform_files <- list.files("data_derived/network_break/social_networks/network_change/", full.names = TRUE)
uniform_data <- lapply(uniform_files, function(x) {
  # Read in file 
  run_file <- read.csv(x)
  #Summarize
  run_data <- run_file %>% 
    mutate(net_same = same_type_adds - same_type_breaks,
           net_diff = diff_type_adds - diff_type_breaks,
           net_out_degree = out_degree - out_degree_initial,
           net_in_degree = in_degree - in_degree_initial,
           threshold_dist = "Uniform dist.") %>% 
    select(-replicate, -individual) %>% 
    tidyr::gather(metric, value, -gamma, -threshold_dist) %>% 
    group_by(threshold_dist, gamma, metric) %>% 
    summarise(mean = mean(value), 
              sd = sd(value),
              error = sd(value)/sqrt(length(value)))
  return(run_data)
})
uniform_data <- do.call("rbind", uniform_data)

# Identical thresholds
identical_files <- list.files("data_derived/network_break/__suppl_analysis/identical_thresholds/social_networks/network_change/", full.names = TRUE)
identical_data <- lapply(identical_files, function(x) {
  # Read in file 
  run_file <- read.csv(x)
  #Summarize
  run_data <- run_file %>% 
    mutate(net_same = same_type_adds - same_type_breaks,
           net_diff = diff_type_adds - diff_type_breaks,
           net_out_degree = out_degree - out_degree_initial,
           net_in_degree = in_degree - in_degree_initial,
           threshold_dist = "Identical") %>% 
    select(-replicate, -individual) %>% 
    tidyr::gather(metric, value, -gamma, -threshold_dist) %>% 
    group_by(threshold_dist, gamma, metric) %>% 
    summarise(mean = mean(value), 
              sd = sd(value),
              error = sd(value)/sqrt(length(value)))
  return(run_data)
})
identical_data <- do.call("rbind", identical_data)

# Bind
network_change_data <- rbind(uniform_data, identical_data) %>% 
  ungroup(threshold_dist) %>%
  mutate(threshold_dist = factor(threshold_dist, levels = c("Uniform dist.", "Identical")))

####################
# Plot
####################
# Change in connections by type
net_type_data <- network_change_data %>% 
  filter(metric %in% c("net_same", "net_diff")) %>% 
  mutate(metric = factor(metric, levels = c("net_same", "net_diff")))
gg_type_change <- ggplot(net_type_data, aes(x = gamma, y = mean, color = threshold_dist)) +
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
  scale_color_manual(values = pal,
                    labels = c("Uniform dist.",
                               "Identical"),
                    name = "Thresholds") +
  theme_ctokita() +
  theme(aspect.ratio = 1)

gg_type_change

ggsave(plot = gg_type_change, 
       filename = "output/network_break/suppl_analysis/tiechange_thresholddistributions.png", 
       width = 75, 
       height = 45, 
       units = "mm", 
       dpi = 400)


# Breaks/new ties by gamma
ties_data <- network_change_data %>% 
  filter(metric %in% c("diff_type_adds", "diff_type_breaks", "same_type_adds", "same_type_breaks")) %>% 
  mutate(set = paste0(threshold_dist, "-", metric),
         metric = factor(metric, levels = c("same_type_adds", "same_type_breaks", "diff_type_adds", "diff_type_breaks")))
gg_ties <- ggplot(ties_data, aes(x = gamma, y = mean, group = metric, col = threshold_dist)) +
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
  scale_color_manual(values = pal,
                      labels = c("Uniform dist.",
                                 "Identical"),
                      name = "Thresholds") +
  scale_fill_manual(values = c(pal[1], pal[1], "white", "white"),
                     labels = c("New tie, same ideology",
                                "Broken tie, same ideology",
                                "New tie, diff. ideology",
                                "Broken tie, diff. ideology"),
                     name = "") +
  theme_ctokita() +
  theme(aspect.ratio = 1)
gg_ties

ggsave(plot = gg_ties, 
       filename = "output/network_break/suppl_analysis/Breaksandadds_thresholddistributions.png", 
       width = 90, 
       height = 45, 
       units = "mm", 
       dpi = 400)


# Change in degree
net_degree_data <- network_change_data %>% 
  filter(metric %in% c("net_out_degree")) %>% 
  mutate(log_mean = log10(mean))
gg_degree_change <- ggplot(net_degree_data, aes(x = gamma, y = mean, color = threshold_dist)) +
  geom_errorbar(aes(ymax = mean + error, ymin = mean - error),
                size = 0.3,
                width = 0) +
  geom_point(aes(shape = metric, 
                 fill = metric),
             size = 0.8) +
  ylab(expression( paste(Delta, " out-degree"))) +
  xlab(expression( paste("Information correlation ", italic(gamma)) )) +
  # scale_y_continuous(limits = c(0, 1.5), 
  #                    expand = c(0, 0)) +
  theme_ctokita() +
  theme(aspect.ratio = 1,
        legend.position = "right")

gg_degree_change

