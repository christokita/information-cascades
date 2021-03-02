########################################
# Created on Thur Jan 28 12:22:00 2021
# @author: ChrisTokita
#
# SCRIPT
# Plot tie break and network data from experiments
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
data_directory <- "/Volumes/CKT-DATA/information-cascades/experimental/" #path to external HD

# Files
path_to_followerchange_data <- paste0(data_directory, 'data_derived/follower_change_data.csv')
path_to_friendchange_data <- paste0(data_directory, 'data_derived/friend_change_data.csv')
dir_brms_fits_EXP <- paste0(data_directory, "data_derived/brms_fits/") #bayesian fits for experimental data
dir_brms_fits_OBS <- "/Volumes/CKT-DATA/information-cascades/observational/data_derived/_analysis/brms_fits/" #bayesian fits for observational data
outpath_experiments <- "experimental/output/"

# Parameters for plots
plot_color <- "#1B3B6F"
ideol_pal <- c("#006195", "#d9d9d9", "#d54c54")
news_pal <- c("#006195", "#829bb7", "#df9694", "#d54c54")
info_corr_pal <- brewer.pal(5, "PuOr")[c(1, 5)]

# Load data
follower_change_data <- read.csv(path_to_followerchange_data, colClasses = c("user_id" = "character"))
friend_change_data <- read.csv(path_to_friendchange_data, colClasses = c("user_id" = "character"))


####################
# Compute bayesian group mean estimation of change in FOLLOWERS
####################

########## Analysis ##########

# Naive prior
file_fit_followerchange <- paste0(dir_brms_fits_EXP, "infoeco_followerchange.rds")
if (file.exists(file_fit_followerchange)) {
  blm_follower_change <- readRDS(file_fit_followerchange)
} else {
  prior <- c(set_prior("normal(0, 0.3)", class = "b")) #population mean = 0.0156, sd = 0.3195
  blm_follower_change <- brm(bf(delta_tiebreak_diff ~ 0 + info_ecosystem), 
                        data = follower_change_data,
                        prior = prior, 
                        family = gaussian(),
                        sample_prior = TRUE,
                        warmup = 5000, 
                        chains = 4, 
                        iter = 15000)
  saveRDS(blm_follower_change, file = file_fit_followerchange)
}

# Hypothesis test that each group's mean is different than zero
hypothesis(blm_follower_change, "info_ecosystemlow_correlation > 0") #prob = 0.91, BF = 10.49
hypothesis(blm_follower_change, "info_ecosystemhigh_correlation > 0") #prob = 0.84, BF = 5.19

# Hypothesis test that low corr info ecosystem > high corr info ecosystem
hypothesis(blm_follower_change, "info_ecosystemlow_correlation > info_ecosystemhigh_correlation") #prob = 0.64, BF = 1.8


########## Plotting ##########

# Prep posterior data
posterior_follower_change <- posterior_samples(blm_follower_change) %>% 
  select(b_info_ecosystemhigh_correlation, b_info_ecosystemlow_correlation) %>% 
  gather("info_ecosystem", "posterior_sample") %>% 
  mutate(info_ecosystem = gsub("b_info_ecosystem", "", info_ecosystem),
         info_ecosystem = gsub("low_correlation", "Low\ncorrelation", info_ecosystem),
         info_ecosystem = gsub("high_correlation", "High\ncorrelation", info_ecosystem)) %>% 
  mutate(info_ecosystem = factor(info_ecosystem, levels = c("Low\ncorrelation", "High\ncorrelation")))
  
# Point estimate
estimate_follower_change <- as.data.frame( posterior_summary(blm_follower_change, 
                                                            probs = c(0.05, 0.95), #90% interval
                                                            pars = c("b_info_ecosystemhigh_correlation", "b_info_ecosystemlow_correlation")) ) %>% 
  tibble::rownames_to_column() %>% 
  rename(info_ecosystem = rowname) %>% 
  mutate(info_ecosystem = gsub("b_info_ecosystem", "", info_ecosystem),
         info_ecosystem = gsub("low_correlation", "Low\ncorrelation", info_ecosystem),
         info_ecosystem = gsub("high_correlation", "High\ncorrelation", info_ecosystem)) %>% 
  mutate(info_ecosystem = factor(info_ecosystem, levels = c("Low\ncorrelation", "High\ncorrelation")))

# Merge in HDI-based CI for point estimates
estimate_follower_change <- posterior_samples(blm_follower_change) %>% 
  select(b_info_ecosystemhigh_correlation, b_info_ecosystemlow_correlation) %>% 
  bayestestR::hdi(., ci = 0.9) %>% 
  as.data.frame() %>% 
  rename(info_ecosystem = Parameter) %>% 
  mutate(info_ecosystem = gsub("b_info_ecosystem", "", info_ecosystem),
         info_ecosystem = gsub("low_correlation", "Low\ncorrelation", info_ecosystem),
         info_ecosystem = gsub("high_correlation", "High\ncorrelation", info_ecosystem)) %>% 
  merge(estimate_follower_change, ., by = "info_ecosystem")

# Plot
gg_follower_change <- ggplot(estimate_follower_change, aes(x = info_ecosystem, color = info_ecosystem)) +
  geom_hline(yintercept = 0, linetype = "dotted", size = 0.3) +
  geom_violin(data = posterior_follower_change, 
              aes(y = posterior_sample, fill = info_ecosystem),
              color = NA, alpha = 0.15, width = 0.4) +
  geom_errorbar(aes(ymin = CI_low, ymax = CI_high), 
                width = 0, 
                size = 0.5) +
  geom_point(aes(y = Estimate), 
             size = 2) + 
  scale_y_continuous(breaks = round(seq(-0.30, 0.30, 0.05), 2), #cuts off edge breaks due to weird float calcualtion of sequence
                     limits = c(-0.1, 0.2), #this cuts off very, very ends of posterior but makes plot more legible
                     expand = c(0, 0)) +
  scale_color_manual(values = info_corr_pal) +
  scale_fill_manual(values = info_corr_pal) +
  xlab("Information ecosystem") +
  ylab("Relative freq.of lost \ncross-ideology followers") +
  theme_ctokita() +
  theme(legend.position = "none",
        axis.text.x = element_text(size = 5))
gg_follower_change
ggsave(gg_follower_change, filename = paste0(outpath_experiments, "follower_change.pdf"), width = 45, height = 45, units = "mm")


####################
# Compute bayesian group mean estimation of change in FRIENDS
####################

########## Analysis ##########

# Naive prior
file_fit_friendchange <- paste0(dir_brms_fits_EXP, "infoeco_friendchange.rds")
if (file.exists(file_fit_friendchange)) {
  blm_friend_change <- readRDS(file_fit_friendchange)
} else {
  prior <- c(set_prior("normal(0, 0.3)", class = "b")) #population mean = 0.0156, sd = 0.3195
  blm_friend_change <- brm(bf(delta_tiebreak_diff ~ 0 + info_ecosystem), 
                             data = friend_change_data,
                             prior = prior, 
                             family = gaussian(),
                             sample_prior = TRUE,
                             warmup = 5000, 
                             chains = 4, 
                             iter = 15000)
  saveRDS(blm_friend_change, file = file_fit_friendchange)
}

# Hypothesis test that each group's mean is different than zero
hypothesis(blm_friend_change, "info_ecosystemlow_correlation > 0") #prob = 0.63, BF = 1.72
hypothesis(blm_friend_change, "info_ecosystemhigh_correlation < 0") #prob = 0.79, BF = 3.84 (negative mean so test less than zero)

# Hypothesis test that low corr info ecosystem > high corr info ecosystem
hypothesis(blm_friend_change, "info_ecosystemlow_correlation > info_ecosystemhigh_correlation") #prob = 0.79, BF = 3.68


########## Plotting ##########

# Prep posterior data
posterior_friend_change <- posterior_samples(blm_friend_change) %>% 
  select(b_info_ecosystemhigh_correlation, b_info_ecosystemlow_correlation) %>% 
  gather("info_ecosystem", "posterior_sample") %>% 
  mutate(info_ecosystem = gsub("b_info_ecosystem", "", info_ecosystem),
         info_ecosystem = gsub("low_correlation", "Low\ncorrelation", info_ecosystem),
         info_ecosystem = gsub("high_correlation", "High\ncorrelation", info_ecosystem)) %>% 
  mutate(info_ecosystem = factor(info_ecosystem, levels = c("Low\ncorrelation", "High\ncorrelation")))

# Point estimate
estimate_friend_change <- as.data.frame( posterior_summary(blm_friend_change, 
                                                             probs = c(0.05, 0.95), #90% interval
                                                             pars = c("b_info_ecosystemhigh_correlation", "b_info_ecosystemlow_correlation")) ) %>% 
  tibble::rownames_to_column() %>% 
  rename(info_ecosystem = rowname) %>% 
  mutate(info_ecosystem = gsub("b_info_ecosystem", "", info_ecosystem),
         info_ecosystem = gsub("low_correlation", "Low\ncorrelation", info_ecosystem),
         info_ecosystem = gsub("high_correlation", "High\ncorrelation", info_ecosystem)) %>% 
  mutate(info_ecosystem = factor(info_ecosystem, levels = c("Low\ncorrelation", "High\ncorrelation")))

# Merge in HDI-based CI for point estimates
estimate_friend_change <- posterior_samples(blm_friend_change) %>% 
  select(b_info_ecosystemhigh_correlation, b_info_ecosystemlow_correlation) %>% 
  bayestestR::hdi(., ci = 0.9) %>% 
  as.data.frame() %>% 
  rename(info_ecosystem = Parameter) %>% 
  mutate(info_ecosystem = gsub("b_info_ecosystem", "", info_ecosystem),
         info_ecosystem = gsub("low_correlation", "Low\ncorrelation", info_ecosystem),
         info_ecosystem = gsub("high_correlation", "High\ncorrelation", info_ecosystem)) %>% 
  merge(estimate_friend_change, ., by = "info_ecosystem")

# Plot
gg_friend_change <- ggplot(estimate_friend_change, aes(x = info_ecosystem, color = info_ecosystem)) +
  geom_hline(yintercept = 0, linetype = "dotted", size = 0.3) +
  geom_violin(data = posterior_friend_change, 
              aes(y = posterior_sample, fill = info_ecosystem),
              color = NA, alpha = 0.15, width = 0.4) +
  geom_errorbar(aes(ymin = CI_low, ymax = CI_high), 
                width = 0, 
                size = 0.5) +
  geom_point(aes(y = Estimate), 
             size = 2) + 
  scale_y_continuous(breaks = round(seq(-0.30, 0.30, 0.05), 2), #cuts off edge breaks due to weird float calcualtion of sequence
                     limits = c(-0.15, 0.15), #this cuts off very, very ends of posterior but makes plot more legible
                     expand = c(0, 0)) +
  scale_color_manual(values = info_corr_pal) +
  scale_fill_manual(values = info_corr_pal) +
  xlab("Information ecosystem") +
  ylab("Relative freq.of lost \ncross-ideology friends") +
  theme_ctokita() +
  theme(legend.position = "none",
        axis.text.x = element_text(size = 5))
gg_friend_change
ggsave(gg_friend_change, filename = paste0(outpath_experiments, "friend_change.pdf"), width = 45, height = 45, units = "mm")

