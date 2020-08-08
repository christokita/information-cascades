#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Aug  7 12:55:35 2020

@author: ChrisTokita, modified from Matt R. Deverna

SCRIPT
Get subset of followers from news sources
"""

####################
# Load packages
####################
import twitter_api_scraper.twee as twee
import twitter_api_scraper.aws as aws
import logging
import time
import tweepy
import pandas as pd
import math


####################
# Set important paths and parameters
####################
# Path to tokens
token_file = '../data/api_tokens/ag_tokens1.json'

# New source to get followers from. Use Twitter formatting, i.e., "@xyz"
news_outlet_name = "usatoday"

# Set s3 keys (these can be found in '../data/s3_keys/s3_key.json')
# Hard coding here for use on virtual machines
s3_key = 'AKIA363GOONZA67VM4N7'
s3_secret_key = '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'

# s3 parameters
bucket_name = "news-source-followers"


####################
# Create a Logger 
####################
# Creates a logger
logger = logging.getLogger(__name__)  

# Set log level of detail to write
logger.setLevel(logging.INFO)

# Define file handler and set logger formatter
log_filename = f"../api_logs/getfollowers_" + news_outlet_name + ".log"
file_handler = logging.FileHandler(log_filename)
formatter = logging.Formatter('%(asctime)s : %(levelname)s : %(name)s : %(message)s')
file_handler.setFormatter(formatter)

# Add file handler to logger
logger.addHandler(file_handler)


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
# Get 250k follower IDs of news source
####################
# When requesting follower IDs, we get 5,000 per page.
# Therefore, we want to do 50 pages worth.
# Follower IDs get a rate limit of 15 requests per 15 minutes.
page_limit = 50
follower_ids = []
for page in tweepy.Cursor(API.followers_ids, id = news_outlet_name).pages(2):
    
    # Check if we need to switch tokens
    switch_token = twee.rate_limit_check(API, all_tokens, logger)
    if switch_token == True:
        logger.info("Trying to switch tokens to ensure we don't hit a rate limit.")
        print("Trying to switch tokens to ensure we don't hit a rate limit.")
        API = twee.switch_token(API, all_tokens, logger)

    # Get user IDs
    try: 
        follower_ids.extend(page)
        time.sleep(10) #sleep for 30 seconds
    except: 
        logger.exception("New token still hasn't cleared rate limit. Let's wait a few minutes.")
        time.sleep(5 * 60) #sleep for 30 seconds
        
# Write to s3
follower_ids_df = pd.DataFrame(follower_ids, columns = ['user_id'])
file_name = news_outlet_name + "_followerIDs"
aws.upload_df_to_s3(data = follower_ids_df, 
                     bucket = bucket_name, 
                     logger = logger, 
                     aws_key = s3_key, 
                     aws_secret_key = s3_secret_key, 
                     object_name = file_name)


####################
# Get basic user info for each of these followers
####################
num_blocks = math.ceil(len(follower_ids) / 100)
info_cols =['user_id', 'user_id_str', 'user_name', 'friends', 'followers', 'statuses',
            'created_at', 'protected', 'verified', 'location', 'description']
follower_info = pd.DataFrame(columns = info_cols)

for i in range(2):
    
    # Check if we need to switch tokens
    switch_token = twee.rate_limit_check(API, all_tokens, logger)
    if switch_token == True:
        logger.info("Trying to switch tokens to ensure we don't hit a rate limit.")
        print("Trying to switch tokens to ensure we don't hit a rate limit.")
        API = twee.switch_token(API, all_tokens, logger)
    
    # Which follower IDs to look up
    start = i * 100
    end = (i+1) * 100
    
    # Search
    users = API.lookup_users(user_ids = follower_ids[start:end], include_entities = False)
    
    # Parse and add to dataframe
    for user in users:
        new_row = pd.DataFrame([[user.id, "\"" + user.id_str + "\"", user.screen_name, user.friends_count, user.followers_count, user.statuses_count,
                                 user.created_at, user.protected, user.verified, user.location, user.description]],
                               columns = info_cols)
        follower_info = follower_info.append(new_row, ignore_index = True)

# Write to s3
file_name = news_outlet_name + "_followerinfo"
aws.upload_df_to_s3(data = follower_info, 
                     bucket = bucket_name, 
                     logger = logger, 
                     aws_key = s3_key, 
                     aws_secret_key = s3_secret_key, 
                     object_name = file_name)



