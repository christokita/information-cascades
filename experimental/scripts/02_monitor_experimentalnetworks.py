#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Dec 15 14:56:23 2020

@author: ChrisTokita

SCRIPT
Process second round survey and monitor our experimental networks.
"""

####################
# Load packages
####################
import twitter_api_scraper.twee as twee
import tweepy
import logging
import pandas as pd
import numpy as np
import xlwings
import dropbox
import json
import os
import shutil
from datetime import date


####################
# Set important paths and parameters
####################
# Path to survey data on Dropbox
dropbox_dir = '/Information Cascades Project/data/'
path_to_survey_data = dropbox_dir + 'survey_data/'
path_to_twitter_data = dropbox_dir + 'twitter_data/'
outpath = "/Volumes/CKT-DATA/information-cascades/experimental/data/"

# File names of data files
crosswalk_file = 'user_crosswalk.xlsx'
twitter_info_file = 'participant_twitter_info.csv'

# Twitter token file
token_files = ['../api_keys/twitter_tokens/ckt_tokens1.json', '../api_keys/twitter_tokens/ag_tokens1.json']

# Get dropbox token
with open('../api_keys/dropbox_token/dropbox_token.json') as f:
    key = json.load(f)
dropbox_token = key.get('access_token')
del key, f

# Date of list pull (to assess whether initial or final state of networks)
retrieval_date = date.today().strftime('%Y-%m-%d')


####################
# Load our list of particpants
####################
# Make temporary directory
tmp_dir = "/Users/ChrisTokita/Documents/Research/Tarnita Lab/Information Cascades/information-cascades/experimental/data/tmp/"
os.makedirs(tmp_dir, exist_ok = True)

# Download encrypted user crosswalk excel file, open to read in data, and load as dataframe
dbx = dropbox.Dropbox(dropbox_token)
dbx.files_download_to_file(download_path = tmp_dir + crosswalk_file, path = dropbox_dir + crosswalk_file)
wb_crosswalk = xlwings.Book(tmp_dir + crosswalk_file) # this will prompt you to enter password in excel
sheet_crosswalk = wb_crosswalk.sheets['Sheet1']
user_crosswalk = sheet_crosswalk.range('A1').options(pd.DataFrame, header = True, index = False, expand='table').value
user_crosswalk['user_id'] = user_crosswalk['user_id_str'].str.replace("\"", "")
del wb_crosswalk, sheet_crosswalk

# Delete downloaded file
shutil.rmtree(tmp_dir)

####################
# Create a Logger for Twitter API
####################
# Creates a logger
logger = logging.getLogger(__name__)  

# Set log level of detail to write
logger.setLevel(logging.INFO)

# Define file handler and set logger formatter
log_filename = "../api_logs/monitor_networks.log"
file_handler = logging.FileHandler(log_filename, mode = "w") #writes over old log
formatter = logging.Formatter('%(asctime)s : %(levelname)s : %(name)s : %(message)s')
file_handler.setFormatter(formatter)
del log_filename

# Add file handler to logger
logger.addHandler(file_handler)


####################
# Initialize API
####################
logger.info("Loading Twitter tokens...")

# Load all tokens
all_tokens = {}
for i in np.arange(len(token_files)):
    token = twee.load_tokens(path = token_files[i], logger = logger)
    all_tokens.update( { str(i+1): token['1'] } )


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
# Pull friend and follower lists for each of our users of interest
####################
# Remove users we already collected (in case we need to run this script again due to error)
users_to_check = user_crosswalk['user_id']
friend_list_files = os.listdir(outpath + "friend_lists/")
follower_list_files = os.listdir(outpath + "follower_lists/")
have_friend_list = [x for x in users_to_check if 'friends_{}_{}.csv'.format(x, retrieval_date) in friend_list_files]
have_follower_list = [x for x in users_to_check if 'followers_{}_{}.csv'.format(x, retrieval_date) in follower_list_files]
have_all_data = np.intersect1d(have_friend_list, have_follower_list) #only remove users that we have both a friend and follower list for
users_to_check = users_to_check[~users_to_check.isin(have_all_data)]

# Loop through users and get their friend/follower ID lists
error_users = []
for user_id in users_to_check:
    
    # List to collect friends and followers
    friend_ids = []
    follower_ids = []
    
    # Check if we need to switch tokens, then get friends
    switch_token = twee.rate_limit_check_specific(API, all_tokens, logger, query_of_interest = "friends")
    if switch_token == True:
        logger.info("Trying to switch tokens to ensure we don't hit a rate limit.")
        print("Trying to switch tokens to ensure we don't hit a rate limit.")
        API = twee.switch_token(API, all_tokens, logger)
     
    try:    
        # Page through friends
        for page in tweepy.Cursor(API.friends_ids, user_id = user_id).pages():
            friend_ids.extend(page)
            del page
            
        # Write to file
        friends_df = pd.DataFrame({'user_id': friend_ids, 'user_id_str': ["\"" + str(x) + "\"" for x in friend_ids]})
        friend_file_name = "friends_{}_{}.csv".format(user_id, retrieval_date)
        friends_df.to_csv(outpath + "friend_lists/" + friend_file_name, index = False)
    except:
        error_users.append(user_id)
        print("Error with getting friends of user %s. Skipping..." % user_id)
    
    # Check if we need to switch tokens, then get followers
    switch_token = twee.rate_limit_check_specific(API, all_tokens, logger, query_of_interest = "followers")
    if switch_token == True:
        logger.info("Trying to switch tokens to ensure we don't hit a rate limit.")
        print("Trying to switch tokens to ensure we don't hit a rate limit.")
        API = twee.switch_token(API, all_tokens, logger)
    
    try:    
        # Page through followers
        for page in tweepy.Cursor(API.followers_ids, user_id = user_id).pages():
            follower_ids.extend(page)
            del page
    
        # Write to file
        followers_df = pd.DataFrame({'user_id': follower_ids, 'user_id_str': ["\"" + str(x) + "\"" for x in follower_ids]})
        follower_file_name = "followers_{}_{}.csv".format(user_id, retrieval_date)
        followers_df.to_csv(outpath + "follower_lists/" + follower_file_name, index = False)
    except:
        error_users.append(user_id)
        print("Error with getting followers of user %s. Skipping..." % user_id)


error_users = np.unique(error_users)
error_users = pd.DataFrame({'user_id': error_users, 'user_id_str': ["\"" + str(x) + "\"" for x in error_users]})
error_users.to_csv(outpath + 'error_users/error_users_{}.csv'.format(retrieval_date), index = False)
