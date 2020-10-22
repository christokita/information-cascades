########################################
# Created on Tues Sept 1 17:00:00 2020
# @author: ChrisTokita
#
# SCRIPT
# Utility functions for estimating ideology scores of twitter users
########################################
library(tweetscores)


############### Functions to handle tokens ###############

# Load tokens (Only use one token!)
create_token_set <- function(list_of_token_files, token_timestamps_file, n_tokens_per_set = 1) {
  for (i in 1:length(list_of_token_files)) {
    
    # Load token, add extra tracking data.
    token_set <- stream_in( file(list_of_token_files[i]) )
    set_name <- gsub(".*/([_a-z0-9]+).json", "\\1", token_lists[i], perl = TRUE)
    token_set$set_name <- set_name
    token_set$current_token <- FALSE

    # Make sure we are only using as many tokens as we want (should be only one)
    token_limit <- min(n_tokens_per_set, nrow(token_set))
    token_set <- token_set[token_limit, ]
    
    # Make sure we properly keep track of when tokens were last used. 
    # Either use record of last use or set as time over 15 minutes ago.
    if (file.exists(token_timestamps_file)) {
      token_times <- read.csv(token_timestamps_file)
      token_set$time_last_use <- as.POSIXct(token_times$time_last_use[i])
      rm(token_times)
    }  else {
      token_set$time_last_use <- Sys.time() - 16*60 #16 minutes ago
    }
    
    # Bind together
    if (i == 1) {
      tokens <- token_set
    } else {
      tokens <- rbind(tokens, token_set)
    }
    
  }
  return(tokens)
}


# Switch token to next token (Running with just one token will not violate Twitter API policy)
switch_API_tokens <- function(tokens, token_time_file, time_buffer = 0.01) {

  #  If it's the last in our set, go back to the first.
  n_tokens <- nrow(tokens)
  prev_token_number <- which(tokens$current_token == TRUE) #note current token
  tokens$current_token <- FALSE #prepare to update current token
  if(prev_token_number == n_tokens) {
    tokens$current_token[1] <- TRUE
  } else {
    tokens$current_token[prev_token_number + 1] <- TRUE
  }
  current_token_number <- which(tokens$current_token == TRUE)
  print(paste("Switched to token", current_token_number))

  # Make sure it's been 15 min since we last used this token (due to rate limits).
  # Updates time we last waited on this token
  tokens <- wait_on_rate_limit(tokens = tokens, 
                               current_token_number = current_token_number,
                               token_time_file = token_time_file,
                               time_buffer = 0.1)

  return(tokens)
}


# Function to wait on using token
wait_on_rate_limit <- function(tokens, current_token_number, token_time_file, time_buffer = 0) {
  wait_time <- 15 + time_buffer #option to add time in case we want to be safe
  time_since_last_use <- difftime(Sys.time(), tokens$time_last_use[current_token_number], units = "mins")
  if (time_since_last_use < wait_time) {
    time_to_sleep <- wait_time - as.numeric(time_since_last_use)
    time_to_sleep <- time_to_sleep
    print(paste0("Sleeping for ", round(time_to_sleep, 1), " minutes until we can start on token ", current_token_number, " again."))
    Sys.sleep(time_to_sleep*60)
  }
  tokens$time_last_use[current_token_number] <- Sys.time()
  write.csv(data.frame(time_last_use = tokens$time_last_use), file = token_time_file, row.names = FALSE) # Output latest list of token use timestamps
  return(tokens)
}


# Function to check if we need to switch tokens, and if we do, it switches it. (Running with just one token will not violate Twitter API policy)
check_tokens <- function(tokens, token_time_file) {

  # Set up Oauth with current token
  current_token_number <- which(tokens$current_token == TRUE)
  oauth <- list(consumer_key = tokens$consumer_key[current_token_number],
                consumer_secret = tokens$consumer_secret[current_token_number],
                access_token = tokens$access_token[current_token_number],
                access_token_secret = tokens$access_token_secret[current_token_number])
  my_oauth <- getOAuth(oauth, verbose=verbose)

  # Check requests limit status and if needed, swith token until we get a fresh one.
  requests_left <- check_rate_limit(my_oauth)
  while (requests_left == 0) {
    tokens <- switch_API_tokens(tokens = tokens, token_time_file = token_time_file, time_buffer = 0)
    current_token_number <- which(tokens$current_token == TRUE)
    oauth <- list(consumer_key = tokens$consumer_key[current_token_number],
                  consumer_secret = tokens$consumer_secret[current_token_number],
                  access_token = tokens$access_token[current_token_number],
                  access_token_secret = tokens$access_token_secret[current_token_number])
    my_oauth <- getOAuth(oauth, verbose=verbose)
    requests_left <- check_rate_limit(my_oauth)
  }

  # Return updated tokens (will be the same if we didn't need to swithc tokens)
  return(tokens)
}


# Borrowed from tweetscores package, specifically script oauth-utils.R
getOAuth <- function(x, verbose=TRUE){
  # first check if x is an object
  if (class(x)=="list"){
    my_oauth <- ROAuth::OAuthFactory$new(consumerKey=x$consumer_key,
                                         consumerSecret=x$consumer_secret,
                                         oauthKey=x$access_token,
                                         oauthSecret=x$access_token_secret,
                                         needsVerifier=FALSE,
                                         handshakeComplete=TRUE,
                                         verifier="1",
                                         requestURL="https://api.twitter.com/oauth/request_token",
                                         authURL="https://api.twitter.com/oauth/authorize",
                                         accessURL="https://api.twitter.com/oauth/access_token",
                                         signMethod="HMAC")
  }
  
  # first check if x exists in disk
  if (class(x)!="list" && class(x)!="OAuth" && file.exists(x)){
    info <- file.info(x)
    # if it's a folder, load one and return
    if (info$isdir){
      creds <- list.files(x, full.names=TRUE)
      cr <- sample(creds, 1)
      if (verbose){message(cr)}
      load(cr)
    }
    # if not, check type
    if (!info$isdir){
      # if it's not csv, guess it's Rdata and load it
      if (!grepl("csv", x)){
        if (verbose){message(x)}
        load(x)
      }
      # if it's a csv file read it, and create token
      if (grepl("csv", x)){
        d <- read.csv(x, stringsAsFactors=F)
        creds <- d[sample(1:nrow(d),1),]
        my_oauth <- ROAuth::OAuthFactory$new(consumerKey=creds$consumer_key,
                                             consumerSecret=creds$consumer_secret,
                                             oauthKey=creds$access_token,
                                             oauthSecret=creds$access_token_secret,
                                             needsVerifier=FALSE,
                                             handshakeComplete=TRUE,
                                             verifier="1",
                                             requestURL="https://api.twitter.com/oauth/request_token",
                                             authURL="https://api.twitter.com/oauth/authorize",
                                             accessURL="https://api.twitter.com/oauth/access_token",
                                             signMethod="HMAC")
        # testing that it works
        #url = "https://api.twitter.com/1.1/users/show.json"
        #params = list(screen_name = "twitter")
        #my_oauth$OAuthRequest(URL=url, params=params, method="GET",
        #                     cainfo=system.file("CurlSSL", "cacert.pem", package = "RCurl"))
      }
      
    }
  }
  if (class(x)=="OAuth"){ my_oauth <- x }
  return(my_oauth)
}


############### Functions to check rate limit ###############

# Borrowed from tweetscores package, scpecifically script oauth-utils.R
getLimitFriends <- function(my_oauth){
  url <- "https://api.twitter.com/1.1/application/rate_limit_status.json"
  params <- list(resources = "friends,application")
  response <- my_oauth$OAuthRequest(URL=url, params=params, method="GET",
                                    cainfo=system.file("CurlSSL", "cacert.pem", package = "RCurl"))
  return(unlist(jsonlite::fromJSON(response)$resources$friends$`/friends/ids`['remaining']))
}

# Crude API rate limit check
check_rate_limit <- function(oauth) {
  
  user_oauth <- getOAuth(oauth)
  requests_left <- getLimitFriends(user_oauth)
  return(requests_left)
  
}

############### Functions for getting friends and ideology ############### 

# Modified version of getFriends function from tweetscores package, script get-friends.R
# This will allow us to switch tokens when paging through people with many friends
# Takes data.frame of tokens instead of single oauth 
getFriends_autocursor <- function(screen_name = NULL, tokens, cursor = -1, user_id = NULL, verbose = TRUE, sleep = 1, token_time_file){

  ## url to call
  url <- "https://api.twitter.com/1.1/friends/ids.json"
  
  ## empty list for friends
  friends <- c()
  error <- NA #will list if we get a Twitter API issue
  
  ## Check if we need to switch tokens. If so, switch to fresh token. Then, load credentials
  tokens <- check_tokens(tokens, token_time_file)
  current_token_number <- which(tokens$current_token == TRUE)
  oauth <- list(consumer_key = tokens$consumer_key[current_token_number],
                consumer_secret = tokens$consumer_secret[current_token_number],
                access_token = tokens$access_token[current_token_number],
                access_token_secret = tokens$access_token_secret[current_token_number])
  my_oauth <- getOAuth(oauth, verbose=verbose)
  
  ## while there's more data to download...
  while (cursor != 0){
    
    ## Check if we need to wait on using this token
    requests_left <- check_rate_limit(my_oauth)
    if (requests_left == 0) {
      tokens <- wait_on_rate_limit(tokens = tokens, current_token_number = current_token_number, token_time_file = token_time_file, time_buffer = 0.1)
    }
    
    ## Prep parameters for API request
    if (!is.null(screen_name)){
      params <- list(screen_name = screen_name, cursor = cursor, stringify_ids="true")
    }
    if (!is.null(user_id)){
      params <- list(user_id = user_id, cursor = cursor, stringify_ids="true")
    }
    
    ## making API call. Try making call. If we get something weird (e.g., error: service unavailable), sleep for a while and try again
    Sys.sleep(sleep)
    url.data <- tryCatch(
      {
        my_oauth$OAuthRequest(URL = url, params = params, method = "GET",
                              cainfo = system.file("CurlSSL", "cacert.pem", package = "RCurl"))
      }, 
      
      # If error, sleep and try again (checking if we need to switch tokens before querying API again).
      error = function (e) {
        handled_error <- handle_OAuth_error(URL = url, params = params, method = "GET", cainfo = system.file("CurlSSL", "cacert.pem", package = "RCurl"),
                                            user_id = user_id, tokens = tokens)
        tokens <<- handled_error$tokens #update tokens globally in case we had to wait on token (updated time of use in that case)
        result <- handled_error$result
        error <- handled_error$error
        return(result)
      }
    )

    ## trying to parse JSON data
    json.data <- jsonlite::fromJSON(url.data)
    
    ## Catch if error from Twitter API normally
    if (length(json.data$error)!=0){
      if (verbose){message(url.data)}
      stop("error! Last cursor: ", cursor)
    }
    
    ## If we are skipping this user because we couldn't fully page through friends, return no friends
    if (is.na(json.data$next_cursor_str)) {
      return(list(friends = c(), tokens = tokens))
    }
    
    ## adding new IDS
    friends <- c(friends, as.character(json.data$ids))
    
    ## get cursor info
    prev_cursor <- json.data$previous_cursor_str
    cursor <- json.data$next_cursor_str
  }
  return(list(friends = friends, tokens = tokens, error = error))
}

# Function to handle an OAuthRequest error with Twitter API. 
# If we get an error, we'll sleep a few minutes, and if still nothing, 
# return an object that will cause the code to stop searching for this user.
handle_OAuth_error <- function(URL, params, method, cainfo, user_id, tokens, token_time_file) {
  
  url_return_data <- tryCatch(
    # Sleep and try again (checking if we need to switch tokens before querying API again).
    {
      print(paste0("We got an error from the Twitter API with user ", user_id, ". Let's sleep 3 minutes and try again."))
      Sys.sleep(180)
      # Check if we need to wait on using this token
      requests_left <- check_rate_limit(my_oauth)
      if (requests_left == 0) {
        tokens <- wait_on_rate_limit(tokens = tokens, current_token_number = current_token_number, token_time_file = token_time_file, time_buffer = 0.1)
      }
      # Try again
      current_token_number <- which(tokens$current_token == TRUE)
      oauth <- list(consumer_key = tokens$consumer_key[current_token_number],
                    consumer_secret = tokens$consumer_secret[current_token_number],
                    access_token = tokens$access_token[current_token_number],
                    access_token_secret = tokens$access_token_secret[current_token_number])
      my_oauth <- getOAuth(oauth, verbose = verbose)
      attempt <- my_oauth$OAuthRequest(URL = URL, params = params, method=method,cainfo=cainfo)
      return(list(result = attempt, tokens = tokens, error = NA))
    },
    
    # If still throwing error, return NA friend list since we can't get their friends.
    error = function(e) {
      print(paste0("We still can't get the friends for user ", user_id, ". Skipping..."))
      attempt <- jsonlite::toJSON(list(friends = "", previous_cursor_str = NA, next_cursor_str = NA))
      return(list(result = attempt, tokens = tokens, error = "Twitter API error"))
    })
  return(url_return_data)
}

# Estimate ideology using two methods from tweetscores package:
# (1) MLE and (2) the newer corerspondence analysis with more "elite" accounts included.
# We wrap the estimating functions in funcitons to supress the output message.
get_ideology <- function(user_id, friend_list) {
  
  # Estimate using MLE. If they don't follow any elite acccounts, it'll result in an error that we can catch.
  suppressMessages( estimate_mle <- tryCatch(estimateIdeology(user_id, friend_list, method = "MLE", verbose = FALSE),
                                             error = function(err) { NA }) )
  if (length(estimate_mle) > 1) {
    estimate_mle <- mean(estimate_mle$samples[, , 2]) #this corresponds to mean of theta samples in MLE estimation 
  }
  
  # Estimate using correspondance. If they don't follow any elite acccounts, it'll result in an error that we can catch.
  suppressMessages( estimate_corresp <- tryCatch(estimateIdeology2(user_id, friend_list, verbose = FALSE, replace_outliers = TRUE), #replace_outliers deals with -inf/inf values
                                                 error = function(err) { NA }))
  
  # Return estimates
  estimates <- data.frame(estimate_mle = estimate_mle, estimate_corresp = estimate_corresp)
  return(estimates)
  
}