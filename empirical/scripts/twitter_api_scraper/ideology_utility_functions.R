########################################
# Created on Tues Sept 1 17:00:00 2020
# @author: ChrisTokita
#
# SCRIPT
# Utility functions for estimating ideology scores of twitter users
########################################
library(tweetscores)


# Crude API rate limit check
check_rate_limit <- function(oauth) {
  
  user_oauth <- getOAuth(oauth)
  requests_left <- getLimitFriends(user_oauth)
  return(requests_left)
  
}

# Switch token to next token
switch_API_tokens <- function(tokens) {
  
  #  If it's the last in our set, go back to the first. 
  n_tokens <- nrow(tokens)
  prev_token_number <- which(tokens$current_token == TRUE) #note current token
  tokens$use_count[prev_token_number] <-   tokens$use_count[prev_token_number] + 1 #note that we've now used the previous token
  tokens$current_token <- FALSE #prepare to update current token
  if(prev_token_number == n_tokens) {
    tokens$current_token[1] <- TRUE
  } else {
    tokens$current_token[prev_token_number + 1] <- TRUE
  }
  current_token_number <- which(tokens$current_token == TRUE)
  print(paste("Switched to token", current_token_number))
  
  # Make sure it's been 15 since we last used this token. If not, sleep until we can start again.
  # If it's the first use of this token, then don't worry since we assume it hasn't been used in a while.
  if (tokens$use_count[current_token_number] > 0) {
    
    time_since_last_use <- difftime(Sys.time(), tokens$time_last_use[current_token_number], units = "mins")
    if (time_since_last_use < 15) {
      time_to_sleep <- 15 - as.numeric(time_since_last_use)
      print(paste0("Sleeping for ", round(time_to_sleep, 1), " minutes until we can start on the token ", current_token_number, " again."))
      Sys.sleep(time_to_sleep*60)
    }
    
  }
  
  # Note start of use of this token and return updated token set
  tokens$time_last_use[current_token_number] <- Sys.time()
  return(tokens)
  
}

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

# 
getLimitFriends <- function(my_oauth){
  url <- "https://api.twitter.com/1.1/application/rate_limit_status.json"
  params <- list(resources = "friends,application")
  response <- my_oauth$OAuthRequest(URL=url, params=params, method="GET",
                                    cainfo=system.file("CurlSSL", "cacert.pem", package = "RCurl"))
  return(unlist(jsonlite::fromJSON(response)$resources$friends$`/friends/ids`['remaining']))
}


# Estimate ideology using two methods from tweetscores package:
# (1) MLE and (2) the newer corerspondence analysis with more "elite" accounts included.
# We wrap the estimating functions in funcitons to supress the output message.
get_ideology <- function(user_id, frends) {
  
  # Estimate using MLE. If they don't follow any elite acccounts, it'll result in an error that we can catch.
  suppressMessages( estimate_mle <- tryCatch(estimateIdeology(user_id, friends, method = "MLE", verbose = FALSE),
                                             error = function(err) { NA }) )
  if (length(estimate_mle) > 1) {
    estimate_mle <- mean(estimate_mle$samples[, , 2]) #this corresponds to mean of theta samples in MLE estimation 
  }
  
  # Estimate using correspondance. If they don't follow any elite acccounts, it'll result in an error that we can catch.
  suppressMessages( estimate_corresp <- tryCatch(estimateIdeology2(user_id, friends, verbose = FALSE, replace_outliers = TRUE), #replace_outliers deals with -inf/inf values
                                                 error = function(err) { NA }))
  
  # Return estimates
  estimates <- data.frame(estimate_mle = estimate_mle, estimate_corresp = estimate_corresp)
  return(estimates)
  
}