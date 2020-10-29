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
news_pal <- c("#006195", "#829bb7", "#df9694", "#d54c54")
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
            follower_liberal_n = sum(ideology_corresp < 0), #count liberals
            follower_conservative_n = sum(ideology_corresp > 0)) %>% #count conservatives
  mutate(followers_liberal_freq = follower_liberal_n / n_follower_samples,
         followers_conservative_freq = follower_conservative_n / n_follower_samples,
         followers_ideology = (follower_conservative_n - follower_liberal_n) / n_follower_samples)

# Calculate freq of breaks by ideology
tie_change_summary <- tie_changes %>%
  filter(tie_change == "broken",
         !is.na(ideology_corresp)) %>% 
  group_by(user_id) %>% 
  summarise(n_tiebreaks = length(ideology_corresp),
            tiebreak_liberal_n = sum(ideology_corresp < 0),
            tiebreak_conservative_n = sum(ideology_corresp > 0)) %>% 
  mutate(tiebreak_liberal_freq = tiebreak_liberal_n / n_tiebreaks,
         tiebreak_conservative_freq = tiebreak_conservative_n / n_tiebreaks)

# Add information to users
user_data <- merge(monitored_users, ideology_mix) %>% 
  merge(tie_change_summary, all.x = TRUE) %>% 
  #make news outlet and information ecosystem factors for plotting purposes
  mutate(info_ecosystem = ifelse(news_source %in% c("cbsnews", "usatoday"), "High correlation", "Low correlation")) %>% 
  mutate(info_ecosystem = factor(info_ecosystem, levels = c("Low correlation", "High correlation"))) %>% 
  mutate(news_source = factor(news_source, levels = c("voxdotcom", "cbsnews", "usatoday", "dcexaminer"))) %>% 
  #create columns for classification of data by same/diff ideology
  mutate(followers_diffideol_freq = NA,
         followers_sameideol_freq = NA,
         tiebreak_diffideol_freq = NA,
         tiebreak_diffideol_n = NA)
user_data$n_tiebreaks[is.na(user_data$n_tiebreaks)] <- 0
  
# Calculate same vs. opposite ideology freq of followers, tie breaks
liberal_users <- user_data$ideology_corresp < 0
conservative_users <- user_data$ideology_corresp > 0

user_data$followers_diffideol_freq[liberal_users] <- user_data$followers_conservative_freq[liberal_users]
user_data$followers_sameideol_freq[liberal_users] <- user_data$followers_liberal_freq[liberal_users]
user_data$followers_diffideol_freq[conservative_users] <- user_data$followers_liberal_freq[conservative_users]
user_data$followers_sameideol_freq[conservative_users] <- user_data$followers_conservative_freq[conservative_users]

user_data$tiebreak_diffideol_freq[liberal_users] <- user_data$tiebreak_conservative_freq[liberal_users]
user_data$tiebreak_diffideol_freq[conservative_users] <- user_data$tiebreak_liberal_freq[conservative_users]

user_data$tiebreak_diffideol_n[liberal_users] <- user_data$tiebreak_conservative_n[liberal_users]
user_data$tiebreak_diffideol_n[conservative_users] <- user_data$tiebreak_liberal_n[conservative_users]
 

####################
# Prep data: calcualte expected frequency of diff ideology tie breaks (same ideology breaks will be mirror image)
#################### 
user_data <- user_data %>% 
  mutate(tiebreak_diffideol_expected = followers_diffideol_freq * n_tiebreaks) %>% 
  mutate(delta_tiebreak_n = tiebreak_diffideol_n - tiebreak_diffideol_expected,
         delta_tiebreak_freq = tiebreak_diffideol_freq - followers_diffideol_freq) %>% 
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
gg_follower_ideol <- ggplot(user_data, aes(x = ideology_corresp, y = followers_conservative_freq, color = ideology_corresp)) +
  geom_point(size = 0.9, stroke = 0, alpha = 0.7) +
  scale_color_gradientn(colors = ideol_pal, limits = c(-2, 2), oob = scales::squish) +
  xlab("User ideology") +
  ylab("Freq. conservative followers") +
  theme_ctokita() +
  theme(legend.position = "none") 
gg_follower_ideol
ggsave(gg_follower_ideol, filename = paste0(outpath_ideology, "user_vs_follower_ideology.pdf"), width = 45, height = 45, units = "mm", dpi = 400)

# Comparison of user ideology vs relative ideological composition of followers
gg_follower_same <- ggplot(user_data, aes(x = ideology_corresp, y = followers_sameideol_freq, color = ideology_corresp)) +
  geom_point(size = 0.9, stroke = 0, alpha = 0.5) +
  scale_color_gradientn(colors = ideol_pal, limits = c(-2, 2), oob = scales::squish) +
  theme_ctokita() +
  theme(legend.position = "none") +
  xlab("User ideology") +
  ylab("Freq. followers same ideology")
gg_follower_same
ggsave(gg_follower_same, filename = paste0(outpath_ideology, "follower_same_ideology.pdf"), width = 45, height = 45, units = "mm", dpi = 400)

# Same ideology follow composition by news source
ggplot(user_data, aes(x = followers_sameideol_freq)) +
  geom_histogram(fill = plot_color) +
  scale_x_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.5)) +
  theme_ctokita() +
  theme(legend.position = "none") +
  facet_wrap(~news_source, scales = "free_x")

####################
# Plot: Opposite-ideology unfollows (tie breaks) by information ecosystem
####################
# Raw plot between expected number of opposite ideology follower tie breaks vs actual number
gg_infoeco_breaks_raw <- ggplot(user_data, aes(x = info_ecosystem, y = delta_tiebreak_freq, color = info_ecosystem)) +
  geom_hline(yintercept = 0, linetype = "dotted", size = 0.3) +
  geom_point(size = 0.9, stroke = 0, alpha = 0.4, position = position_jitter(width = 0.05, height = 0.02)) +
  scale_y_continuous(limits = c(-1, 1)) +
  scale_color_manual(values = info_corr_pal) +
  theme_ctokita() +
  theme(legend.position = "none") +
  xlab("Information ecosystem") +
  ylab("Relative freq. of opposite-ideology unfollows")
gg_infoeco_breaks_raw
ggsave(gg_infoeco_breaks_raw, filename = paste0(outpath_tiebreaks, "tiebreaks_relativefreq_infocorr_raw.pdf"), width = 90, height = 90, units = "mm", dpi = 400)

# Estimate mean using bayesian inference
low_corr_estimate <- Bolstad::normnp(x = user_data$delta_tiebreak_freq[user_data$info_ecosystem == "Low correlation"],
                                     m.x = 0, s.x = 0.05, quiet = TRUE, plot = FALSE)
high_corr_estimate <- Bolstad::normnp(x = user_data$delta_tiebreak_freq[user_data$info_ecosystem == "High correlation"],
                                      m.x = 0, s.x = 0.05, quiet = TRUE, plot = FALSE)
info_correlation_estimates <- data.frame(info_ecosystem = factor(c("Low\ncorrelation", "High\ncorrelation"), levels = c("Low\ncorrelation", "High\ncorrelation")), 
                                         delta_freq_tiebreak_diff = c(low_corr_estimate$mean, high_corr_estimate$mean),
                                         ci_80_low = c(low_corr_estimate$quantileFun(0.1), high_corr_estimate$quantileFun(0.1)),
                                         ci_80_high = c(low_corr_estimate$quantileFun(0.9), high_corr_estimate$quantileFun(0.9)),
                                         ci_95_low = c(low_corr_estimate$quantileFun(0.025), high_corr_estimate$quantileFun(0.025)),
                                         ci_95_high = c(low_corr_estimate$quantileFun(0.975), high_corr_estimate$quantileFun(0.975)))

# Plot estimates of relative frequency of cross-ideology breaks (relative to expected by random chance)
gg_infoeco_breaks <- ggplot(info_correlation_estimates, aes(x = info_ecosystem, color = info_ecosystem)) +
  geom_hline(yintercept = 0, linetype = "dotted", size = 0.3) +
  geom_errorbar(aes(ymin = ci_95_low, ymax = ci_95_high), width = 0, size = 0.3) +
  geom_errorbar(aes(ymin = ci_80_low, ymax = ci_80_high), width = 0, size = 0.8) +
  scale_y_continuous(limits = c(-0.02, 0.043)) +
  geom_point(aes(y = delta_freq_tiebreak_diff), size = 2) + 
  scale_color_manual(values = info_corr_pal) +
  xlab("Information ecosystem") +
  ylab("Relative freq.\ncross-ideology unfollows") +
  theme_ctokita() +
  theme(legend.position = "none",
        axis.text.x = element_text(size = 5))
gg_infoeco_breaks
ggsave(gg_infoeco_breaks, filename = paste0(outpath_tiebreaks, "tiebreaks_relativefreq_infocorr.pdf"), width = 45, height = 45, units = "mm")



####################
# Plot: Opposite-ideology unfollows (tie breaks) by news source
####################.
# Raw plot between expected number of opposite ideology follower tie breaks vs actual number
gg_newssource_breaks_raw <- ggplot(user_data, aes(x = news_source, y = delta_tiebreak_freq, color = news_source)) +
  geom_hline(yintercept = 0, linetype = "dotted", size = 0.3) +
  geom_point(size = 0.9, stroke = 0, alpha = 0.5, position = position_jitter(width = 0.05, height = 0.02)) +
  scale_y_continuous(limits = c(-1, 1)) +
  scale_color_manual(values = news_pal) +
  theme_ctokita() +
  theme(legend.position = "none") +
  xlab("News outlet") +
  ylab("Diff. ideology unfollows relative to expected")
gg_newssource_breaks_raw
ggsave(gg_newssource_breaks_raw, filename = paste0(outpath_tiebreaks, "tiebreaks_relativefreq_newssource_raw.pdf"), width = 90, height = 90, units = "mm", dpi = 400)

# Bayesian estimate  of relative frequency of cross-ideology tie breaks
newssource_estimates <- data.frame()
for (outlet in unique(user_data$news_source)) {
  estimate <-Bolstad::normnp(x = user_data$delta_tiebreak_freq[user_data$news_source == outlet],
                             m.x = 0, s.x = 0.1, quiet = TRUE, plot = TRUE)
  lean <- ifelse(outlet %in% c("cbsnews", "voxdotcom"), "Liberal", "Conservative")
  estimate <- data.frame(news_source = outlet, 
                         ideology = lean,
                         info_ecosystem = unique(user_data$info_ecosystem[user_data$news_source == outlet]),
                         delta_freq_tiebreak_diff = estimate$mean,
                         ci_80_low = estimate$quantileFun(0.1),
                         ci_80_high = estimate$quantileFun(0.9),
                         ci_95_low = estimate$quantileFun(0.025), estimate$quantileFun(0.025),
                         ci_95_high = estimate$quantileFun(0.975), estimate$quantileFun(0.975))
  newssource_estimates <- rbind(newssource_estimates, estimate)
}
newssource_estimates <- newssource_estimates %>% 
  mutate(info_ecosystem = gsub(" correlation", "\ncorrelation", info_ecosystem)) %>% 
  mutate(info_ecosystem = factor(info_ecosystem, levels = c("Low\ncorrelation", "High\ncorrelation")))

# Plot estimates of relative frequency of cross-ideology breaks (relative to expected by random chance)
dodge_width <- 0.25
gg_newssource_breaks <- ggplot(newssource_estimates, aes(x = info_ecosystem, color = ideology, group = ideology)) +
  geom_hline(yintercept = 0, linetype = "dotted", size = 0.3) +
  geom_errorbar(aes(ymin = ci_95_low, ymax = ci_95_high), 
                position = position_dodge(dodge_width), width = 0, size = 0.3) +
  geom_errorbar(aes(ymin = ci_80_low, ymax = ci_80_high),
                position = position_dodge(dodge_width), width = 0, size = 0.8) +
  geom_line(aes(y = delta_freq_tiebreak_diff), 
            position = position_dodge(dodge_width), size = 0.3) +
  geom_point(aes(y = delta_freq_tiebreak_diff), 
             position = position_dodge(dodge_width), size = 2) + 
  # scale_y_continuous(limits = c(-0.03, 0.06), breaks = seq(-0.04, 0.06, 0.02)) +
  scale_color_manual(values = ideol_pal[c(3, 1)]) +
  xlab("Information ecosystem") +
  ylab("Relative freq.\ncross-ideology unfollows") +
  theme_ctokita() +
  theme(legend.position = "none",
        axis.text.x = element_text(size = 5))
gg_newssource_breaks
ggsave(gg_newssource_breaks, filename = paste0(outpath_tiebreaks, "tiebreaks_relativefreq_newssource.pdf"), width = 45, height = 45, units = "mm")
