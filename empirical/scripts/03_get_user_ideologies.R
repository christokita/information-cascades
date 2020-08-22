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
####################
# Dependendcies
toInstall <- c("ggplot2", "scales", "R2WinBUGS", "devtools", "yaml", "httr", "RJSONIO") #dependendices as listed on the package website
# toInstall <- c(toInstall, "aws.s3") #extra needed packages for this script
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
library(aws.s3)

output_name <- "monitored_users_ideology_scores.csv"
bucket_name <- "ideology-scores"
path_to_users <- "../data_derived/monitored_users/"
path_to_twitter_keys <- "../api_keys/twitter_tokens/"
path_to_s3_keys <- "../api_keys/s3_keys/s3_key.json"

####################
# Prep for AWS s3
####################
# s3_token <- read_json(path_to_s3_keys)
# Sys.setenv("AWS_ACCESS_KEY_ID" = s3_token$access_key_id,
#            "AWS_SECRET_ACCESS_KEY" = s3_token$access_secret_key,
#            "AWS_DEFAULT_REGION" = "us-east-1")

####################
# Prep for data collection via Twitter API
####################
# Load users of interest
twitter_users <- read.csv(paste0(path_to_users, "monitored_users_preliminary.csv"), colClasses = c("user_id"="character"))

# Load user ideology table if it exists, otherwise create it
# suppressMessages( file_exists_already <- head_object(object = output_name, bucket = bucket_name)[1] ) #supress message because it will print an error if not found
file_exists_already <- file.exists(paste0(path_to_users, output_name))
if (file_exists_already) {
  # user_ideologies <- s3read_using(read.csv, object = output_name, bucket = bucket_name)
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

####################
# Helpful functions
####################
# Crude API rate limit check
check_rate_limit <- function(requests_left, user_friend_count) {
  
  n_requests <- ceiling(user_friend_count / 5000) #we can only pull down 5,000 friends per request
  if ( (requests_left - n_requests) < 0) {
    switch_needed <- TRUE
  } else {
    switch_needed <- FALSE
  }
  return(switch_needed)
  
}

# Switch token to next token
switch_API_tokens <- function(current_token_number, n_tokens, first_token_start_time) {
  
  #  If it's the last in our set, go back to the first. 
  if(current_token_number == n_tokens) {
    current_token_number <- 1
  } else {
    current_token_number <- current_token_number + 1
  }
  print(paste("Switching to token", current_token_number))
  
  # If we're back at the first token and it's been less than 15 since its first use, sleep until we can start again
  time_since_first_token <- Sys.time() - first_token_start_time
  if (current_token_number == 1 & time_since_first_token < 15*60) {
    time_to_sleep <- 15 - as.numeric(time_since_first_token)
    print(paste0("Sleeping for ", round(time_to_sleep, 1), " minutes until we can start on the first token again."))
    Sys.sleep(time_to_sleep)
    first_token_start_time <- Sys.time()
  }
  
  # Return dataframe row so separate data types can be maintained
  token_info <- data.frame(token_number = current_token_number, first_token_time = first_token_start_time)
  return(token_info)
  
}

####################
# Estimate ideology of monitored users
####################
# We'll do this with a single core, but we'll need to be careful about rate limits.
# For a given token, we can only do 15 calls per token per 15 minutes

# Grab indicies of which  users don't have estimates yet (in case this has been run partially before)
no_estimate <- which(is.na(user_ideologies$ideology_mle))
how_many_users <- length(no_estimate)

# Loop through users
requests_left <- 15 #assuming fresh start with new token that hasn't been used recently
current_token_number <- 1 #start with our first token in our set
first_token_time <- Sys.time()
for (i in no_estimate) {
  
  # Check if we need to switch API tokens
  n_requests <- ceiling(user_ideologies$friend_count[i] / 5000) #we can only pull down 5,000 friends per request
  if ((requests_left - n_requests) <= 0) {
    token_switch <- switch_API_tokens(current_token_number = current_token_number, n_tokens = nrow(tokens), first_token_start_time = first_token_time)
    current_token_number <- token_switch$token_number
    first_token_time <- token_switch$first_token_time
    requests_left <- 15 - n_requests
  } else {
    requests_left <- requests_left - n_requests
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
  
  # estimate ideology using two methods: 
  # (1) MLE and (2) the newer corerspondence analysis with more "elite" accounts included
  # If the account couldn't be found, do not calculate 
  if (length(friends) > 0) {
    
    estimate_mle <- NA
    estimate_corresp <- NA
    suppressMessages( estimate_mle <- estimateIdeology(user_id, friends, method = "MLE", verbose = FALSE) )
    estimate_mle <- mean(estimate_mle$samples[, , 2]) #this corresponds to mean of theta samples in ML estimation 
    suppressMessages( estimate_corresp <- estimateIdeology2(user_id, friends, verbose = FALSE) )
    
    # If they follow no elite accounts, it will result in an NA score.
    if(is.na(estimate_mle)) {
      issue <- "No elite friends"
    }
    
  } else {
    
    issue <- "Account not found"
    
  }

  # Add scores to our data set
  user_ideologies$ideology_mle[i] <- estimate_mle
  user_ideologies$ideology_corresp[i] <- estimate_corresp
  
  # Note issue
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




