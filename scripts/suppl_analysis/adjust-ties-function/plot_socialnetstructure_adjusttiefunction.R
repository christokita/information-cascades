########################################
#
# PLOT: Social network structure with adjust_ties function instead of separate break_tie and make_tie functions
#
########################################

####################
# Load packages
####################
library(ggplot2)
library(dplyr)
library(tidyr)
source("scripts/_plot_themes/theme_ctokita.R")

# Palette for plotting
pal <- c("#225ea8", "#41b6c4", "#9DDBDA")

############################## Assortatiity ##############################

####################
# Load data and summarise
####################
# Adjust_tie_function
adjust_tie_data <- read.csv('data_derived/network_break/__suppl_sims/adjust_tie_function/social_networks/assortativity_adjusttie.csv', header = TRUE) %>% 
  mutate(model = "Adjust tie")

# No new ties formed, 10^6 steps
p0_longdata <- read.csv('data_derived/network_break/__suppl_sims/p0_longsim/social_networks/assortativity_p0_10^6steps.csv', header = TRUE) %>% 
  mutate(model = "p = 0")

# No new ties formed, 10^6 steps
psmall_data <- read.csv('data_derived/network_break/__suppl_sims/psmall/social_networks/assortativity_psmall.csv', header = TRUE) %>% 
  mutate(model = "p = 0.0005")

# Bind
assort_sum <- rbind(adjust_tie_data, p0_longdata, psmall_data) %>% 
  mutate(delta_assort = assort_final - assort_initial) %>% 
  select(-replicate) %>% 
  tidyr::gather(metric, value, -gamma, -model) %>% 
  group_by(gamma, metric, model) %>% 
  summarise(mean = mean(value, na.rm = TRUE),
            sd = sd(value, na.rm = TRUE),
            ci95 = qnorm(0.975) * sd(value, na.rm = TRUE) / sqrt( sum(!is.na(value)) ),
            iqr_low = mean(value, na.rm = TRUE) - quantile(value, 0.25),
            iqr_high = quantile(value, 0.75) - mean(value, na.rm = TRUE)) #denominator removes NA values from count

####################
# Plot
####################
# Raw final assortativity values in comparison with other models
assort_raw <- assort_sum %>% 
  filter(metric == "assort_final")
gg_assort_comp <- ggplot(data = assort_raw, aes(x = gamma, y = mean, color = model, fill = model)) +
  geom_hline(aes(yintercept = 0), 
             size = 0.3, 
             linetype = "dotted") +
  geom_ribbon(aes(ymin = mean - ci95, ymax = mean + ci95),
              alpha = 0.4,
              color = NA) +
  geom_line(size = 0.3) +
  geom_point(size = 0.8) +
  scale_color_manual(values = pal) +
  scale_fill_manual(values = pal) +
  scale_y_continuous(breaks = seq(-0.5, 0.3, 0.05)) +
  ylab(expression( paste("Assortativity ", italic(r[global])) )) +
  xlab(expression( paste("Information correlation ", italic(gamma)) )) +
  theme_ctokita() 
gg_assort_comp #show plot before saving
ggsave(plot = gg_assort_comp, 
       filename = "output/network_break/__suppl_analysis/adjust_tie_function/assortativity_adjusttiescomparison.png", 
       height = 45, 
       width = 100, units = "mm", dpi = 400)


# Raw final assortativity values
assort_raw <- assort_sum %>% 
  filter(metric == "assort_final", model == "Adjust tie")
gg_assort <- ggplot(data = assort_raw, aes(x = gamma, y = mean, color = model, fill = model)) +
  geom_hline(aes(yintercept = 0), 
             size = 0.3, 
             linetype = "dotted") +
  geom_ribbon(aes(ymin = mean - sd, ymax = mean + sd),
              alpha = 0.4,
              color = NA) +
  geom_line(size = 0.3) +
  geom_point(size = 0.8) +
  scale_color_manual(values = pal) +
  scale_fill_manual(values = pal) +
  scale_y_continuous(breaks = seq(-0.05, 0.3, 0.05)) +
  ylab(expression( paste("Assortativity ", italic(r[global])) )) +
  xlab(expression( paste("Information correlation ", italic(gamma)) )) +
  theme_ctokita()  +
  theme(legend.position = "none")
gg_assort #show plot before saving
ggsave(plot = gg_assort, 
       filename = "output/network_break/__suppl_analysis/adjust_tie_function/assortativity_adjustties.png", 
       height = 45, 
       width = 45, units = "mm", dpi = 600)


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
  scale_y_continuous(limits = c(0, 1.21),
                     breaks = seq(0, 2, 0.2),
                     expand = c(0, 0)) +
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

# Change in degree
net_degree_data <- network_change_sum %>% 
  filter(metric %in% c("net_out_degree"))
gg_degree_change <- ggplot(net_degree_data, aes(x = gamma, y = mean)) +
  geom_ribbon(aes(ymax = mean + error, ymin = mean - error), 
              alpha = 0.4) +
  geom_line(size = 0.3) +
  geom_point(aes(fill = metric),
             size = 0.8) +
  ylab(expression( paste(Delta, " out-degree"))) +
  xlab(expression( paste("Information correlation ", italic(gamma)) )) +
  theme_ctokita() +
  theme(aspect.ratio = 1,
        legend.position = "none")
gg_degree_change #show plot before saving
ggsave(plot = gg_degree_change, filename = paste0(out_path, "outdegreechange", plot_tag, ".png"), width = 45, height = 45, units = "mm", dpi = 400)

