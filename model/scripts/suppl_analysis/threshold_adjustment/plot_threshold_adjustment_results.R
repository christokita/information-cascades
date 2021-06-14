########################################
#
# PLOT: The affect of allowing threshold adjustment/desensitization in model
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
assort_file_threshadjust <- "model/data_derived/network_break/__suppl_sims/threshold_adjustment/social_networks/assortativity.csv" #path to file containing assortativity data

fit_cascade_path_threshadjust <- "model/data_derived/network_break/__suppl_sims/threshold_adjustment/fitness_trials/fitness_cascadestats.csv" #path to fitness cascade data
fit_behavior_path_threshadjust <- "model/data_derived/network_break/__suppl_sims/threshold_adjustment/fitness_trials/fitness_behavior.csv" #path to fitness behavior data

fit_cascade_path_normal <- "model/data_derived/network_break/fitness_trials/fitness_cascadestats.csv" #path to fitness cascade data
fit_behavior_path_normal <- "model/data_derived/network_break/fitness_trials/fitness_behavior.csv" #path to fitness behavior data

out_path <- "model/output/network_break/__suppl_analysis/threshold_adjustment/" #directory you wish to save plots
plot_tag <- "" #extra info to add onto end of plot name
if (plot_tag != "") {
  plot_tag <- paste0("_", plot_tag)
}

# Colors
models_pal <- c("#B7C0EE" , "#495867")
pal <- brewer.pal(4, "PuOr")




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
  mutate(model = "Tie break only (default)")

# Load homophily tie formation model data and summarise
assort_data_threshadjust <- read.csv(assort_file_threshadjust, header = TRUE)
assort_sum_threshadjust <- assort_data_threshadjust %>% 
  mutate(assort_type_delta = assort_type_final - assort_type_initial,
         assort_thresh_delta = assort_thresh_final - assort_thresh_initial) %>% 
  select(-replicate) %>% 
  gather(metric, value, -gamma) %>% 
  group_by(gamma, metric) %>% 
  summarise(mean = mean(value),
            sd = sd(value),
            ci95 = qnorm(0.975) * sd(value)/ sqrt( sum(!is.na(value)) )) %>% 
mutate(model = "Tie break +\nthreshold adjustment")

# Bind together
assort_sum <- rbind(assort_sum_normal, assort_sum_threshadjust)


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
  scale_fill_manual(name = "Response to\nincorrect cascade",
                    values = models_pal) +
  scale_color_manual(name = "Response to\nincorrect cascade",
                     values = models_pal) +
  theme_ctokita() 
gg_assorttype #show plot before saving
ggsave(plot = gg_assorttype, filename = paste0(out_path, "assortativity_by_tie_formation", plot_tag, ".pdf"), width = 80, height = 45, units = "mm", dpi = 600)



############################## Fitness trials: cascades and behavior ##############################

####################
# Load data 
####################
# Summarize cascade data by gamma, bind together
cascade_sum_normal <- read.csv(fit_cascade_path_normal, header = TRUE) %>% 
  gather(metric, value, -trial, -gamma) %>% 
  mutate(trial = factor(trial, levels = c("pre", "post"))) %>% 
  group_by(trial, gamma, metric) %>% 
  summarise(mean = mean(value, na.rm = TRUE),
            sd = sd(value, na.rm = TRUE),
            ci95 = qnorm(0.975) * sd(value, na.rm = TRUE) / sqrt( sum(!is.na(value)) )) %>%  #denominator removes NA values from count
  mutate(model = "Tie break only (default)")

cascade_sum_threshadjust <- read.csv(fit_cascade_path_threshadjust, header = TRUE) %>% 
  gather(metric, value, -trial, -gamma) %>% 
  mutate(trial = factor(trial, levels = c("pre", "post"))) %>% 
  group_by(trial, gamma, metric) %>% 
  summarise(mean = mean(value, na.rm = TRUE),
            sd = sd(value, na.rm = TRUE),
            ci95 = qnorm(0.975) * sd(value, na.rm = TRUE) / sqrt( sum(!is.na(value)) )) %>%  #denominator removes NA values from count
  mutate(model = "Tie break +\nthreshold adjustment")

cascade_sum <- rbind(cascade_sum_normal, cascade_sum_threshadjust)
rm(cascade_sum_normal, cascade_sum_threshadjust)

# Summarize behavior data by gamma, bind together
behav_sum_normal <- read.csv(fit_behavior_path_normal, header = TRUE) %>% 
  gather(metric, value, -trial, -gamma) %>% 
  mutate(trial = factor(trial, levels = c("pre", "post"))) %>% 
  group_by(trial, gamma, metric) %>% 
  summarise(mean = mean(value, na.rm = TRUE),
            sd = sd(value, na.rm = TRUE),
            ci95 = qnorm(0.975) * sd(value, na.rm = TRUE) / sqrt( sum(!is.na(value)) )) %>%  #denominator removes NA values from count
  mutate(model = "Tie break only (default)")

behav_sum_threshadjust <- read.csv(fit_behavior_path_threshadjust, header = TRUE) %>% 
  gather(metric, value, -trial, -gamma) %>% 
  mutate(trial = factor(trial, levels = c("pre", "post"))) %>% 
  group_by(trial, gamma, metric) %>% 
  summarise(mean = mean(value, na.rm = TRUE),
            sd = sd(value, na.rm = TRUE),
            ci95 = qnorm(0.975) * sd(value, na.rm = TRUE) / sqrt( sum(!is.na(value)) )) %>%  #denominator removes NA values from count
  mutate(model = "Tie break +\nthreshold adjustment")

behav_sum <- rbind(behav_sum_normal, behav_sum_threshadjust)
rm(behav_sum_normal, behav_sum_threshadjust)


####################
# Plot: Avg.cascade size 
####################
# Filter
avgsize <- cascade_sum %>% 
  filter(metric == "avg_cascade_size",
         gamma == -1)

# Plot
gg_size <- ggplot(avgsize, aes(x = trial, y = mean, color = model, group = model)) +
  geom_line(size = 0.3, alpha = 0.8) +
  geom_point(size = 0.8) +
  scale_color_manual(name = "Response to\nincorrect cascade",
                     values = models_pal) +  
  scale_x_discrete(labels = c("Initial network", "Final network")) +
  scale_y_continuous(breaks = seq(0, 6, 1), limits = c(0, 6), expand = c(0, 0)) +
  ylab("Avg. cascade size") +
  theme_ctokita() +
  theme(axis.title.x = element_blank())
gg_size #show plot before saving


####################
# Plot: Avg.cascade bias 
####################
# Filter
bias <- cascade_sum %>% 
  filter(metric == "cascade_bias",
         gamma == -1)

# Plot
gg_bias <- ggplot(bias, aes(x = trial, y = mean, color = model, group = model)) +
  geom_line(size = 0.3, alpha = 0.8) +
  geom_point(size = 0.8) +
  scale_color_manual(name = "Response to\nincorrect cascade",
                     values = models_pal) + 
  scale_x_discrete(labels = c("Initial network", "Final network")) +
  scale_y_continuous(breaks = seq(0, 1, 0.1), limits = c(0, 0.8), expand = c(0, 0)) +
  ylab("Cascade bias") +
  theme_ctokita() +
  theme(axis.title.x = element_blank())
gg_bias #show plot before saving


####################
# Plot: Avg.cascade bias 
####################
# Filter
behavrates <- behav_sum %>% 
  filter(metric %in% c("true_positive", "true_negative", "false_positive", "false_negative"),
         gamma == -1) %>% 
  mutate(metric = factor(metric, levels = c("true_positive", "false_positive", "false_negative", "true_negative"))) %>% 
  mutate(news = NA, 
         reaction = NA)
levels(behavrates$metric) <- c("True positive", "False positive", "False negative", "True negative")

# Plot
gg_behavrates <- ggplot(behavrates, aes(x = trial, y = mean, color = model, group = model)) +
  geom_line(size = 0.3, alpha = 0.8) +
  geom_point(size = 0.8) +
  scale_color_manual(name = "Response to\nincorrect cascade",
                     values = models_pal) + 
  scale_x_discrete(labels = c("Initial\nnetwork", "Final\nnetwork")) +
  ylab("Behavior frequency") +
  theme_ctokita() +
  theme(axis.line = element_line(),
        axis.title.x = element_blank(),
        # legend.position = "none",
        strip.text = element_text(face = "bold")) +
  facet_wrap(~metric, scales = "free")

gg_behavrates #show plot before saving
ggsave(plot = gg_behavrates, filename = paste0(out_path, "behaviorrates_by_tie_formation", plot_tag, ".pdf"), width = 120, height = 70, units = "mm", dpi = 600)

