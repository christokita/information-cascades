########################################
#
# PLOT: Effect of the information ecosystem (gamma) on other elements of network structure (e.g. centrality, degree, local assortativity)
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
source("_plot_themes/theme_ctokita.R")

####################
# Paramters for analysis: paths to data, paths for output, and filename
####################
network_data_dir <- "model/data_derived/network_break/social_networks/network_change/" #path to directory containing network change data
out_path <- "model/output/network_break/social_networks/" #directory you wish to save plots
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
centrality_fit_file <- paste0(out_path, "regression_fits/centrality-threshold_linearfit.rds")
gamma_values <- as.numeric(names(centrality_data))
if (file.exists(centrality_fit_file)) { 
  regression_cent <- readRDS(centrality_fit_file)
} else {
  regression_cent <- brm_multiple(data = centrality_data,
                                  formula = value ~ 1 + threshold,
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
# Plot fitted regressions for thresold vs eigenvector centrality value in each info ecosystem (gamma)
####################
# All gammas
gg_centrality <- ggplot(fit_cent, aes(x = threshold, y = Estimate, color = gamma, group = gamma)) +
  # geom_ribbon(aes(ymin = Q2.5, ymax = Q97.5, fill = gamma), color = NA, alpha = 0.3) +
  geom_line(size = 0.3, alpha = 0.8) +
  scale_color_gradientn(colors = pal, name = expression(paste("Information\necosystem", gamma))) +
  scale_fill_gradientn(colors = pal, name = expression(paste("Information\necosystem", gamma))) +
  ylab("Centrality") +
  xlab(expression(paste("Threshold, ", theta[i]))) +
  theme_ctokita() 
gg_centrality
ggsave(gg_centrality, filename = paste0(out_path, "threshold-centrality", plot_tag, ".pdf"), width = 75, height = 45, units = "mm", dpi = 400)

# Select gammas
gamma_vals <- c(-1, 0.8, 0.6, 0.4, 0, 1)
gg_centrality_select <- fit_cent %>% 
  filter(gamma %in% gamma_vals) %>%
  ggplot(., aes(x = threshold, y = Estimate, color = gamma, group = gamma)) +
  # geom_ribbon(aes(ymin = Q2.5, ymax = Q97.5, fill = gamma), color = NA, alpha = 0.3) +
  geom_point(data = network_change_data %>% filter(metric == "centrality", gamma  %in% gamma_vals), aes(x = threshold, y = value), alpha = 0.02, size = 0.05) +
  geom_line() +
  scale_color_gradientn(colors = pal, name = expression(paste("Information\necosystem", gamma))) +
  scale_fill_gradientn(colors = pal, name = expression(paste("Information\necosystem", gamma))) +
  scale_x_continuous(breaks = seq(0, 1, 1)) +
  ylab("Centrality") +
  xlab(expression(paste("Threshold ", theta[i]))) +
  facet_grid(.~gamma) +
  theme_ctokita() +
  theme(aspect.ratio = 3,
        legend.position = "none", 
        strip.background = element_blank())
gg_centrality_select



############################## Degree ##############################

####################
# Filter to data of interest, fit regression
####################
degree_data <- network_change_data %>% 
  filter(metric == "degree") %>% 
  split(.$gamma)

# Check if regression fit already exists, otherwise conduct bayesian regression
degree_fit_file <- paste0(out_path, "regression_fits/degree-threshold_linearfit.rds")
gamma_values <- as.numeric(names(degree_data))
if (file.exists(degree_fit_file)) { 
  regression_deg <- readRDS(degree_fit_file)
} else {
  gamma_values <- as.numeric(names(degree_data))
  regression_deg <- brm_multiple(data = degree_data,
                                  formula = value ~ 1 + threshold,
                                  prior = c(prior(uniform(-10, 10), class = Intercept),
                                            prior(normal(0, 10), class = b),
                                            prior(normal(0, 50), class = sigma)),
                                  iter = 3000,
                                  warmup = 1000,
                                  chains = 4,
                                  seed = 323,
                                  combine = FALSE)
  saveRDS(regression_deg, file = degree_fit_file)
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
# Plot fitted regressions for thresold value vs degree in each info ecosystem (gamma)
####################
# All gammas
gg_degree <- ggplot(fit_deg, aes(x = threshold, y = Estimate, color = gamma, group = gamma)) +
  # geom_ribbon(aes(ymin = Q2.5, ymax = Q97.5, fill = gamma), color = NA, alpha = 0.3) +
  geom_line(size = 0.3, alpha = 0.8) +
  scale_color_gradientn(colors = pal, name = expression(paste("Information\necosystem", gamma))) +
  scale_fill_gradientn(colors = pal, name = expression(paste("Information\necosystem", gamma))) +
  ylab("Degree") +
  xlab(expression(paste("Threshold, ", theta[i]))) +
  theme_ctokita() 
gg_degree
ggsave(gg_degree, filename = paste0(out_path, "threshold-degree", plot_tag, ".pdf"), width = 75, height = 45, units = "mm", dpi = 400)

# Select gammas
gamma_vals <- c(-1, 0.8, 0.6, 0.4, 0, 1)
gg_degree_select <- fit_deg %>% 
  filter(gamma %in% gamma_vals) %>%
  ggplot(., aes(x = threshold, y = Estimate, color = gamma, group = gamma)) +
  # geom_ribbon(aes(ymin = Q2.5, ymax = Q97.5, fill = gamma), color = NA, alpha = 0.3) +
  geom_point(data = network_change_data %>% filter(metric == "degree", gamma  %in% gamma_vals), 
             aes(x = threshold, y = value), 
             alpha = 0.02, 
             size = 0.05,
             position = position_jitter(height = 1)) +
  geom_line() +
  scale_color_gradientn(colors = pal, name = expression(paste("Information\necosystem", gamma))) +
  scale_fill_gradientn(colors = pal, name = expression(paste("Information\necosystem", gamma))) +
  scale_x_continuous(breaks = seq(0, 1, 1)) +
  ylab("Degree") +
  xlab(expression(paste("Threshold ", theta[i]))) +
  facet_grid(.~gamma) +
  theme_ctokita() +
  theme(aspect.ratio = 3,
        legend.position = "none", 
        strip.background = element_blank())
gg_degree_select

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



############################## Local Assortativity ##############################

####################
# Filter to data of interest, fit regression
####################
localassort_data <- network_change_data %>% 
  filter(metric == "local_assortativity") %>% 
  split(.$gamma)

# Check if regression fit already exists, otherwise conduct bayesian regression
localassort_fit_file <- paste0(out_path, "regression_fits/localassort-threshold_linearfit.rds")
gamma_values <- as.numeric(names(localassort_data))
if (file.exists(localassort_fit_file)) { 
  regression_la <- readRDS(localassort_fit_file) 
} else {
  gamma_values <- as.numeric(names(localassort_data))
  regression_la <- brm_multiple(data = localassort_data,
                                 formula = value ~ 1 + threshold,
                                 prior = c(prior(uniform(-10, 10), class = Intercept),
                                           prior(normal(0, 10), class = b),
                                           prior(normal(0, 50), class = sigma)),
                                 iter = 3000,
                                 warmup = 1000,
                                 chains = 4,
                                 seed = 323,
                                 combine = FALSE)
  saveRDS(regression_la, file = localassort_fit_file)
}

# Get fitted values from model to data range/space
x_values <- data.frame(threshold = seq(0, 1, 0.01))
fit_la <- lapply(seq(1:length(gamma_values)), function(i) {
  gamma <- gamma_values[i]
  fit_line <- fitted(regression_la[[i]], newdata = x_values) %>% 
    as.data.frame() %>% 
    mutate(gamma = gamma,
           threshold = seq(0, 1, 0.01))
})
fit_la <- do.call("rbind", fit_la)

####################
# Plot fitted regressions for thresold value vs local assortativity in each info ecosystem (gamma)
####################
# All gammas
gg_localassort <- ggplot(fit_la, aes(x = threshold, y = Estimate, color = gamma, group = gamma)) +
  geom_hline(aes(yintercept = 0), 
             size = 0.3, 
             linetype = "dotted") +
  # geom_ribbon(aes(ymin = Q2.5, ymax = Q97.5, fill = gamma), color = NA, alpha = 0.3) +
  geom_line(size = 0.3, alpha = 0.8) +
  scale_color_gradientn(colors = pal, name = expression(paste("Information\necosystem", gamma))) +
  scale_fill_gradientn(colors = pal, name = expression(paste("Information\necosystem", gamma))) +
  ylab(expression(paste("Local assortativity, ", r[local]))) +
  xlab(expression(paste("Threshold, ", theta[i]))) +
  theme_ctokita() 
gg_localassort
ggsave(gg_localassort, filename = paste0(out_path, "threshold-localassort", plot_tag, ".pdf"), width = 75, height = 45, units = "mm", dpi = 400)

# Select gammas
gamma_vals <- c(-1, 0.8, 0.6, 0.4, 0, 1)
gg_localassort_select <- fit_la %>% 
  filter(gamma %in% gamma_vals) %>%
  ggplot(., aes(x = threshold, y = Estimate, color = gamma, group = gamma)) +
  # geom_ribbon(aes(ymin = Q2.5, ymax = Q97.5, fill = gamma), color = NA, alpha = 0.3) +
  geom_point(data = network_change_data %>% filter(metric == "local_assortativity", gamma  %in% gamma_vals), 
             aes(x = threshold, y = value), 
             alpha = 0.02, 
             size = 0.05) +
  geom_line() +
  scale_color_gradientn(colors = pal, name = expression(paste("Information\necosystem", gamma))) +
  scale_fill_gradientn(colors = pal, name = expression(paste("Information\necosystem", gamma))) +
  scale_x_continuous(breaks = seq(0, 1, 1)) +
  ylab(expression(paste("Local assortativity ", r[local]))) +
  xlab(expression(paste("Threshold ", theta[i]))) +
  facet_grid(.~gamma) +
  theme_ctokita() +
  theme(aspect.ratio = 3,
        legend.position = "none", 
        strip.background = element_blank())
gg_localassort_select


####################
# Plot thresold value vs local assortativity (raw values)
####################
gamma_of_interest <- -0.5

localassort_raw <- network_change_data %>% 
  filter(metric == "local_assortativity",
         gamma == gamma_of_interest)

fit_example <- fit_la %>% 
  filter(gamma == gamma_of_interest)

gg_localassort_raw <- ggplot(localassort_raw, aes(x = threshold, y = value)) +
  geom_point(size = 0.1, alpha = 0.2) +
  geom_line(data = fit_example, aes(x = threshold, y = Estimate)) +
  ylab("Local assortativity") +
  xlab(expression(paste("Threshold, ", theta[i]))) +
  theme_ctokita()
gg_localassort_raw



############################## Summary plot of all metrics ##############################

####################
# Compile data
####################
# Compile fits
fit_cent$metric <- "Centrality"
fit_deg$metric <- "Degree"
fit_la$metric <- "Local assort."
fits <- rbind(fit_cent, fit_deg, fit_la)

# Raw data
raw_network_data <- network_change_data %>% 
  mutate(metric = gsub("centrality", "Centrality", metric),
         metric = gsub("degree", "Degree", metric),
         metric = gsub("local_assortativity", "Local assort.", metric)) %>% #make proper labels
  filter(metric %in% unique(fits$metric))

####################
# Plot gamma by metric
####################
# Select gammas
gamma_vals <- c(-1, -0.4, 0.0, 0.4, 0.9, 1)

# Plot
gg_localnetmetrics <- fits %>% 
  filter(gamma %in% gamma_vals) %>%
  ggplot(., aes(x = threshold, y = Estimate, color = gamma, group = gamma)) +
  # geom_ribbon(aes(ymin = Q2.5, ymax = Q97.5, fill = gamma), color = NA, alpha = 0.3) +
  geom_point(data = raw_network_data %>% filter(gamma  %in% gamma_vals), 
             aes(x = threshold, y = value), 
             alpha = 0.05,
             stroke = 0,
             size = 0.2) +
  geom_line(size = 0.4) +
  scale_color_gradientn(colors = pal, name = expression(paste("Information\necosystem", gamma))) +
  scale_fill_gradientn(colors = pal, name = expression(paste("Information\necosystem", gamma))) +
  scale_x_continuous(breaks = seq(0, 1, 1)) +
  ylab("") +
  xlab(expression(paste("Threshold, ", theta[i]))) +
  facet_grid(metric~gamma, scales = "free_y", switch = "y",
             labeller = label_bquote(cols = gamma == .(gamma))) +
  theme_ctokita() +
  theme(strip.background = element_blank(),
        legend.position = "none",
        strip.placement = "outside",
        aspect.ratio = NULL, 
        axis.title.y = element_blank(),
        strip.text.y = element_text(size = 6),
        plot.background = element_blank())
gg_localnetmetrics
ggsave(gg_localnetmetrics, filename = paste0(out_path, "threshold-individualnetworkmetrics", plot_tag, ".png"), bg = "transparent", width = 90, height = 60, units = "mm", dpi = 400)

####################
# Plot linear component of fit by gamma (for each metric)
####################
# Function to extract linear coefficient from our quadratic regressions
extract_coeffs <- function(regressions, gamma_values, metric) {
  coeffs <- data.frame(gamma = NULL, slope = NULL, metric = NULL)
  for (i in 1:length(regressions)) {
    fixed_effects <- fixef(regressions[[i]])
    new_row <- data.frame(gamma = gamma_values[i], slope = fixed_effects[2], metric = metric) #intercept is 1st, then linear slope, then quadratic coeff
    coeffs <- rbind(coeffs, new_row)
  }
  return(coeffs)
}

# Get coeffs
coeffs_cent <- extract_coeffs(regressions = regression_cent, gamma_values = gamma_values, metric = "Centrality")
coeffs_deg <- extract_coeffs(regressions = regression_deg, gamma_values = gamma_values, metric = "Degree")
ceoffs_localassort <- extract_coeffs(regressions = regression_la, gamma_values = gamma_values, metric = "Local assort.")
coeffs_all <- rbind(coeffs_cent, coeffs_deg, ceoffs_localassort)
rm(coeffs_cent, coeffs_deg, ceoffs_localassort)

# Plot
gg_coeffs <- ggplot(coeffs_all, aes(x = gamma, y = slope, color = gamma)) +
  # geom_ribbon(aes(ymin = Q2.5, ymax = Q97.5, fill = gamma), color = NA, alpha = 0.3) +
  geom_line(size = 0.3) +
  geom_point(stroke = 0) +
  scale_x_continuous(breaks = seq(-1, 1, 1)) +
  scale_y_continuous(expand = c(0.3, 0)) +
  scale_color_gradientn(colors = pal, name = expression(paste("Information\necosystem", gamma))) +
  facet_wrap(~metric, 
             scales = "free_y", 
             ncol = 1,
             strip.position = "right") +
  ylab("Thresholds regression coefficient") +
  xlab(expression(paste("Information ecosystem ", gamma))) +
  theme_ctokita() +
  theme(strip.background = element_blank(),
        # strip.placement = "inside",
        legend.margin = margin(c(0, 0, 0, 0)),
        legend.box.margin=margin(-2,-2,-2,-2),
        legend.position = "none",
        aspect.ratio = NULL, 
        strip.text.y = element_text(size = 6))
gg_coeffs
ggsave(gg_coeffs, filename = paste0(out_path, "threshold-networkmetriccoeffs", plot_tag, ".pdf"), width = 35, height = 54, units = "mm", dpi = 400)
