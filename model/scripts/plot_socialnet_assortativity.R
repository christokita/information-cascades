########################################
#
# PLOT: The effect of the information ecosystem (gamma) on network assortativity and social ties
#
########################################

####################
# Load packages
####################
library(ggplot2)
library(dplyr)
library(tidyr)
source("_plot_themes/theme_ctokita.R")

####################
# Paramters for analysis: paths to data, paths for output, and filename
####################
assort_file <- "model/data_derived/network_break/social_networks/assortativity.csv" #path to file containing assortativity data
network_data_dir <- "model/data_derived/network_break/social_networks/network_change/" #path to directory containing network change data
out_path <- "model/output/network_break/social_networks/" #directory you wish to save plots
plot_tag <- "" #extra info to add onto end of plot name
if (plot_tag != "") {
  plot_tag <- paste0("_", plot_tag)
}

pal_type <- "#495867"
pal <- pal_type
pal_thresh <- "#9EACB3"
# pal <- "#16425B"


############################## Global assortativity ##############################

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
  ylab("Ideological assortativity") +
  xlab(expression( paste("Information ecosystem ", italic(gamma)) )) +
  scale_y_continuous(limits = c(-0.04, 0.43)) + 
  theme_ctokita() 
gg_assorttype #show plot before saving
ggsave(plot = gg_assorttype, filename = paste0(out_path, "assortativity_type", plot_tag, ".pdf"), width = 45, height = 45, units = "mm", dpi = 600)

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
  ylab(expression( paste(Delta, " ideological assortativity")) ) +
  xlab(expression( paste("Information ecosystem ", italic(gamma)) )) +
  theme_ctokita() 
gg_assorttypeD #show plot before saving
ggsave(plot = gg_assorttypeD, filename = paste0(out_path, "assortchange_type", plot_tag, ".pdf"), width = 45, height = 45, units = "mm", dpi = 400)

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
  ylab("Threshold assortativity") +
  xlab(expression( paste("Information ecosystem ", italic(gamma)) )) +
  # scale_y_continuous(limits = c(-0.04, 0.43)) + 
  theme_ctokita() 
gg_assortthresh #show plot before saving
ggsave(plot = gg_assortthresh, filename = paste0(out_path, "assortativity_threshold", plot_tag, ".pdf"), width = 45, height = 45, units = "mm", dpi = 600)

# Plot against assortativity by type
assort_comp <- rbind(assort_thresh, assort_type)
pal_comp <- c(pal_thresh, pal_type)
labs <- c("threshold", "ideology")
gg_assortcomp <- ggplot(data = assort_comp, aes(x = gamma, y = mean, group = metric)) +
  geom_hline(aes(yintercept = 0), 
             size = 0.3, 
             linetype = "dotted") +
  geom_ribbon(aes(ymin = mean - sd, ymax = mean + sd, fill = metric),
              alpha = 0.4) +
  geom_line(aes(color = metric), 
            size = 0.3) +
  geom_point(aes(shape = metric, color = metric), size = 0.8, fill = "white") +
  ylab("Assortativity") +
  xlab(expression( paste("Information ecosystem ", italic(gamma)) )) +
  scale_color_manual(values = pal_comp, name = "Assortativity by", labels = labs) + 
  scale_fill_manual(values = pal_comp, name = "Assortativity by", labels = labs) + 
  scale_shape_manual(values = c(21, 19), name = "Assortativity by", labels = labs) +
  scale_y_continuous(limits = c(-0.31, 0.42),
                     breaks = seq(-0.4, 0.4, 0.1),
                     expand = c(0, 0)) +
  theme_ctokita() 
gg_assortcomp #show plot before saving
ggsave(plot = gg_assortcomp, filename = paste0(out_path, "assortativity_comparison", plot_tag, ".pdf"), width = 75, height = 45, units = "mm", dpi = 600)



############################## Changes in social ties by political type ##############################

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
network_change_data <- do.call("rbind", network_change_data) 

#Summarize
network_change_sum <- network_change_data %>% 
  gather(metric, value, -gamma, -replicate, -individual, -type, -threshold) %>% 
  select(-replicate, -individual, -type, -threshold) %>% 
  group_by(gamma, metric) %>% 
  summarise(mean = mean(value), 
            sd = sd(value),
            error = qnorm(0.975)*sd(value)/sqrt(length(value)))


####################
# Plot: Change in connections by type 
####################
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
  ylab(expression( paste("Net ", Delta, " social ties")) ) +
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
  theme_ctokita()
gg_type_change #show plot before saving
ggsave(plot = gg_type_change, filename = paste0(out_path, "tie_netchange", plot_tag, ".pdf"), width = 75, height = 45, units = "mm", dpi = 400)

####################
# Plot: Breaks/new ties by gamma
####################
ties_data <- network_change_sum %>% 
  filter(metric %in% c("diff_type_adds", "diff_type_breaks", "same_type_adds", "same_type_breaks")) %>% 
  mutate(metric = factor(metric, levels = c("same_type_adds", "same_type_breaks", "diff_type_adds", "diff_type_breaks")))

# All ties
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
  theme_ctokita()
gg_ties #show plot before saving
ggsave(plot = gg_ties, filename = paste0(out_path, "tie_breaksandadds", plot_tag, ".pdf"), width = 90, height = 45, units = "mm", dpi = 400)

# Breaks only
gg_breaks <- ties_data %>% 
  filter(grepl("breaks", metric)) %>% 
  ggplot(., aes(x = gamma, y = mean, group = metric)) +
  geom_ribbon(aes(ymax = mean + error, ymin = mean - error), 
              alpha = 0.2,
              fill = pal) +
  geom_line(size = 0.3, color = pal) +
  geom_point(aes(shape = metric, fill = metric),
             size = 1, color = pal) +
  ylab("Number of broken ties") +
  xlab(expression( paste("Information ecosystem ", italic(gamma)) )) +
  scale_y_continuous(limits = c(0, 3),
                     breaks = seq(0, 3, 0.5),
                     expand = c(0, 0)) +
  scale_shape_manual(values = c(17, 24),
                     labels = c("Same ideology",
                                "Diff. ideology"),
                     name = "") +
  scale_fill_manual(values = c("black", "white"),
                    labels = c("Same ideology",
                               "Diff. ideology"),
                    name = "") +
  theme_ctokita()
gg_breaks #show plot before saving
ggsave(plot = gg_breaks, filename = paste0(out_path, "tie_breaks", plot_tag, ".pdf"), width = 75, height = 30, units = "mm", dpi = 400)


####################
# Plot: For paper--net change and number of breaks
####################
# Net change in social ties (Figure set up)
gg_type_change_FIG <- ggplot(net_type_data, aes(x = gamma, y = mean, group = metric)) +
  geom_hline(yintercept = 0, 
             size = 0.3, 
             linetype = "dotted") +
  geom_line(size = 0.3, color = pal) +
  geom_point(aes(shape = metric, fill = metric),
             size = 1, color = pal) +
  ylab(expression( paste("Net ", Delta, " social ties")) ) +
  xlab(expression( paste("Information ecosystem ", italic(gamma)) )) +
  scale_y_continuous(breaks = seq(-2, 2, 1),
                     limits = c(-2, 2)) +
  scale_x_continuous(breaks = seq(-1, 1, 1), labels = scales::number_format(accuracy = 0.1)) +
  scale_shape_manual(values = c(19, 21),
                     labels = c("Same ideology",
                                "Diff. ideology")) +
  scale_fill_manual(values = c(pal, "white"),
                    labels = c("Same ideology",
                               "Diff. ideology")) +
  theme_ctokita() +
  theme(legend.position = "none")

gg_breaks_FIG <- ties_data %>% 
  filter(grepl("breaks", metric)) %>% 
  ggplot(., aes(x = gamma, y = mean, group = metric)) +
  geom_line(size = 0.3, color = pal) +
  geom_point(aes(shape = metric, fill = metric),
             size = 1, color = pal) +
  ylab("Number of broken ties") +
  xlab(expression( paste("Information ecosystem ", italic(gamma)) )) +
  scale_y_continuous(limits = c(0, 3),
                     breaks = seq(0, 3,1),
                     expand = c(0, 0)) +
  scale_x_continuous(breaks = seq(-1, 1, 1), labels = scales::number_format(accuracy = 0.1)) +
  scale_shape_manual(values = c(16, 21),
                     labels = c("Same ideology",
                                "Diff. ideology")) +
  scale_fill_manual(values = c("black", "white"),
                    labels = c("Same ideology",
                               "Diff. ideology")) +
  theme_ctokita() +
  theme(legend.position = "none")

# Plot using ggpubr
gg_network_change_summary_fig <- ggpubr::ggarrange(gg_type_change_FIG, gg_breaks_FIG, 
                                           ncol = 1, nrow = 2)

gg_network_change_summary_fig
ggsave(gg_network_change_summary_fig, filename = paste0(out_path, "tie_change_summary", plot_tag, ".pdf"), width = 40, height = 75, units = "mm", dpi = 400)
