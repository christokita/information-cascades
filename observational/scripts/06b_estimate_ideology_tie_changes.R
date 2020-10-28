########################################
# Created on Tues Oct 13 15:56:00 2020
# @author: ChrisTokita
#
# SCRIPT
# Estimate ideologies of users who created new ties or broke ties during observation period
#
# NOTE
# Normally with Rstudio we set the working directory to where the .Rproject file is, but here we will set WD to the locaiton of the script so it can be run from command line.
# If running this script in Rstudio, go to "Session" -> "Set Working Directory" -> "To Source File Location"
########################################

####################
# Load packages and set important paths
####################
library(tweetscores)
library(jsonlite)
library(dplyr)
source("twitter_api_scraper/ideology_utility_functions.R")

# High-level data directory
# data_directory <- "/Volumes/CKT-DATA/information-cascades/observational/" #path to external HD
data_directory <- "../" #path if done within local directory

# File paths
token_file1 <- "../api_keys/twitter_tokens/ag_tokens1.json"
# token_file2 <- "../api_keys/twitter_tokens/ckt_tokens1.json" #only use one token!
token_timestamps_file <- "../api_keys/twitter_token_timestamps.csv" #this file stores the last time these tokens were used
changed_ties_data_file = paste0(data_directory, "data_derived/monitored_users/changed_ties.csv")


####################
# Load and prep data
####################
# Load changed ties data
changed_ties <- read.csv(changed_ties_data_file) %>% 
  mutate(user_id = gsub("\"", "", user_id_str),
         follower_id = gsub("\"", "", follower_id_str))

# Merge in ideology scores from our sampled followers and our users 
if (!"ideology_corresp" %in% names(changed_ties)) {
  
  # Load ideology scores we have on hand and merge into our changed ties dataset
  final_users <- read.csv( paste0(data_directory, "data_derived/monitored_users/monitored_users_final.csv") ) %>% 
    mutate(user_id = gsub("\"", "", user_id_str)) %>% 
    select(user_id, ideology_mle, ideology_corresp) %>% 
    rename(follower_id = user_id)
  follower_ideologies <- read.csv( paste0(data_directory, "data_derived/monitored_users/follower_ideology_samples.csv") ) %>% 
    mutate(follower_id = gsub("\"", "", follower_id_str)) %>% 
    select(follower_id, ideology_mle, ideology_corresp) %>% 
    rbind(final_users) %>% 
    distinct(follower_id, .keep_all = TRUE)
  changed_ties <- merge(changed_ties, follower_ideologies, by = "follower_id", all.x = T) %>% 
    relocate(user_id, user_id_str) %>% 
    arrange(user_id)
  rm(final_users, follower_ideologies)
  
  # Add column to note issues in attempting to get score
  changed_ties$issue <- NA
  
}

# Set who we want to check based on the criteria:
#   1. tie change type, i.e., broken and/or new
#   2. is an account that is not suspended/deleted
#   3. is not a protected account (can't get their friend lists)
#   4. doesn't already have a score or wasn't already looked up
followers_of_interest <- changed_ties %>% 
  filter(tie_change == "broken",
         found_on_twitter == "True",
         protected == "False",
         is.na(ideology_corresp),
         is.na(issue) | issue == "Twitter API error") %>% #add no elite friends flag for now because this could include people for whom we encountered a Twitter API error
  distinct(follower_id) %>% 
  pull(follower_id)

print(paste0("Attempting to estimate ideology scores for ", length(followers_of_interest), " users."))

####################
# Prep Twitter token
####################
# Load tokens, add extra info
token_lists <- c(token_file1) #we're only going to use one token!
tokens <- create_token_set(list_of_token_files = token_lists, 
                           token_timestamps_file = token_timestamps_file, 
                           n_tokens_per_set = 1)
current_token_number <- 1 #start with our first token in our set
tokens$current_token[current_token_number] <- TRUE #flag our current token

# Make sure it's been 15 min since we last used this token (due to rate limits).
time_since_last_use <- difftime(Sys.time(), tokens$time_last_use[current_token_number], units = "mins")
if (time_since_last_use < 15.01) {
  time_to_sleep <- 15.01 - as.numeric(time_since_last_use) 
  time_to_sleep <- time_to_sleep
  print(paste0("Sleeping for ", round(time_to_sleep, 1), " minutes until we can start on token ", current_token_number, " again."))
  Sys.sleep(time_to_sleep*60)
}
tokens$time_last_use[current_token_number] <- Sys.time() #start use on this token, so mark time.


####################
# Loop through tie changers of interest and get ideology scores
####################
for (follower_id in followers_of_interest) {
  
  # Set up token to check basic user info
  current_token_number <- which(tokens$current_token == TRUE)
  my_oauth <- list(consumer_key = tokens$consumer_key[current_token_number],
                   consumer_secret = tokens$consumer_secret[current_token_number],
                   access_token = tokens$access_token[current_token_number],
                   access_token_secret = tokens$access_token_secret[current_token_number])

  # Look up user again to check if they have friends (0 friends could be due to temporary restriction of account)
  issue <- NA
  user_info <- getUsers(oauth = my_oauth, ids = follower_id) # we get 900 GET users calls per 15 min so not a worry with current token
  friend_count <- user_info[[1]]$friends_count
  is_protected <-  user_info[[1]]$protected
  
  # Skip if account can't be found (i.e., deleted/suspended account) or is protected
  if (is.null(friend_count)) {
    friend_count <- 0
  } else if (is_protected) {
    friend_count <- 0
  }
  
  # Get friends of this user, estimate ideology
  if (friend_count > 0) {
    
    search_results <- getFriends_autocursor(user_id = follower_id, tokens = tokens, sleep = 1, token_time_file = token_timestamps_file)
    friends <- search_results$friends
    tokens <- search_results$tokens
    issue <- search_results$error #will be NA unless we encountered an issue with the Twitter API itself
    estimates <- get_ideology(follower_id, friends) #estimate ideology based on friend list
    estimate_mle <- estimates$estimate_mle
    estimate_corresp <- estimates$estimate_corresp
    if( is.na(estimate_corresp) & is.na(issue) ) {
      issue <- "No elite friends" #only assign to users who we didn't encounter an API issue during the attempt to get their friends
    }
    
  } else {
    
    issue <- "No friends/Restricted"
    estimate_mle <- NA
    estimate_corresp <- NA
    
  }
  
  # Add scores to our data set, and note issue
  which_users <- which(changed_ties$follower_id == follower_id)
  changed_ties$ideology_mle[which_users] <- estimate_mle
  changed_ties$ideology_corresp[which_users] <- estimate_corresp
  changed_ties$issue[which_users] <- issue

  # Print progress to console
  print(paste0("DONE: user ID ", follower_id))
  progress_measure <- which(followers_of_interest == follower_id)
  one_percent_increment <- ceiling(length(followers_of_interest)/100)
  if (progress_measure %% one_percent_increment == 0) {
    print(paste0(progress_measure / one_percent_increment, "% done..."))
  }
  
  # Save
  write.csv(changed_ties, file = changed_ties_data_file, row.names = FALSE)

}


