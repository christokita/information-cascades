########################################
# Created on Thu Aug 19 11:51:00 2020
# @author: ChrisTokita
#
# SCRIPT
# This script wil use Pablo Barbera's R package, "tweetsscores", to get user ideology based on their Twitter follows.
# For more information about this package, see: https://github.com/pablobarbera/twitter_ideology
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
data_directory <- "/Volumes/CKT-DATA/information-cascades/observational/" #path to external HD
#data_directory <- "../" #path if done within local directory

# File paths
output_name <- "monitored_users_ideology_scores.csv"
path_to_users <- paste0(data_directory, "data_derived/monitored_users/")
path_to_twitter_keys <- "../api_keys/twitter_tokens/"
path_for_user_friends <- paste0(data_directory, "data_derived/monitored_users/friend_lists/")


####################
# Prep for data collection via Twitter API
####################
# Load users of interest
twitter_users <- read.csv(paste0(path_to_users, "monitored_users_preliminary.csv"), colClasses = c("user_id"="character"))

# Load user ideology table if it exists, otherwise create it
file_exists_already <- file.exists(paste0(path_to_users, output_name))
if (file_exists_already) {
  user_ideologies <- read.csv(paste0(path_to_users, output_name))
} else {
  user_ideologies <- data.frame(user_id = twitter_users$user_id, 
                                user_id_str = twitter_users$user_id_str,
                                user_name = twitter_users$user_name,
                                friend_count = twitter_users$friends,
                                ideology_mle = NA, 
                                ideology_corresp = NA,
                                issue = NA)
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
# Estimate ideology of monitored users
####################
# We'll do this with a single core, but we'll need to be careful about rate limits.
# For a given token, we can only do 15 calls per token per 15 minutes

# Grab indicies of which  users don't have estimates yet (in case this has been run partially before)
no_estimate <- which(is.na(user_ideologies$ideology_corresp))
how_many_users <- length(no_estimate)

# If we've recently ran this script, uncomment below to make sure all tokens are ready for use
print("Since we recently used this script, sleeping for 15 min to make sure tokens can all be used.")
Sys.sleep(15*60)

# Prep our tokens for tracking use and avoiding rate limits
current_token_number <- 1 #start with our first token in our set
tokens$current_token[current_token_number] <- TRUE #flag our current token
tokens$time_last_use <- Sys.time() #make time format, note start of first token use

# Loop through users
for (i in no_estimate) {
  
  # Check if we need to switch API tokens
  # We can only pull down 5,000 friends per request. So we account for number of requests we will need to make for this user.
  n_requests <- ceiling( (user_ideologies$friend_count[i] + 500) / 5000)  #We add a buffer of 500 friends in case they followed more accounts recently.
  requests_left <- check_rate_limit(my_oauth)
  if ((requests_left - n_requests) <= 0) {
    tokens <- switch_API_tokens(tokens)
    current_token_number <- which(tokens$current_token == TRUE)
    requests_left <- 15 #fresh token
  } 
  
  # Grab specific Twitter API key/token
  my_oauth <- list(consumer_key = tokens$consumer_key[current_token_number],
                   consumer_secret = tokens$consumer_secret[current_token_number],
                   access_token = tokens$access_token[current_token_number],
                   access_token_secret = tokens$access_token_secret[current_token_number])
  
  # Get user's ID and look up friends
  issue <- NA
  user_id <- user_ideologies$user_id_str[i]
  user_id <- gsub("\"", "", user_id) #remove quotes
  suppressMessages( friends <- tryCatch(getFriends(user_id = user_id, oauth = my_oauth, sleep = 1), error = function(err) { c() }) )
  requests_left <- requests_left - n_requests
  
  # estimate ideology using two methods: 
  # (1) MLE and (2) the newer corerspondence analysis with more "elite" accounts included
  # If the account couldn't be found, do not calculate 
  if (length(friends) > 0) {
    
    # Estimate ideolgoy
    estimates <- get_ideology(user_id, friends)
    estimate_mle <- estimates$estimate_mle
    estimate_corresp <- estimates$estimate_corresp
    if( (is.na(estimate_mle)) & (is.na(estimate_corresp)) ) {
      issue <- "No elite friends"
    }
    
    # Save friends list
    friend_list = data.frame('user_id' = friends) %>% 
      mutate(user_id_str = paste0("\"", user_id, "\""))
    write.csv(friend_list, file = paste0(path_for_user_friends, "FriendIDs_", user_id, ".csv"), row.names = FALSE)
    
  } else {
    issue <- "Account not found"
    estimate_mle <- NA
    estimate_corresp <- NA
  }

  # Add scores to our data set, and note issue
  user_ideologies$ideology_mle[i] <- estimate_mle
  user_ideologies$ideology_corresp[i] <- estimate_corresp
  user_ideologies$issue[i] <- issue
  
  # Print progress to console
  progress_measure <- which(no_estimate == i)
  one_percent_increment <- ceiling(length(no_estimate)/100)
  if (progress_measure %% one_percent_increment == 0) {
    print(paste0(progress_measure / one_percent_increment, "% done..."))
  }
  
  # Save every 1,000 new scores or if we hit the end
  # Write to temporary file and then upload to s3
  if ( (progress_measure %% 1000 == 0) | (progress_measure == length(no_estimate)) ) {
    print("Saving what we have to file.")
    write.csv(user_ideologies, file = paste0(path_to_users, output_name), row.names = FALSE)
    # put_object(file = output_name, object = output_name, bucket = bucket_name)
    # file.remove(output_name)
  }
}




