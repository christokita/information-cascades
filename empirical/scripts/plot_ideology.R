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
data_directory <- "/Volumes/CKT-DATA/information-cascades/empirical/" #path to external HD
#data_directory <- "empirical/" #path if done within local directory

# File paths
ideology_file <- paste0(data_directory, 'data_derived/monitored_users/monitored_users_ideology_scores.csv')
user_file <- paste0(data_directory, 'data_derived/monitored_users/monitored_users_preliminary.csv')
outpath <- "empirical/output/ideology/"

# Load data
users_ideology <- read.csv(ideology_file, colClasses = c("user_id"="character")) %>% 
  mutate(user_id = gsub("\"", "", user_id_str))
users <- read.csv(user_file, colClasses = c("user_id"="character")) %>% 
  mutate(user_id = gsub("\"", "", user_id_str))
users_ideology <- merge(users_ideology, users[c("user_id", "news_source")], all = T) %>% 
  mutate(ideology_category = ifelse(ideology_corresp < 0, "Liberal", 
                                    ifelse(ideology_corresp > 0, "Conservative", NA))) #add categorical label based on C.A. ideology score
rm(users)


# Parameters for plots
plot_color <- "#1B3B6F"
ideol_pal <- c("#006195", "#d9d9d9", "#d54c54")

####################
# Compare two methods of ideology estimation
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
ggsave(gg_ideology_hists, filename = paste0(outpath, "ideology_distribution_by_method.png"), width = 90, height = 90, units = "mm", dpi = 400)

# Scatter plot against each other
gg_compare_ideology_scores <- ggplot(data = users_ideology, aes(x = ideology_mle, y = ideology_corresp)) +
  geom_point(size = 0.5, alpha = 0.3, stroke = 0, color = plot_color) +
  geom_abline(intercept = 0, slope = 1, size = 0.3, linetype = "dashed") + 
  scale_x_continuous(limits = c(-4, 4)) +
  xlab("Ideology, bayesian ideal point") +
  ylab("Ideology, correspond. analysis") +
  theme_ctokita()
gg_compare_ideology_scores
ggsave(gg_compare_ideology_scores, filename = paste0(outpath, "compare_estimation_methods.png"), width = 45, height = 45, units = "mm", dpi = 400)


####################
# Compare user ideology by news source
####################
# Plot histograms
gg_ideology_by_outlet <- users_ideology %>% 
  select(user_id, ideology_mle, ideology_corresp, news_source) %>% 
  gather("metric", "ideology", -user_id, -news_source) %>% 
  mutate(metric = ifelse(metric == "ideology_mle", "Bayesian", "C.A.")) %>% 
  ggplot(., aes(x = ideology, fill = ..x..)) +
  geom_histogram(bins = 30) +
  scale_fill_gradientn(colors = ideol_pal, limits = c(-2, 2), oob = scales::squish, guide = FALSE) +
  theme_ctokita() +
  facet_grid(metric~news_source)
gg_ideology_by_outlet
ggsave(gg_ideology_by_outlet, filename = paste0(outpath, "method_vs_newssource.png"), width = 100, height = 60, units = "mm", dpi = 400)

# Count up liberal and conservative users by new source and method
ideology_count <- users_ideology %>% 
  select(user_id, ideology_mle, ideology_corresp, news_source) %>% 
  gather("metric", "ideology", -user_id, -news_source) %>% 
  mutate(metric = ifelse(metric == "ideology_mle", "Bayesian", "C.A.")) %>% 
  group_by(news_source, metric) %>% 
  summarise(liberals = length(ideology[ideology < 0]),
            conservatives = length(ideology[ideology > 0])) %>% 
  arrange(metric, news_source)


####################
# Count users of each ideology category (based on C.A. ideology score)
####################
# After conversations with Andy Guess--who also consulted Pablo Barbera--we will use the correspondance analysis scores
ideology_counts <- users_ideology %>% 
  select(news_source, ideology_category) %>% 
  group_by(news_source) %>% 
  summarise(Liberals = sum(ideology_category == "Liberal", na.rm = TRUE),
            Conservatives = sum(ideology_category == "Conservative", na.rm = TRUE))


