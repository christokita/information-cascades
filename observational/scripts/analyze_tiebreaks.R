########################################
# Created on Wed Dec 02 16:32:00 2020
# @author: ChrisTokita
#
# SCRIPT
# Analyze the pattern of same- and opposite- ideology tie breaks
########################################

####################
# Load pacakges and data
####################
library(ggplot2)
library(dplyr)
library(tidyr)
library(brms)
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
dir_compiled_data <- paste0(data_directory, "data_derived/_analysis/") #save compiled data set
dir_brms_fits <- paste0(dir_compiled_data, "brms_fits/") #save our brms fits

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
         followers_conservative_freq = follower_conservative_n / n_follower_samples) #MLE estimate

# Bayesian estimate of follower ideology
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
tiebreak_data <- merge(monitored_users, ideology_mix) %>% 
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
         tiebreak_sameideol_freq = NA,
         tiebreak_diffideol_n = NA,
         tiebreak_sameideol_n = NA)
tiebreak_data$n_tiebreaks[is.na(tiebreak_data$n_tiebreaks)] <- 0

# Calculate same vs. opposite ideology freq of followers, tie breaks
liberal_users <- tiebreak_data$ideology_corresp < 0
conservative_users <- tiebreak_data$ideology_corresp > 0

tiebreak_data$followers_diffideol_freq[liberal_users] <- tiebreak_data$followers_conservative_freq[liberal_users]
tiebreak_data$followers_sameideol_freq[liberal_users] <- tiebreak_data$followers_liberal_freq[liberal_users]
tiebreak_data$followers_diffideol_freq[conservative_users] <- tiebreak_data$followers_liberal_freq[conservative_users]
tiebreak_data$followers_sameideol_freq[conservative_users] <- tiebreak_data$followers_conservative_freq[conservative_users]

tiebreak_data$followers_diffideol_est[liberal_users] <- tiebreak_data$followers_conservative_est[liberal_users]
tiebreak_data$followers_sameideol_est[liberal_users] <- tiebreak_data$followers_liberal_est[liberal_users]
tiebreak_data$followers_diffideol_est[conservative_users] <- tiebreak_data$followers_liberal_est[conservative_users]
tiebreak_data$followers_sameideol_est[conservative_users] <- tiebreak_data$followers_conservative_est[conservative_users]

tiebreak_data$tiebreak_diffideol_freq[liberal_users] <- tiebreak_data$tiebreak_conservative_freq[liberal_users]
tiebreak_data$tiebreak_diffideol_freq[conservative_users] <- tiebreak_data$tiebreak_liberal_freq[conservative_users]
tiebreak_data$tiebreak_sameideol_freq[liberal_users] <- tiebreak_data$tiebreak_liberal_freq[liberal_users]
tiebreak_data$tiebreak_sameideol_freq[conservative_users] <- tiebreak_data$tiebreak_conservative_freq[conservative_users]

tiebreak_data$tiebreak_diffideol_n[liberal_users] <- tiebreak_data$tiebreak_conservative_n[liberal_users]
tiebreak_data$tiebreak_diffideol_n[conservative_users] <- tiebreak_data$tiebreak_liberal_n[conservative_users]
tiebreak_data$tiebreak_sameideol_n[liberal_users] <- tiebreak_data$tiebreak_liberal_n[liberal_users]
tiebreak_data$tiebreak_sameideol_n[conservative_users] <- tiebreak_data$tiebreak_conservative_n[conservative_users]

####################
# Prep data: calcualte expected frequency of diff ideology tie breaks (same ideology breaks will be mirror image)
#################### 
tiebreak_data <- tiebreak_data %>% 
  # Calcualte expected number of breaks given follower ideol composition (raw or bayesian estiamte)
  mutate(tiebreak_diffideol_expected = followers_diffideol_freq * n_tiebreaks,
         tiebreak_diffideol_expected_est = followers_diffideol_est * n_tiebreaks) %>% 
  # Calcualte delta between expected and actual tie break number/frequency
  mutate(delta_tiebreak_n = tiebreak_diffideol_n - tiebreak_diffideol_expected,
         delta_tiebreak_n_est = tiebreak_diffideol_n - tiebreak_diffideol_expected_est,
         delta_tiebreak_freq = tiebreak_diffideol_freq - followers_diffideol_freq,
         delta_tiebreak_freq_est = tiebreak_diffideol_freq - followers_diffideol_est)

# SAVE
save(tiebreak_data, file = paste0(dir_compiled_data, "tiebreak_data.Rdata"))



######################### Analysis: Cross-ideology unfollows by INFORMATION ECOSYSTEM #########################

####################
# Frequentist group mean estimation
####################
# Simple fixed effects linear model (test whether different than zero)
lm_infoecosystem <- lm(delta_tiebreak_freq ~ 0 + info_ecosystem, data = tiebreak_data)
summary(lm_infoecosystem) # low-correlation is significantly different than zero (but not different from high-correlation)
anova(lm_infoecosystem)


####################
# Bayesian group mean estimation
####################
# Compute bayesian estimation
file_fit_infoeco <- paste0(dir_brms_fits, "infoeco_relfreq.rds")
if (file.exists(file_fit_infoeco)) {
  blm_infoecosystem <- readRDS(file_fit_infoeco)
} else {
  prior <- c(set_prior("normal(0, 1)", class = "b"))
  blm_infoecosystem <- brm(delta_tiebreak_freq ~ 0 + info_ecosystem, 
                           data = tiebreak_data,
                           prior = prior, 
                           sample_prior = TRUE,
                           warmup = 1000, 
                           chains = 2, 
                           iter = 4000)
  saveRDS(blm_infoecosystem, file = file_fit_infoeco)
}



# Hypothesis test that Low_correlation > high_correlation ecoystem
hypothesis(blm_infoecosystem, "info_ecosystemLowcorrelation > 0")
hypothesis(blm_infoecosystem, "info_ecosystemHighcorrelation > 0")


# Hypothesis test that Low_correlation > high_correlation ecoystem
hypothesis_infoecosystem <- hypothesis(blm_infoecosystem, "info_ecosystemLowcorrelation > info_ecosystemHighcorrelation")
hypothesis_infoecosystem$hypothesis$Post.Prob

# Plot posterior estimates
posterior_infoecosystem <- posterior_samples(blm_infoecosystem)
posterior_infoecosystem_estimates <- posterior_infoecosystem %>% 
  gather("info_ecosystem", "posterior_sample") %>% 
  filter(info_ecosystem %in% c("b_info_ecosystemLowcorrelation", "b_info_ecosystemHighcorrelation")) %>% 
  mutate(info_ecosystem = gsub("b_info_ecosystem", "", info_ecosystem)) %>% 
  mutate(info_ecosystem = gsub("correlation", " correlation", info_ecosystem)) %>% 
  mutate(info_ecosystem = factor(info_ecosystem, levels = c("Low correlation", "High correlation")))
gg_infoeco_post <- ggplot(posterior_infoecosystem_estimates, aes(x = posterior_sample, fill = info_ecosystem)) +
  geom_density(alpha = 0.6, color = NA) +
  # geom_histogram(position = "identity", alpha = 0.6, binwidth = 0.0025, stat = "density") +
  xlab("Relative frequency\ncross-ideology unfollows") +
  ylab("Density of posterior estimate") +
  scale_fill_manual(values = info_corr_pal) +
  theme_ctokita()
gg_infoeco_post
ggsave(gg_infoeco_post, filename = paste0(outpath_tiebreaks, "posteriorest_relativefreq_infoeco.pdf"), width = 70, height = 45, units = "mm")


######################### Analysis: Cross-ideology unfollows by NEWS SOURCE #########################


####################
# Analyze: relative cross-ideology tiebreak occurence vs. news source
####################
# Simple fixed effects linear model
lm_newssource <- lm(delta_tiebreak_freq ~ news_source - 1, data = tiebreak_data)
summary(lm_newssource) # vox siginfincalty positive, dc examiner approach significance
anova(lm_newssource)

# Mixed effects model, treating ideological extremity as random effect
lmm_newsideol <- lmer(delta_tiebreak_freq ~ news_source + (1|ideology_extremity_bin) - 1, data = tiebreak_data)
summary(lmm_newsideol)
confint(lmm_newsideol)


####################
# Futher exploration for now...
####################
ggplot(data = tiebreak_data, aes(x = tiebreak_diffideol_expected, y = tiebreak_diffideol_n) ) +
  geom_point(alpha = 0.4, stroke = 0) +
  geom_abline(aes(intercept = 0, slope = 1)) +
  theme_ctokita() +
  facet_wrap(~info_ecosystem)

# Analyze by ideology extremity
lm_ideolextreme <- lm(delta_tiebreak_freq ~ ideology_extremity, data = tiebreak_data)
summary(lm_ideolextreme) # intercept not significant, ideology_extremity is significant
anova(lm_ideolextreme)

# Analyze by info ecosystem and ideology extremity
lm_infoideol <- lm(delta_tiebreak_freq ~ info_ecosystem + ideology_extremity + ideology_extremity:info_ecosystem - 1, data = tiebreak_data)
summary(lm_infoideol) # only i





