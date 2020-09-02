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
data_directory <- "/Volumes/CKT-DATA/information-cascades/empirical/" #path to external HD
#data_directory <- "../" #path if done within local directory

# File paths
path_to_users <- paste0(data_directory, "data_derived/monitored_users/")
path_to_twitter_keys <- "../api_keys/twitter_tokens/"
path_for_user_friends <- paste0(data_directory, "data_derived/monitored_users/friend_lists/")
path_for_follower_samples <- paste0(data_directory, "data_derived/monitored_users/sampled_follower_friendlists/")
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
           follower_id = gsub("\"", "", follower_id))
} else {
  follower_ideologies <- data.frame(user_id = character(), 
                                    user_id_str = character(),
                                    user_name = character(),
                                    follower_count = character(),
                                    follower_id = character(),
                                    follower_id_str = character(),
                                    follower_user_name = character(),
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
current_token_number <- 10 #start with our first token in our set
tokens$current_token[current_token_number] <- TRUE #flag our current token
tokens$time_last_use <- Sys.time() #make time format, note start of first token use

# Set up first token
my_oauth <- list(consumer_key = tokens$consumer_key[current_token_number],
                 consumer_secret = tokens$consumer_secret[current_token_number],
                 access_token = tokens$access_token[current_token_number],
                 access_token_secret = tokens$access_token_secret[current_token_number])

# Loop through users in need of sample follower ideologies
for (user_id in final_users$user_id) {
  
  # Print progress
  print(paste0("STARTING user ", which(user_id == final_users$user_id), "/", length(final_users$user_id), ": user ID ", user_id))
  
  # Load follower list
  follower_file <- follower_files[grep(paste0("followerIDs_", user_id, ".csv"), follower_files)]
  followers <- read.csv(follower_file, colClasses = c("user_id" = "character"))
  followers$user_id <- gsub("\"", "", followers$user_id_str)
  
  # Grab followers that have already been sampled (or if none have been sampled yet, create empty dataframe with desired columns)
  follower_samples <- follower_ideologies[follower_ideologies$user_id == user_id,]
  
  # Randomly set order that followers will be sampled. Remove IDs that have already been sampled in previous runs.
  set.seed(323)
  follower_order <- sample(followers$user_id)
  if (nrow(follower_samples) > 0) {
    already_sampled <- which(follower_order %in% follower_samples$follower_id) #determine which have already been sampled
    start_here <- max(already_sampled)+1 #find last follower we found scores for
    follower_order <- follower_order[ start_here:length(follower_order) ] #remove up to this last-sampled-and-scored follower
  }
  
  # Go through followers until we have N sample ideologies
  for(j in 1:length(follower_order)) {
    
    # Get user's ID and see how many friends they have
    follower_id <- follower_order[j]
    follower_info <- getUsers(oauth = my_oauth, ids = follower_id) # we get 900 GET users calls per 15 min so not a worry with current token
    friend_count <- follower_info[[1]]$friends_count
    follower_screenname <- follower_info[[1]]$screen_name
    is_protected <-  follower_info[[1]]$protected
    if (is_protected) {
      next
    }
    
    # Check if we need to switch API tokens
    # We can only pull down 5,000 friends per request. So we account for number of requests we will need to make for this user.
    n_requests <- ceiling(friend_count / 5000)
    requests_left <- check_rate_limit(my_oauth)
    if ((requests_left - n_requests) <= 0) {
      tokens <- switch_API_tokens(tokens)
      current_token_number <- which(tokens$current_token == TRUE)
      if (n_requests >= 15) {  # If person has massive number of friends, we're going to have to sleep. no way around it
        print(paste0("Follower @", follower_screenname, " is going to need ", n_requests, " requests to get all their friends. We're going to have to sleep for a while."))
      }
    } 
    
    # Grab specific Twitter API key/token
    my_oauth <- list(consumer_key = tokens$consumer_key[current_token_number],
                     consumer_secret = tokens$consumer_secret[current_token_number],
                     access_token = tokens$access_token[current_token_number],
                     access_token_secret = tokens$access_token_secret[current_token_number])
    
    # Get user's ID and look up friends
    suppressMessages( friends <- tryCatch(getFriends(user_id = follower_id, oauth = my_oauth, sleep = 0), error = function(err) { c() }) )

    # estimate ideology using two methods: 
    # (1) MLE and (2) the newer corerspondence analysis with more "elite" accounts included
    # If the account couldn't be found, do not calculate 
    if (length(friends) > 0) {
      
      # Estimate ideolgoy
      estimates <- get_ideology(follower_id, friends)
      estimate_mle <- estimates$estimate_mle
      estimate_corresp <- estimates$estimate_corresp
      
      # If the C.A. ideology score (what we are using for this project) isn't NA, add to our set of ideologoy samples
      if(!is.na(estimate_corresp) ) { 
        
        # Add row to our ideology samples
        new_row <- data.frame(user_id = user_id,
                              user_id_str = paste0("\"", user_id, "\""),
                              follower_count = nrow(followers),
                              follower_id = follower_id,
                              follower_id_str = paste0("\"", follower_id, "\""),
                              follower_user_name = follower_screenname,
                              ideology_mle = estimate_mle, 
                              ideology_corresp = estimate_corresp)
        follower_samples <- rbind(follower_samples, new_row)
        rm(new_row)
        
        # Print progress
        print(paste0("User ", user_id, ": ", nrow(follower_samples), "/", n_samples, " follower samples acquired."))
        
        # Save friends list
        friend_list = data.frame('user_id' = friends) %>% 
          mutate(user_id_str = paste0("\"", user_id, "\""))
        write.csv(friend_list, file = paste0(path_for_follower_samples, "Sampled_FriendIDs_", follower_id, ".csv"), row.names = FALSE)
        
        # Increase our sample count
        sample_count <- sample_count + 1
      }
      
      # If we've reached the end of our possible set of followers to sample from OR we've hit our goal of sampled followers, end sampling process. 
      if (j > length(follower_order) | nrow(follower_samples) == n_samples) {
        break 
      }
    }
    
  }
  
  # Finished getting N sample follower ideologies for this user, add to our large dataset and save our progress
  follower_ideologies <- rbind(follower_ideologies, follower_samples) %>% 
    arrange(user_id)
  write.csv(follower_ideologies, file = output_name, row.names = FALSE)
  
}



