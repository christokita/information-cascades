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
library(dplyr)
library(tidyr)
library(brms)
library(RColorBrewer)
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
# Plot: Scatter plot of relative FREQUENCY of cross-ideology breaks (relative to expected by random chance)
####################
gg_infoeco_breaks_freq_raw <- tiebreak_data %>% 
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
# Load bayesian estimate
blm_infoeco_freq <- readRDS(paste0(dir_brms_fits, "infoeco_relfreq.rds"))
posterior_infoeco_freq <- posterior_samples(blm_infoeco_freq) %>% 
  gather("info_ecosystem", "posterior_sample") %>% 
  filter(info_ecosystem %in% c("b_info_ecosystemLowcorrelation", "b_info_ecosystemHighcorrelation")) %>% 
  mutate(info_ecosystem = gsub("b_info_ecosystem", "", info_ecosystem),
         info_ecosystem = gsub("correlation", "\ncorrelation", info_ecosystem),
         info_ecosystem = factor(info_ecosystem, levels = c("Low\ncorrelation", "High\ncorrelation")))

# Get point estimates
infoeco_freq_estimates <- as.data.frame( posterior_summary(blm_infoeco_freq, 
                                                           probs = c(0.05, 0.95), #90% interval
                                                           pars = c("b_info_ecosystemLowcorrelation", "b_info_ecosystemHighcorrelation")) ) %>%  
  tibble::rownames_to_column() %>% 
  rename(info_ecosystem = rowname) %>% 
  mutate(info_ecosystem = gsub("b_info_ecosystem", "", info_ecosystem),
         info_ecosystem = gsub("correlation", "\ncorrelation", info_ecosystem),
         info_ecosystem = factor(info_ecosystem, levels = c("Low\ncorrelation", "High\ncorrelation")))
  mutate()

# Plot: estimates, 90% CI, and posterior
gg_infoeco_breaks_freq <- ggplot(infoeco_freq_estimates, aes(x = info_ecosystem, color = info_ecosystem)) +
  geom_hline(yintercept = 0, linetype = "dotted", size = 0.3) +
  geom_violin(data = posterior_infoeco_freq, 
              aes(y = posterior_sample, fill = info_ecosystem),
              color = NA, alpha = 0.15, width = 0.4) +
  geom_errorbar(aes(ymin = Q5, ymax = Q95), 
                width = 0, 
                size = 0.5) +
  geom_point(aes(y = Estimate), 
             size = 2) + 
  scale_y_continuous(breaks = round(seq(-0.10, 0.10, 0.01), 2), #cuts off edge breaks due to weird float calcualtion of sequence
                     limits = c(-0.02, 0.05), 
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
# Plot: Scatter plot of relative NUMBER of cross-ideology breaks
####################
gg_infoeco_breaks_n_raw <- tiebreak_data %>% 
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
  info_eco_data <- tiebreak_data %>% 
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
gg_newssource_breaks_freq_raw <- tiebreak_data %>% 
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
for (outlet in unique(tiebreak_data$news_source)) {
  newssource_data <- tiebreak_data %>% 
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
gg_newssource_breaks_n_raw <- tiebreak_data %>% 
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
for (outlet in unique(tiebreak_data$news_source)) {
  newssource_data <- tiebreak_data %>% 
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
for (outlet in unique(tiebreak_data$news_source)) {
  ideology <- ifelse(outlet %in% c("cbsnews", "voxdotcom"), "Liberal", "Conservative")
  estimate_unfollows <- estimate_mean(data = tiebreak_data %>% filter(news_source == outlet, n_tiebreaks > 0) %>% .$tiebreak_diffideol_freq, 
                                      mean_prior = 0,
                                      std_prior = 0.5, 
                                      info_ecosystem = unique(tiebreak_data$info_ecosystem), 
                                      ideology = ideology) %>% 
    mutate(measure = "Cross-ideology unfollows")
  estimate_followers <- estimate_mean(data = tiebreak_data %>% filter(news_source == outlet, n_tiebreaks > 0) %>% .$followers_diffideol_freq, 
                                      mean_prior = 0,
                                      std_prior = 0.5, 
                                      info_ecosystem = unique(tiebreak_data$info_ecosystem), 
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
unfollow_ideol_data <- tiebreak_data %>% 
  filter(n_tiebreaks > 0) %>% 
  mutate(relative_tiebreak_ideol = tiebreak_ideol_avg - followers_ideol_avg)

# Bayesian estimate  of unadjusted frequency of cross-ideology unfollows and initial followers
newssource_unfollow_ideology <- data.frame()
for (outlet in unique(tiebreak_data$news_source)) {
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



######################### Analysis: Cross-ideology unfollows linear mixed model #########################

####################
# Analyze: relative cross-ideology tiebreak occurence vs. information ecosystem
####################
# Simple fixed effects linear model (test whether different than zero)
lm_infoecosystem <- lm(delta_tiebreak_freq ~ 0 + info_ecosystem, data = tiebreak_data)
summary(lm_infoecosystem) # low-correlation is significantly different than zero (but not different from high-correlation)
anova(lm_infoecosystem)

# Bayesian approach to T test
prior <- c(set_prior("normal(0, 1)", class = "b"))
blm_infoecosystem <- brm(delta_tiebreak_freq ~ 0 + info_ecosystem, data = tiebreak_data, prior = prior, sample_prior = "yes")
hypothesis_infoecosystem <- hypothesis(blm_infoecosystem, "info_ecosystemLowcorrelation > info_ecosystemHighcorrelation")
hypothesis_infoecosystem
posterior_infoecosystem <- posterior_samples(blm_infoecosystem)
hist(posterior_infoecosystem$b_info_ecosystemHighcorrelation, col = rgb(0,0,1,0.5), xlim=c(-0.03, 0.06), breaks = seq(-0.03, 0.06, 0.0025), border = NA)
hist(posterior_infoecosystem$b_info_ecosystemLowcorrelation, col = rgb(1,0,0,0.5), breaks = seq(-0.03, 0.06, 0.0025), border = NA, add = T)

# Mixed effects model, treating ideological extremity as random effect
lmm_infoideol <- lmer(delta_tiebreak_freq ~ info_ecosystem + (1|ideology_extremity_bin) - 1, data = tiebreak_data)
summary(lmm_infoideol)
confint(lmm_infoideol)

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



