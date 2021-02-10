########################################
# Created on Tues Feb 9 14:41:00 2021
# @author: ChrisTokita
#
# SCRIPT
# Measure the news diet of our 4,000 monitored users
########################################

####################
# Load packages and set important paths
####################
library(ggplot2)
library(RColorBrewer)
library(dplyr)
library(tidyr)
library(brms)
source("_plot_themes/theme_ctokita.R")

# High-level data directory
data_directory <- "/Volumes/CKT-DATA/information-cascades/observational/" #path to external HD

# Paths to/for data
dir_monitored_users_friends = paste0(data_directory, "data_derived/monitored_users/friend_lists/") #where the friend list (at time t=0) of each of our monitored users
dir_brms_fits <- paste0(data_directory, "data_derived/_analysis/", "brms_fits/") #save our brms fits
final_user_file = paste0(data_directory, "data_derived/monitored_users/monitored_users_final.csv")
news_source_ideology_file = paste0(data_directory, "data/news_source_ideologies/news_ideology.csv")
compiled_news_diet_file = paste0(data_directory, "data_derived/monitored_users/news_diet_compiled.csv")
out_path <- "observational/output/news_diet/"

# Palette for plotting
plot_color <- "#1B3B6F"
news_pal <- c("#006195", "#829bb7", "#df9694", "#d54c54")


####################
# Load compiled data set of user news diet
####################
# If it doesn't already exist create it, otherwise load it
if ( file.exists(compiled_news_diet_file) ) {
  
  user_news_diet <- read.csv(compiled_news_diet_file, colClasses = c("user_id" = "character", "news_user_id" = "character"))
  
} else {
  
  # Load list of monitored users (our final pool of monitored users that are included in the main analysis)
  final_users <- read.csv(final_user_file, colClasses = c("user_id" = "character")) %>% 
    mutate(user_id = gsub("\"", "", user_id_str)) #make sure user id is correct by using string form

  # Load our set of news source ideologies (provided by Andy Guess)
  news_source_ideologies <- read.csv(news_source_ideology_file, colClasses = c("id.y" = "character")) %>% 
    rename(user_id = id.y,
           description = description.y,
           media_organization = media.organization,
           user_name = screenName,
           follower_count = followersCount.y)

  # Compile list of what news sources in our list each user followers
  col_names <- c('user_id', 'news_source_group', 'user_ideology', 'news_name', 'news_user_id', 'news_ideology')
  user_news_diet <- data.frame( matrix(nrow = 0, ncol = length(col_names)) ) 
  names(user_news_diet) <- col_names
  rm(col_names)
  
  friend_list_files <- list.files(dir_monitored_users_friends)
  for (i in 1:nrow(final_users) ) {
    
    # Print progress
    five_percent <- nrow(final_users) / 20
    if ( (i %% five_percent) == 0 ) {
      print( paste0(i/five_percent * 5, "% done...") )
    }
    rm(five_percent)
    
    # Grab users list of friends and load
    user_file = paste0(dir_monitored_users_friends, "FriendIDs_", final_users$user_id[i], ".csv")
    user_friends = read.csv(user_file, colClasses = c("user_id" = "character")) %>% 
      mutate(user_id = gsub("\"", "", user_id_str)) %>% 
      select(user_id)

    # Match to known news source ideologies, append to dataframe for collection
    news_followed <- news_source_ideologies %>% 
      select(user_name, user_id, ideology) %>% 
      merge(user_friends, by = 'user_id') %>% 
      rename(news_user_id = user_id,
             news_name = user_name,
             news_ideology = ideology) %>% 
      mutate(user_id = final_users$user_id[i],
             news_source_group = final_users$news_source[i],
             user_ideology = final_users$ideology_corresp[i])
    news_followed <- news_followed[ , names(user_news_diet) ] #re-order columns
    user_news_diet <- rbind(user_news_diet, news_followed)
    rm(user_friends, news_followed)
    
  }
    
  # Save 
  write.csv(user_news_diet, file = compiled_news_diet_file, row.names = FALSE)
  
}


####################
# Analyze mean news diet of users with Bayesian inference
####################
# Calculate mean news diet of each user
user_news_diet_means <- user_news_diet %>% 
  group_by(user_id, news_source_group, user_ideology) %>% 
  summarise(mean_news_ideology = mean(news_ideology))

# Bayesian group mean estimation 
file_fit_newsdiet <- paste0(dir_brms_fits, "user_news_diet.rds")
if (file.exists(file_fit_newsdiet)) {
  blm_newsdiet <- readRDS(file_fit_newsdiet)
} else {
  prior <- c(set_prior("normal(0, 1)", class = "b")) #population mean = 0.0156, sd = 0.3195
  blm_newsdiet <- brm(bf(mean_news_ideology ~ 0 + news_source_group), 
                      data = user_news_diet_means,
                      prior = prior, 
                      family = gaussian(),
                      sample_prior = TRUE,
                      warmup = 5000, 
                      chains = 4, 
                      iter = 15000)
  saveRDS(blm_newsdiet, file = file_fit_newsdiet)
}


####################
# Plot estimates
####################
# Get posteriors
posteriors <- posterior_samples(blm_newsdiet) %>% 
  select(-sigma, -prior_b, -prior_sigma, -lp__) %>% 
  pivot_longer(cols = starts_with("b_news_source_group"), names_to = "user_group", values_to = "posterior_sample") %>% 
  mutate(user_group = gsub("b_news_source_group", "", user_group)) %>% 
  mutate(user_group = factor(user_group, levels = c("voxdotcom", "cbsnews", "usatoday", "dcexaminer")))

# Get point estimates
estimates <- data.frame( posterior_summary(blm_newsdiet, 
                                           probs = c(0.05, 0.95) )) %>% #90% interval (quantile based)
  tibble::rownames_to_column() %>% 
  rename(user_group = rowname) %>% 
  filter(grepl("b_news_source_group", user_group)) %>% 
  mutate(user_group = gsub("b_news_source_group", "", user_group))

# Merge in HDI-based CI
estimates <- posterior_samples(blm_newsdiet) %>% 
  bayestestR::hdi(., ci = 0.9) %>% 
  rename(user_group = Parameter) %>% 
  filter(grepl("b_news_source_group", user_group)) %>% 
  mutate(user_group = gsub("b_news_source_group", "", user_group)) %>% 
  merge(estimates, ., by = "user_group") %>% 
  mutate(user_group = factor(user_group, levels = c("voxdotcom", "cbsnews", "usatoday", "dcexaminer")))
        

# Plot
gg_newsdiet <- ggplot(estimates, 
                      aes(x = user_group, y = Estimate, color = user_group)) +
  geom_hline(yintercept = 0, 
             linetype = "dotted", 
             size = 0.3) +
  geom_violin(data = posteriors,
              aes(y = posterior_sample, fill = user_group),
              color = NA, alpha = 0.15, width = 1) +
  geom_errorbar(aes(ymin = CI_low, ymax = CI_high),
                width = 0, 
                size = 0.5) +
  geom_point(size = 1) +
  scale_fill_manual(values = news_pal) +
  scale_color_manual(values = news_pal) +
  scale_x_discrete(labels = c("Vox", "CBS", "USA\nToday", "Wash.\nExam.")) +
  scale_y_continuous(breaks = round(seq(-0.6, 0.3, 0.1), 1), 
                     limits = c(-0.6, 0.3),
                     expand = c(0, 0)) +
  xlab("Twitter followers of") +
  ylab("Mean news diet ideology") +
  theme_ctokita() +
  theme(legend.position = "none",
        aspect.ratio = NULL)
gg_newsdiet

ggsave(gg_newsdiet, filename = paste0(out_path, "estimated_user_news_diet.pdf"), width = 45, height = 90, units = "mm")


####################
# Plot raw data
####################
gg_newsdiet_raw <- user_news_diet_means %>% 
  mutate(news_source_group = factor(news_source_group, levels = c("voxdotcom", "cbsnews", "usatoday", "dcexaminer"))) %>% 
  ggplot(., aes(x = news_source_group, y = mean_news_ideology, color = news_source_group)) +
  geom_hline(yintercept = 0, 
             linetype = "dotted", 
             size = 0.3) +
  geom_point(size = 0.5,
             stroke = 0,
             alpha = 0.4,
             position = position_jitter(width = 0.05)) +
  scale_color_manual(values = news_pal) +
  scale_x_discrete(labels = c("Vox", "CBS", "USA\nToday", "Wash.\nExam.")) +
  scale_y_continuous(breaks = seq(-2, 2, 1)) +
  xlab("Twitter followers of") +
  ylab("News diet ideology") +
  theme_ctokita() +
  theme(legend.position = "none")
gg_newsdiet_raw

ggsave(gg_newsdiet_raw, filename = paste0(out_path, "raw_user_news_diet.pdf"), width = 45, height = 50, units = "mm")


####################
# Histogram of news source ideologies in dataset
####################
# Prep data
news_source_ideologies <- read.csv(news_source_ideology_file, colClasses = c("id.y" = "character")) %>% 
  rename(user_id = id.y,
         description = description.y,
         media_organization = media.organization,
         user_name = screenName,
         follower_count = followersCount.y)

# Plot
gg_news_ideology <- ggplot(news_source_ideologies, aes(x = ideology)) +
  geom_vline(xintercept = 0, 
             linetype = "dotted", 
             size = 0.3) +
  geom_histogram(binwidth = 0.25, 
                 alpha = 0.7, 
                 color = "white",
                 size = 0.6) +
  scale_y_continuous(breaks = seq(0, 20, 5),
                     limits = c(0, 20),
                     expand = c(0, 0)) +
  xlab("News outlet ideology") +
  ylab("Count") +
  theme_ctokita()
gg_news_ideology

ggsave(gg_news_ideology, filename = paste0(out_path, "news_ideology_histogram.pdf"), width = 45, height = 45, units = "mm")
