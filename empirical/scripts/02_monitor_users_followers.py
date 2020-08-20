#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Aug 13 10:37:20 2020

@author: ChrisTokita

SCRIPT
Monitor the followers of our selected twitter users.
We will get the follower ID lists of the users at the beginning and end of our monitoring period (~1 month).
This script is intended to be run on an ec2 instance, but can also be done locally.

We intend to run this script at two time points:
    (1) Using the initial 2.5k users per news source, at start of 1 month period.
    (2) Using the final 1k users per news source, at end of 1 month period and after selecting based on ideology.
"""

####################
# Load packages
####################
import twitter_api_scraper.twee as twee
import twitter_api_scraper.aws as aws
import logging
import pandas as pd
import json
import tweepy
import time


####################
# Set important paths and parameters
####################
# Path to tokens
token_file = '../api_keys/twitter_tokens/ag_tokens2.json'

# New source to get followers from. Use Twitter formatting, i.e., "@xyz"
news_outlet_name = "dcexaminer"

# Set s3 keys (these can be found in '../data/s3_keys/s3_key.json')
with open('../api_keys/s3_keys/s3_key.json') as f:
    keys = json.load(f)
s3_key = keys.get('access_key_id')
s3_secret_key = keys.get('access_secret_key')
del keys

# s3 parameters
bucket_name = "user-followers-initial"
error_bucket_name = "users-initial-errors"


####################
# Create a Logger 
####################
# Creates a logger
logger = logging.getLogger(__name__)  

# Set log level of detail to write
logger.setLevel(logging.INFO)

# Define file handler and set logger formatter
log_filename = f"../api_logs/getfollowers_users_" + news_outlet_name + ".log"
file_handler = logging.FileHandler(log_filename, mode = "w") #writes over old log
formatter = logging.Formatter('%(asctime)s : %(levelname)s : %(name)s : %(message)s')
file_handler.setFormatter(formatter)

# Add file handler to logger
logger.addHandler(file_handler)


####################
# Load our Twitter users of interest
####################
# Load preliminary list of followers
selected_users = pd.read_csv('../data_derived/monitored_users/monitored_users_preliminary.csv', 
                             dtype = {'user_id': object, 'user_id_str': str, 'location': str, 'verified': bool, 'protected': bool},
                             lineterminator = '\n') #this prevents read errors from other symbols (e.g., '\r')

# Filter to just the users who follow the selected news_source
selected_users = selected_users[selected_users.news_source == news_outlet_name]
selected_users = selected_users.reset_index() #reset index so we can properly keep track of progress working through data

####################
# Initialize API
####################
logger.info("Loading Twitter tokens...")

# Load all tokens
all_tokens = twee.load_tokens(path = token_file, logger = logger)

# Set the initial token key to select the first token
token_key = "1"
logger.info("Initilizing the Twitter API with first token...")

# Select first token and it's details
consumer_key, consumer_secret, access_token, access_token_secret = twee.get_token(token_key, all_tokens, logger)

# Use these details to activate the API object
API = twee.set_api_keys(consumer_key = consumer_key, 
                        consumer_secret = consumer_secret, 
                        access_token = access_token, 
                        access_token_secret = access_token_secret,
                        logger = logger)


####################
# Get follower ID lists for each of our selected users
####################
# Format user IDs for use in searching
# We'll use the string ID column to be safe, since integers can sometimes get misread
selected_users['user_id_str'] = selected_users['user_id_str'].str.replace("\"", "")

# Remove users for whom we already have follower IDs in this s3 bucket (in case we are rerunning this script)
already_processed = aws.list_files_in_s3_bucket(bucket = bucket_name, 
                                                logger = logger, 
                                                aws_key = s3_key, 
                                                aws_secret_key = s3_secret_key)
already_processed = [item.replace("followerIDs_", "") for item in already_processed]
already_processed = [item.replace(".csv", "") for item in already_processed]
selected_users = selected_users[~selected_users['user_id_str'].isin(already_processed)]
del already_processed

# Load list of users who we know already had errors when trying to get their followers
users_with_errors = []
error_files = aws.list_files_in_s3_bucket(bucket = error_bucket_name, 
                                          logger = logger, 
                                          aws_key = s3_key, 
                                          aws_secret_key = s3_secret_key)
if "users_with_errors_" + news_outlet_name + ".csv" in error_files:
    error_users = aws.get_object_from_s3(file = "users_with_errors_" + news_outlet_name + ".csv", 
                                         bucket = error_bucket_name, 
                                         logger = logger, 
                                         aws_key = s3_key, 
                                         aws_secret_key = s3_secret_key)
    error_users = pd.read_csv(error_users['Body'], dtype = {'user_id': str})
    error_users['user_id_str'] = error_users['user_id_str'].str.replace("\"", "")
    users_with_errors = list(error_users['user_id_str'])
del error_files

# Loop through users, get follower ID list, and upload to s3
logger.info("Getting the follower IDs for the selected users who follower %s." % news_outlet_name)
for user_id in selected_users['user_id_str']:
    
    # Check if we need to switch tokens
    # If we hit the rate limit (e.g., switch back to a token that hasn't passed the 15 min mark),
    # tweepy will smartly have us sleep until we're good again
    switch_token = twee.rate_limit_check(API, all_tokens, logger)
    if switch_token == True:
        logger.info("Trying to switch tokens to ensure we don't hit a rate limit.")
        print("Trying to switch tokens to ensure we don't hit a rate limit.")
        API = twee.switch_token(API, all_tokens, logger)
        
    # Progress update by 5% increments
    which_row = selected_users[selected_users.user_id_str == user_id].index.item()
    if which_row % 125 == 0:
        progress = int((which_row / 125) * 5)
        print("...%d%% done." % progress)
        logger.info("...%d%% done." % progress)

    # Attempt to get follower IDs and upload to s3
    try:
        follower_ids = API.followers_ids(id = user_id)
        follower_ids_df = pd.DataFrame(data = follower_ids, columns = ['user_id'], dtype = str)
        follower_ids_df['user_id_str'] = "\"" + follower_ids_df['user_id'] +  "\""
        file_name = "followerIDs_" + user_id
        aws.upload_df_to_s3(data = follower_ids_df, 
                                 bucket = bucket_name, 
                                 logger = logger, 
                                 aws_key = s3_key, 
                                 aws_secret_key = s3_secret_key, 
                                 object_name = file_name,
                                 verbose = False)
        time.sleep(10)
       
    # Handle error if it arises    
    except tweepy.TweepError as error:
        response = str(error.response)
        reason = str(error.reason)
        print("Failed to get followers for user %s. Skipping..." % user_id)
        logger.info("Failed to get followers for user %s. Skipping..." % user_id)
        logger.info("ERROR CODE: %s; REASON: %s" % (response, reason))
        if user_id not in users_with_errors:
            users_with_errors.append(user_id)

        
# Upload list of users we failed to get followers for (likely the person proteceted their account in the meantime)
if len(users_with_errors) > 0:
    error_df = pd.DataFrame(data = users_with_errors, columns = ['user_id'])
    error_df['user_id_str'] = "\"" + error_df['user_id'] +  "\""
    aws.upload_df_to_s3(data = error_df, 
                        bucket = error_bucket_name, 
                        logger = logger, 
                        aws_key = s3_key, 
                        aws_secret_key = s3_secret_key, 
                        object_name = "users_with_errors_" + news_outlet_name)
