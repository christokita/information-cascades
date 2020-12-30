########################################
# Created on Mon Dec 21 14:51:00 2020
# @author: ChrisTokita
#
# SCRIPT
# Plot analysis of our monitored news sources (e.g., estimated gamma)
########################################

####################
# Load pacakges and data
####################
library(ggplot2)
library(dplyr)
library(tidyr)
library(RColorBrewer)
source("_plot_themes/theme_ctokita.R")

# High-level data directory
data_directory <- "/Volumes/CKT-DATA/information-cascades/observational/" #path to external HD

# File paths
news_gamma_file <- paste0(data_directory, 'data_derived/news_source_tweets/estimated_gamma_cosinesim.csv')
assort_file <- "model/data_derived/network_break/social_networks/assortativity.csv" #path to file containing assortativity data
network_data_dir <- "model/data_derived/network_break/social_networks/network_change/" #path to directory containing network change data
outpath <- "observational/output/news_sources/"

# Load news data
news_correlations <- read.csv(news_gamma_file) %>%
  mutate(news_source = tolower(news_source)) %>% 
  mutate(ideology = ifelse(news_source %in% c("cbsnews", "voxdotcom"), "Liberal",
                            ifelse(news_source %in% c("usatoday", "dcexaminer"), "Conservative", "Baseline")),
         info_ecosystem = ifelse(news_source %in% c("cbsnews", "usatoday"), "High correlation", 
                                  ifelse(news_source %in% c("voxdotcom", "dcexaminer"), "Low correlation", "Baseline"))) %>% 
  mutate(info_ecosystem = factor(info_ecosystem, levels = c("Low correlation", "High correlation")), 
         news_source = factor(news_source, levels = c("voxdotcom", "cbsnews", "usatoday", "dcexaminer", "ap", "reuters")),
         ideology = factor(ideology, levels = c("Liberal", "Conservative")))

# Parameters for plots
plot_color <- "#1B3B6F"
pal_type <- "#495867"
ideol_pal <- c("#006195", "#d9d9d9", "#d54c54")
news_pal <- c("#006195", "#829bb7", "#df9694", "#d54c54", "grey", "grey")
info_corr_pal <- brewer.pal(5, "PuOr")[c(1, 5)]


####################
# Load data
####################
# Load news data
news_correlations <- read.csv(news_gamma_file) %>%
  mutate(news_source = tolower(news_source)) %>% 
  mutate(ideology = ifelse(news_source %in% c("cbsnews", "voxdotcom"), "Liberal",
                           ifelse(news_source %in% c("usatoday", "dcexaminer"), "Conservative", "Baseline")),
         info_ecosystem = ifelse(news_source %in% c("cbsnews", "usatoday"), "High correlation", 
                                 ifelse(news_source %in% c("voxdotcom", "dcexaminer"), "Low correlation", "Baseline"))) %>% 
  mutate(info_ecosystem = factor(info_ecosystem, levels = c("Low correlation", "High correlation")), 
         news_source = factor(news_source, levels = c("voxdotcom", "cbsnews", "usatoday", "dcexaminer", "ap", "reuters")),
         ideology = factor(ideology, levels = c("Liberal", "Conservative")))

monitored_news <- news_correlations %>% 
  filter(news_source %in% c("voxdotcom", "cbsnews", "usatoday", "dcexaminer"))

# Load assortativity data
assort_data <- read.csv(assort_file, header = TRUE)
assort_sum <- assort_data %>% 
  mutate(assort_type_delta = assort_type_final - assort_type_initial,
         assort_thresh_delta = assort_thresh_final - assort_thresh_initial) %>% 
  select(-replicate) %>% 
  gather(metric, value, -gamma) %>% 
  group_by(gamma, metric) %>% 
  summarise(mean = mean(value),
            sd = sd(value),
            ci95 = qnorm(0.975) * sd(value)/ sqrt( sum(!is.na(value)) ))


####################
# Plot estimated correlation values
####################
gg_est_gamma <- monitored_news %>% 
  mutate(news_source = factor(news_source, levels = c("voxdotcom", "dcexaminer", "cbsnews", "usatoday"))) %>% 
  ggplot(., aes(y = news_source, x = estimated_gamma, color = news_source)) +
  geom_vline(aes(xintercept = 0), size = 0.3, linetype = "dotted") +
  geom_segment(aes(yend = news_source, xend = 0), size = 0.3) +
  geom_point(size = 1.5) +
  # geom_bar(stat = "identity") +
  scale_x_continuous(breaks = seq(-1, 1, 0.2), 
                     limits = c(-1, 1),
                     expand = c(0, 0)) +
  scale_y_discrete(labels = c("Vox", "Washington Examiner", "CBS News", "USA Today")) +
  scale_color_manual(values = news_pal[c(1, 4, 2, 3)],
                     guide = FALSE) +
  ylab("News source") +
  xlab(expression( paste("Estimated ", italic(gamma)) )) +
  theme_ctokita() +
  theme(aspect.ratio = NULL,
        axis.title.y = element_blank())
gg_est_gamma

ggsave(gg_est_gamma, filename = paste0(outpath, "estimated_gamma.pdf"), width = 90, height = 45, units = "mm", dpi = 400)


####################
# Plot estimated correlation values over predicted model assortativity
####################
assort_type <- assort_sum %>% 
  filter(metric == "assort_type_final")
gg_assort_with_news <- ggplot(data = assort_type, aes(x = gamma, y = mean)) +
  # Plot news source estimates
  geom_vline(data = monitored_news, aes(xintercept = estimated_gamma, color = news_source), 
             size = 0.6, alpha = 0.8) +
  # Plot assort data
  geom_hline(aes(yintercept = 0), 
             size = 0.3, 
             linetype = "dotted") +
  geom_ribbon(aes(ymin = mean - sd, ymax = mean + sd),
              alpha = 0.4,
              fill = pal_type) +
  geom_line(size = 0.3, color = pal_type) +
  geom_point(size = 0.8, color = pal_type) +
  # Plot parameters
  ylab("Ideological assortativity") +
  xlab(expression( paste("Information ecosystem ", italic(gamma)) )) +
  scale_y_continuous(limits = c(-0.04, 0.43)) + 
  scale_color_manual(name = "",
                     values = news_pal,
                     guide = FALSE) +
  theme_ctokita() 
gg_assort_with_news

ggsave(gg_assort_with_news, filename = paste0(outpath, "model_assort_with_newsestimantes.pdf"), width = 45, height = 45, units = "mm", dpi = 400)


####################
# Plot estimated correlation values over predicted model tie breaks
####################
# Load data and summarise
network_files <- list.files(network_data_dir, full.names = TRUE)
network_change_data <- lapply(network_files, function(x) {
  # Read in file 
  run_file <- read.csv(x) %>% 
    mutate(net_same = same_type_adds - same_type_breaks,
           net_diff = diff_type_adds - diff_type_breaks,
           net_degree = degree - degree_initial,
           net_centrality = centrality - centrality_initial)
  return(run_file)
})
network_change_data <- do.call("rbind", network_change_data) 

#Summarize
network_change_sum <- network_change_data %>% 
  gather(metric, value, -gamma, -replicate, -individual, -type, -threshold) %>% 
  select(-replicate, -individual, -type, -threshold) %>% 
  group_by(gamma, metric) %>% 
  summarise(mean = mean(value), 
            sd = sd(value),
            error = qnorm(0.975)*sd(value)/sqrt(length(value)))
ties_data <- network_change_sum %>% 
  filter(metric %in% c("diff_type_adds", "diff_type_breaks", "same_type_adds", "same_type_breaks")) %>% 
  mutate(metric = factor(metric, levels = c("same_type_adds", "same_type_breaks", "diff_type_adds", "diff_type_breaks")))


gg_breaks <- ties_data %>% 
  filter(grepl("breaks", metric)) %>% 
  ggplot(., aes(x = gamma, y = mean, group = metric)) +
  # Plot news source estimates
  geom_vline(data = monitored_news, aes(xintercept = estimated_gamma, color = news_source), 
             size = 0.6, alpha = 0.8) +
  # Plot tie break data
  geom_ribbon(aes(ymax = mean + error, ymin = mean - error), 
              alpha = 0.2,
              fill = pal_type) +
  geom_line(size = 0.3, color = pal_type) +
  geom_point(aes(shape = metric, fill = metric),
             size = 1, color = pal_type) +
  # Plot parameters
  ylab("Number of broken ties") +
  xlab(expression( paste("Information ecosystem ", italic(gamma)) )) +
  scale_y_continuous(limits = c(0, 3),
                     breaks = seq(0, 3, 0.5),
                     expand = c(0, 0)) +
  scale_shape_manual(values = c(21, 21),
                     labels = c("Same ideology",
                                "Diff. ideology"),
                     name = "") +
  scale_fill_manual(values = c("black", "white"),
                    labels = c("Same ideology",
                               "Diff. ideology"),
                    name = "") +
  scale_color_manual(name = "",
                     values = news_pal,
                     guide = FALSE) +
  theme_ctokita()
gg_breaks

ggsave(gg_breaks, filename = paste0(outpath, "model_tiebreaks_with_newsestimantes.pdf"), width = 70, height = 45, units = "mm", dpi = 400)

