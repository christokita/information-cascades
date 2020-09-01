########################################
# Created on Tues Sept 1 17:00:00 2020
# @author: ChrisTokita
#
# SCRIPT
# Utility functions for estimating ideology scores of twitter users
########################################
library(tweetscores)


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


# Estimate ideology using two methods from tweetscores package:
# (1) MLE and (2) the newer corerspondence analysis with more "elite" accounts included.
# We wrap the estimating functions in funcitons to supress the output message.
get_ideology <- function(user_id, frends) {
  
  # Estimate using MLE. If they don't follow any elite acccounts, it'll result in an error that we can catch.
  suppressMessages( estimate_mle <- tryCatch(estimateIdeology(user_id, friends, method = "MLE", verbose = FALSE),
                                             error = function(err) { NA }) )
  if (!is.na(estimate_mle)) {
    estimate_mle <- mean(estimate_mle$samples[, , 2]) #this corresponds to mean of theta samples in MLE estimation 
  }
  
  # Estimate using correspondance. If they don't follow any elite acccounts, it'll result in an error that we can catch.
  suppressMessages( estimate_corresp <- tryCatch(estimateIdeology2(user_id, friends, verbose = FALSE),
                                                 error = function(err) { NA }))
  
  # Return estimates
  estimates <- data.frame(estimate_mle = estimate_mle, estimate_corresp = estimate_corresp)
  return(estimates)
  
}