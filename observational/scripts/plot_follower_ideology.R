########################################
# Created on Tue Oct 27 13:47:00 2020
# @author: ChrisTokita
#
# SCRIPT
# Plot and analyze the pattern of follower ideology of our monitored users
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
outpath_ideology <- "observational/output/ideology/"

# Parameters for plots
plot_color <- "#1B3B6F"
ideol_pal <- c("#006195", "#d9d9d9", "#d54c54")


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
k <- 1
ideology_mix <- ideology_mix %>% 
  mutate(followers_liberal_est = (follower_liberal_n + k) / (n_follower_samples + 2*k),
         followers_conservative_est = (follower_conservative_n + k) / (n_follower_samples + 2*k))

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
# Plot: Follower ideology distribution
####################
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


####################
# Plot: Comparison of user ideology vs ideological composition of followers
####################
# All together
gg_follower_ideol <- user_data %>% 
  filter(n_tiebreaks > 0) %>% 
  ggplot(., aes(x = ideology_corresp, y = followers_conservative_freq, color = ideology_corresp)) +
  geom_point(size = 1, stroke = 0, alpha = 0.5, shape = 16) +
  scale_y_continuous(limits = c(0, 1),
                     breaks = seq(0, 1, 0.25),
                     expand = c(0, 0)) +
  scale_color_gradientn(colors = ideol_pal, 
                        limits = c(-2, 2), 
                        oob = scales::squish) +
  xlab("User ideology") +
  ylab("\nFreq. conservative followers") +
  theme_ctokita() +
  theme(legend.position = "none") +
  coord_cartesian(clip = "off")
gg_follower_ideol
ggsave(gg_follower_ideol, filename = paste0(outpath_ideology, "user_vs_follower_ideology.pdf"), width = 45, height = 45, units = "mm", dpi = 400)

# Broken out by news source
gg_follower_ideol_brokenout <- user_data %>% 
  filter(n_tiebreaks > 0) %>% 
  ggplot(., aes(x = ideology_corresp, y = followers_conservative_freq, color = ideology_corresp)) +
  geom_point(size = 0.5, stroke = 0, alpha = 0.5, shape = 16) +
  scale_x_continuous(breaks = seq(-2, 2, 2), limits = c(-2.4, 2.4)) +
  scale_y_continuous(breaks = seq(0, 1, 0.5), 
                     limits = c(0, 1), 
                     expand = c(0, 0)) +
  scale_color_gradientn(colors = ideol_pal, 
                        limits = c(-2, 2), 
                        oob = scales::squish) +
  xlab("User ideology") +
  ylab("Freq. conservative followers") +
  theme_ctokita() +
  theme(legend.position = "none",
        strip.text = element_text(size = 6))  +
  facet_wrap(~news_source, 
             dir = "v")
gg_follower_ideol_brokenout
ggsave(gg_follower_ideol_brokenout, filename = paste0(outpath_ideology, "user_vs_follower_ideology_bynewsource.pdf"), width = 45, height = 45, units = "mm", dpi = 400)


####################
# Plot: Comparison of user ideology vs relative ideological composition of followers
####################
gg_follower_same <- user_data %>% 
  filter(n_tiebreaks > 0) %>% 
  ggplot(., aes(x = ideology_corresp, y = followers_sameideol_freq, color = ideology_corresp)) +
  geom_point(size = 1, stroke = 0, alpha = 0.5, shape = 16) +
  scale_color_gradientn(colors = ideol_pal, limits = c(-2, 2), oob = scales::squish) +
  theme_ctokita() +
  theme(legend.position = "none") +
  xlab("User ideology") +
  ylab("Freq. followers same ideology")
gg_follower_same
ggsave(gg_follower_same, filename = paste0(outpath_ideology, "follower_same_ideology.pdf"), width = 45, height = 45, units = "mm", dpi = 400)


####################
# Plot: Same ideology follow composition by news source
####################
gg_follower_dist <- ggplot(user_data, aes(x = followers_conservative_freq)) +
  geom_histogram(fill = plot_color, color = plot_color, binwidth = 0.01, size = 1) +
  scale_x_continuous(breaks = seq(0, 1, 0.5)) +
  xlab("Freq. of conservative followers") +
  theme_ctokita() +
  theme(legend.position = "none") +
  facet_wrap(~news_source)
gg_follower_dist
ggsave(gg_follower_dist, filename = paste0(outpath_ideology, "follower_conservative_bynewssource.pdf"), width = 90, height = 90, units = "mm", dpi = 400)

