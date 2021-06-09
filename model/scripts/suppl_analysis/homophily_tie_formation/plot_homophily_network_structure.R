########################################
#
# PLOT: The affect of homophily tie formation on assortativity and network structure
#
########################################

####################
# Load packages
####################
library(ggplot2)
library(dplyr)
library(tidyr)
library(RColorBrewer)
library(brms)
source("_plot_themes/theme_ctokita.R")

####################
# Paramters for analysis: paths to data, paths for output, and filename
####################
# Files
assort_file_normal <- "model/data_derived/network_break/social_networks/assortativity.csv" #path to file containing assortativity data
assort_file_homophily <- "model/data_derived/network_break/__suppl_sims/homophily_tie_formation/social_networks/assortativity.csv" #path to file containing assortativity data

network_data_dir_normal <- "model/data_derived/network_break/social_networks/network_change/" #path to directory containing network change data
network_data_dir_homophily <- "model/data_derived/network_break/__suppl_sims/homophily_tie_formation/social_networks/network_change/" #path to directory containing network change data


out_path <- "model/output/network_break/__suppl_analysis/homophily_tie_formation/" #directory you wish to save plots
plot_tag <- "" #extra info to add onto end of plot name
if (plot_tag != "") {
  plot_tag <- paste0("_", plot_tag)
}

# Colors
models_pal <- c("#04A777" , "#495867")



############################## Assortativity ##############################

####################
# Load in data
####################
# Load normal model data and summarise
assort_data_normal <- read.csv(assort_file_normal, header = TRUE)
assort_sum_normal <- assort_data_normal %>% 
  mutate(assort_type_delta = assort_type_final - assort_type_initial,
         assort_thresh_delta = assort_thresh_final - assort_thresh_initial) %>% 
  select(-replicate) %>% 
  gather(metric, value, -gamma) %>% 
  group_by(gamma, metric) %>% 
  summarise(mean = mean(value),
            sd = sd(value),
            ci95 = qnorm(0.975) * sd(value)/ sqrt( sum(!is.na(value)) )) %>% 
  mutate(model = "random")

# Load homophily tie formation model data and summarise
assort_data_homophily <- read.csv(assort_file_homophily, header = TRUE)
assort_sum_homphily <- assort_data_homophily %>% 
  mutate(assort_type_delta = assort_type_final - assort_type_initial,
         assort_thresh_delta = assort_thresh_final - assort_thresh_initial) %>% 
  select(-replicate) %>% 
  gather(metric, value, -gamma) %>% 
  group_by(gamma, metric) %>% 
  summarise(mean = mean(value),
            sd = sd(value),
            ci95 = qnorm(0.975) * sd(value)/ sqrt( sum(!is.na(value)) )) %>% 
mutate(model = "choice homophily")

# Bind together
assort_sum <- rbind(assort_sum_normal, assort_sum_homphily)


####################
# Plot
####################
assort_type <- assort_sum %>% 
  filter(metric == "assort_type_final")
gg_assorttype <- ggplot(data = assort_type, aes(x = gamma, y = mean, color = model, fill = model)) +
  geom_hline(aes(yintercept = 0), 
             size = 0.3, 
             linetype = "dotted") +
  geom_ribbon(aes(ymin = mean - sd, ymax = mean + sd),
              alpha = 0.4,
              color = NA) +
  # geom_line(size = 0.3, color = pal_type) +
  geom_point(size = 0.8) +
  ylab("Political assortativity") +
  xlab(expression( paste("Information ecosystem ", italic(gamma)) )) +
  scale_y_continuous(limits = c(-0.1, 0.5), 
                     breaks = seq(-0.1, 0.5, 0.1), 
                     expand = c(0, 0)) + 
  scale_fill_manual(name = "Tie formation",
                    values = models_pal) +
  scale_color_manual(name = "Tie formation",
                     values = models_pal) +
  theme_ctokita() 
gg_assorttype #show plot before saving
ggsave(plot = gg_assorttype, filename = paste0(out_path, "assortativity_by_tie_formation", plot_tag, ".pdf"), width = 75, height = 45, units = "mm", dpi = 600)


############################## Thresholds and network structure ##############################

####################
# Load data
####################
# Read in and compile data files for model with homophily tie formation
network_files <- list.files(network_data_dir_homophily, full.names = TRUE)
network_change_homophily <- lapply(network_files, function(x) {
  # Read in file 
  run_file <- read.csv(x) %>% 
    mutate(net_same = same_type_adds - same_type_breaks,
           net_diff = diff_type_adds - diff_type_breaks,
           net_degree = degree - degree_initial,
           net_centrality = centrality - centrality_initial)
  return(run_file)
})
network_change_homophily <- do.call("rbind", network_change_homophily) %>% 
  gather(metric, value, -gamma, -replicate, -individual, -type, -threshold) %>% 
  mutate(tie_formation = "Choice homophily")

# Read in and compile data files for model with random tie formation
network_files <- list.files(network_data_dir_normal, full.names = TRUE)
network_change_normal <- lapply(network_files, function(x) {
  # Read in file 
  run_file <- read.csv(x) %>% 
    mutate(net_same = same_type_adds - same_type_breaks,
           net_diff = diff_type_adds - diff_type_breaks,
           net_degree = degree - degree_initial,
           net_centrality = centrality - centrality_initial)
  return(run_file)
})
network_change_normal <- do.call("rbind", network_change_normal) %>% 
  gather(metric, value, -gamma, -replicate, -individual, -type, -threshold) %>% 
  mutate(tie_formation = "Random")

# Bind together
network_change_data <- rbind(network_change_homophily, network_change_normal)
rm(network_change_homophily, network_change_normal,network_files)


####################
# Filter to centrality, calculate binned means, and plot
####################
# NOTE: Fitting regression lines doesn't seem to show what a plain scatterplot can

#Summarize
centrality_data <- network_change_data %>% 
  filter(metric == "centrality") %>% 
  mutate(threshold_bin = cut(threshold, breaks = seq(0, 1, 0.1), labels = seq(0.05, 0.95, 0.1))) %>% 
  mutate(threshold_bin = as.numeric( as.character(threshold_bin) ) ) %>% 
  group_by(tie_formation, gamma, threshold_bin) %>% 
  summarise(mean_centrality = mean(value))

# Plot
gg_centrality_select <- centrality_data %>% 
  filter(gamma %in% seq(-1, 1, 1)) %>% 
  ggplot(., aes(x = threshold_bin, y = mean_centrality, color = tie_formation)) +
  geom_point(size = 0.8) +
  scale_x_continuous(breaks = seq(0, 1, 0.5), limits = c(0, 1), expand = c(0, 0)) +
  scale_y_continuous(breaks = seq(0.1, 0.6, 0.1), limits = c(0.1, 0.6), expand = c(0, 0)) +
  scale_color_manual(name = "Tie formation", values = models_pal) +
  ylab("Mean centrality") +
  xlab(expression(paste("Threshold ", theta[i]))) +
  theme_ctokita() +
  theme(panel.spacing = unit(1.1,  "lines"),
        legend.position = "none") +
  facet_grid(.~gamma,
             labeller = label_bquote(cols = gamma == .(gamma))) 
gg_centrality_select

ggsave(gg_centrality_select, filename = paste0(out_path, "centrality_by_tie_formation", plot_tag, ".pdf"), width = 90, height = 32.5, units = "mm", dpi = 600)


####################
# Filter to degree, calculate binned means, and plot
####################
#Summarize
degree_data <- network_change_data %>% 
  filter(metric == "degree") %>% 
  mutate(threshold_bin = cut(threshold, breaks = seq(0, 1, 0.1), labels = seq(0.05, 0.95, 0.1))) %>% 
  mutate(threshold_bin = as.numeric( as.character(threshold_bin) ) ) %>% 
  group_by(tie_formation, gamma, threshold_bin) %>% 
  summarise(mean_degree = mean(value))

# Plot
gg_degree_select <- degree_data %>% 
  filter(gamma %in% seq(-1, 1, 1)) %>% 
  ggplot(., aes(x = threshold_bin, y = mean_degree, color = tie_formation)) +
  geom_point(size = 0.8) +
  scale_x_continuous(breaks = seq(0, 1, 0.5), limits = c(0, 1), expand = c(0, 0)) +
  scale_y_continuous(breaks = seq(3, 12, 2), limits = c(3, 12), expand = c(0, 0)) +
  scale_color_manual(name = "Tie formation", values = models_pal) +
  ylab("Mean degree") +
  xlab(expression(paste("Threshold ", theta[i]))) +
  theme_ctokita() +
  theme(panel.spacing = unit(1.1, "lines"),
        legend.position = "none") +
  facet_grid(.~gamma,
             labeller = label_bquote(cols = gamma == .(gamma))) 
gg_degree_select

ggsave(gg_degree_select, filename = paste0(out_path, "degree_by_tie_formation", plot_tag, ".pdf"), width = 90, height = 32.5, units = "mm", dpi = 600)


