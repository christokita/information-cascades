########################################
# Created on Tue Oct 27 13:47:00 2020
# @author: ChrisTokita
#
# SCRIPT
# Plot and analyze the pattern of same- and opposite- ideology tie breaks
########################################

####################
# Load pacakges and data
####################
library(ggplot2)
library(dplyr)
library(tidyr)
library(Bolstad)
library(RColorBrewer)
source("_plot_themes/theme_ctokita.R")

# High-level data directory
data_directory <- "/Volumes/CKT-DATA/information-cascades/observational/" #path to external HD

# File paths
tiechange_file <- paste0(data_directory, 'data_derived/monitored_users/changed_ties.csv')
user_file <- paste0(data_directory, 'data_derived/monitored_users/monitored_users_final.csv')
follower_ideology_file <- paste0(data_directory, 'data_derived/monitored_users/follower_ideology_samples.csv')
outpath_tiebreaks <- "observational/output/tie_breaks/"
outpath_ideology <- "observational/output/ideology/"

# Parameters for plots
plot_color <- "#1B3B6F"
ideol_pal <- c("#006195", "#d9d9d9", "#d54c54")
info_corr_pal <- brewer.pal(5, "PuOr")[c(1, 5)]

# Load data
monitored_users <- read.csv(user_file) %>% 
  mutate(user_id = gsub("\"", "", user_id_str))

follower_ideologies <- read.csv(follower_ideology_file) %>% 
  mutate(user_id = gsub("\"", "", user_id_str),
         follower_id = gsub("\"", "", follower_id_str))

tie_changes <- read.csv(tiechange_file) %>% 
  mutate(user_id = gsub("\"", "", user_id_str),
         follower_id = gsub("\"", "", follower_id_str))


####################
# Prep data: calculate baseline initial frequency of same and opposite ideology followers, tiebreaks
####################
# Calculate mix of liberal and conservative followers per user
ideology_mix <- follower_ideologies %>% 
  group_by(user_id) %>% 
  summarise(n_follower_samples = length(ideology_corresp),
            n_follower_liberal = sum(ideology_corresp < 0),
            n_follower_conservative = sum(ideology_corresp > 0)) %>% 
  mutate(followers_freq_liberal = n_follower_liberal / n_follower_samples,
         followers_freq_conservative = n_follower_conservative / n_follower_samples,
         followers_ideology = (n_follower_conservative - n_follower_liberal) / n_follower_samples)

# Calculate freq of breaks by ideology
tie_change_summary <- tie_changes %>%
  filter(tie_change == "broken",
         !is.na(ideology_corresp)) %>% 
  group_by(user_id) %>% 
  summarise(n_tiebreaks = length(ideology_corresp),
            n_tiebreak_liberal = sum(ideology_corresp < 0),
            n_tiebreak_conservative = sum(ideology_corresp > 0)) %>% 
  mutate(tiebreak_freq_liberal = n_tiebreak_liberal / n_tiebreaks,
         tiebreak_freq_conservative = n_tiebreak_conservative / n_tiebreaks)

# Add information to users
user_data <- merge(monitored_users, ideology_mix) %>% 
  merge(tie_change_summary, all.x = TRUE) %>% 
  mutate(info_correlation = ifelse(news_source %in% c("cbsnews", "usatoday"), "High correlation", "Low correlation")) %>% 
  mutate(info_correlation = factor(info_correlation, levels = c("Low correlation", "High correlation"))) %>% 
  mutate(followers_freq_same = NA,
         followers_freq_diff = NA,
         tiebreak_freq_same = NA,
         tiebreak_freq_diff = NA,
         tiebreak_n_same = NA,
         tiebreak_n_diff = NA)
user_data$n_tiebreaks[is.na(user_data$n_tiebreaks)] <- 0
  
# Calculate same vs. opposite ideology freq of followers, tie breaks
liberal_users <- user_data$ideology_corresp < 0
conservative_users <- user_data$ideology_corresp > 0

user_data$followers_freq_same[liberal_users] <- user_data$followers_freq_liberal[liberal_users]
user_data$followers_freq_diff[liberal_users] <- user_data$followers_freq_conservative[liberal_users]
user_data$followers_freq_same[conservative_users] <- user_data$followers_freq_conservative[conservative_users]
user_data$followers_freq_diff[conservative_users] <- user_data$followers_freq_liberal[conservative_users]

user_data$tiebreak_freq_same[liberal_users] <- user_data$tiebreak_freq_liberal[liberal_users]
user_data$tiebreak_freq_diff[liberal_users] <- user_data$tiebreak_freq_conservative[liberal_users]
user_data$tiebreak_freq_same[conservative_users] <- user_data$tiebreak_freq_conservative[conservative_users]
user_data$tiebreak_freq_diff[conservative_users] <- user_data$tiebreak_freq_liberal[conservative_users]

user_data$tiebreak_n_same[liberal_users] <- user_data$n_tiebreak_liberal[liberal_users]
user_data$tiebreak_n_diff[liberal_users] <- user_data$n_tiebreak_conservative[liberal_users]
user_data$tiebreak_n_same[conservative_users] <- user_data$n_tiebreak_conservative[conservative_users]
user_data$tiebreak_n_diff[conservative_users] <- user_data$n_tiebreak_liberal[conservative_users]
 

####################
# Prep data: calcualte expected frequency of diff ideology tie breaks (same ideology breaks will be mirror image)
#################### 
user_data <- user_data %>% 
  mutate(expected_tiebreak_diff = followers_freq_diff * n_tiebreaks) %>% 
  mutate(delta_n_tiebreak_diff = tiebreak_n_diff - expected_tiebreak_diff,
         perc_diff_breaks_above_expected = (tiebreak_n_diff - expected_tiebreak_diff) / expected_tiebreak_diff,
         delta_freq_tiebreak_diff = tiebreak_freq_diff - followers_freq_diff) %>% 
  # Filter out individuals that didn't show any breaks
  filter(n_tiebreaks > 0)


####################
# Plot: preliminary summary plots
####################
# Follower ideology distribution
gg_follower_dist <- ggplot(follower_ideologies, aes(x = ideology_corresp, fill = ..x..)) +
  geom_histogram(bins = 30) +
  scale_fill_gradientn(colors = ideol_pal, limits = c(-2, 2), oob = scales::squish) +
  xlab("Follower ideology") +
  ylab("Count") +
  theme_ctokita() +
  theme(legend.position = "none",
        aspect.ratio = 0.5)
gg_follower_dist
ggsave(gg_follower_dist, filename = paste0(outpath_ideology, "follower_ideology.pdf"), width = 90, height = 45, units = "mm", dpi = 400)

# Comparison of user ideology vs ideological composition of followers
gg_follower_ideol <- ggplot(user_data, aes(x = ideology_corresp, y = followers_freq_conservative, color = ideology_corresp)) +
  geom_point(size = 0.9, stroke = 0, alpha = 0.7) +
  scale_color_gradientn(colors = ideol_pal, limits = c(-2, 2), oob = scales::squish) +
  xlab("User ideology") +
  ylab("Freq. conservative followers") +
  theme_ctokita() +
  theme(legend.position = "none") 
gg_follower_ideol
ggsave(gg_follower_ideol, filename = paste0(outpath_ideology, "user_vs_follower_ideology.pdf"), width = 45, height = 45, units = "mm", dpi = 400)

# Comparison of user ideology vs relative ideological composition of followers
gg_follower_same <- ggplot(user_data, aes(x = ideology_corresp, y = followers_freq_same, color = ideology_corresp)) +
  geom_point(size = 0.9, stroke = 0, alpha = 0.7) +
  scale_color_gradientn(colors = ideol_pal, limits = c(-2, 2), oob = scales::squish) +
  theme_ctokita() +
  theme(legend.position = "none") +
  xlab("User ideology") +
  ylab("Freq. followers same ideology")
gg_follower_same
ggsave(gg_follower_same, filename = paste0(outpath_ideology, "follower_same_ideology.pdf"), width = 45, height = 45, units = "mm", dpi = 400)


####################
# Plot: Opposite-ideology unfollows (tie breaks) by information corelation
####################
# Raw plot between expected number of opposite ideology follower tie breaks vs actual number
gg_opposite_breaks_raw <- ggplot(user_data, aes(x = info_correlation, y = delta_freq_tiebreak_diff, color = info_correlation)) +
  geom_hline(yintercept = 0, linetype = "dotted", size = 0.3) +
  geom_point(size = 0.9, stroke = 0, alpha = 0.5, position = position_jitter(width = 0.05, height = 0.05)) +
  scale_y_continuous(limits = c(-1, 1)) +
  scale_color_manual(values = info_corr_pal) +
  theme_ctokita() +
  theme(legend.position = "none") +
  xlab("Information ecosystem") +
  ylab("Diff. ideology unfollows relative to expected")
gg_opposite_breaks_raw
ggsave(gg_opposite_breaks_raw, filename = paste0(outpath_tiebreaks, "breaks_above_expected_infocorr_raw.pdf"), width = 90, height = 90, units = "mm", dpi = 400)

# Estimate mean using bayesian inference
low_corr_estimate <- Bolstad::normnp(x = user_data$delta_n_tiebreak_diff[user_data$info_correlation == "Low correlation"],
                                     m.x = 0, s.x = 1, quiet = TRUE, plot = FALSE)
high_corr_estimate <- Bolstad::normnp(x = user_data$delta_n_tiebreak_diff[user_data$info_correlation == "High correlation"],
                                      m.x = 0, s.x = 1, quiet = TRUE, plot = FALSE)
info_correlation_estimates <- data.frame(info_correlation = factor(c("Low corr.", "High corr."), levels = c("Low corr.", "High corr.")), 
                                         delta_n_tiebreak_diff = c(low_corr_estimate$mean, high_corr_estimate$mean),
                                         ci_80_low = c(low_corr_estimate$quantileFun(0.1), high_corr_estimate$quantileFun(0.1)),
                                         ci_80_high = c(low_corr_estimate$quantileFun(0.9), high_corr_estimate$quantileFun(0.9)),
                                         ci_95_low = c(low_corr_estimate$quantileFun(0.01), high_corr_estimate$quantileFun(0.01)),
                                         ci_95_high = c(low_corr_estimate$quantileFun(0.99), high_corr_estimate$quantileFun(0.99)))

# Plot estimates of mean number of breaks above/below expected number of breaks
gg_opposite_breaks <- ggplot(info_correlation_estimates, aes(x = info_correlation, color = info_correlation)) +
  geom_hline(yintercept = 0, linetype = "dotted", size = 0.3) +
  geom_errorbar(aes(ymin = ci_95_low, ymax = ci_95_high), width = 0, size = 0.3) +
  geom_errorbar(aes(ymin = ci_80_low, ymax = ci_80_high), width = 0, size = 0.8) +
  geom_point(aes(y = delta_n_tiebreak_diff), size = 2) + 
  scale_color_manual(values = info_corr_pal) +
  xlab("Information ecosystem") +
  ylab("Diff. ideology unfollows\nrelative to expected") +
  theme_ctokita() +
  theme(legend.position = "none")
gg_opposite_breaks
ggsave(gg_opposite_breaks, filename = paste0(outpath_tiebreaks, "breaks_above_expected_infocorr.pdf"), width = 50, height = 45, units = "mm")

test  <- user_data %>% 
  group_by(info_correlation) %>% 
  filter(perc_diff_breaks_above_expected < 1000) %>% 
  summarise(delta_n_tiebreak_diff = mean(delta_n_tiebreak_diff, na.rm = T),
            perc_diff_breaks_above_expected = mean(perc_diff_breaks_above_expected, na.rm = T),
            delta_freq_tiebreak_diff = mean(delta_freq_tiebreak_diff, na.rm = T))

