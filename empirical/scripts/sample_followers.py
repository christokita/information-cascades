#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Aug  7 12:55:35 2020

@author: ChrisTokita, modified from Matt R. Deverna

SCRIPT
Try sampling users from news sources
"""

####################
# Load packages
####################
import twitter_api_scraper.twee as twee
import logging
import time
import tweepy

####################
# Set important paths and parameters
####################
# Path to token set
token_file = '../data/api_tokens/ag_tokens1.json'

# New source to get followers from. Use Twitter formatting, i.e., "@xyz"
news_outlet_name = "@USATODAY"

####################
# Create a Logger 
####################
# Creates a logger
logger = logging.getLogger(__name__)  

# Set log level of detail to write
logger.setLevel(logging.INFO)

# Define file handler and set logger formatter
log_filename = f"../api_logs/test.log"
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
# Get 500k follower IDs of news source
####################
# When requesting follower IDs, we get 5,000 per page.
# Therefore, we want to do 100 pages worth.
# Follower IDs get a rate limit of 15 requests per 15 minutes.
page_count = 1
follower_ids = []
while page_count != 100:
    
    # Check if we need to switch tokens
    switch_token = twee.rate_limit_check(API, all_tokens, logger)
    if switch_token == True:
        logger.info("Trying to switch tokens to ensure we don't hit a rate limit.")
        print("Trying to switch tokens to ensure we don't hit a rate limit.")
        API = twee.switch_token(API, all_tokens, logger)

    # Get user IDs
    try: 
        ids = API.followers_ids(id = news_outlet_name)
        follower_ids.append(ids)
        time.sleep(10) #sleep for 30 seconds
    except: 
        logger.exception("New token still hasn't cleared rate limit. Let's wait a few minutes.")
        time.sleep(5 * 60) #sleep for 30 seconds



follower_ids = API.followers_ids(id = news_outlet_name)
follower = API.followers(id = news_outlet_name, count = 200)



