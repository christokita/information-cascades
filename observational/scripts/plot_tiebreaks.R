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
library(ebbr)
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
            follower_conservative_n = sum(ideology_corresp > 0), #count conservatives
            followers_ideol_avg = mean(ideology_corresp)) %>%
  mutate(followers_liberal_freq = follower_liberal_n / n_follower_samples, #MLE estimate
         followers_conservative_freq = follower_conservative_n / n_follower_samples, #MLE estimate
         followers_ideology_skew = (follower_conservative_n - follower_liberal_n) / n_follower_samples)

# Bayesian estimate of follower ideology
# prior_liberal <- ideology_mix %>%
#   ebbr::ebb_fit_prior(follower_liberal_n, n_follower_samples)
# prior_conserv <- ideology_mix %>%
#   ebbr::ebb_fit_prior(follower_conservative_n, n_follower_samples)
# a_L <- prior_liberal$parameters$alpha
# b_L <- prior_liberal$parameters$beta
# a_C <- prior_conserv$parameters$alpha
# b_C <- prior_conserv$parameters$beta
a_L <- 1
b_L <- 1
a_C <- 1
b_C <- 1
ideology_mix <- ideology_mix %>% 
  mutate(followers_liberal_est = (follower_liberal_n + a_L) / (n_follower_samples + a_L + b_L),
         followers_conservative_est = (follower_conservative_n + a_C) / (n_follower_samples + a_C + b_C))

# Calculate freq of breaks by ideology
tie_change_summary <- tie_changes %>%
  filter(tie_change == "broken",
         !is.na(ideology_corresp)) %>%
  group_by(user_id) %>% 
  summarise(n_tiebreaks = length(ideology_corresp),
            tiebreak_liberal_n = sum(ideology_corresp < 0),
            tiebreak_conservative_n = sum(ideology_corresp > 0),
            tiebreak_ideol_avg = mean(ideology_corresp)) %>% 
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
         followers_diffideol_est = NA,
         followers_sameideol_est = NA,
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

user_data$followers_diffideol_est[liberal_users] <- user_data$followers_conservative_est[liberal_users]
user_data$followers_sameideol_est[liberal_users] <- user_data$followers_liberal_est[liberal_users]
user_data$followers_diffideol_est[conservative_users] <- user_data$followers_liberal_est[conservative_users]
user_data$followers_sameideol_est[conservative_users] <- user_data$followers_conservative_est[conservative_users]

user_data$tiebreak_diffideol_freq[liberal_users] <- user_data$tiebreak_conservative_freq[liberal_users]
user_data$tiebreak_diffideol_freq[conservative_users] <- user_data$tiebreak_liberal_freq[conservative_users]

user_data$tiebreak_diffideol_n[liberal_users] <- user_data$tiebreak_conservative_n[liberal_users]
user_data$tiebreak_diffideol_n[conservative_users] <- user_data$tiebreak_liberal_n[conservative_users]
 

####################
# Prep data: calcualte expected frequency of diff ideology tie breaks (same ideology breaks will be mirror image)
#################### 
user_data <- user_data %>% 
  # Calcualte expected number of breaks given follower ideol composition (raw or bayesian estiamte)
  mutate(tiebreak_diffideol_expected = followers_diffideol_freq * n_tiebreaks,
         tiebreak_diffideol_expected_est = followers_diffideol_est * n_tiebreaks) %>% 
  # Calcualte delta between expected and actual tie break number/frequency
  mutate(delta_tiebreak_n = tiebreak_diffideol_n - tiebreak_diffideol_expected,
         delta_tiebreak_n_est = tiebreak_diffideol_n - tiebreak_diffideol_expected_est,
         delta_tiebreak_freq = tiebreak_diffideol_freq - followers_diffideol_freq,
         delta_tiebreak_freq_est = tiebreak_diffideol_freq - followers_diffideol_est)


####################
# Function to do bayesian estimation of mean, assuming normal distribution
####################
estimate_mean <- function(data, mean_prior, std_prior, info_ecosystem, ideology) {
  est <- Bolstad::normnp(x = data, m.x = mean_prior, s.x = std_prior, quiet = TRUE, plot = FALSE)
  df_est <- data.frame(info_ecosystem = info_ecosystem, 
                       est_mean = est$mean,
                       ideology = ideology,
                       ci_80_low = est$quantileFun(0.1),
                       ci_80_high = est$quantileFun(0.9),
                       ci_90_low = est$quantileFun(0.05),
                       ci_90_high = est$quantileFun(0.95),
                       ci_95_low = est$quantileFun(0.025),
                       ci_95_high = est$quantileFun(0.975))
  return(df_est)
}



######################### Analysis: Cross-ideology unfollows (tie breaks) by INFORMATION ECOSYSTEM #########################

####################
# Plot: Scatter plot of relative FREQUENCY of cross-ideology breaks (relative to expected by random chance)
####################
gg_infoeco_breaks_freq_raw <- user_data %>% 
  filter(n_tiebreaks > 0) %>% 
  ggplot(., aes(x = info_ecosystem, y = delta_tiebreak_freq, color = info_ecosystem)) +
  geom_hline(yintercept = 0, linetype = "dotted", size = 0.3) +
  geom_point(size = 1, stroke = 0, alpha = 0.4, shape = 16, position = position_jitter(width = 0.05, height = 0.02)) +
  # geom_violin() +
  scale_y_continuous(limits = c(-1, 1)) +
  scale_color_manual(values = info_corr_pal) +
  theme_ctokita() +
  theme(legend.position = "none") +
  xlab("Information ecosystem") +
  ylab("Relative freq. of opposite-ideology unfollows")
gg_infoeco_breaks_freq_raw
ggsave(gg_infoeco_breaks_freq_raw, filename = paste0(outpath_tiebreaks, "relativefreq_infoeco_raw.pdf"), width = 90, height = 90, units = "mm", dpi = 400)


####################
# Plot: Estimates of relative FREQUENCY of cross-ideology breaks
####################
# Estimate mean using bayesian inference
infoeco_freq_estimates <- data.frame()
for (info_corr in c("Low correlation", "High correlation")) {
  info_eco_data <- user_data %>% 
    filter(info_ecosystem == info_corr,
           n_tiebreaks > 0) %>% 
    .$delta_tiebreak_freq
  estimate <- estimate_mean(data = info_eco_data, 
                            mean_prior = 0,
                            std_prior = 0.05, 
                            info_ecosystem = info_corr, 
                            ideology = NA)
  infoeco_freq_estimates <- rbind(infoeco_freq_estimates, estimate)
  rm(info_eco_data, estimate)
}
infoeco_freq_estimates <- infoeco_freq_estimates %>% 
  mutate(info_ecosystem = gsub(" ", "\n", info_ecosystem)) %>% #add line break for plotting
  mutate(info_ecosystem = factor(info_ecosystem, levels = c("Low\ncorrelation", "High\ncorrelation"))) #set plotting order

# Plot estimates
gg_infoeco_breaks_freq <- ggplot(infoeco_freq_estimates, aes(x = info_ecosystem, color = info_ecosystem)) +
  geom_hline(yintercept = 0, linetype = "dotted", size = 0.3) +
  geom_errorbar(aes(ymin = ci_95_low, ymax = ci_95_high), 
                width = 0, 
                size = 0.5) +
  geom_point(aes(y = est_mean), 
             size = 2) + 
  scale_y_continuous(breaks = round(seq(-0.10, 0.10, 0.01), 2), #cuts off edge breaks due to weird float calcualtion of sequence
                     limits = c(-0.02, 0.04), 
                     expand = c(0, 0)) +
  scale_color_manual(values = info_corr_pal) +
  xlab("Information ecosystem") +
  ylab("Relative freq.\ncross-ideology unfollows") +
  theme_ctokita() +
  theme(legend.position = "none",
        axis.text.x = element_text(size = 5))
gg_infoeco_breaks_freq
ggsave(gg_infoeco_breaks_freq, filename = paste0(outpath_tiebreaks, "relativefreq_infoeco.pdf"), width = 45, height = 45, units = "mm")


####################
# Plot: Scatter plot of relative NUMBER of cross-ideology breaks
####################
gg_infoeco_breaks_n_raw <- user_data %>% 
  filter(n_tiebreaks > 0) %>% 
  ggplot(., aes(x = info_ecosystem, y = delta_tiebreak_n, color = info_ecosystem)) +
  geom_hline(yintercept = 0, linetype = "dotted", size = 0.3) +
  geom_point(size = 1, stroke = 0, alpha = 0.4, shape = 16, position = position_jitter(width = 0.05, height = 0.02)) +
  scale_color_manual(values = info_corr_pal) +
  theme_ctokita() +
  theme(legend.position = "none") +
  xlab("Information ecosystem") +
  ylab("Relative number of opposite-ideology unfollows")
gg_infoeco_breaks_n_raw
ggsave(gg_infoeco_breaks_n_raw, filename = paste0(outpath_tiebreaks, "relativenumber_infoeco_raw.pdf"), width = 90, height = 90, units = "mm", dpi = 400)

####################
# Plot: Estimates of relative NUMBER of cross-ideology breaks
####################
# Estimate mean using bayesian inference
infoeco_n_estimates <- data.frame()
for (info_corr in c("Low correlation", "High correlation")) {
  info_eco_data <- user_data %>% 
    filter(info_ecosystem == info_corr,
           n_tiebreaks > 0) %>% 
    .$delta_tiebreak_n
  estimate <- estimate_mean(data = info_eco_data, 
                            mean_prior = 0,
                            std_prior = 0.5, 
                            info_ecosystem = info_corr, 
                            ideology = NA)
  infoeco_n_estimates <- rbind(infoeco_n_estimates, estimate)
  rm(info_eco_data, estimate)
}
infoeco_n_estimates <- infoeco_n_estimates %>% 
  mutate(info_ecosystem = gsub(" ", "\n", info_ecosystem)) %>% #add line break for plotting
  mutate(info_ecosystem = factor(info_ecosystem, levels = c("Low\ncorrelation", "High\ncorrelation"))) #set plotting order

# Plot estimates
gg_infoeco_breaks_n <- ggplot(infoeco_n_estimates, aes(x = info_ecosystem, color = info_ecosystem)) +
  geom_hline(yintercept = 0, linetype = "dotted", size = 0.3) +
  geom_errorbar(aes(ymin = ci_95_low, ymax = ci_95_high), width = 0, size = 0.5) +
  scale_y_continuous(breaks = seq(-0.03, 0.15, 0.03),
                     limits = c(-0.03, 0.15), 
                     expand = c(0, 0)) +
  geom_point(aes(y = est_mean), size = 2) + 
  scale_color_manual(values = info_corr_pal) +
  xlab("Information ecosystem") +
  ylab("Relative number\ncross-ideology unfollows") +
  theme_ctokita() +
  theme(legend.position = "none",
        axis.text.x = element_text(size = 5))
gg_infoeco_breaks_n
ggsave(gg_infoeco_breaks_n, filename = paste0(outpath_tiebreaks, "relativenumber_infoeco.pdf"), width = 45, height = 45, units = "mm")



######################### Analysis: Cross-ideology unfollows (tie breaks) by NEWS SOURCE #########################

####################
# Plot: Scatter plot of FREQUENCY of cross-ideology breaks (relative to expected by random chance)
####################.
gg_newssource_breaks_freq_raw <- user_data %>% 
  filter(n_tiebreaks > 0) %>% 
  ggplot(., aes(x = news_source, y = delta_tiebreak_freq, color = news_source)) +
  geom_hline(yintercept = 0, linetype = "dotted", size = 0.3) +
  geom_point(size = 1, stroke = 0, alpha = 0.5, shape = 16, position = position_jitter(width = 0.05, height = 0.02)) +
  scale_y_continuous(limits = c(-1, 1)) +
  scale_color_manual(values = news_pal) +
  theme_ctokita() +
  theme(legend.position = "none") +
  xlab("News outlet") +
  ylab("Relative freq.cross-ideology unfollows")
gg_newssource_breaks_freq_raw
ggsave(gg_newssource_breaks_freq_raw, filename = paste0(outpath_tiebreaks, "relativefreq_newssource_raw.pdf"), width = 90, height = 90, units = "mm", dpi = 400)

####################
# Bayesian estimate  of relative FREQUENCY of cross-ideology tie breaks
####################
# Estimate mean using bayesian inference
newssource_freq_estimates <- data.frame()
for (outlet in unique(user_data$news_source)) {
  newssource_data <- user_data %>% 
    filter(news_source == outlet,
           n_tiebreaks > 0)
  ideology <- ifelse(outlet %in% c("cbsnews", "voxdotcom"), "Liberal", "Conservative")
  estimate <- estimate_mean(data = newssource_data$delta_tiebreak_freq, 
                            mean_prior = 0,
                            std_prior = 0.05, 
                            info_ecosystem = unique(newssource_data$info_ecosystem), 
                            ideology = ideology)
  newssource_freq_estimates <- rbind(newssource_freq_estimates, estimate)
  rm(newssource_data, ideology, estimate)
}
newssource_freq_estimates <- newssource_freq_estimates %>% 
  mutate(info_ecosystem = gsub(" ", "\n", info_ecosystem)) %>% #add line break for plotting
  mutate(info_ecosystem = factor(info_ecosystem, levels = c("Low\ncorrelation", "High\ncorrelation"))) #set plotting order

# Plot estimates
dodge_width <- 0.25
gg_newssource_breaks_freq <- ggplot(newssource_freq_estimates, aes(x = info_ecosystem, color = ideology, group = ideology)) +
  geom_hline(yintercept = 0, linetype = "dotted", size = 0.3) +
  geom_errorbar(aes(ymin = ci_95_low, ymax = ci_95_high), 
                position = position_dodge(dodge_width), width = 0, size = 0.5) +
  geom_line(aes(y = est_mean), 
            position = position_dodge(dodge_width), size = 0.3) +
  geom_point(aes(y = est_mean), 
             position = position_dodge(dodge_width), size = 2) + 
  scale_y_continuous(limits = c(-0.04, 0.06), 
                     breaks = seq(-0.04, 0.06, 0.02),
                     expand = c(0, 0)) +
  scale_color_manual(values = ideol_pal[c(3, 1)]) +
  xlab("Information ecosystem") +
  ylab("Relative freq.\ncross-ideology unfollows") +
  theme_ctokita() +
  theme(legend.position = "none",
        axis.text.x = element_text(size = 5))
gg_newssource_breaks_freq
ggsave(gg_newssource_breaks_freq, filename = paste0(outpath_tiebreaks, "relativefreq_newssource.pdf"), width = 45, height = 45, units = "mm")


####################
# Plot: Scatter plot of NUMBER of cross-ideology breaks
####################.
gg_newssource_breaks_n_raw <- user_data %>% 
  filter(n_tiebreaks > 0) %>% 
  ggplot(., aes(x = news_source, y = delta_tiebreak_n, color = news_source)) +
  geom_hline(yintercept = 0, linetype = "dotted", size = 0.3) +
  geom_point(size = 1, stroke = 0, alpha = 0.5, shape = 16, position = position_jitter(width = 0.05, height = 0.02)) +
  scale_y_continuous(limits = c(-15, 15), breaks = seq(-15, 15, 5)) +
  scale_color_manual(values = news_pal) +
  theme_ctokita() +
  theme(legend.position = "none") +
  xlab("News outlet") +
  ylab("Relative number cross-ideology unfollows")
gg_newssource_breaks_n_raw
ggsave(gg_newssource_breaks_n_raw, filename = paste0(outpath_tiebreaks, "relativenumber_newssource_raw.pdf"), width = 90, height = 90, units = "mm", dpi = 400)

####################
# Bayesian estimate of relative NUMBER of cross-ideology tie breaks
####################
# Estimate mean using bayesian inference
newssource_n_estimates <- data.frame()
for (outlet in unique(user_data$news_source)) {
  newssource_data <- user_data %>% 
    filter(n_tiebreaks > 0,
           news_source == outlet)
  ideology <- ifelse(outlet %in% c("cbsnews", "voxdotcom"), "Liberal", "Conservative")
  estimate <- estimate_mean(data = newssource_data$delta_tiebreak_n, 
                            mean_prior = 0,
                            std_prior = 0.05, 
                            info_ecosystem = unique(newssource_data$info_ecosystem), 
                            ideology = ideology)
  newssource_n_estimates <- rbind(newssource_n_estimates, estimate)
  rm(newssource_data, ideology, estimate)
}
newssource_n_estimates <- newssource_n_estimates %>% 
  mutate(info_ecosystem = gsub(" ", "\n", info_ecosystem)) %>% #add line break for plotting
  mutate(info_ecosystem = factor(info_ecosystem, levels = c("Low\ncorrelation", "High\ncorrelation"))) #set plotting order

# Plot estimates
dodge_width <- 0.25
gg_newssource_breaks_n <- ggplot(newssource_n_estimates, aes(x = info_ecosystem, color = ideology, group = ideology)) +
  geom_hline(yintercept = 0, linetype = "dotted", size = 0.3) +
  geom_errorbar(aes(ymin = ci_95_low, ymax = ci_95_high), 
                position = position_dodge(dodge_width), width = 0, size = 0.5) +
  geom_line(aes(y = est_mean), 
            position = position_dodge(dodge_width), size = 0.3) +
  geom_point(aes(y = est_mean), 
             position = position_dodge(dodge_width), size = 2) + 
  scale_y_continuous(limits = c(-0.10, 0.15),
                     breaks = seq(-0.1, 0.15, 0.05),
                     expand = c(0, 0)) +
  scale_color_manual(values = ideol_pal[c(3, 1)]) +
  xlab("Information ecosystem") +
  ylab("Relative number\ncross-ideology unfollows") +
  theme_ctokita() +
  theme(legend.position = "none",
        axis.text.x = element_text(size = 5))
gg_newssource_breaks_n
ggsave(gg_newssource_breaks_n, filename = paste0(outpath_tiebreaks, "relativenumber_newssource.pdf"), width = 45, height = 45, units = "mm")


######################### Analysis: Cross-ideology unfollows (tie breaks) WIHTOUT CONSIDERING BASELINE follower composition #########################

####################
# Plot: Cross-ideology unfollows (tie breaks) in camparison to follwoer compsition by news source
####################
# Bayesian estimate  of unadjusted frequency of cross-ideology unfollows and initial followers
newssource_unadjust_estimates <- data.frame()
for (outlet in unique(user_data$news_source)) {
  ideology <- ifelse(outlet %in% c("cbsnews", "voxdotcom"), "Liberal", "Conservative")
  estimate_unfollows <- estimate_mean(data = user_data %>% filter(news_source == outlet, n_tiebreaks > 0) %>% .$tiebreak_diffideol_freq, 
                                      mean_prior = 0,
                                      std_prior = 0.5, 
                                      info_ecosystem = unique(user_data$info_ecosystem), 
                                      ideology = ideology) %>% 
    mutate(measure = "Cross-ideology unfollows")
  estimate_followers <- estimate_mean(data = user_data %>% filter(news_source == outlet, n_tiebreaks > 0) %>% .$followers_diffideol_freq, 
                                      mean_prior = 0,
                                      std_prior = 0.5, 
                                      info_ecosystem = unique(user_data$info_ecosystem), 
                                      ideology = ideology) %>% 
    mutate(measure = "Diff. ideology followers")
  estimate <- rbind(estimate_unfollows, estimate_followers)
  estimate$news_source <- outlet
  newssource_unadjust_estimates <- rbind(newssource_unadjust_estimates, estimate)
  rm(estimate, estimate_followers, estimate_unfollows)
}
newssource_unadjust_estimates <- newssource_unadjust_estimates %>% 
  mutate(news_source = factor(news_source, levels = c("voxdotcom", "cbsnews", "usatoday", "dcexaminer")),
         measure = factor(measure, levels = c("Diff. ideology followers", "Cross-ideology unfollows")))

# Plot estimates of relative frequency of cross-ideology breaks & initial followers
dodge_width <- 0.4
gg_newssource_unadjusted <- ggplot(newssource_unadjust_estimates, 
                                aes(x = news_source, color = news_source, group = measure, shape = measure)) +
  geom_errorbar(aes(ymin = ci_95_low, ymax = ci_95_high), 
                width = 0, 
                size = 0.3, 
                position = position_dodge(width = dodge_width)) +
  geom_point(aes(y = est_mean), 
             size = 1.5, 
             fill = "white", 
             position = position_dodge(width = dodge_width)) + 
  scale_color_manual(values = news_pal) +
  scale_shape_manual(values = c(21, 16), name = "") +
  xlab("News outlet") +
  ylab("Frequency") +
  theme_ctokita() +
  theme(legend.position = "right",
        axis.text.x = element_text(size = 5, angle = 45, hjust = 1),
        aspect.ratio = NULL) +
  guides(color = FALSE)
gg_newssource_unadjusted
ggsave(gg_newssource_unadjusted, filename = paste0(outpath_tiebreaks, "unadjusted_freq_newssource.pdf"), width = 75, height = 45, units = "mm")


####################
# Plot: Avg ideological distance of unfollows
####################
# Calcualte difference in follower and tie-breaker (users who unfollowed) ideology
unfollow_ideol_data <- user_data %>% 
  filter(n_tiebreaks > 0) %>% 
  mutate(relative_tiebreak_ideol = tiebreak_ideol_avg - followers_ideol_avg)

# Bayesian estimate  of unadjusted frequency of cross-ideology unfollows and initial followers
newssource_unfollow_ideology <- data.frame()
for (outlet in unique(user_data$news_source)) {
  newssource_data <- unfollow_ideol_data %>% 
    filter(n_tiebreaks > 0,
           news_source == outlet)
  ideology <- ifelse(outlet %in% c("cbsnews", "voxdotcom"), "Liberal", "Conservative")
  estimate <- estimate_mean(data = newssource_data$relative_tiebreak_ideol, 
                            mean_prior = 0,
                            std_prior = 0.05, 
                            info_ecosystem = unique(newssource_data$info_ecosystem), 
                            ideology = ideology)
  estimate$news_source <- outlet
  newssource_unfollow_ideology <- rbind(newssource_unfollow_ideology, estimate)
  rm(newssource_data, ideology, estimate)
}
newssource_unfollow_ideology <- newssource_unfollow_ideology %>% 
  mutate(news_source = factor(news_source, levels = c("voxdotcom", "cbsnews", "usatoday", "dcexaminer")))

# Plot
gg_unfollow_ideol <- ggplot(newssource_unfollow_ideology, 
                                   aes(x = news_source, y = est_mean, color = news_source)) +
  geom_hline(yintercept = 0, linetype = "dotted", size = 0.3) +
  geom_errorbar(aes(ymin = ci_95_low, ymax = ci_95_high), 
                position = position_dodge(dodge_width), 
                width = 0, 
                size = 0.5) +
  geom_point(size = 2) + 
  scale_y_continuous(limits = c(-0.08, 0.12),
                     breaks = seq(-0.12, 0.12, 0.04),
                     expand = c(0, 0)) +
  scale_color_manual(values = news_pal) +
  xlab("News outlet") +
  ylab("Relative ideology of unfollowers") +
  theme_ctokita() +
  theme(legend.position = "right",
        axis.text.x = element_text(size = 5, angle = 45, hjust = 1)) +
  guides(color = FALSE)
gg_unfollow_ideol
ggsave(gg_unfollow_ideol, filename = paste0(outpath_tiebreaks, "relativeideology_newssource.pdf"), width = 45, height = 45, units = "mm")

