########################################
# Created on Tues Sept 1 14:57:00 2020
# @author: ChrisTokita
#
# SCRIPT
# This script wil use Pablo Barbera's R package, "tweetsscores", to get the ideology scores of the followers of each of our monitored users.
#
# NOTE
# Normally with Rstudio we set the working directory to where the .Rproject file is, but here we will set WD to the locaiton of the script so it can be run from command line.
# If running this script in Rstudio, go to "Session" -> "Set Working Directory" -> "To Source File Location"
########################################

rm(list = ls())

####################
# Install required packages, per Pablo Barbera's instructions at URL above
#
# If doing this in a linux environment, before opening R to install packages, make sure to type into command line:
# > module load rh/devtoolset/8
####################
# Dependendcies
toInstall <- c("ggplot2", "scales", "R2WinBUGS", "devtools", "yaml", "httr", "RJSONIO") #dependendices as listed on the package website
toInstall <- toInstall[!toInstall %in% rownames(installed.packages())] #check to see what is already installed
if (length(toInstall) > 0) {
  install.packages(toInstall, repos = "https://cloud.r-project.org/")
}
rm(toInstall)

# Download and install tweetscores
if (!"tweetscores" %in% rownames(installed.packages())) {
  library(devtools)
  install_github("pablobarbera/twitter_ideology/pkg/tweetscores")
}


####################
# Load packages and set important paths
####################
library(tweetscores)
library(jsonlite)
library(dplyr)
source("twitter_api_scraper/ideology_utility_functions.R")

# High-level data directory
# data_directory <- "/Volumes/CKT-DATA/information-cascades/empirical/" #path to external HD
data_directory <- "../" #path if done within local directory

# File paths
path_to_users <- paste0(data_directory, "data_derived/monitored_users/")
path_to_twitter_keys <- "../api_keys/twitter_tokens/"
path_for_user_friends <- paste0(data_directory, "data_derived/monitored_users/friend_lists/")
output_name <- paste0(path_to_users, "follower_ideology_samples.csv")


####################
# Prep for data collection via Twitter API
####################
# Load users of interest
final_users <- read.csv(paste0(path_to_users, "monitored_users_final.csv"), colClasses = c("user_id"="character"))
final_users$user_id <- gsub("\"", "", final_users$user_id_str) #ensure ID is corect

# set parameters for sampling
n_samples <- 50

# Load follower ideology table if it exists, otherwise create it
if ( file.exists(output_name) ) {
  follower_ideologies <- read.csv(output_name) %>% 
    mutate(user_id = gsub("\"", "", user_id_str),
           follower_id = gsub("\"", "", follower_id_str))
} else {
  follower_ideologies <- data.frame(user_id = character(), 
                                    user_id_str = character(),
                                    user_name = character(),
                                    follower_count = character(),
                                    follower_id = character(),
                                    follower_id_str = character(),
                                    follower_user_name = character(),
                                    follower_friend_count = numeric(),
                                    ideology_mle = numeric(), 
                                    ideology_corresp = numeric())
}

# Get our twitter API token sets, bind into one large set
token_lists <- list.files(path_to_twitter_keys, full.names = TRUE)
token_lists <- gsub("//", "/", token_lists) #prevent double slash that occurs when list.files gives full file paths
for (i in 1:length(token_lists)) {
  token_set <- stream_in( file(token_lists[i]) )
  set_name <- gsub( paste0(path_to_twitter_keys, "([_a-z0-9]+).json"), "\\1", token_lists[i], perl = TRUE)
  token_set$set_name <- set_name
  if (exists("tokens")) {
    tokens <- rbind(tokens, token_set)
  } else {
    tokens <- token_set
  }
}
rm(token_lists, token_set) #clean up
tokens$current_token <- FALSE
tokens$use_count <- 0 #keep track of how many times each token has been used


####################
# Sample follower ideologies for our monitored users
####################
# Prep for getting follower ideologies
follower_files <- list.files(paste0(data_directory, "data_derived/user_followers_initial"), full.names = TRUE)
current_token_number <- 1 #start with our first token in our set
tokens$current_token[current_token_number] <- TRUE #flag our current token
tokens$time_last_use <- Sys.time() #make time format, note start of first token use

# Loop through users in need of sample follower ideologies
for (user_id in final_users$user_id) {
  
  # Grab followers that have already been sampled (or if none have been sampled yet, create empty dataframe with desired columns)
  follower_samples <- follower_ideologies[follower_ideologies$user_id == user_id,]
  print(paste0("~~ STARTING user ", which(user_id == final_users$user_id), "/", length(final_users$user_id), ": user ID ", user_id, " ~~"))
  
  # If we already had sampled enough from this user before, skip.
  if (nrow(follower_samples) == n_samples) {
    next 
  }
  
  # Load follower list
  follower_file <- follower_files[grep(paste0("followerIDs_", user_id, ".csv"), follower_files)]
  followers <- read.csv(follower_file, colClasses = c("user_id" = "character"))
  followers$user_id <- gsub("\"", "", followers$user_id_str)
  
  # Randomly set order that followers will be sampled. 
  user_seed <- substr(user_id, start = 1, stop = 8) #take first 8 digits of user ID as seed (will be shorter for shorter user IDs)
  set.seed(user_seed)
  follower_order <- sample(followers$user_id)
  
  # Remove IDs that have already been sampled in previous runs.
  if (nrow(follower_samples) > 0) {
    already_sampled <- which(follower_order %in% follower_samples$follower_id) #determine which have already been sampled
    start_here <- max(already_sampled)+1 #find last follower we found scores for
    follower_order <- follower_order[ start_here:length(follower_order) ] #remove up to this last-sampled-and-scored follower
    
    # Skip this user if we've already tapped out their followers--in the event they have less than 50 total with ideology scores
    if (start_here > length(followers$user_id)) { 
      next 
    }
  }
  
  # Go through followers until we have N sample ideologies
  for(j in 1:length(follower_order)) {
    
    # If we've already reached our goal of sampled followers, end sampling process. 
    if (nrow(follower_samples) == n_samples) {
      break 
    }
    
    # Set up token to check basic user info
    current_token_number <- which(tokens$current_token == TRUE)
    my_oauth <- list(consumer_key = tokens$consumer_key[current_token_number],
                     consumer_secret = tokens$consumer_secret[current_token_number],
                     access_token = tokens$access_token[current_token_number],
                     access_token_secret = tokens$access_token_secret[current_token_number])
    
    # Get user's ID and see how many friends they have
    follower_id <- follower_order[j]
    follower_info <- getUsers(oauth = my_oauth, ids = follower_id) # we get 900 GET users calls per 15 min so not a worry with current token
    friend_count <- follower_info[[1]]$friends_count
    follower_screenname <- follower_info[[1]]$screen_name
    is_protected <-  follower_info[[1]]$protected
    
    # Skip if account can't be found (i.e., deleted/suspended account) or is protected
    if (is.null(is_protected)) {
      next
    }
    if (is_protected) {
      next
    }
    
    # If we've already calculated this follower's ideology before, get their ideology from our dataset.
    # Otherwise, estimate ideology from scratch.
    if (follower_id %in% follower_ideologies$follower_id) {
      
      follower_in_dataset <- follower_ideologies[follower_ideologies$follower_id == follower_id, ]
      estimate_mle <- follower_in_dataset$ideology_mle[1] #grab first instance in case there are multiple rows
      estimate_corresp <- follower_in_dataset$ideology_corresp[1] #grab first instance in case there are multiple rows
      
    } else {
      
      # Look up friends, get back friend list and updated token set (noting which token is currently in use)
      search_results <- getFriends_autocursor(user_id = follower_id, tokens = tokens, sleep = 1)
      friends <- search_results$friends
      tokens <- search_results$tokens
      
      # estimate ideology using two methods: 
      # (1) MLE and (2) the newer corerspondence analysis with more "elite" accounts included
      estimates <- get_ideology(follower_id, friends)
      estimate_mle <- estimates$estimate_mle
      estimate_corresp <- estimates$estimate_corresp
      
    }
    
    # If the C.A. ideology score (what we are using for this project) isn't NA, add to our set of ideologoy samples
    if(!is.na(estimate_corresp) ) { 
      
      # Add row to our ideology samples
      new_row <- data.frame(user_id = user_id,
                            user_id_str = paste0("\"", user_id, "\""),
                            follower_count = nrow(followers),
                            follower_id = follower_id,
                            follower_id_str = paste0("\"", follower_id, "\""),
                            follower_user_name = follower_screenname,
                            follower_friend_count = friend_count,
                            ideology_mle = estimate_mle, 
                            ideology_corresp = estimate_corresp)
      follower_samples <- rbind(follower_samples, new_row)
      rm(new_row)
      
      # Print progress
      print(paste0("User ", user_id, ": ", nrow(follower_samples), "/", n_samples, " follower samples acquired. j = ", j))
      
    }
    
  }
  
  # Finished getting N sample follower ideologies for this user, add to our large dataset and save our progress
  follower_ideologies <- follower_ideologies[follower_ideologies$user_id != user_id, ] #remove this set of rows since we will reappend them with new data next
  follower_ideologies <- rbind(follower_ideologies, follower_samples) %>% 
    arrange(user_id)
  write.csv(follower_ideologies, file = output_name, row.names = FALSE)
  
}



