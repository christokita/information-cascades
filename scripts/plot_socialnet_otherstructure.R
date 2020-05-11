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

####################
# Function to do bayesian regression over gamma values
####################
bayes_regression <- function(gammas, data) {
  # Loop over gamma values, fitting a bayesian regression to each subset of data
  regression <- lapply(gammas, function(gamma) {
    # Filter to just data of interest
    gamma_data <- data %>% 
      filter(gamma == gamma)
    # Fit bayesian model
    model <- brm(data = gamma_data,
                 formula = value ~ 1 + threshold,
                 prior = c(prior(uniform(-10, 10), class = Intercept),
                           prior(normal(0, 10), class = b),
                           prior(normal(0, 50), class = sigma)),
                 iter = 3000,
                 warmup = 1000,
                 chains = 2,
                 seed = 323)
    # Get model predictions for plotting as line
    x_values <- data.frame(threshold = seq(0, 1, 0.01))
    fitted_values <- fitted(model, newdata = x_values) %>% 
      as.data.frame() %>% 
      mutate(gamma = gamma,
             threshold = seq(0, 1, 0.01))
    return(fitted_values)
  })
  # Bind together and return
  regression <- do.call("rbind", regression)
  return(regression)
} 


############################## Centrality ##############################

####################
# Filter to data of interest, fit regression
####################
centrality_data <- network_change_data %>% 
  filter(metric == "centrality")
gammas <- sort( unique(centrality_data$gamma) )
gammas <- gammas[c(3, 21)]
reg_centrality <- bayes_regression(gammas = gammas, data = centrality_data)


####################
# Plot eigenvector centrality vs thresold value for each info ecosystem (gamma)
####################
gg_centrality <- ggplot(reg_centrality, aes(x = threshold, y = Estimate, color = gamma, group = gamma)) +
  # geom_ribbon(aes(ymin = Q2.5, ymax = Q97.5), fill = "grey80", color = NA, alpha = 0.2) +
  geom_line() +
  scale_color_gradientn(colors = pal, name = expression(paste("Information\necosystem", gamma))) +
  theme_ctokita() 
gg_centrality



############################## Degree ##############################

# Degree 
degree_data <- network_change_data %>% 
  filter(metric == "degree")
gg_degree <- ggplot(degree_data, aes(x = threshold, y = value, color = gamma, group = gamma)) +
  # geom_bin2d() +
  # geom_point(size = 0.1, alpha = 0.2) +
  stat_smooth(geom = 'line', size = 0.3, alpha = 0.8, se = FALSE) +
  scale_color_gradientn(colors = pal, name = expression(paste("Information\necosystem", gamma))) +
  theme_ctokita() 
gg_degree
