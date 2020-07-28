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
source("scripts/_plot_themes/theme_ctokita.R")

####################
# Paramters for analysis: paths to data, paths for output, and filename
####################
assort_file <- "data_derived/network_break/social_networks/assortativity.csv" #path to file containing assortativity data
network_data_dir <- "data_derived/network_break/social_networks/network_change/" #path to directory containing network change data
out_path <- "output/network_break/social_networks/" #directory you wish to save plots
plot_tag <- "" #extra info to add onto end of plot name
if (plot_tag != "") {
  plot_tag <- paste0("_", plot_tag)
}

pal_type <- "#495867"
pal <- pal_type
pal_thresh <- "#9EACB3"
# pal <- "#16425B"

############################## Assortatiity ##############################

# Load data and summarise
assort_data <- read.csv(assort_file, header = TRUE)
assort_sum <- assort_data %>% 
  mutate(assort_type_delta = assort_type_final - assort_type_initial,
         assort_thresh_delta = assort_thresh_final - assort_thresh_initial) %>% 
  select(-replicate) %>% 
  gather(metric, value, -gamma) %>% 
  group_by(gamma, metric) %>% 
  summarise(mean = mean(value),
            sd = sd(value),
            ci95 = qnorm(0.975) * sd(value)/ sqrt( sum(!is.na(value)) ))

####################
# Plot: assortativity by type
####################
# Raw final assortativity values
assort_type <- assort_sum %>% 
  filter(metric == "assort_type_final")
gg_assorttype <- ggplot(data = assort_type, aes(x = gamma, y = mean)) +
  geom_hline(aes(yintercept = 0), 
             size = 0.3, 
             linetype = "dotted") +
  geom_ribbon(aes(ymin = mean - sd, ymax = mean + sd),
              alpha = 0.4,
              fill = pal_type) +
  geom_line(size = 0.3, color = pal_type) +
  geom_point(size = 0.8, color = pal_type) +
  ylab(expression( paste("Assortativity ", italic(r[global])) )) +
  xlab(expression( paste("Information ecosystem ", italic(gamma)) )) +
  scale_y_continuous(limits = c(-0.04, 0.43)) + 
  theme_ctokita() 
gg_assorttype #show plot before saving
ggsave(plot = gg_assorttype, filename = paste0(out_path, "assortativity_type", plot_tag, ".png"), width = 45, height = 45, units = "mm", dpi = 600)
ggsave(plot = gg_assorttype, filename = paste0(out_path, "assortativity_type", plot_tag, ".svg"), width = 45, height = 45, units = "mm")

# Change in assortativity
assort_type_change <- assort_sum %>% 
  filter(metric == "assort_type_delta")
gg_assorttypeD <- ggplot(data = assort_type_change, aes(x = gamma, y = mean)) +
  geom_hline(aes(yintercept = 0), 
             size = 0.3, 
             linetype = "dotted") +
  geom_ribbon(aes(ymin = mean - sd, ymax = mean + sd),
              alpha = 0.4,
              fill = pal_type) +
  geom_line(size = 0.3, color = pal_type) +
  geom_point(size = 0.8, color = pal_type) +
  ylab(expression( paste(Delta, " assortativity ", italic(r[global])) )) +
  xlab(expression( paste("Information ecosystem ", italic(gamma)) )) +
  theme_ctokita() 
gg_assorttypeD #show plot before saving
ggsave(plot = gg_assorttypeD, filename = paste0(out_path, "assortchange_type", plot_tag, ".png"), width = 45, height = 45, units = "mm", dpi = 400)
ggsave(plot = gg_assorttypeD, filename = paste0(out_path, "assortchange_type", plot_tag, ".svg"), width = 45, height = 45, units = "mm")

####################
# Plot: assortativity by threshold
####################
# Raw final assortativity values
assort_thresh <- assort_sum %>% 
  filter(metric == "assort_thresh_final")
gg_assortthresh <- ggplot(data = assort_thresh, aes(x = gamma, y = mean)) +
  geom_hline(aes(yintercept = 0), 
             size = 0.3, 
             linetype = "dotted") +
  geom_ribbon(aes(ymin = mean - sd, ymax = mean + sd),
              alpha = 0.4,
              fill = pal_thresh) +
  geom_line(size = 0.3, color = pal_thresh) +
  geom_point(size = 0.8, color = pal_thresh, shape = 21, fill = "white") +
  ylab(expression( paste("Assortativity ", italic(r[global])) )) +
  xlab(expression( paste("Information ecosystem ", italic(gamma)) )) +
  # scale_y_continuous(limits = c(-0.04, 0.43)) + 
  theme_ctokita() 
gg_assortthresh #show plot before saving
ggsave(plot = gg_assortthresh, filename = paste0(out_path, "assortativity_threshold", plot_tag, ".png"), width = 45, height = 45, units = "mm", dpi = 600)

# Plot against assortativity by type
assort_comp <- rbind(assort_thresh, assort_type)
pal_comp <- c(pal_thresh, pal_type)
labs <- c("threshold", "political type")
gg_assortcomp <- ggplot(data = assort_comp, aes(x = gamma, y = mean, group = metric)) +
  geom_hline(aes(yintercept = 0), 
             size = 0.3, 
             linetype = "dotted") +
  geom_ribbon(aes(ymin = mean - sd, ymax = mean + sd, fill = metric),
              alpha = 0.4) +
  geom_line(aes(color = metric), 
            size = 0.3) +
  geom_point(aes(shape = metric, color = metric), size = 0.8, fill = "white") +
  ylab(expression( paste("Assortativity ", italic(r[global])) )) +
  xlab(expression( paste("Information ecosystem ", italic(gamma)) )) +
  scale_color_manual(values = pal_comp, name = "Assortativity by", labels = labs) + 
  scale_fill_manual(values = pal_comp, name = "Assortativity by", labels = labs) + 
  scale_shape_manual(values = c(21, 19), name = "Assortativity by", labels = labs) +
  scale_y_continuous(limits = c(-0.31, 0.42),
                     breaks = seq(-0.4, 0.4, 0.1),
                     expand = c(0, 0)) +
  theme_ctokita() 
gg_assortcomp #show plot before saving
ggsave(plot = gg_assortcomp, filename = paste0(out_path, "assortativity_comparison", plot_tag, ".png"), width = 75, height = 45, units = "mm", dpi = 600)



############################## Changes in network structure ##############################

# Load data and summarise
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
# Plot summarize data
####################
# Change in connections by type
net_type_data <- network_change_sum %>% 
  filter(metric %in% c("net_same", "net_diff")) %>% 
  mutate(metric = factor(metric, levels = c("net_same", "net_diff")))
gg_type_change <- ggplot(net_type_data, aes(x = gamma, y = mean, group = metric)) +
  geom_hline(yintercept = 0, 
             size = 0.3, 
             linetype = "dotted") +
  geom_ribbon(aes(ymax = mean + error, ymin = mean - error), 
              alpha = 0.2,
              fill = pal) +
  geom_line(size = 0.3, color = pal) +
  geom_point(aes(shape = metric, fill = metric),
             size = 1, color = pal) +
  ylab(expression( paste(Delta, " social ties")) ) +
  xlab(expression( paste("Information ecosystem ", italic(gamma)) )) +
  scale_y_continuous(breaks = seq(-2, 2, 0.5)) +
  scale_shape_manual(values = c(19, 21),
                     labels = c("Same ideology",
                                "Diff. ideology"),
                     name = "Connetion type") +
  scale_fill_manual(values = c(pal, "white"),
                    labels = c("Same ideology",
                               "Diff. ideology"),
                    name = "Connetion type") +
  theme_ctokita() +
  theme(aspect.ratio = 1)
gg_type_change #show plot before saving
ggsave(plot = gg_type_change, filename = paste0(out_path, "tiechange", plot_tag, ".png"), width = 75, height = 45, units = "mm", dpi = 400)
ggsave(plot = gg_type_change, filename = paste0(out_path, "tiechange", plot_tag, ".svg"), width = 75, height = 45, units = "mm")

# Breaks/new ties by gamma
ties_data <- network_change_sum %>% 
  filter(metric %in% c("diff_type_adds", "diff_type_breaks", "same_type_adds", "same_type_breaks")) %>% 
  mutate(metric = factor(metric, levels = c("same_type_adds", "same_type_breaks", "diff_type_adds", "diff_type_breaks")))
gg_ties <- ggplot(ties_data, aes(x = gamma, y = mean, group = metric)) +
  geom_ribbon(aes(ymax = mean + error, ymin = mean - error), 
              alpha = 0.2,
              fill = pal) +
  geom_line(size = 0.3, color = pal) +
  geom_point(aes(shape = metric, fill = metric),
             size = 1, color = pal) +
  ylab("Count") +
  xlab(expression( paste("Information ecosystem ", italic(gamma)) )) +
  # scale_y_continuous(limits = c(0, 1.21), 
  #                    breaks = seq(0, 2, 0.2),
  #                    expand = c(0, 0)) +
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
gg_ties #show plot before saving
ggsave(plot = gg_ties, filename = paste0(out_path, "tie_breaksandadds", plot_tag, ".png"), width = 90, height = 45, units = "mm", dpi = 400)
ggsave(plot = gg_ties, filename = paste0(out_path, "tie_breaksandadds", plot_tag, ".svg"), width = 90, height = 45, units = "mm")

# Note: Net changes in degree and centrality are not terribly informative. 
# Degree remains unchanged (total edges is constant). Centrality uniformly decreases ever so slightly.
net_degree_data <- network_change_sum %>% 
  filter(metric %in% c("net_degree"))
gg_degree_change <- ggplot(net_degree_data, aes(x = gamma, y = mean)) +
  geom_hline(yintercept = 0, 
             size = 0.3, 
             linetype = "dotted") +
  geom_ribbon(aes(ymax = mean + error, ymin = mean - error), 
              alpha = 0.4,
              fill = pal) +
  geom_line(size = 0.3,
            color = pal) +
  geom_point(size = 0.8,
             color = pal) +
  ylab(expression( paste(Delta, " out-degree"))) +
  xlab(expression( paste("Information ecosystem ", italic(gamma)) )) +
  scale_y_continuous(limits = c(-0.5, 1.5), 
                     expand = c(0, 0)) +
  theme_ctokita() +
  theme(aspect.ratio = 1,
        legend.position = "none")
gg_degree_change #show plot before saving
ggsave(plot = gg_degree_change, filename = paste0(out_path, "outdegreechange", plot_tag, ".png"), width = 45, height = 45, units = "mm", dpi = 400)
ggsave(plot = gg_degree_change, filename = paste0(out_path, "outdegreechange", plot_tag, ".svg"), width = 45, height = 45, units = "mm")

# Change in centrality
net_cent_data <- network_change_sum %>% 
  filter(metric %in% c("net_centrality"))
gg_central_change <- ggplot(net_cent_data, aes(x = gamma, y = mean)) +
  geom_hline(yintercept = 0, 
             size = 0.3, 
             linetype = "dotted") +
  geom_ribbon(aes(ymax = mean + error, ymin = mean - error), 
              alpha = 0.4,
              fill = pal) +
  geom_line(size = 0.3,
            color = pal) +
  geom_point(size = 0.8,
             color = pal) +
  ylab(expression( paste(Delta, " out-degree"))) +
  xlab(expression( paste("Information ecosystem ", italic(gamma)) )) +
  scale_y_continuous(limits = c(-0.5, 1.5), 
                     expand = c(0, 0)) +
  theme_ctokita() +
  theme(aspect.ratio = 1,
        legend.position = "none")
gg_central_change

####################
# Plot disaggregated data
####################
library(RColorBrewer)
library(brms)
pal <- brewer.pal(4, "PuOr")

# Function to do bayesian regression over gamma values
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


# Centrality 
centrality_data <- network_change_data %>% 
  filter(metric == "centrality")
gammas <- sort( unique(centrality_data$gamma) )
gammas <- gammas[c(3, 21)]
reg_centrality <- bayes_regression(gammas = gammas, data = centrality_data)

gg_centrality <- ggplot(reg_centrality, aes(x = threshold, y = Estimate, color = gamma, group = gamma)) +
  # geom_ribbon(aes(ymin = Q2.5, ymax = Q97.5), fill = "grey80", color = NA, alpha = 0.2) +
  geom_line() +
  scale_color_gradientn(colors = pal, name = expression(paste("Information\necosystem", gamma))) +
  theme_ctokita() 
gg_centrality

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
