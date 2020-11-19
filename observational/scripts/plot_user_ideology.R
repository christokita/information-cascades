########################################
# Created on Thu Aug 25 17:53:00 2020
# @author: ChrisTokita
#
# SCRIPT
# Quick plot of ideology scores of our monitored users
########################################

####################
# Load pacakges and data
####################
library(ggplot2)
library(dplyr)
library(tidyr)
source("_plot_themes/theme_ctokita.R")

# High-level data directory
data_directory <- "/Volumes/CKT-DATA/information-cascades/observational/" #path to external HD
#data_directory <- "empirical/" #path if done within local directory

# File paths
ideology_file <- paste0(data_directory, 'data_derived/monitored_users/monitored_users_ideology_scores.csv')
all_user_file <- paste0(data_directory, 'data_derived/monitored_users/monitored_users_preliminary.csv')
monitored_user_file <- paste0(data_directory, 'data_derived/monitored_users/monitored_users_final.csv')
outpath <- "observational/output/ideology/"

# Load data
users_ideology <- read.csv(ideology_file, colClasses = c("user_id"="character")) %>% 
  mutate(user_id = gsub("\"", "", user_id_str))
all_users <- read.csv(all_user_file, colClasses = c("user_id"="character")) %>% 
  mutate(user_id = gsub("\"", "", user_id_str))
final_users <- read.csv(monitored_user_file, colClasses = c("user_id"="character")) %>% 
  mutate(user_id = gsub("\"", "", user_id_str))
all_users_ideology <- merge(users_ideology, all_users[c("user_id", "news_source")], all = T) %>% 
  mutate(ideology_category = ifelse(ideology_corresp < 0, "Liberal", 
                                    ifelse(ideology_corresp > 0, "Conservative", NA)),  #add categorical label based on C.A. ideology score
         news_source = factor(news_source, levels = c("voxdotcom", "cbsnews", "usatoday", "dcexaminer")))
final_users_ideology <- merge(final_users[c("user_id", "news_source")], users_ideology, all.x = T) %>% 
  mutate(ideology_category = ifelse(ideology_corresp < 0, "Liberal", 
                                    ifelse(ideology_corresp > 0, "Conservative", NA)),  #add categorical label based on C.A. ideology score
         news_source = factor(news_source, levels = c("voxdotcom", "cbsnews", "usatoday", "dcexaminer")))

# Parameters for plots
plot_color <- "#1B3B6F"
ideol_pal <- c("#006195", "#d9d9d9", "#d54c54")



######################### Plot/Analyze: All sampled users #########################

####################
# Compare old scores to new scores (we repulled ideology scores ~1 week later)
####################
old_scores <-read.csv(paste0(data_directory, 'data_derived/monitored_users/old_data/monitored_users_ideology_scores_2020-08-23.csv')) %>% 
  select(user_id_str, ideology_mle, ideology_corresp) %>% 
  rename(old_mle = ideology_mle, old_corresp = ideology_corresp)

score_check <- merge(users_ideology, old_scores, by = "user_id_str")

ggplot(score_check, aes(x = old_mle, ideology_mle)) +
  geom_hline(yintercept = 0, size = 0.3, linetype = "dashed") +
  geom_vline(xintercept = 0, size = 0.3, linetype = "dashed") +
  geom_point(size = 1, alpha = 0.3, stroke = 0, color = plot_color) +
  xlab("First MLE ideology score") +
  ylab("Second MLE ideology score") +
  theme_ctokita()

ggplot(score_check, aes(x = old_corresp, ideology_corresp)) +
  geom_hline(yintercept = 0, size = 0.3, linetype = "dashed") +
  geom_vline(xintercept = 0, size = 0.3, linetype = "dashed") +
  geom_point(size = 1, alpha = 0.3, stroke = 0, color = plot_color) +
  xlab("First C.A. ideology score") +
  ylab("Second C.A. ideology score") +
  theme_ctokita()

####################
# Compare two methods of ideology estimation (across all sampled users)
####################
# Plot hitograms of each
gg_ideology_mle <- ggplot(data = users_ideology, aes(x = ideology_mle, fill = ..x..)) +
  geom_histogram(bins = 30) +
  xlab("Ideology") +
  scale_fill_gradientn(colors = ideol_pal, limits = c(-3, 3), oob = scales::squish, guide = FALSE) +
  ggtitle("Bayesian ideal point") +
  theme_ctokita() +
  theme(aspect.ratio = NULL,
        plot.title = element_text(size = 9))

gg_ideology_corresp <- ggplot(data = users_ideology, aes(x = ideology_corresp, fill = ..x..)) +
  geom_histogram(bins = 30) +
  xlab("Ideology") +
  scale_fill_gradientn(colors = ideol_pal, limits = c(-1.75, 1.75), oob = scales::squish, guide = FALSE) +
  ggtitle("Correspondence analysis") +
  theme_ctokita() +
  theme(aspect.ratio = NULL,
        plot.title = element_text(size = 9))

gg_ideology_hists <- gridExtra::arrangeGrob(gg_ideology_mle, gg_ideology_corresp, ncol = 1)
ggsave(gg_ideology_hists, filename = paste0(outpath, "ideology_distribution_by_method.pdf"), width = 90, height = 90, units = "mm", dpi = 400)

# Scatter plot against each other
gg_compare_ideology_scores <- ggplot(data = users_ideology, aes(x = ideology_mle, y = ideology_corresp)) +
  geom_point(size = 0.5, alpha = 0.3, stroke = 0, color = plot_color) +
  geom_abline(intercept = 0, slope = 1, size = 0.3, linetype = "dashed") + 
  scale_x_continuous(limits = c(-4, 4)) +
  xlab("Ideology, bayesian ideal point") +
  ylab("Ideology, correspond. analysis") +
  theme_ctokita()
gg_compare_ideology_scores
ggsave(gg_compare_ideology_scores, filename = paste0(outpath, "compare_estimation_methods.pdf"), width = 45, height = 45, units = "mm", dpi = 400)


####################
# Compare user ideology by news source and ideology method (across all sampled users)
####################
# Plot histograms
gg_ideology_by_outletmethod <- all_users_ideology %>% 
  select(user_id, ideology_mle, ideology_corresp, news_source) %>% 
  gather("metric", "ideology", -user_id, -news_source) %>% 
  mutate(metric = ifelse(metric == "ideology_mle", "Bayesian", "C.A.")) %>% 
  ggplot(., aes(x = ideology, fill = ..x..)) +
  geom_histogram(bins = 30) +
  scale_fill_gradientn(colors = ideol_pal, limits = c(-2, 2), oob = scales::squish, guide = FALSE) +
  theme_ctokita() +
  facet_grid(metric~news_source)
gg_ideology_by_outletmethod
ggsave(gg_ideology_by_outletmethod, filename = paste0(outpath, "method_vs_newssource.pdf"), width = 100, height = 60, units = "mm", dpi = 400)

# Plot only correspondance analysis method (what we use in this study)
gg_ideology_by_outlet <- all_users_ideology %>%
  mutate(info_ecosystem = ifelse(news_source %in% c("cbsnews", "usatoday"), "High corr.", "Low corr."),
         news_outlet_ideology = ifelse(news_source %in% c("cbsnews", "voxdotcom"), "Liberal", "Conservative")) %>% 
  mutate(news_outlet_ideology = factor(news_outlet_ideology, levels = c("Liberal", "Conservative"))) %>% 
  ggplot(., aes(x = ideology_corresp, fill = ..x.., color = ..x..)) +
  geom_histogram(binwidth = 0.2, size = 0.05) +
  ylab("Count") +
  xlab("User ideology") +
  scale_fill_gradientn(name = "Twitter user ideology",
                       colors = ideol_pal, 
                       limits = c(-2, 2), 
                       oob = scales::squish) +
  scale_color_gradientn(name = "Twitter user ideology",
                        colors = ideol_pal, 
                        limits = c(-2, 2), 
                        oob = scales::squish) +
  scale_x_continuous(breaks = seq(-2, 2, 2)) +
  scale_y_continuous(limits = c(0, 600),
                     breaks = seq(0, 600, 200),
                     expand = c(0, 0)) +
  theme_ctokita() +
  theme(strip.text.x = element_blank(),
        legend.position = "none") +
  facet_grid(info_ecosystem~news_outlet_ideology)
gg_ideology_by_outlet
ggsave(gg_ideology_by_outlet, filename = paste0(outpath, "sampledusers_ideology_bynewssource.pdf"), width = 50, height = 40, units = "mm", dpi = 400)


# Count up liberal and conservative users by new source and method
# NOTE: After conversations with Andy Guess--who also consulted Pablo Barbera--we will use the correspondance analysis scores
ideology_count <- all_users_ideology %>% 
  select(user_id, ideology_mle, ideology_corresp, news_source) %>% 
  gather("metric", "ideology", -user_id, -news_source) %>% 
  mutate(metric = ifelse(metric == "ideology_mle", "Bayesian", "C.A.")) %>% 
  group_by(news_source, metric) %>% 
  summarise(liberals = sum(ideology < 0, na.rm = TRUE),
            conservatives = sum(ideology > 0, na.rm = TRUE)) %>% 
  mutate(total_ideol_scores = liberals + conservatives) %>% 
  arrange(metric, news_source)


######################### Plot/Analyze: Final set of monitored users #########################

####################
# Plot: histogram of monitored user ideology
####################
gg_user_ideology <- ggplot(final_users_ideology, aes(x = ideology_corresp, fill = ..x..)) +
  geom_histogram(binwidth = 0.2) +
  scale_fill_gradientn(colors = ideol_pal, limits = c(-2, 2), oob = scales::squish, guide = FALSE) +
  theme_ctokita() +
  theme(legend.position = "none",
        strip.text = element_text(size = 6)) +
  facet_wrap(~news_source, dir = "v")
gg_user_ideology
ggsave(gg_user_ideology, filename = paste0(outpath, "user_ideology_bynewssource.pdf"), width = 45, height = 45, units = "mm", dpi = 400)
