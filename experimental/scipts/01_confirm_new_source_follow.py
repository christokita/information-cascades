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
import numpy as np
import math
import xlwings
import dropbox
import json
import os
import shutil


####################
# Set important paths and parameters
####################
# Path to survey data on Dropbox
dropbox_dir = '/Information Cascades Project/data/'
path_to_survey_data = dropbox_dir + 'survey_data/'
path_to_twitter_data = dropbox_dir + 'twitter_data/'

# File names of raw survey data
survey_file = 'raw_survey_rd1.xlsx'

# Twitter token file
token_file = '../api_keys/twitter_tokens/ckt_tokens1.json'

# Get dropbox token
with open('../api_keys/dropbox_token/dropbox_token.json') as f:
    key = json.load(f)
dropbox_token = key.get('access_token')
del key


####################
# Read in raw survey data
####################
# Make temporary directory
tmp_dir = "/Users/ChrisTokita/Documents/Research/Tarnita Lab/Information Cascades/information-cascades/experimental/data/tmp/"
os.mkdir(tmp_dir)

# Download encrypted excel file and open for now
dbx = dropbox.Dropbox(dropbox_token)
dbx.files_download_to_file(download_path = tmp_dir + survey_file, path = path_to_survey_data + survey_file)
wb = xlwings.Book(tmp_dir + survey_file) # this will prompt you to enter password in excel

# Read in excel data
sheet = wb.sheets['Sheet0']
raw_survey_data = sheet.range('A1').options(pd.DataFrame, header = True, index = False, expand='table').value
raw_survey_data = raw_survey_data.iloc[1:] #first row is question text
raw_survey_data = raw_survey_data.reset_index(drop = True)

# Delete downloaded file
shutil.rmtree(tmp_dir)


####################
# Clean up data, prepare separate survey data file and data crosswalk for twitter data
####################
# Only keep particpants who finished the survey
raw_survey_data = raw_survey_data[raw_survey_data.Finished == 'True'] 

# Get list of individuals we should not pay in the event they submit a HIT code for payment
do_not_pay = pd.DataFrame(data = raw_survey_data.qid[raw_survey_data.Finished == 'False'], columns = ['qid'])

# Create list of partipants that will form basis of our crosswalk
user_crosswalk = raw_survey_data[['qid', 'twitter_username']].copy()
user_crosswalk['twitter_username'] = user_crosswalk['twitter_username'].str.replace("^@", "") #clean up user names by removing leading "@"
user_crosswalk = user_crosswalk.rename(columns = {'twitter_username': 'survey_user_name'})

# Remove twitter identifying data & irrelevant columns from survey
# This will be our set of survey data we can save for use later.
survey_data = raw_survey_data.drop(columns = ['twitter_username', 'confirmed_username', 
                                              'Status', 'IPAddress', 'Progress',
                                              'RecipientLastName', 'RecipientFirstName', 'RecipientEmail',
                                              'ExternalReference', 'LocationLatitude', 'LocationLongitude',
                                              'DistributionChannel', 'UserLanguage'])


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
del log_filename

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
n_batches = math.ceil( len(user_crosswalk['survey_user_name']) / 100 )

# Loop thorugh our participants and look them up
info_cols =['user_id', 'user_id_str', 'user_name', 'friends', 'followers', 'statuses',
            'created_at', 'protected', 'verified', 'location', 'description', 'survey_user_name']
twitter_info = pd.DataFrame(columns = info_cols)
for i in range(n_batches):
    
    # Check if we need to switch tokens (we shouldn't)
    switch_token = twee.rate_limit_check(API, all_tokens, logger)
    if switch_token == True:
        logger.info("Trying to switch tokens to ensure we don't hit a rate limit.")
        print("Trying to switch tokens to ensure we don't hit a rate limit.")
        API = twee.switch_token(API, all_tokens, logger)
        
    # Look up users
    username_batch = user_crosswalk['survey_user_name'].iloc[100*i:100*(i+1)]
    user_data = API.lookup_users(screen_names = list(username_batch), include_entities = False)
    
    # Parse and add to dataframe
    for user in user_data:
        new_row = pd.DataFrame([[user.id, "\"" + user.id_str + "\"", user.screen_name, user.friends_count, user.followers_count, user.statuses_count,
                                 user.created_at, user.protected, user.verified, user.location, user.description, ""]],
                               columns = info_cols)
        new_row['survey_user_name'] = username_batch[username_batch.str.lower() == user.screen_name.lower()].item()
        twitter_info = twitter_info.append(new_row, ignore_index = True)
        del new_row
            
# Add twitter user ID into our crosswalk, drop username
user_crosswalk = user_crosswalk.merge(twitter_info[['survey_user_name', 'user_id', 'user_id_str']], on = 'survey_user_name', how = 'left')
user_crosswalk = user_crosswalk.drop(columns = ['survey_user_name'])


####################
# Confirm they are following news source
####################
# Create temporary dataset of users and the news source they are following
users_to_check = survey_data[['qid', 'news_source']].copy()
users_to_check = users_to_check.merge(user_crosswalk, on = 'qid')
users_to_check = users_to_check[~pd.isna(users_to_check['user_id'])].reset_index(drop = True)
users_to_check['following_news_source'] = np.nan

# loop through users to confirm they are following
for j in range(users_to_check.shape[0]):
    # Check if we need to switch tokens (we shouldn't)
    switch_token = twee.rate_limit_check(API, all_tokens, logger)
    if switch_token == True:
        logger.info("Trying to switch tokens to ensure we don't hit a rate limit.")
        print("Trying to switch tokens to ensure we don't hit a rate limit.")
        API = twee.switch_token(API, all_tokens, logger)
    
    # Check if following
    follow_check = API.show_friendship(source_id = users_to_check.user_id[j], 
                                       target_screen_name = users_to_check.news_source[j])
    follow_obj = follow_check[0]
    
    # Append data
    users_to_check.loc[j, 'following_news_source'] =  follow_obj.following
    del follow_check, follow_obj
    
# Note who is following news sources among our particpants
twitter_info = twitter_info.merge(users_to_check[['user_id', 'user_id_str', 'following_news_source']], 
                                  on = ['user_id', 'user_id_str'],
                                  how = 'left')
    
####################
# Upload to dropbox
####################
# Make temporary directory
tmp_dir = "/Users/ChrisTokita/Documents/Research/Tarnita Lab/Information Cascades/information-cascades/experimental/data/tmp/"
os.mkdir(tmp_dir)
    
# Write files to temporary directory
user_crosswalk.to_excel(tmp_dir + 'user_crosswalk.xlsx', index = False)
do_not_pay.to_csv(tmp_dir + 'donotpay_rd1.csv', index = False)
survey_data.to_csv(tmp_dir + 'survey_data_rd1.csv', index = False)
twitter_info.to_csv(tmp_dir + 'participant_twitter_info.csv', index = False)

# Upload to dropbox
for file in ['donotpay_rd1.csv', 'survey_data_rd1.csv']:
    with open(tmp_dir + file, "rb") as f:
        dbx.files_upload(f.read(), path = path_to_survey_data + file, mode = dropbox.files.WriteMode.overwrite)
        
with open(tmp_dir + 'participant_twitter_info.csv', "rb") as f:
    dbx.files_upload(f.read(), path = path_to_twitter_data + 'participant_twitter_info.csv', mode = dropbox.files.WriteMode.overwrite)
    
with open(tmp_dir + 'user_crosswalk.xlsx', "rb") as f:
    dbx.files_upload(f.read(), path = dropbox_dir + 'user_crosswalk.xlsx', mode = dropbox.files.WriteMode.overwrite)
  
# Delete files
shutil.rmtree(tmp_dir)         