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
assort_file <- "data_derived/network_break/social_networks/assortativity_gammasweep.csv" #path to file containing assortativity data
network_data_dir <- "data_derived/network_break/social_networks/network_change/" #path to directory containing network change data
out_path <- "output/network_break/social_networks/" #directory you wish to save plots
plot_tag <- "gamma" #extra info to add onto end of plot name
if (plot_tag != "") {
  plot_tag <- paste0("_", plot_tag)
}

pal <- "#1B3B6F"
# pal <- "#225ea8"

############################## Assortatiity ##############################

####################
# Load data and summarise
####################
assort_data <- read.csv(assort_file, header = TRUE)
assort_sum <- assort_data %>% 
  mutate(delta_assort = assort_final - assort_initial) %>% 
  select(gamma, delta_assort, assort_final) %>% 
  gather(metric, value, -gamma) %>% 
  group_by(gamma, metric) %>% 
  summarise(mean = mean(value),
            sd = sd(value),
            ci95 = qnorm(0.975) * sd(value)/ sqrt( sum(!is.na(value)) ))

####################
# Plot
####################
# Raw final assortativity values
assort_raw <- assort_sum %>% 
  filter(metric == "assort_final")
gg_assort <- ggplot(data = assort_raw, aes(x = gamma, y = mean)) +
  geom_hline(aes(yintercept = 0), 
             size = 0.3, 
             linetype = "dotted") +
  # geom_errorbar(aes(ymin = mean - sd, ymax = mean + sd), 
  #               width = 0,
  #               size = 0.3, color = "#225ea8") +
  geom_ribbon(aes(ymin = mean - sd, ymax = mean + sd),
              alpha = 0.4,
              fill = pal) +
  geom_line(size = 0.3, color = pal) +
  geom_point(size = 0.8, color = pal) +
  ylab(expression( paste("Assortativity ", italic(r[global])) )) +
  xlab(expression( paste("Information correlation ", italic(gamma)) )) +
  theme_ctokita() 
gg_assort #show plot before saving
ggsave(plot = gg_assort, filename = paste0(out_path, "assortativity", plot_tag, ".png"), width = 45, height = 45, units = "mm", dpi = 400)
ggsave(plot = gg_assort, filename = paste0(out_path, "assortativity", plot_tag, ".svg"), width = 45, height = 45, units = "mm")

# Change in assortativity
assort_change <- assort_sum %>% 
  filter(metric == "delta_assort")
gg_assortchange <- ggplot(data = assort_change, aes(x = gamma, y = mean)) +
  geom_hline(aes(yintercept = 0), 
             size = 0.3, 
             linetype = "dotted") +
  geom_ribbon(aes(ymin = mean - sd, ymax = mean + sd), 
              alpha = 0.4) +
  geom_line(size = 0.3) +
  geom_point(size = 0.8) +
  ylab(expression( paste(Delta, " assortativity ", italic(r[global])) )) +
  xlab(expression( paste("Information correlation ", italic(gamma)) )) +
  theme_ctokita() 
gg_assortchange #show plot before saving
ggsave(plot = gg_assortchange, filename = paste0(out_path, "assortchange", plot_tag, ".png"), width = 45, height = 45, units = "mm", dpi = 400)
ggsave(plot = gg_assortchange, filename = paste0(out_path, "assortchange", plot_tag, ".svg"), width = 45, height = 45, units = "mm")



############################## Changes in network structure ##############################

##########
# Load data and summarise
##########
network_files <- list.files(network_data_dir, full.names = TRUE)
network_change_data <- lapply(network_files, function(x) {
  # Read in file 
  run_file <- read.csv(x) %>% 
    mutate(net_same = same_type_adds - same_type_breaks,
           net_diff = diff_type_adds - diff_type_breaks,
           net_out_degree = out_degree - out_degree_initial,
           net_in_degree = in_degree - in_degree_initial)
  return(run_file)
})
network_change_data <- do.call("rbind", network_change_data)

#Summarize
network_change_sum <- network_change_data %>% 
  select(-replicate, -individual) %>% 
  gather(metric, value, -gamma) %>% 
  group_by(gamma, metric) %>% 
  summarise(mean = mean(value), 
            sd = sd(value),
            error = qnorm(0.975)*sd(value)/sqrt(length(value)))


####################
# Plot
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
              alpha = 0.4) +
  geom_line(size = 0.3) +
  geom_point(aes(shape = metric, fill = metric),
             size = 1) +
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
gg_type_change #show plot before saving
ggsave(plot = gg_type_change, filename = paste0(out_path, "tiechange", plot_tag, ".png"), width = 75, height = 45, units = "mm", dpi = 400)
ggsave(plot = gg_type_change, filename = paste0(out_path, "tiechange", plot_tag, ".svg"), width = 75, height = 45, units = "mm")

# Breaks/new ties by gamma
ties_data <- network_change_sum %>% 
  filter(metric %in% c("diff_type_adds", "diff_type_breaks", "same_type_adds", "same_type_breaks")) %>% 
  mutate(metric = factor(metric, levels = c("same_type_adds", "same_type_breaks", "diff_type_adds", "diff_type_breaks")))
gg_ties <- ggplot(ties_data, aes(x = gamma, y = mean, group = metric)) +
  geom_line(size = 0.3) +
  geom_ribbon(aes(ymax = mean + error, ymin = mean - error),
              alpha = 0.4) +
  geom_point(aes(shape = metric, fill = metric),
             size = 1) +
  ylab("Count") +
  xlab(expression( paste("Information correlation ", italic(gamma)) )) +
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

# Change in degree
net_degree_data <- network_change_sum %>% 
  filter(metric %in% c("net_out_degree"))
gg_degree_change <- ggplot(net_degree_data, aes(x = gamma, y = mean)) +
  geom_hline(yintercept = 0, 
             size = 0.3, 
             linetype = "dotted") +
  geom_ribbon(aes(ymax = mean + error, ymin = mean - error), 
              alpha = 0.4) +
  geom_line(size = 0.3) +
  geom_point(aes(fill = metric),
             size = 0.8) +
  ylab(expression( paste(Delta, " out-degree"))) +
  xlab(expression( paste("Information correlation ", italic(gamma)) )) +
  scale_y_continuous(limits = c(-0.5, 1.5), 
                     expand = c(0, 0)) +
  theme_ctokita() +
  theme(aspect.ratio = 1,
        legend.position = "none")
gg_degree_change #show plot before saving
ggsave(plot = gg_degree_change, filename = paste0(out_path, "outdegreechange", plot_tag, ".png"), width = 45, height = 45, units = "mm", dpi = 400)
ggsave(plot = gg_degree_change, filename = paste0(out_path, "outdegreechange", plot_tag, ".svg"), width = 45, height = 45, units = "mm")


