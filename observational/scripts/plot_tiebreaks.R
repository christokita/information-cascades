########################################
# Created on Tue Oct 27 13:47:00 2020
# @author: ChrisTokita
#
# SCRIPT
# Plot pattern of same- and opposite- ideology tie breaks
# Note: The analyze_tiebreaks.R script must be first to generate the compiled data and bayesian model fits.
########################################

####################
# Load pacakges and data
####################
library(ggplot2)
library(RColorBrewer)
library(dplyr)
library(tidyr)
library(brms)
library(bayestestR)
source("_plot_themes/theme_ctokita.R")

# High-level data directory
data_directory <- "/Volumes/CKT-DATA/information-cascades/observational/" #path to external HD

# File paths
compiled_data_file <- paste0(data_directory, "data_derived/_analysis/tiebreak_data.Rdata") #compiled tiebreak data set
dir_brms_fits <- paste0(data_directory, "data_derived/_analysis/", "brms_fits/") #save our brms fits
outpath_tiebreaks <- "observational/output/tie_breaks/"
outpath_ideology <- "observational/output/ideology/"

# Parameters for plots
plot_color <- "#1B3B6F"
ideol_pal <- c("#006195", "#d9d9d9", "#d54c54")
news_pal <- c("#006195", "#829bb7", "#df9694", "#d54c54")
info_corr_pal <- brewer.pal(5, "PuOr")[c(1, 5)]

# Load data
load(compiled_data_file)


######################### Analysis: Cross-ideology unfollows (tie breaks) by INFORMATION ECOSYSTEM #########################

####################
# Plot: Histogram of relative FREQUENCY of cross-ideology breaks (relative to expected by random chance)
####################
gg_infoeco_breaks_freq_hist <- tiebreak_data %>% 
  filter(!is.na(delta_tiebreak_freq)) %>% 
  mutate(info_ecosystem = gsub("correlation", "corr.", info_ecosystem),
         info_ecosystem = factor(info_ecosystem, levels = c("High corr.", "Low corr."))) %>% 
  ggplot(., aes(x = delta_tiebreak_freq, fill = info_ecosystem)) +
  geom_vline(xintercept = 0, linetype = "dotted", size = 0.3) +
  geom_histogram(alpha = 0.8, position = "identity", binwidth = 0.1) +
  scale_x_continuous(limits = c(-1, 1),
                     breaks = seq(-1, 1, 0.5)) +
  scale_y_continuous(breaks = seq(0, 400, 200)) +
  scale_fill_manual(values = rev(info_corr_pal)) +
  xlab("Relative frequency\ncross-ideology unfollows") +
  ylab("Count") +
  theme_ctokita() +
  theme(legend.position = "none",
        aspect.ratio = NULL) +
  facet_grid(info_ecosystem~.)
gg_infoeco_breaks_freq_hist
ggsave(gg_infoeco_breaks_freq_hist, filename = paste0(outpath_tiebreaks, "raw_relativefreq_infoeco.pdf"), width = 45, height = 45, units = "mm", dpi = 400)


####################
# Plot: Estimates of relative FREQUENCY of cross-ideology breaks
####################
# Load bayesian estimate
blm_infoeco_freq <- readRDS(paste0(dir_brms_fits, "infoeco_relfreq.rds"))

# Get posterior samples
# posterior_infoeco_freq <- posterior_samples(blm_infoeco_freq) %>% 
#   gather("info_ecosystem", "posterior_sample") %>% 
#   filter(info_ecosystem %in% c("b_info_ecosystemLowcorrelation", "b_info_ecosystemHighcorrelation")) %>% 
#   mutate(info_ecosystem = gsub("b_info_ecosystem", "", info_ecosystem),
#          info_ecosystem = gsub("correlation", "\ncorrelation", info_ecosystem),
#          info_ecosystem = factor(info_ecosystem, levels = c("Low\ncorrelation", "High\ncorrelation")))

# Get point estimates and quantile-based CI
infoeco_freq_estimates <- as.data.frame( posterior_summary(blm_infoeco_freq, 
                                                           probs = c(0.05, 0.95), #90% interval (quantile based)
                                                           pars = c("b_info_ecosystemLowcorrelation", "b_info_ecosystemHighcorrelation")) ) %>%  
  tibble::rownames_to_column() %>% 
  rename(info_ecosystem = rowname) %>% 
  mutate(info_ecosystem = gsub("b_info_ecosystem", "", info_ecosystem),
         info_ecosystem = gsub("correlation", "\ncorrelation", info_ecosystem),
         info_ecosystem = factor(info_ecosystem, levels = c("Low\ncorrelation", "High\ncorrelation")))

# Merge in HDI-based CI
infoeco_freq_estimates <- posterior_samples(blm_infoeco_freq) %>% 
  select(b_info_ecosystemLowcorrelation, b_info_ecosystemHighcorrelation) %>% 
  bayestestR::hdi(., ci = 0.9) %>% 
  as.data.frame() %>% 
  rename(info_ecosystem = Parameter) %>% 
  mutate(info_ecosystem = gsub("b_info_ecosystem", "", info_ecosystem),
         info_ecosystem = gsub("correlation", "\ncorrelation", info_ecosystem),
         info_ecosystem = factor(info_ecosystem, levels = c("Low\ncorrelation", "High\ncorrelation"))) %>% 
  merge(infoeco_freq_estimates, ., by = "info_ecosystem")

# Plot: estimates, 90% CI, and posterior
gg_infoeco_breaks_freq <- ggplot(infoeco_freq_estimates, aes(x = info_ecosystem, color = info_ecosystem)) +
  geom_hline(yintercept = 0, linetype = "dotted", size = 0.3) +
  geom_errorbar(aes(ymin = CI_low, ymax = CI_high), 
                width = 0, 
                size = 0.5) +
  geom_point(aes(y = Estimate), 
             size = 2) + 
  scale_y_continuous(breaks = seq(-0.02, 0.04, 0.02), #cuts off edge breaks due to weird float calcualtion of sequence
                     limits = c(-0.02, 0.04), #this cuts off very, very ends of posterior but makes plot more legible
                     expand = c(0, 0)) +
  scale_color_manual(values = info_corr_pal) +
  scale_fill_manual(values = info_corr_pal) +
  xlab("Information ecosystem") +
  ylab("Relative freq.\ncross-ideology unfollows") +
  theme_ctokita() +
  theme(legend.position = "none",
        axis.text.x = element_text(size = 5))
gg_infoeco_breaks_freq
ggsave(gg_infoeco_breaks_freq, filename = paste0(outpath_tiebreaks, "relativefreq_infoeco.pdf"), width = 45, height = 45, units = "mm")


####################
# Plot: Histogram of relative NUMBER of cross-ideology breaks
####################
gg_infoeco_breaks_n_hist <- tiebreak_data %>% 
  filter(!is.na(delta_tiebreak_freq)) %>% 
  mutate(info_ecosystem = gsub("correlation", "corr.", info_ecosystem),
         info_ecosystem = factor(info_ecosystem, levels = c("High corr.", "Low corr."))) %>% 
  ggplot(., aes(x = delta_tiebreak_n, fill = info_ecosystem)) +
  geom_vline(xintercept = 0, linetype = "dotted", size = 0.3) +
  geom_histogram(alpha = 0.8, position = "identity", binwidth = 0.5) +
  scale_y_continuous(breaks = seq(0, 600, 200),
                     limits = c(0, 600)) +
  scale_fill_manual(values = rev(info_corr_pal)) +
  xlab("Relative number\ncross-ideology unfollows") +
  ylab("Count") +
  theme_ctokita() +
  theme(legend.position = "none",
        aspect.ratio = NULL) +
  facet_grid(info_ecosystem~.)
gg_infoeco_breaks_n_hist
ggsave(gg_infoeco_breaks_n_hist, filename = paste0(outpath_tiebreaks, "raw_relativenumber_infoeco.pdf"), width = 45, height = 45, units = "mm", dpi = 400)



######################### Analysis: Cross-ideology unfollows (tie breaks) by NEWS SOURCE #########################

####################
# Plot: Histogram plot of FREQUENCY of cross-ideology breaks (relative to expected by random chance)
####################
gg_newssource_breaks_freq_hist <- tiebreak_data %>% 
  filter(!is.na(delta_tiebreak_freq)) %>% 
  mutate(news_source = factor(news_source, levels = c("cbsnews", "voxdotcom", "usatoday", "dcexaminer"))) %>% 
  ggplot(., aes(x = delta_tiebreak_freq, fill = news_source)) +
  geom_vline(xintercept = 0, linetype = "dotted", size = 0.3) +
  geom_histogram(alpha = 0.8, position = "identity", binwidth = 0.1) +
  scale_x_continuous(limits = c(-1, 1),
                     breaks = seq(-1, 1, 0.5)) +
  scale_y_continuous(breaks = seq(0, 400, 100)) +
  scale_fill_manual(values = news_pal[c(2, 1, 3, 4)]) +
  xlab("Relative frequency\ncross-ideology unfollows") +
  ylab("Count") +
  theme_ctokita() +
  theme(legend.position = "none",
        aspect.ratio = NULL,
        strip.text = element_text(size = 5)) +
  facet_wrap(news_source~., 
             ncol = 2, 
             dir = "v", 
             strip.position = "right")
gg_newssource_breaks_freq_hist
ggsave(gg_newssource_breaks_freq_hist, filename = paste0(outpath_tiebreaks, "raw_relativefreq_newssource.pdf"), width = 90, height = 45, units = "mm", dpi = 400)


####################
# Bayesian estimate  of relative FREQUENCY of cross-ideology tie breaks
####################
# Load bayesian estimate
blm_newssource_freq <- readRDS(paste0(dir_brms_fits, "newssource_relfreq.rds"))

# # Get posterior samples
# posterior_newssource_freq <- posterior_samples(blm_newssource_freq) %>% 
#   gather("news_source", "posterior_sample") %>% 
#   filter(news_source %in% c("b_news_sourcevoxdotcom", "b_news_sourcecbsnews", "b_news_sourceusatoday", "b_news_sourcedcexaminer")) %>% 
#   mutate(news_source = gsub("b_news_source", "", news_source),
#          info_ecosystem = ifelse(news_source %in% c("cbsnews", "usatoday"), "High\ncorrelation", "Low\ncorrelation"),
#          info_ecosystem = factor(info_ecosystem, levels = c("Low\ncorrelation", "High\ncorrelation")),
#          ideology = ifelse(news_source %in% c("cbsnews", "voxdotcom"), "Liberal", "Conservative"),
#          ideology = factor(ideology, levels = c("Liberal", "Conservative")))

# Get point estimates
newssource_freq_estimates <- as.data.frame( posterior_summary(blm_newssource_freq, 
                                                             probs = c(0.05, 0.95), #90% interval
                                                             pars =  c("b_news_sourcevoxdotcom", "b_news_sourcecbsnews", "b_news_sourceusatoday", "b_news_sourcedcexaminer")) ) %>%  
  tibble::rownames_to_column() %>% 
  rename(news_source = rowname) %>% 
  mutate(news_source = gsub("b_news_source", "", news_source),
         info_ecosystem = ifelse(news_source %in% c("cbsnews", "usatoday"), "High\ncorrelation", "Low\ncorrelation"),
         info_ecosystem = factor(info_ecosystem, levels = c("Low\ncorrelation", "High\ncorrelation")),
         ideology = ifelse(news_source %in% c("cbsnews", "voxdotcom"), "Liberal", "Conservative"),
         ideology = factor(ideology, levels = c("Liberal", "Conservative")))

# Merge in HDI-based CI
newssource_freq_estimates <- posterior_samples(blm_newssource_freq) %>% 
  select(b_news_sourcevoxdotcom, b_news_sourcecbsnews, b_news_sourceusatoday, b_news_sourcedcexaminer) %>% 
  bayestestR::hdi(., ci = 0.9) %>% 
  as.data.frame() %>% 
  rename(news_source = Parameter) %>% 
  mutate(news_source = gsub("b_news_source", "", news_source)) %>% 
  merge(newssource_freq_estimates, ., by = "news_source")

# Plot estimates
dodge_width <- 0.35
gg_newssource_breaks_freq <- ggplot(newssource_freq_estimates, aes(x = info_ecosystem, color = ideology)) +
  geom_hline(yintercept = 0, linetype = "dotted", size = 0.3) +
  geom_errorbar(aes(ymin = CI_low, ymax = CI_high), 
                position = position_dodge(dodge_width),
                width = 0, 
                size = 0.5) +
  geom_point(aes(y = Estimate), 
             position = position_dodge(dodge_width),
             size = 2) + 
  scale_y_continuous(limits = c(-0.03, 0.06),
                     breaks = seq(-0.03, 0.06, 0.03),
                     expand = c(0, 0)) +
  scale_color_manual(values = ideol_pal[c(1, 3)]) +
  scale_fill_manual(values = ideol_pal[c(1, 3)]) +
  xlab("Information ecosystem") +
  ylab("Relative freq.\ncross-ideology unfollows") +
  theme_ctokita() +
  theme(legend.position = "none",
        axis.text.x = element_text(size = 5))
gg_newssource_breaks_freq
ggsave(gg_newssource_breaks_freq, filename = paste0(outpath_tiebreaks, "relativefreq_newssource.pdf"), width = 45, height = 45, units = "mm")


####################
# Plot: Histogram plot of NUMBER of cross-ideology breaks
####################
gg_newssource_breaks_n_hist <- tiebreak_data %>% 
  filter(!is.na(delta_tiebreak_freq)) %>% 
  mutate(news_source = factor(news_source, levels = c("cbsnews", "voxdotcom", "usatoday", "dcexaminer"))) %>% 
  ggplot(., aes(x = delta_tiebreak_n, fill = news_source)) +
  geom_vline(xintercept = 0, linetype = "dotted", size = 0.3) +
  geom_histogram(alpha = 0.8, position = "identity", binwidth = 0.5) +
  scale_y_continuous(breaks = seq(0, 400, 100)) +
  scale_fill_manual(values = news_pal[c(2, 1, 3, 4)]) +
  xlab("Relative frequency\ncross-ideology unfollows") +
  ylab("Count") +
  theme_ctokita() +
  theme(legend.position = "none",
        aspect.ratio = NULL,
        strip.text = element_text(size = 5)) +
  facet_wrap(news_source~., 
             ncol = 2, 
             dir = "v", 
             strip.position = "right")
gg_newssource_breaks_n_hist
ggsave(gg_newssource_breaks_n_hist, filename = paste0(outpath_tiebreaks, "raw_relativenumber_newssource.pdf"), width = 90, height = 45, units = "mm", dpi = 400)



