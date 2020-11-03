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
            follower_conservative_n = sum(ideology_corresp > 0)) %>% #count conservatives
  mutate(followers_liberal_freq = follower_liberal_n / n_follower_samples, #MLE estimate
         followers_conservative_freq = follower_conservative_n / n_follower_samples, #MLE estimate
         followers_ideology = (follower_conservative_n - follower_liberal_n) / n_follower_samples)

# Bayesian estimate of follower ideology
prior_liberal <- ideology_mix %>%
  ebbr::ebb_fit_prior(follower_liberal_n, n_follower_samples)
prior_conserv <- ideology_mix %>%
  ebbr::ebb_fit_prior(follower_conservative_n, n_follower_samples)
a_L <- prior_liberal$parameters$alpha
b_L <- prior_liberal$parameters$beta
a_C <- prior_conserv$parameters$alpha
b_C <- prior_conserv$parameters$beta
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
         delta_tiebreak_freq_est = tiebreak_diffideol_freq - followers_diffideol_est) %>% 
  # Filter out individuals that didn't show any breaks
  filter(n_tiebreaks > 0)


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
                       ci_95_low = est$quantileFun(0.025),
                       ci_95_high = est$quantileFun(0.975))
  return(df_est)
}


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
  geom_point(size = 1, stroke = 0, alpha = 0.5, shape = 16) +
  scale_color_gradientn(colors = ideol_pal, limits = c(-2, 2), oob = scales::squish) +
  xlab("User ideology") +
  ylab("Freq. conservative followers") +
  theme_ctokita() +
  theme(legend.position = "none") 
gg_follower_ideol
ggsave(gg_follower_ideol, filename = paste0(outpath_ideology, "user_vs_follower_ideology.pdf"), width = 45, height = 45, units = "mm", dpi = 400)

# Comparison of user ideology vs relative ideological composition of followers
gg_follower_same <- ggplot(user_data, aes(x = ideology_corresp, y = followers_sameideol_freq, color = ideology_corresp)) +
  geom_point(size = 1, stroke = 0, alpha = 0.5, shape = 16) +
  scale_color_gradientn(colors = ideol_pal, limits = c(-2, 2), oob = scales::squish) +
  theme_ctokita() +
  theme(legend.position = "none") +
  xlab("User ideology") +
  ylab("Freq. followers same ideology")
gg_follower_same
ggsave(gg_follower_same, filename = paste0(outpath_ideology, "follower_same_ideology.pdf"), width = 45, height = 45, units = "mm", dpi = 400)

# Same ideology follow composition by news source
gg_follower_dist <- ggplot(user_data, aes(x = followers_conservative_freq)) +
  geom_histogram(fill = plot_color, color = plot_color) +
  scale_x_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.5)) +
  xlab("Freq. of conservative followers") +
  theme_ctokita() +
  theme(legend.position = "none") +
  facet_wrap(~news_source, scales = "free_x")
ggsave(gg_follower_dist, filename = paste0(outpath_ideology, "follower_conservative_bynewssource.pdf"), width = 90, height = 90, units = "mm", dpi = 400)


####################
# Plot: Cross-ideology unfollows (tie breaks) by information ecosystem
####################

########## Relative frequency ########## 

# Scatter plot of relative frequency of cross-ideology breaks (relative to expected by random chance)
gg_infoeco_breaks_freq_raw <- ggplot(user_data, aes(x = info_ecosystem, y = delta_tiebreak_freq, color = info_ecosystem)) +
  geom_hline(yintercept = 0, linetype = "dotted", size = 0.3) +
  geom_point(size = 1, stroke = 0, alpha = 0.4, shape = 16, position = position_jitter(width = 0.05, height = 0.02)) +
  # geom_violin() +
  scale_y_continuous(limits = c(-1, 1)) +
  scale_color_manual(values = info_corr_pal) +
  theme_ctokita() +
  theme(legend.position = "none") +
  xlab("Information ecosystem") +
  ylab("Relative freq. of opposite-ideology unfollows")
gg_infoeco_breaks_raw
ggsave(gg_infoeco_breaks_raw, filename = paste0(outpath_tiebreaks, "relativefreq_infoeco_raw.pdf"), width = 90, height = 90, units = "mm", dpi = 400)

# Estimate mean using bayesian inference
infoeco_freq_estimates <- data.frame()
for (info_corr in c("Low correlation", "High correlation")) {
  info_eco_data <- user_data$delta_tiebreak_freq[user_data$info_ecosystem == info_corr]
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

# Plot estimates of relative frequency of cross-ideology breaks (relative to expected by random chance)
gg_infoeco_breaks_freq <- ggplot(infoeco_freq_estimates, aes(x = info_ecosystem, color = info_ecosystem)) +
  geom_hline(yintercept = 0, linetype = "dotted", size = 0.3) +
  geom_errorbar(aes(ymin = ci_95_low, ymax = ci_95_high), width = 0, size = 0.3) +
  geom_errorbar(aes(ymin = ci_80_low, ymax = ci_80_high), width = 0, size = 0.8) +
  geom_point(aes(y = est_mean), size = 2) + 
  scale_color_manual(values = info_corr_pal) +
  xlab("Information ecosystem") +
  ylab("Relative freq.\ncross-ideology unfollows") +
  theme_ctokita() +
  theme(legend.position = "none",
        axis.text.x = element_text(size = 5))
gg_infoeco_breaks
ggsave(gg_infoeco_breaks, filename = paste0(outpath_tiebreaks, "relativefreq_infoeco.pdf"), width = 45, height = 45, units = "mm")


########## Relative count ########## 

# Scatter plot of number of cross-ideology breaks (relative to expected by random chance)
gg_infoeco_breaks_n_raw <- ggplot(user_data, aes(x = info_ecosystem, y = delta_tiebreak_n, color = info_ecosystem)) +
  geom_hline(yintercept = 0, linetype = "dotted", size = 0.3) +
  geom_point(size = 1, stroke = 0, alpha = 0.4, shape = 16, position = position_jitter(width = 0.05, height = 0.02)) +
  scale_color_manual(values = info_corr_pal) +
  theme_ctokita() +
  theme(legend.position = "none") +
  xlab("Information ecosystem") +
  ylab("Relative number of opposite-ideology unfollows")
gg_infoeco_breaks_n_raw
ggsave(gg_infoeco_breaks_n_raw, filename = paste0(outpath_tiebreaks, "relativenumber_infoeco_raw.pdf"), width = 90, height = 90, units = "mm", dpi = 400)

# Estimate mean using bayesian inference
infoeco_n_estimates <- data.frame()
for (info_corr in c("Low correlation", "High correlation")) {
  info_eco_data <- user_data$delta_tiebreak_n[user_data$info_ecosystem == info_corr]
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

# Plot estimates of relative frequency of cross-ideology breaks (relative to expected by random chance)
gg_infoeco_breaks_n <- ggplot(infoeco_n_estimates, aes(x = info_ecosystem, color = info_ecosystem)) +
  geom_hline(yintercept = 0, linetype = "dotted", size = 0.3) +
  geom_errorbar(aes(ymin = ci_95_low, ymax = ci_95_high), width = 0, size = 0.3) +
  geom_errorbar(aes(ymin = ci_80_low, ymax = ci_80_high), width = 0, size = 0.8) +
  scale_y_continuous(breaks = seq(-0.03, 0.15, 0.03)) +
  geom_point(aes(y = est_mean), size = 2) + 
  scale_color_manual(values = info_corr_pal) +
  xlab("Information ecosystem") +
  ylab("Relative number\ncross-ideology unfollows") +
  theme_ctokita() +
  theme(legend.position = "none",
        axis.text.x = element_text(size = 5))
gg_infoeco_breaks_n
ggsave(gg_infoeco_breaks_n, filename = paste0(outpath_tiebreaks, "relativenumber_infoeco.pdf"), width = 45, height = 45, units = "mm")


####################
# Plot: Opposite-ideology unfollows (tie breaks) by news source
####################.
########## Relative frequency ##########

# Scatter plot of frequency of cross-ideology breaks (relative to expected by random chance)
gg_newssource_breaks_freq_raw <- ggplot(user_data, aes(x = news_source, y = delta_tiebreak_freq, color = news_source)) +
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

# Bayesian estimate  of relative frequency of cross-ideology tie breaks
newssource_freq_estimates <- data.frame()
for (outlet in unique(user_data$news_source)) {
  newssource_data <- user_data[user_data$news_source == outlet, ]
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

# Plot estimates of relative frequency of cross-ideology breaks (relative to expected by random chance)
dodge_width <- 0.25
gg_newssource_breaks_freq <- ggplot(newssource_freq_estimates, aes(x = info_ecosystem, color = ideology, group = ideology)) +
  geom_hline(yintercept = 0, linetype = "dotted", size = 0.3) +
  geom_errorbar(aes(ymin = ci_95_low, ymax = ci_95_high), 
                position = position_dodge(dodge_width), width = 0, size = 0.3) +
  geom_errorbar(aes(ymin = ci_80_low, ymax = ci_80_high),
                position = position_dodge(dodge_width), width = 0, size = 0.8) +
  geom_line(aes(y = est_mean), 
            position = position_dodge(dodge_width), size = 0.3) +
  geom_point(aes(y = est_mean), 
             position = position_dodge(dodge_width), size = 2) + 
  # scale_y_continuous(limits = c(-0.03, 0.06), breaks = seq(-0.04, 0.06, 0.02)) +
  scale_color_manual(values = ideol_pal[c(3, 1)]) +
  xlab("Information ecosystem") +
  ylab("Relative freq.\ncross-ideology unfollows") +
  theme_ctokita() +
  theme(legend.position = "none",
        axis.text.x = element_text(size = 5))
gg_newssource_breaks_freq
ggsave(gg_newssource_breaks_freq, filename = paste0(outpath_tiebreaks, "relativefreq_newssource.pdf"), width = 45, height = 45, units = "mm")


########## Relative count ##########

# Scatter plot of number of cross-ideology breaks (relative to expected by random chance)
gg_newssource_breaks_n_raw <- ggplot(user_data, aes(x = news_source, y = delta_tiebreak_n, color = news_source)) +
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

# Bayesian estimate  of relative frequency of cross-ideology tie breaks
newssource_n_estimates <- data.frame()
for (outlet in unique(user_data$news_source)) {
  newssource_data <- user_data[user_data$news_source == outlet, ]
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

# Plot estimates of relative frequency of cross-ideology breaks (relative to expected by random chance)
dodge_width <- 0.25
gg_newssource_breaks_n <- ggplot(newssource_n_estimates, aes(x = info_ecosystem, color = ideology, group = ideology)) +
  geom_hline(yintercept = 0, linetype = "dotted", size = 0.3) +
  geom_errorbar(aes(ymin = ci_95_low, ymax = ci_95_high), 
                position = position_dodge(dodge_width), width = 0, size = 0.3) +
  geom_errorbar(aes(ymin = ci_80_low, ymax = ci_80_high),
                position = position_dodge(dodge_width), width = 0, size = 0.8) +
  geom_line(aes(y = est_mean), 
            position = position_dodge(dodge_width), size = 0.3) +
  geom_point(aes(y = est_mean), 
             position = position_dodge(dodge_width), size = 2) + 
  # scale_y_continuous(limits = c(-0.03, 0.06), breaks = seq(-0.04, 0.06, 0.02)) +
  scale_color_manual(values = ideol_pal[c(3, 1)]) +
  xlab("Information ecosystem") +
  ylab("Relative number\ncross-ideology unfollows") +
  theme_ctokita() +
  theme(legend.position = "none",
        axis.text.x = element_text(size = 5))
gg_newssource_breaks_n
ggsave(gg_newssource_breaks_n, filename = paste0(outpath_tiebreaks, "relativenumber_newssource.pdf"), width = 45, height = 45, units = "mm")



####################
# Plot: Cross-ideology unfollows (tie breaks) without considering baseline follower composition
####################

########## Info ecosystem ##########

# Bayesian estimate  of unadjusted frequency of cross-ideology unfollows and initial followers
infoeco_unadjust_estimates <- data.frame()
for (info_corr in c("Low correlation", "High correlation")) {
  estimate_unfollows <- estimate_mean(data = user_data$tiebreak_diffideol_freq[user_data$info_ecosystem == info_corr], 
                                      mean_prior = 0,
                                      std_prior = 0.5, 
                                      info_ecosystem = info_corr, 
                                      ideology = NA) %>% 
    mutate(measure = "Cross-ideology unfollows")
  estimate_followers <- estimate_mean(data = user_data$followers_diffideol_freq[user_data$info_ecosystem == info_corr], 
                                      mean_prior = 0,
                                      std_prior = 0.5, 
                                      info_ecosystem = info_corr, 
                                      ideology = NA) %>% 
    mutate(measure = "Diff. ideology followers")
  estimate <- rbind(estimate_unfollows, estimate_followers)
  infoeco_unadjust_estimates <- rbind(infoeco_unadjust_estimates, estimate)
  rm(estimate, estimate_followers, estimate_unfollows)
}
infoeco_unadjust_estimates <- infoeco_unadjust_estimates %>% 
  mutate(info_ecosystem = gsub(" ", "\n", info_ecosystem)) %>% #add line break for plotting
  mutate(info_ecosystem = factor(info_ecosystem, levels = c("Low\ncorrelation", "High\ncorrelation")),
         measure = factor(measure, levels = c("Diff. ideology followers", "Cross-ideology unfollows"))) 

# Plot estimates of relative frequency of cross-ideology breaks & initial followers
dodge_width <- 0.25
gg_infoeco_unadjusted <- ggplot(infoeco_unadjust_estimates, 
                                aes(x = info_ecosystem, color = info_ecosystem, group = measure, shape = measure)) +
  geom_errorbar(aes(ymin = ci_95_low, ymax = ci_95_high), width = 0, size = 0.3, position = position_dodge(width = dodge_width)) +
  geom_errorbar(aes(ymin = ci_80_low, ymax = ci_80_high), width = 0, size = 0.8, position = position_dodge(width = dodge_width)) +
  geom_point(aes(y = est_mean), size = 2, fill = "white", position = position_dodge(width = dodge_width)) + 
  scale_color_manual(values = info_corr_pal, name = "Information ecosystem") +
  scale_shape_manual(values = c(21, 16), name = "") +
  xlab("Information ecosystem") +
  ylab("Frequency") +
  theme_ctokita() +
  theme(legend.position = "right",
        axis.text.x = element_text(size = 5)) +
  guides(color = FALSE)
gg_infoeco_unadjusted
ggsave(gg_infoeco_unadjusted, filename = paste0(outpath_tiebreaks, "unadjusted_freq_infoeco.pdf"), width = 80, height = 45, units = "mm")


########## News source ##########

# Bayesian estimate  of unadjusted frequency of cross-ideology unfollows and initial followers
newssource_unadjust_estimates <- data.frame()
for (outlet in unique(user_data$news_source)) {
  ideology <- ifelse(outlet %in% c("cbsnews", "voxdotcom"), "Liberal", "Conservative")
  estimate_unfollows <- estimate_mean(data = user_data$tiebreak_diffideol_freq[user_data$news_source == outlet], 
                                      mean_prior = 0,
                                      std_prior = 0.5, 
                                      info_ecosystem = unique(user_data$info_ecosystem), 
                                      ideology = ideology) %>% 
    mutate(measure = "Cross-ideology unfollows")
  estimate_followers <- estimate_mean(data = user_data$followers_diffideol_freq[user_data$news_source == outlet], 
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
dodge_width <- 0.25
gg_newssource_unadjusted <- ggplot(newssource_unadjust_estimates, 
                                aes(x = news_source, color = news_source, group = measure, shape = measure)) +
  geom_errorbar(aes(ymin = ci_95_low, ymax = ci_95_high), width = 0, size = 0.3, position = position_dodge(width = dodge_width)) +
  geom_errorbar(aes(ymin = ci_80_low, ymax = ci_80_high), width = 0, size = 0.8, position = position_dodge(width = dodge_width)) +
  geom_point(aes(y = est_mean), size = 2, fill = "white", position = position_dodge(width = dodge_width)) + 
  scale_color_manual(values = news_pal) +
  scale_shape_manual(values = c(21, 16), name = "") +
  xlab("News outlet") +
  ylab("Frequency") +
  theme_ctokita() +
  theme(legend.position = "right",
        axis.text.x = element_text(size = 5),
        aspect.ratio = NULL) +
  guides(color = FALSE)
gg_newssource_unadjusted
ggsave(gg_newssource_unadjusted, filename = paste0(outpath_tiebreaks, "unadjusted_freq_newssource.pdf"), width = 90, height = 45, units = "mm")



ggplot(user_data, aes(x = followers_diffideol_freq)) +
  geom_histogram() +
  theme_ctokita() +
  facet_wrap(~news_source)

