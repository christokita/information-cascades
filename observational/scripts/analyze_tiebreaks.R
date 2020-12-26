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

# Simple fixed effects linear model (compare information ecosystems to each other)
lm_infoecosystem_comp <- lm(delta_tiebreak_freq ~ info_ecosystem, data = tiebreak_data)
summary(lm_infoecosystem_comp) # low-correlation is significantly different than zero (but not different from high-correlation)

# T test
low_corr <- tiebreak_data$delta_tiebreak_freq[tiebreak_data$info_ecosystem == "Low correlation"]
high_corr <- tiebreak_data$delta_tiebreak_freq[tiebreak_data$info_ecosystem == "High correlation"]
t.test(low_corr, high_corr, alternative = "greater")

# calculate effect size of group difference
M_lowcorr <- lm_infoecosystem_comp$coefficients[1]
M_highcorr <- lm_infoecosystem_comp$coefficients[1] + lm_infoecosystem_comp$coefficients[2]
sd_pop <- sd(tiebreak_data$delta_tiebreak_freq, na.rm = T)
effect_size <- (M_lowcorr - M_highcorr) / sd_pop
library(pwr)
n_groups <- tiebreak_data %>% 
  filter(!is.na(delta_tiebreak_freq)) %>% 
  group_by(info_ecosystem) %>% 
  count()
n_lowcorr <- n_groups$n[n_groups$info_ecosystem == "Low correlation"]
n_highcorr <- n_groups$n[n_groups$info_ecosystem == "High correlation"]
pwr.t2n.test(n1 = n_lowcorr,
             n2 = n_highcorr,
             d = effect_size,
             sig.level = 0.05,
             alternative = "greater")

pwr.t.test(d = effect_size,
           sig.level = 0.05,
           power = 0.8,
           alternative = "greater")


####################
# Bayesian group mean estimation
####################
# Compute bayesian estimation
file_fit_infoeco <- paste0(dir_brms_fits, "infoeco_relfreq.rds")
if (file.exists(file_fit_infoeco)) {
  blm_infoecosystem <- readRDS(file_fit_infoeco)
} else {
  prior <- c(set_prior("normal(0, 0.3)", class = "b")) #population mean = 0.0156, sd = 0.3195
  blm_infoecosystem <- brm(bf(delta_tiebreak_freq ~ 0 + info_ecosystem), 
                           data = tiebreak_data,
                           prior = prior, 
                           family = gaussian(),
                           sample_prior = TRUE,
                           warmup = 5000, 
                           chains = 4, 
                           iter = 15000)
  saveRDS(blm_infoecosystem, file = file_fit_infoeco)
}

# Hypothesis test that each group's mean is different than zero
hypothesis(blm_infoecosystem, "info_ecosystemLowcorrelation > 0") #prob = 1, BF = 887.89
hypothesis(blm_infoecosystem, "info_ecosystemHighcorrelation > 0") #prob = 0.78, BF = 3.45

# Plot posterior estimates of each group
posterior_infoecosystem <- posterior_samples(blm_infoecosystem)
posterior_infoecosystem_estimates <- posterior_infoecosystem %>% 
  gather("info_ecosystem", "posterior_sample") %>% 
  filter(info_ecosystem %in% c("b_info_ecosystemLowcorrelation", "b_info_ecosystemHighcorrelation")) %>% 
  mutate(info_ecosystem = gsub("b_info_ecosystem", "", info_ecosystem),
         info_ecosystem = gsub("correlation", " correlation", info_ecosystem),
         info_ecosystem = factor(info_ecosystem, levels = c("Low correlation", "High correlation")))
gg_infoeco_post <- ggplot(posterior_infoecosystem_estimates, aes(x = posterior_sample, fill = info_ecosystem, group = info_ecosystem)) +
  geom_density(alpha = 0.6, color = NA) +
  # geom_histogram(position = "identity", alpha = 0.6, binwidth = 0.5, aes(y = stat(count) / sum(count))) +
  xlab("Relative frequency\ncross-ideology unfollows") +
  ylab("Posterior probability density") +
  scale_fill_manual(name = "Information\necosystem",
                    values = info_corr_pal) +
  theme_ctokita()
gg_infoeco_post
ggsave(gg_infoeco_post, filename = paste0(outpath_tiebreaks, "posteriorest_relativefreq_infoeco.pdf"), width = 70, height = 45, units = "mm")

# Hypothesis test that Low_correlation > high_correlation ecoystem
hypothesis_infoecosystem <- hypothesis(blm_infoecosystem, "info_ecosystemLowcorrelation > info_ecosystemHighcorrelation")
hypothesis_infoecosystem$hypothesis$Post.Prob

# Plot posterior of group difference
posterior_infoeco_contrast <- posterior_infoecosystem %>% 
  rename(low_correlation = b_info_ecosystemLowcorrelation,
         high_correlation = b_info_ecosystemHighcorrelation) %>% 
  select(low_correlation, high_correlation) %>% 
  mutate(group_contrast = high_correlation - low_correlation,
         greater_than_zero = group_contrast > 0)
gg_infoeco_contrast <- ggplot(posterior_infoeco_contrast, aes(x = group_contrast, fill = greater_than_zero)) +
  # geom_density(aes(y=..count../sum(..count..)), ) +
  geom_histogram(aes(y=..count../sum(..count..)),
                 breaks = seq(-0.075, 0.075, 0.0025),
                 color = NA, alpha = 0.6) +
  geom_vline(xintercept = 0, color = "white", size = 0.6) +
  geom_vline(xintercept = 0, color = "grey70", size = 0.3, linetype = "dotted") +
  xlab("Est. difference in group mean") +
  ylab(expression(paste("Pr(", mu[high], " - ", mu[low], ")"))) +
  scale_x_continuous(limits = c(-0.08, 0.08),
                     breaks = seq(-0.12, 0.12, 0.04)) +
  scale_y_continuous(limits = c(0, 0.1), breaks = seq(0, 0.2, 0.05)) +
  scale_fill_manual(values = info_corr_pal) +
  theme_ctokita() +
  theme(legend.position = "none",
        aspect.ratio = NULL)
gg_infoeco_contrast
ggsave(gg_infoeco_contrast, filename = paste0(outpath_tiebreaks, "posteriordiff_relativefreq_infoeco.pdf"), width = 45, height = 45, units = "mm")



######################### Analysis: Cross-ideology unfollows by NEWS SOURCE #########################


####################
# Frequentist group mean estimation
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
# Bayesian group mean estimation
####################
# Compute bayesian estimation
file_fit_newssource <- paste0(dir_brms_fits, "newssource_relfreq.rds")
if (file.exists(file_fit_newssource)) {
  blm_newssource <- readRDS(file_fit_newssource)
} else {
  prior <- c(set_prior("normal(0, 0.3)", class = "b")) #population mean = 0.0156, sd = 0.3195
  blm_newssource <- brm(bf(delta_tiebreak_freq ~ 0 + news_source), 
                           data = tiebreak_data,
                           prior = prior, 
                           family = gaussian(),
                           sample_prior = TRUE,
                           warmup = 5000, 
                           chains = 4, 
                           iter = 15000)
  saveRDS(blm_newssource, file = file_fit_newssource)
}

# Hypothesis test that each group's mean is different than zero
hypothesis(blm_newssource, "news_sourceusatoday > 0") #prob = 0.36, BF = 0.57
hypothesis(blm_newssource, "news_sourcecbsnews > 0") #prob = 0.92, BF = 10.79
hypothesis(blm_newssource, "news_sourcedcexaminer > 0") #prob = 0.97, BF = 29.86
hypothesis(blm_newssource, "news_sourcevoxdotcom > 0") #prob = 0.99, BF = 148.25

# Plot posterior estimates of each group
posterior_newssource <- posterior_samples(blm_newssource)
posterior_newssource_estimates <- posterior_newssource %>% 
  gather("news_source", "posterior_sample") %>% 
  filter(news_source %in% c("b_news_sourcevoxdotcom", "b_news_sourcecbsnews", "b_news_sourceusatoday", "b_news_sourcedcexaminer")) %>% 
  mutate(news_source = gsub("b_news_source", "", news_source))
gg_newssource_post <- ggplot(posterior_newssource_estimates, aes(x = posterior_sample, fill = news_source, group = news_source)) +
  geom_density(alpha = 0.6, color = NA) +
  # geom_histogram(position = "identity", alpha = 0.6, binwidth = 0.5, aes(y = stat(count) / sum(count))) +
  xlab("Relative frequency\ncross-ideology unfollows") +
  ylab("Posterior probability density") +
  # scale_fill_manual(name = "Information\necocystem",
  #                   values = info_corr_pal) +
  theme_ctokita()
gg_newssource_post

# Hypothesis test that low corr is higher than higher corr for given ideology group
hypothesis(blm_newssource, "news_sourcevoxdotcom > news_sourcecbsnews") #prob = 0.78, BF = 3.6
hypothesis(blm_newssource, "news_sourcedcexaminer > news_sourceusatoday") #prob = 0.93, BF = 14.15

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





