#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Sep 23 12:04:45 2020

@author: ChrisTokita

SCRIPT
Process our participant recruitment from the first round of the survey.
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
mturk_survey_file = 'mturk_survey_rd1_raw.xlsx'
fb_survey_file = 'fb_survey_rd1_raw.xlsx'

# Twitter token file
token_files = ['../api_keys/twitter_tokens/ckt_tokens1.json', '../api_keys/twitter_tokens/ag_tokens1.json']

# Get dropbox token
with open('../api_keys/dropbox_token/dropbox_token.json') as f:
    key = json.load(f)
dropbox_token = key.get('access_token')
del key, f


####################
# Read in raw survey data
####################
# Make temporary directory
tmp_dir = "/Users/ChrisTokita/Documents/Research/Tarnita Lab/Information Cascades/information-cascades/experimental/data/tmp/"
os.makedirs(tmp_dir, exist_ok = True)

# Download encrypted MTurk excel file and open to read in data
dbx = dropbox.Dropbox(dropbox_token)
dbx.files_download_to_file(download_path = tmp_dir + mturk_survey_file, path = path_to_survey_data + mturk_survey_file)
wb_mturk = xlwings.Book(tmp_dir + mturk_survey_file) # this will prompt you to enter password in excel

# Download encrypted FB excel file and open to read in data
dbx.files_download_to_file(download_path = tmp_dir + fb_survey_file, path = path_to_survey_data + fb_survey_file)
wb_facebook = xlwings.Book(tmp_dir + fb_survey_file) # this will prompt you to enter password in excel

# Read in excel data
sheet_mturk = wb_mturk.sheets['Sheet0']
sheet_fb = wb_facebook.sheets['Sheet0']
raw_survey_data_mturk = sheet_mturk.range('A1').options(pd.DataFrame, header = True, index = False, expand='table').value
raw_survey_data_mturk = raw_survey_data_mturk.iloc[1:] #first row is question text
raw_survey_data_mturk = raw_survey_data_mturk.reset_index(drop = True)
raw_survey_data_mturk['email'] = '' #we didn't collect email in Mturk, but did in FB survey
raw_survey_data_mturk['email_confirm'] = ''
raw_survey_data_mturk['recruited_from'] = 'mturk'

raw_survey_data_fb = sheet_fb.range('A1').options(pd.DataFrame, header = True, index = False, expand='table').value
raw_survey_data_fb = raw_survey_data_fb.iloc[1:] #first row is question text
raw_survey_data_fb = raw_survey_data_fb.reset_index(drop = True)
raw_survey_data_fb['recruited_from'] = 'fb'
del sheet_mturk, sheet_fb, wb_mturk, wb_facebook

# Delete downloaded file
shutil.rmtree(tmp_dir)


####################
# Clean up data, prepare separate survey data file and data crosswalk for twitter data
####################
# Drop columns not found in each other (these are the Q25 text columns)
mutual_columns = np.intersect1d(raw_survey_data_mturk.columns, raw_survey_data_fb.columns)
raw_survey_data_mturk = raw_survey_data_mturk[mutual_columns]
raw_survey_data_fb = raw_survey_data_fb[mutual_columns]

# Combine
raw_survey_data = raw_survey_data_mturk.append(raw_survey_data_fb, ignore_index = True)
raw_survey_data['username_manual_compile'] = raw_survey_data['username_manual_compile'].str.strip(to_strip = ' ') #remove any lurking leading/trailing spaces
del raw_survey_data_mturk, raw_survey_data_fb

# Only keep particpants who finished the survey  (doesn't really seem to affect anything since Qualtrics only gives completed answers)
do_not_pay = pd.DataFrame(data = raw_survey_data.qid[raw_survey_data.Finished == 'False'], columns = ['qid'])
raw_survey_data = raw_survey_data[raw_survey_data.Finished == 'True'] 

# Flag which usernames came from the VolunteerScience App and which came from manual entry
raw_survey_data['username_source'] = None
for index,row in raw_survey_data.iterrows():
    if (row['twitterhandle'] is not None) & (row['username_manual_compile'] is not None):
        row.username_source = 'VS_app'
    elif row['username_manual_compile'] is not None:
        row.username_source = 'manual_entry'
        
# Flag true moderates, who we cannot use for experiment
raw_survey_data['ideology'][raw_survey_data.moderate_lean == "Neither"] = "moderate"

# Get list of individuals show shared their username voluntarily and were sorted into a treament group
shared_username = raw_survey_data[~pd.isna(raw_survey_data['username_manual_compile'])].copy()
shared_username = shared_username[~pd.isna(shared_username['hi_corr'])].copy()
treatment_counts = shared_username.groupby(['ideology', 'hi_corr']).size() #moderates don't appear in this because they aren't sorted into a treatment!

# Make sure there aren't duplicated entries (sometimes people tried to do the study multiple times)
# We manually will check which one is the legitimate one (usually, which based on which news account they are actually following)
duplicated_usernames = shared_username['username_manual_compile'][shared_username.duplicated(subset = ['username_manual_compile'])]
check_duplicates = shared_username[shared_username['username_manual_compile'].isin(duplicated_usernames)]
check_duplicates = check_duplicates[['username_manual_compile', 'news_source', 'qid', 'recruited_from', 'username_source']]
duplicates_to_drop = ['305894', '586007', '345488', '368149', '899029'] #these were manually checked. See lab notebook.
shared_username = shared_username[~shared_username['qid'].isin(duplicates_to_drop)]

# Create list of partipants that will form basis of our crosswalk
user_crosswalk = shared_username[['qid', 'username_manual_compile', 'email']].copy()
user_crosswalk['username_manual_compile'] = user_crosswalk['username_manual_compile'].str.replace("^.*@", "") #clean up user names by removing leading "@". Some people put their name before the @.
user_crosswalk['username_manual_compile'] = user_crosswalk['username_manual_compile'].str.replace(" [^a-zA-Z0-9]+", "") #one person put a trailing marks at the end of the entry
user_crosswalk['username_manual_compile'] = user_crosswalk['username_manual_compile'].str.strip() #remove trailing/leading space
user_crosswalk = user_crosswalk.rename(columns = {'username_manual_compile': 'survey_user_name'})

# Remove twitter identifying data & irrelevant columns from survey
# This will be our set of survey data we can save for use later (after we filter to just the users of interest)
survey_data = shared_username.drop(columns = ['twitterhandle', 'username_manual_compile', 'username_backup',
                                              'email', 'email_confirm',
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
log_filename = "../api_logs/check_users_survey_rd1.log"
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
# Get twitter user info
####################
logger.info("Now looking up our survey particpants to get their full twitter info...")  

# Determine how many batches of 100 user names we'll need (can only search 100 users at a time)
usernames_to_check = shared_username['username_manual_compile']
n_batches = math.ceil( len(usernames_to_check) / 100 )

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
    username_batch = usernames_to_check.iloc[100*i:100*(i+1)]
    user_data = API.lookup_users(screen_names = list(username_batch), include_entities = False)
    
    # Parse and add to dataframe
    for user in user_data:
        new_row = pd.DataFrame([[user.id, "\"" + user.id_str + "\"", user.screen_name, user.friends_count, user.followers_count, user.statuses_count,
                                 user.created_at, user.protected, user.verified, user.location, user.description, ""]],
                               columns = info_cols)
        new_row['survey_user_name'] = username_batch[username_batch.str.lower() == user.screen_name.lower()].iloc[0] #in case of multiple entries of a username, just take first
        twitter_info = twitter_info.append(new_row, ignore_index = True)
        del new_row
            
# Add twitter user ID into our crosswalk, drop username
user_crosswalk = user_crosswalk.merge(twitter_info[['survey_user_name', 'user_id', 'user_id_str']], on = 'survey_user_name', how = 'left')
user_crosswalk = user_crosswalk.drop(columns = ['survey_user_name'])


####################
# Create our final set of particpants
####################
# Create dataset of relevant user info
participants = user_crosswalk.merge(survey_data[['qid', 'hi_corr', 'ideology', 'recruited_from']], on = 'qid', how = 'left')
participants = participants.merge(twitter_info[['user_id', 'user_id_str', 'user_name', 'protected']], on = ['user_id', 'user_id_str'], how = 'left')

# Flag who is in the final user pool based on our criteria of:
#     (1) provided real twitter username
#     (2) provided a twitter account that is NOT private
#     (3) provided us way to contact them, i.e., email for those we recruited from FB
valid_username = ~pd.isna(participants['user_id_str']) 
protected_account = participants['protected'].astype(bool)
fb_no_email = (participants.recruited_from == 'fb') & pd.isna(participants['email'])
participants['final_user_pool'] = valid_username & ~fb_no_email & ~protected_account 

# Narrow down our survey data, user_crosswalk, and participants to only those who are in the final pool
final_participants = participants[participants.final_user_pool == True].copy()
final_twitter_info = twitter_info[twitter_info['user_id_str'].isin(final_participants.user_id_str)]
final_survey_data = survey_data[survey_data['qid'].isin(final_participants['qid'])].copy()
final_user_crosswalk = user_crosswalk[user_crosswalk['qid'].isin(final_participants['qid'])].copy()

final_survey_data[['ideology', 'hi_corr']].value_counts()


####################
# Confirm they are following news source
####################
# Create temporary dataset of users and the news source they are following
users_to_check = final_survey_data[['qid', 'news_source']].copy()
users_to_check = users_to_check.merge(final_user_crosswalk, on = 'qid')
users_to_check['following_newssource_postrd1'] = np.nan

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
    users_to_check.loc[j, 'following_newssource_postrd1'] =  follow_obj.following
    del follow_check, follow_obj
    
# Note who is following news sources among our particpants
final_twitter_info = final_twitter_info.merge(users_to_check[['user_id', 'user_id_str', 'following_newssource_postrd1']], 
                                              on = ['user_id', 'user_id_str'],
                                              how = 'left')


####################
# Batch out users for second wave
####################
# Split users into hi-corr and low-corr treatment groups
high_corr_group = final_participants[final_participants.hi_corr == '1'].copy()
low_corr_group = final_participants[final_participants.hi_corr == '0'].copy()

# Assign survey wave
def assign_survey_wave(df, seed):
    np.random.seed(seed)
    n_rows = df.shape[0]
    n_repeats = math.ceil(n_rows / 3)
    batch_assignments = np.tile([1, 2, 3], n_repeats)
    batch_assignments = batch_assignments[0:n_rows]
    batch_assignments = np.random.choice(batch_assignments, size = n_rows, replace = False) #shuffle around
    return batch_assignments
    
high_corr_group['survey_wave'] = assign_survey_wave(high_corr_group, seed = 609)
low_corr_group['survey_wave'] = assign_survey_wave(low_corr_group, seed = 323)

# Create set of arrays for use in follow up survey
def create_survey_wave_lists(df):
    wave1 = list(df.user_name[df.survey_wave == 1])
    wave2 = list(df.user_name[df.survey_wave == 2])
    wave3 = list(df.user_name[df.survey_wave == 3])
    wave_lists = [wave1, wave2, wave3]
    return wave_lists
    
high_corr_waves = create_survey_wave_lists(high_corr_group)
low_corr_waves = create_survey_wave_lists(low_corr_group)    


####################
# Upload to dropbox
####################
# Make temporary directory
tmp_dir = "/Users/ChrisTokita/Documents/Research/Tarnita Lab/Information Cascades/information-cascades/experimental/data/tmp/"
os.mkdir(tmp_dir)
    
# Write files to temporary directory
final_user_crosswalk.to_excel(tmp_dir + 'user_crosswalk.xlsx', index = False)
do_not_pay.to_csv(tmp_dir + 'donotpay_rd1.csv', index = False)
final_survey_data.to_csv(tmp_dir + 'survey_data_rd1.csv', index = False)
final_twitter_info.to_csv(tmp_dir + 'participant_twitter_info.csv', index = False)

with open(tmp_dir + 'survey2_high_corr_waves.txt', 'w') as filehandle:
    filehandle.writelines("%s\n" % x for x in high_corr_waves)
with open(tmp_dir + 'survey2_low_corr_waves.txt', 'w') as filehandle:
    filehandle.writelines("%s\n" % x for x in low_corr_waves)    


# Upload to dropbox
for file in ['donotpay_rd1.csv', 'survey_data_rd1.csv', 'survey2_high_corr_waves.txt', 'survey2_low_corr_waves.txt']:
    with open(tmp_dir + file, "rb") as f:
        dbx.files_upload(f.read(), path = path_to_survey_data + file, mode = dropbox.files.WriteMode.overwrite)
        
with open(tmp_dir + 'participant_twitter_info.csv', "rb") as f:
    dbx.files_upload(f.read(), path = path_to_twitter_data + 'participant_twitter_info.csv', mode = dropbox.files.WriteMode.overwrite)
    
with open(tmp_dir + 'user_crosswalk.xlsx', "rb") as f:
    dbx.files_upload(f.read(), path = dropbox_dir + 'user_crosswalk.xlsx', mode = dropbox.files.WriteMode.overwrite)
  
# Delete files
shutil.rmtree(tmp_dir)         


####################
# Select payment for first round FB survey deployment (one $25 gift card per twenty five participants)
####################
# Make temporary directory
tmp_dir = "/Users/ChrisTokita/Documents/Research/Tarnita Lab/Information Cascades/information-cascades/experimental/data/tmp/"
os.mkdir(tmp_dir)

# Determine who won payment
fb_participants = raw_survey_data[raw_survey_data.recruited_from == 'fb']
n_giftcards = math.ceil(fb_participants.shape[0] / 25) #round up to nearest 25 to make sure people are paid more than not
fb_participants_with_emails = fb_participants[~pd.isna(fb_participants.email)]
pay_these_participants = fb_participants_with_emails['email'].sample(n = n_giftcards, replace = False, random_state = 609)
pay_these_participants = pd.DataFrame({'email': pay_these_participants})

# Uplod to Dropbox
pay_these_participants.to_csv(tmp_dir + 'TO_PAY_fb_participants.csv', index = False)
with open(tmp_dir + 'TO_PAY_fb_participants.csv', "rb") as f:
    dbx.files_upload(f.read(), path = path_to_survey_data + 'TO_PAY_fb_participants.csv', mode = dropbox.files.WriteMode.overwrite)
    
# Delete files
shutil.rmtree(tmp_dir)     