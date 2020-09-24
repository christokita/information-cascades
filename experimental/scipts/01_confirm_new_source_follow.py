#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Sep 23 12:04:45 2020

@author: ChrisTokita

SCRIPT
Check to confirm participants followed the requested news source.
"""

####################
# Load packages
####################
import twitter_api_scraper.twee as twee
import logging
import pandas as pd
import math
import tweepy
import xlwings
import dropbox
import json
import os
import shutil


####################
# Set important paths and parameters
####################
# Path to survey data on Dropbox
dropbox_dir = '/Information Cascades Project/survey/data/'
survey_file = 'survey_rd1.xlsx'

# Twitter token file
token_file = '../api_keys/twitter_tokens/ckt_tokens1.json'

# Get dropbox token
with open('../api_keys/dropbox_token/dropbox_token.json') as f:
    key = json.load(f)
dropbox_token = key.get('access_token')
del key


####################
# Load data
####################
# Make temporary directory
tmp_dir = "/Users/ChrisTokita/Documents/Research/Tarnita Lab/Information Cascades/information-cascades/experimental/data/tmp/"
os.mkdir(tmp_dir)

# Download encrypted excel file and open for now
dbx = dropbox.Dropbox(dropbox_token)
dbx.files_download_to_file(download_path = tmp_dir + survey_file, path = dropbox_dir + survey_file)
wb = xlwings.Book(tmp_dir + survey_file) # this will prompt you to enter password in excel

# Read in excel data
sheet = wb.sheets['Sheet0']
survey_data = sheet.range('A1').options(pd.DataFrame, header = True, index = False, expand='table').value
survey_data = survey_data.iloc[1:] #first row is question text
survey_data = survey_data.reset_index(drop = True)

# Delete downloaded file
shutil.rmtree(tmp_dir)

# Create list of survey takers
participants = survey_data[['qid', 'twitter_username', 'hi_corr', 'news_source', 'ideology', 'ideology_lean']]
participants = participants.sort_values(by = 'twitter_username')

####################
# Create a Logger for Twitter API
####################
# Creates a logger
logger = logging.getLogger(__name__)  

# Set log level of detail to write
logger.setLevel(logging.INFO)

# Define file handler and set logger formatter
log_filename = f"../api_logs/check_users_survey_rd1.log"
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
# Get twitter user info
####################
logger.info("Now looking up our survey particpants to get their full twitter info...")  

# Determine how many batches of 100 user names we'll need (can only search 100 users at a time)
n_batches = math.ceil( len(participants['twitter_username']) / 100 )

# Loop thorugh our participants and look them up
info_cols =['user_id', 'user_id_str', 'user_name', 'friends', 'followers', 'statuses',
            'created_at', 'protected', 'verified', 'location', 'description', 'survey_user_name']
user_info = pd.DataFrame(columns = info_cols)
for i in np.arange(n_batches):
    
    # Check if we need to switch tokens (we shouldn't)
    switch_token = twee.rate_limit_check(API, all_tokens, logger)
    if switch_token == True:
        logger.info("Trying to switch tokens to ensure we don't hit a rate limit.")
        print("Trying to switch tokens to ensure we don't hit a rate limit.")
        API = twee.switch_token(API, all_tokens, logger)
        
    # Look up users
    username_batch = participants['twitter_username'].iloc[100*i:100*(i+1)]
    user_data = API.lookup_users(screen_names = list(username_batch), include_entities = False)
    
    # Parse and add to dataframe
    for user in user_data:
        new_row = pd.DataFrame([[user.id, "\"" + user.id_str + "\"", user.screen_name, user.friends_count, user.followers_count, user.statuses_count,
                                 user.created_at, user.protected, user.verified, user.location, user.description, ""]],
                               columns = info_cols)
        user_info = user_info.append(new_row, ignore_index = True)
        del new_row
    user_info['survey_user_name'] = username_batch.values
        
# Append twitter info to our particpant data
participants = participants.merge(user_info, left_on = 'twitter_username', right_on = 'survey_user_name')
participants = participants.drop(columns = ['twitter_username'])
participants.to_excel('')


####################
# Confirm they are following news source
####################
follow_cols = ['user_name', 'user_id', 'user_id_str', 'news_source', 'following']
participant_following = pd.DataFrame(columns = follow_cols)

for j in range(participants.shape[0]):
    # Check if we need to switch tokens (we shouldn't)
    switch_token = twee.rate_limit_check(API, all_tokens, logger)
    if switch_token == True:
        logger.info("Trying to switch tokens to ensure we don't hit a rate limit.")
        print("Trying to switch tokens to ensure we don't hit a rate limit.")
        API = twee.switch_token(API, all_tokens, logger)
    
    # Check if following
    follow_check = API.show_friendship(source_id = participants.user_id[j], 
                                       target_screen_name = participants.news_source[j])
    follow_obj = follow_check[0]
    
    # Append data
    new_row = pd.DataFrame([[participants.user_name[j], participants.user_id[j], participants.user_id_str[j], participants.news_source[j], follow_obj.following]],
                            columns = follow_cols)
    participant_following = participant_following.append(new_row, ignore_index = True)
    
    
participant_following.to_excel('')
            