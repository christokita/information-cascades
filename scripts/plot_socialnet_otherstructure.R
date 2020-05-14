########################################
#
# PLOT: Effect of initial social network structure on ending network structure
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
library(rstantools)
source("scripts/_plot_themes/theme_ctokita.R")

####################
# Paramters for analysis: paths to data, paths for output, and filename
####################
network_data_dir <- "data_derived/network_break/social_networks/network_change/" #path to directory containing network change data
out_path <- "output/network_break/social_networks/" #directory you wish to save plots
plot_tag <- "" #extra info to add onto end of plot name
if (plot_tag != "") {
  plot_tag <- paste0("_", plot_tag)
}

pal <- brewer.pal(4, "PuOr")

####################
# Load data
####################
# Read in and compile data files
network_files <- list.files(network_data_dir, full.names = TRUE)
network_change_data <- lapply(network_files, function(x) {
  # Read in file 
  run_file <- read.csv(x) %>% 
    mutate(net_same = same_type_adds - same_type_breaks,
           net_diff = diff_type_adds - diff_type_breaks,
           net_degree = degree - degree_initial,
           net_centrality = centrality - centrality_initial)
  return(run_file)
})
network_change_data <- do.call("rbind", network_change_data) %>% 
  gather(metric, value, -gamma, -replicate, -individual, -type, -threshold)

#Summarize
network_change_sum <- network_change_data %>% 
  select(-replicate, -individual, -type, -threshold) %>% 
  group_by(gamma, metric) %>% 
  summarise(mean = mean(value), 
            sd = sd(value),
            error = qnorm(0.975)*sd(value)/sqrt(length(value)))



############################## Centrality ##############################

####################
# Filter to data of interest, fit regression
####################
centrality_data <- network_change_data %>% 
  filter(metric == "centrality") %>% 
  split(.$gamma)

# Check if regression fit already exists, otherwise conduct bayesian regression
centrality_fit_file <- paste0(out_path, "regression_fits/centrality-threshold_cubicfit.rds")
gamma_values <- as.numeric(names(centrality_data))
if (file.exists(centrality_fit_file)) { 
  regression_cent <- readRDS(centrality_fit_file)
} else {
  regression_cent <- brm_multiple(data = centrality_data,
                                  formula = value ~ 1 + threshold + I(threshold^2) + I(threshold^3),
                                  prior = c(prior(uniform(-10, 10), class = Intercept),
                                            prior(normal(0, 10), class = b),
                                            prior(normal(0, 50), class = sigma)),
                                  iter = 3000,
                                  warmup = 1000,
                                  chains = 4,
                                  seed = 323,
                                  combine = FALSE)
  saveRDS(regression_cent, file = centrality_fit_file)
}

# Get fitted values from model to data range/space
x_values <- data.frame(threshold = seq(0, 1, 0.01))
fit_cent <- lapply(seq(1:length(gamma_values)), function(i) {
  gamma <- gamma_values[i]
  fit_line <- fitted(regression_cent[[i]], newdata = x_values) %>% 
    as.data.frame() %>% 
    mutate(gamma = gamma,
           threshold = seq(0, 1, 0.01))
})
fit_cent <- do.call("rbind", fit_cent)

####################
# Plot thresold vs eigenvector centrality value for each info ecosystem (gamma)
####################
gg_centrality <- ggplot(fit_cent, aes(x = threshold, y = Estimate, color = gamma, group = gamma)) +
  # geom_ribbon(aes(ymin = Q2.5, ymax = Q97.5, fill = gamma), color = NA, alpha = 0.3) +
  geom_line(size = 0.3, alpha = 0.8) +
  scale_color_gradientn(colors = pal, name = expression(paste("Information\necosystem", gamma))) +
  scale_fill_gradientn(colors = pal, name = expression(paste("Information\necosystem", gamma))) +
  ylab("Centrality") +
  xlab(expression(paste("Threshold, ", theta[i]))) +
  theme_ctokita() 
gg_centrality
ggsave(gg_centrality, filename = paste0(out_path, "centrality-thresholds", plot_tag, ".png"), width = 75, height = 45, units = "mm", dpi = 400)


# # Plot of raw data points
# gg_cent <- ggplot(network_change_data %>% filter(metric == "centrality", gamma == -0.5), aes(x = threshold, y = value, color = gamma, group = gamma)) +
#   # geom_bin2d() +
#   geom_point(size = 0.5, alpha = 0.2) +
#   stat_smooth(geom = 'line', size = 0.3, alpha = 0.8) +
#   scale_color_gradientn(colors = pal, name = expression(paste("Information\necosystem", gamma))) +
#   theme_ctokita()
# gg_cent

############################## Degree ##############################

####################
# Filter to data of interest, fit regression
####################
degree_data <- network_change_data %>% 
  filter(metric == "degree") %>% 
  split(.$gamma)

# Check if regression fit already exists, otherwise conduct bayesian regression
degree_fit_file <- paste0(out_path, "regression_fits/degree-threshold_cubicfit.rds")
if (file.exists(degree_fit_file)) { 
  regression_deg <- readRDS(degree_fit_file)
} else {
  gamma_values <- as.numeric(names(centrality_data))
  regression_deg <- brm_multiple(data = degree_data,
                                  formula = value ~ 1 + threshold + I(threshold^2) + I(threshold^3),
                                  prior = c(prior(uniform(-10, 10), class = Intercept),
                                            prior(normal(0, 10), class = b),
                                            prior(normal(0, 50), class = sigma)),
                                  iter = 3000,
                                  warmup = 1000,
                                  chains = 4,
                                  seed = 323,
                                  combine = FALSE)
  saveRDS(regression_deg, file = centrality_data)
}

# Get fitted values from model to data range/space
x_values <- data.frame(threshold = seq(0, 1, 0.01))
fit_deg <- lapply(seq(1:length(gamma_values)), function(i) {
  gamma <- gamma_values[i]
  fit_line <- fitted(regression_deg[[i]], newdata = x_values) %>% 
    as.data.frame() %>% 
    mutate(gamma = gamma,
           threshold = seq(0, 1, 0.01))
})
fit_deg <- do.call("rbind", fit_deg)


####################
# Plot thresold value vs degree for each info ecosystem (gamma)
####################
gg_degree <- ggplot(fit_deg, aes(x = threshold, y = Estimate, color = gamma, group = gamma)) +
  # geom_ribbon(aes(ymin = Q2.5, ymax = Q97.5, fill = gamma), color = NA, alpha = 0.3) +
  geom_line(size = 0.3, alpha = 0.8) +
  scale_color_gradientn(colors = pal, name = expression(paste("Information\necosystem", gamma))) +
  scale_fill_gradientn(colors = pal, name = expression(paste("Information\necosystem", gamma))) +
  ylab("Degree") +
  xlab(expression(paste("Threshold, ", theta[i]))) +
  theme_ctokita() 
gg_degree
ggsave(gg_degree, filename = paste0(out_path, "degree-thresholds", plot_tag, ".png"), width = 75, height = 45, units = "mm", dpi = 400)


####################
# Plot degree distribution for each info ecosystem (gamma)
####################
degree_dist_data <- network_change_data %>% 
  filter(metric %in% c("degree", "degree_initial")) %>% 
  filter(gamma %in% seq(-1, 1, 0.5)) 
# %>% 
#   cut(x =.$value, breaks = seq(0, 30, 1), labels =  seq(0, 29, 1), include.lowest = TRUE, right = F)

gg_degree_dist <- ggplot(degree_dist_data, aes(x = value, fill = metric)) +
  geom_histogram(binwidth = 1, alpha = 0.5, position = "identity") +
  theme_ctokita() +
  theme(aspect.ratio = 0.3) +
  facet_grid(gamma~.)
gg_degree_dist

# # Plot of raw data points
# degree_data <- network_change_data %>% 
#   filter(metric == "degree") %>% 
#   filter(gamma == 0.9)
# gg_degree <- ggplot(network_change_data %>% filter(metric == "degree", gamma == 0.9), aes(x = threshold, y = value, color = gamma, group = gamma)) +
#   # geom_bin2d() +
#   geom_point(size = 0.1, alpha = 0.2) +
#   stat_smooth(geom = 'line', size = 0.3, alpha = 0.8, se = FALSE) +
#   scale_color_gradientn(colors = pal, name = expression(paste("Information\necosystem", gamma))) +
#   theme_ctokita() 
# gg_degree
