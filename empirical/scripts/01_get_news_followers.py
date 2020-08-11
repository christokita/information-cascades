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
import json


####################
# Set important paths and parameters
####################
# Path to tokens
token_file = '../api_keys/twitter_tokens/ag_tokens1.json'

# New source to get followers from. Use Twitter formatting, i.e., "@xyz"
news_outlet_name = "usatoday"

# Set s3 keys (these can be found in '../data/s3_keys/s3_key.json')
with open('../api_keys/s3_keys/s3_key.json') as f:
    keys = json.load(f)
s3_key = keys.get('access_key_id')
s3_secret_key = keys.get('access_secret_key')
del keys

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
file_handler = logging.FileHandler(log_filename, mode = "w") #writes over old log
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
# Get 200k follower IDs of news source
####################
# Check if follower ID list already exists, if so skip this step and load data
file_name = news_outlet_name + "_followerIDs"
file_exists = aws.check_if_file_on_s3(file = file_name + '.csv',
                                      bucket = bucket_name, 
                                      logger = logger, 
                                      aws_key = s3_key, 
                                      aws_secret_key = s3_secret_key)
if not file_exists:
    # When requesting follower IDs, we get 5,000 per page.
    # Therefore, we want to do 40 pages worth.
    page_limit = 40
    follower_ids = []
    logger.info("Getting follower IDs for @%s...", news_outlet_name)
    page_number = 0
    for page in tweepy.Cursor(API.followers_ids, id = news_outlet_name).pages(page_limit):

        # Progress update
        page_number += 1
        if page_number%5 == 0:
            print("...page %d/%d." % (page_number, page_limit))
            logger.info("...page %d/%d.", page_number, page_limit)
        
        # Get user IDs
        try: 
            follower_ids.extend(page)
            time.sleep(60) #sleep for 60 seconds to meet rate limit
        except: 
            logger.exception("New token still hasn't cleared rate limit. Let's wait a few minutes.")
            time.sleep(5 * 60) #sleep for 30 seconds
            
    # Write to s3
    follower_ids_df = pd.DataFrame(follower_ids, columns = ['user_id'], dtype = str)
    aws.upload_df_to_s3(data = follower_ids_df, 
                         bucket = bucket_name, 
                         logger = logger, 
                         aws_key = s3_key, 
                         aws_secret_key = s3_secret_key, 
                         object_name = file_name)
    
# If follower ID list already exists load it   
else:
    follower_ids_df = aws.load_csv_from_s3(file = file_name + '.csv',
                                           bucket = bucket_name, 
                                           logger = logger, 
                                           aws_key = s3_key, 
                                           aws_secret_key = s3_secret_key)
    follower_ids = list(follower_ids_df['user_id'])
    
# Remove Follower ID dataframe to free up space
del follower_ids_df


####################
# Get basic user info for each of these followers
####################
logger.info("Now searching each individual follower of @{news_outlet_name}...")  
    
# When searching users, we can search 100 per search and do 900 searches per 15 min.
# Therefore, we want to do 2,000 searches.
num_blocks = math.ceil(len(follower_ids) / 100)
info_cols =['user_id', 'user_id_str', 'user_name', 'friends', 'followers', 'statuses',
            'created_at', 'protected', 'verified', 'location', 'description']
follower_info = pd.DataFrame(columns = info_cols)

for i in range(num_blocks):
    
    # Check if we need to switch tokens
    switch_token = twee.rate_limit_check(API, all_tokens, logger)
    if (switch_token == True) or (i == 0): #switch to start
        logger.info("Trying to switch tokens to ensure we don't hit a rate limit.")
        print("Trying to switch tokens to ensure we don't hit a rate limit.")
        API = twee.switch_token(API, all_tokens, logger)
    
    # Which follower IDs to look up
    start = i * 100
    end = (i+1) * 100
    
    # Progress update
    if start % 20000 == 0:
        total_followers = len(follower_ids)
        print("...looking up followers %d/%d." % (start, total_followers))
        logger.info("...looking up followers %d/%d." % (start, total_followers))
    
    # Search
    users = API.lookup_users(user_ids = follower_ids[start:end], include_entities = False)
    
    # Parse and add to dataframe
    for user in users:
        new_row = pd.DataFrame([[user.id, "\"" + user.id_str + "\"", user.screen_name, user.friends_count, user.followers_count, user.statuses_count,
                                 user.created_at, user.protected, user.verified, user.location, user.description]],
                               columns = info_cols)
        follower_info = follower_info.append(new_row, ignore_index = True)
    del new_row, users
    
    # Save in batches of 100k followers, to speed up data collection 
    if (end % 100000) == 0:
        
        # Write to s3
        chunk = int(end / 100000)
        file_name = news_outlet_name + "_followerinfo_" + str((chunk - 1)*100) + "-" + str(chunk*100) + "k"
        aws.upload_df_to_s3(data = follower_info, 
                             bucket = bucket_name, 
                             logger = logger, 
                             aws_key = s3_key, 
                             aws_secret_key = s3_secret_key, 
                             object_name = file_name)
        
        # Create new dataframe
        del follower_info
        follower_info = pd.DataFrame(columns = info_cols)

