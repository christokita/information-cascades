##############################
#
# PLOT: How initial network type affects network-breaking model results 
#
##############################

##########
# Load packages
##########
library(ggplot2)
library(dplyr)
source("scripts/plot_theme_ctokita.R")

##########
# Plot parameters
##########
pal <- c("#e41a1c", "#377eb8", "#4daf4a", "#984ea3")


############################## Assortatiity ##############################

##########
# Load data and summarise
##########
# Normal sim (random network)
rand_data <- read.csv('data_derived/network_break/social_networks/assortativity_gammasweep.csv', header = TRUE) %>% 
  mutate(delta_assort = assort_final - assort_initial,
         network_type = "Random (default)") 

# Scale-free network
sf_data <- read.csv('data_derived/network_break/__suppl_analysis/other_network_types/assortativity_scalefree.csv', header = TRUE) %>% 
  mutate(delta_assort = assort_final - assort_initial,
         network_type = "Scale-free") 

# Complete network
comp_data <- read.csv('data_derived/network_break/__suppl_analysis/other_network_types/assortativity_completenetwork-longsim.csv', header = TRUE) %>% 
  mutate(delta_assort = assort_final - assort_initial,
         network_type = "Complete (100x longer sim)")

# Regular network
reg_data <- read.csv('data_derived/network_break/__suppl_analysis/other_network_types/assortativity_regular.csv', header = TRUE) %>% 
  mutate(delta_assort = assort_final - assort_initial,
         network_type = "Regular")

# Bind and summarize
assort_data <- rbind(rand_data, sf_data, comp_data, reg_data) %>% 
  mutate(network_type = factor(network_type, 
                               levels = c("Random (default)", "Regular", "Scale-free", "Complete (100x longer sim)")))
rm(rand_data, sf_data, comp_data, reg_data)
assort_sum <- assort_data %>% 
  tidyr::gather(metric, value, -gamma, -network_type) %>% 
  group_by(gamma, network_type, metric) %>% 
  summarise(mean = mean(value),
            sd = sd(value),
            ci95 = qnorm(0.975) * sd(value) / sqrt( sum(!is.na(value)) ))
  

##########
# Plot assortativity
##########
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
  geom_ribbon(aes(ymin = mean - ci95, ymax = mean + ci95), 
              alpha = 0.4,
              color = NA) +
  geom_line(size = 0.3) +
  geom_point(size = 0.8) +
  scale_color_manual(name = "Network type", values = pal) +
  scale_fill_manual(name = "Network type", values = pal) +
  ylab(expression( paste("Assortativity ", italic(r[global])) )) +
  xlab(expression( paste("Information correlation ", italic(gamma)) )) +
  theme_ctokita() +
  theme(aspect.ratio = 1)
gg_assort_networktype
ggsave(plot = gg_assort_networktype, filename = "output/network_break/suppl_analysis/Assortativity_by_networktype_longersim.png", height = 45, width = 90, units = "mm", dpi = 400)



############################## Changes in network structure ##############################

##########
# Load data and summarise
##########
# Normal sim (random network)
rand_files <- list.files("data_derived/network_break/social_networks/network_change/", full.names = TRUE)
rand_data <- lapply(rand_files, function(x) {
  # Read in file 
  run_file <- read.csv(x)
  # Create extra metrics
  run_data <- run_file %>% 
    mutate(net_same = same_type_adds - same_type_breaks,
           net_diff = diff_type_adds - diff_type_breaks,
           net_out_degree = out_degree - out_degree_initial,
           net_in_degree = in_degree - in_degree_initial,
           network_type = "Random (default)") 
  return(run_data)
})
rand_data <- do.call("rbind", rand_data)

# Complete network
comp_files <- list.files("data_derived/network_break/__suppl_analysis/other_network_types/network_change/", pattern = "_completegraph", full.names = TRUE)
comp_data <- lapply(comp_files, function(x) {
  # Read in file 
  run_file <- read.csv(x)
  # Create extra metrics
  run_data <- run_file %>% 
    mutate(net_same = same_type_adds - same_type_breaks,
           net_diff = diff_type_adds - diff_type_breaks,
           net_out_degree = out_degree - out_degree_initial,
           net_in_degree = in_degree - in_degree_initial,
           network_type = "Complete") 
  return(run_data)
})
comp_data <- do.call("rbind", comp_data)

# Bind and sum
network_change_data <- rbind(rand_data, comp_data)
rm(rand_data, comp_data)
network_change_sum <- network_change_data %>% 
  select(-replicate, -individual) %>% 
  tidyr::gather(metric, value, -gamma, -network_type) %>% 
  group_by(network_type, gamma, metric) %>% 
  summarise(mean = mean(value), 
            sd = sd(value),
            error = sd(value)/sqrt(length(value)))

##########
# Plot raw data
##########
sample_data <- network_change_data %>% 
  filter(gamma %in% seq(-1, 1, 0.5))
ggplot(data = sample_data, aes(x = as.factor(gamma), y = as.factor(net_diff), color = network_type, group = network_type)) +
  geom_point(size = 0.3, alpha = 0.1, position = position_jitterdodge(dodge.width = 0.2, jitter.width = 0.05)) +
  theme_ctokita()

##########
# Plot summarized data
##########
# Change in connections by type
net_type_data <- network_change_sum %>% 
  filter(metric %in% c("net_same", "net_diff")) %>% 
  mutate(metric = factor(metric, levels = c("net_same", "net_diff")))
gg_type_change <- ggplot(net_type_data, aes(x = gamma, y = mean, color = network_type)) +
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

# Breaks/new ties by gamma
ties_data <- network_change_sum %>% 
  filter(metric %in% c("diff_type_adds", "diff_type_breaks", "same_type_adds", "same_type_breaks")) %>% 
  mutate(set = paste0(network_type, "-", metric),
         metric = factor(metric, levels = c("same_type_adds", "same_type_breaks", "diff_type_adds", "diff_type_breaks")))
gg_ties <- ggplot(ties_data, aes(x = gamma, y = mean, group = metric, color = network_type)) +
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

# Change in degree
net_degree_data <- network_change_sum %>% 
  filter(metric %in% c("net_out_degree"))
gg_degree_change <- ggplot(net_degree_data, aes(x = gamma, y = mean, color = network_type)) +
  geom_errorbar(aes(ymax = mean + error, ymin = mean - error),
                size = 0.3,
                width = 0) +
  geom_point(aes(shape = metric, fill = metric),
             size = 0.8) +
  ylab(expression( paste(Delta, " out-degree"))) +
  xlab(expression( paste("Information correlation ", italic(gamma)) )) +
  theme_ctokita()
gg_degree_change
