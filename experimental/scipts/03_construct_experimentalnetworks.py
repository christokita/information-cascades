#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Jan 11 11:37:52 2021

@author: ChrisTokita

SCRIPT
Use friend/follower lists to construct the full network of users in each treatment group
"""

####################
# Load packages
####################
import pandas as pd
import numpy as np
import xlwings
import dropbox
import json
import os
import shutil
import re


####################
# Set important paths and parameters
####################
# Path to survey data on Dropbox
dropbox_dir = '/Information Cascades Project/data/'
path_to_survey_data = dropbox_dir + 'survey_data/'
path_to_twitter_data = dropbox_dir + 'twitter_data/'

# File names of data files on DropBox
crosswalk_file = 'user_crosswalk.xlsx'
survey_file = 'survey_data_rd1.csv'

# Path to networks
network_data_dir = "/Volumes/CKT-DATA/information-cascades/experimental/data/"

# Get dropbox token
with open('../api_keys/dropbox_token/dropbox_token.json') as f:
    key = json.load(f)
dropbox_token = key.get('access_token')
del key, f


####################
# Load our list of particpants
####################
# Interface with Dropbox API
dbx = dropbox.Dropbox(dropbox_token)

# Load our user cross walk: make temporary directory, download/open encrypted file, read in data, and delete temporary directory
tmp_dir = "/Users/ChrisTokita/Documents/Research/Tarnita Lab/Information Cascades/information-cascades/experimental/data/tmp/"
os.makedirs(tmp_dir, exist_ok = True)
dbx.files_download_to_file(download_path = tmp_dir + crosswalk_file, path = dropbox_dir + crosswalk_file)
wb_crosswalk = xlwings.Book(tmp_dir + crosswalk_file) # this will prompt you to enter password in excel
sheet_crosswalk = wb_crosswalk.sheets['Sheet1']
user_crosswalk = sheet_crosswalk.range('A1').options(pd.DataFrame, header = True, index = False, expand='table').value
user_crosswalk['user_id'] = user_crosswalk['user_id_str'].str.replace("\"", "")
del wb_crosswalk, sheet_crosswalk
shutil.rmtree(tmp_dir)

# Load survey data to get info about which treatment group each individual is in
_, res = dbx.files_download(path_to_survey_data + survey_file)
survey_data = pd.read_csv(res.raw, dtype = {'qid': object})
del _, res


####################
# Split participants into hi and low corr lists
####################
user_crosswalk = user_crosswalk.merge(survey_data[['qid', 'hi_corr']], on = 'qid', how = 'left')

low_corr_users = user_crosswalk[user_crosswalk.hi_corr == 0]
low_corr_users = low_corr_users.sort_values(by = 'user_id')

high_corr_users = user_crosswalk[user_crosswalk.hi_corr == 1]
high_corr_users = high_corr_users.sort_values(by = 'user_id')



####################
# Construct initial network
####################
# Function to construct initial networks
def construct_initial_network(user_ids, initial_friendfollower_files):
    
    # Loop through users in this tereatment group
    friend_network = pd.DataFrame(columns = user_ids) #who follows whom
    follower_network = pd.DataFrame(columns = user_ids) #who is followed by whom
    for user in user_ids:
        
        # Grab friend/follower files
        user_files = [x for x in friendfollower_files if re.search(user, x)]
        
        # Users who were protected didn't get friend/follower lists
        if len(user_files) == 0:
            participants_followed = np.repeat(False, len(user_ids))
            participants_following = np.repeat(False, len(user_ids))
            
        # Otherwise, grab appropriate friend/follower lists
        else: 
            if len(user_files) > 2: # for late survey takers that we pulled a few days later
                user_follower_file = [x for x in user_files if re.search('followers.*2020-12-26', x)][0]
                user_friend_file = [x for x in user_files if re.search('friends.*2020-12-26', x)][0]
            else: 
                user_follower_file = [x for x in user_files if re.search('followers', x)][0]
                user_friend_file = [x for x in user_files if re.search('friends', x)][0]
                
            # Determine who they are following
            friends = pd.read_csv(network_data_dir + 'friend_lists/' + user_friend_file, dtype = {'user_id': object, 'user_id_str': object})
            friends['user_id'] = friends['user_id_str'].str.replace("\"", "")
            followers = pd.read_csv(network_data_dir + 'follower_lists/' + user_follower_file, dtype = {'user_id': object, 'user_id_str': object})
            followers['user_id'] = friends['user_id_str'].str.replace("\"", "")
    
            participants_followed = np.array( [x in friends['user_id'].values for x in user_ids] )
            participants_following = np.array( [x in followers['user_id'].values for x in user_ids] )
                    
        # Append to dataframes
        new_friend_row = pd.DataFrame([participants_followed.astype(int)], columns = user_ids, index = [user])
        friend_network = friend_network.append(new_friend_row)
        
        new_follower_row = pd.DataFrame([participants_following.astype(int)], columns = user_ids, index = [user])
        follower_network = follower_network.append(new_follower_row)
        
    # End function    
    return friend_network, follower_network
    
    
# Get list of friend/follower files
# NOTE: two users changed to Protected status during space between initial recruitment and monitoring of friend/follower network
# As a result, we have 307 total initial friend/follower lists
follower_list_files = os.listdir(network_data_dir + 'follower_lists')
friend_list_files = os.listdir(network_data_dir + 'friend_lists')

# Combine friend and follower lists into one to make parsing easier, narrow to just dates of interest
friendfollower_files = follower_list_files + friend_list_files
initial_friendfollower_files = [x for x in friendfollower_files if re.search('(2020-12-20|2020-12-26)', x)]

# Construct networks
lowcorr_initial_network, lowcorr_initial_follower_network = construct_initial_network(user_ids = low_corr_users['user_id'], initial_friendfollower_files = initial_friendfollower_files)
highcorr_initial_network, highcorr_initial_follower_network = construct_initial_network(user_ids = high_corr_users['user_id'], initial_friendfollower_files = initial_friendfollower_files)

# Determine which users we do not have lists for (for accounts that were Protected when we collected friend/follower lists)
unique_users_with_data = [re.search("[a-z]+_([0-9]+)_.*", x).group(1) for x in initial_friendfollower_files]
unique_users_with_data = np.unique(unique_users_with_data)
lowcorr_users_without_list = [x for x in low_corr_users['user_id'] if x not in unique_users_with_data] #only one user
highcorr_users_without_list =  [x for x in high_corr_users['user_id'] if x not in unique_users_with_data] #only one user

# Fill in missing data
lowcorr_initial_network.loc[lowcorr_users_without_list[0], :] = lowcorr_initial_follower_network[lowcorr_users_without_list[0]]
highcorr_initial_network.loc[highcorr_users_without_list[0], :] = highcorr_initial_follower_network[highcorr_users_without_list[0]]


####################
# Upload to dropbox
####################
# Make temporary directory
tmp_dir = "/Users/ChrisTokita/Documents/Research/Tarnita Lab/Information Cascades/information-cascades/experimental/data/tmp/"
os.mkdir(tmp_dir)

# Write files to temporary directory
lowcorr_initial_network.to_csv(tmp_dir + 'lowcorr_initial_network.csv', index = True)
highcorr_initial_network.to_csv(tmp_dir + 'highcorr_initial_network.csv', index = True)

# Upload to dropbox
for file in ['lowcorr_initial_network.csv', 'highcorr_initial_network.csv']:
    with open(tmp_dir + file, "rb") as f:
        dbx.files_upload(f.read(), path = path_to_twitter_data + file, mode = dropbox.files.WriteMode.overwrite)  
 
# Delete files
shutil.rmtree(tmp_dir)  