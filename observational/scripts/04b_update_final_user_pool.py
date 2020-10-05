#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Oct  5 15:33:15 2020

@author: ChrisTokita

SCRIPT
Update our final set of monitored users. 
Some users had their accounts deleted/protected/suspended over the last 6 weeks, 
so we need to subustitute in users from our broader preliminary pool to get up to 1k total.
"""

####################
# Load packages, set paths to data
####################
import pandas as pd
import numpy as np
import os
import re

# High-level data directory
data_directory = "/Volumes/CKT-DATA/information-cascades/observational/" #path to external HD
#data_directory = "../" #path if done within local directory

# File paths
ideology_file = data_directory + 'data_derived/monitored_users/monitored_users_ideology_scores.csv'
initial_users_file = data_directory + 'data_derived/monitored_users/monitored_users_preliminary.csv'
final_users_file = data_directory + 'data_derived/monitored_users/monitored_users_final-interim.csv'
path_to_users_with_errors = data_directory + 'data_derived/users_final_errors/'
output_name = data_directory + 'data_derived/monitored_users/monitored_users_final.csv'


####################
# Load initial and final user pool
####################
# Load our initial pool of users, add ideology scores
user_pool = pd.read_csv(initial_users_file, dtype = {'user_id':str})
user_pool['user_id'] = user_pool['user_id_str'].str.replace("\"", "")
ideology_data = pd.read_csv(ideology_file, dtype = {'user_id': object})
ideology_data['user_id'] = ideology_data['user_id_str'].str.replace("\"", "")
ideology_data = ideology_data.drop(columns = ['user_name', 'friend_count'])
user_pool = user_pool.merge(ideology_data, on = ['user_id', 'user_id_str'], how = 'outer')
user_pool = user_pool.drop(columns = ['issue'])

# Load final user pool (interim)
final_users = pd.read_csv(final_users_file, dtype = {'user_id':str})
final_users['user_id'] = final_users['user_id_str'].str.replace("\"", "")


####################
# Determine which users we were unable to get final (e.g., t + 6months) follower lists for
####################
# Load users who threw errors
error_users = pd.DataFrame(columns = ['user_id', 'user_id_str'])
error_files = os.listdir(path_to_users_with_errors)
error_files = [f for f in error_files if re.search("^[a-z]", f)]
for file in os.listdir(path_to_users_with_errors):
    error_list = pd.read_csv(path_to_users_with_errors + file, dtype = {'user_id': str})
    error_list['user_id'] = error_list['user_id_str'].str.replace("\"", "")
    error_users = error_users.append(error_list, ignore_index = True)
    del error_list
    
# Filter out users  with errors
final_users = final_users[~final_users['user_id_str'].isin(error_users.user_id_str)]
final_users['news_source'].value_counts()


####################
# Determine eligible users to select from initial pool of users
####################
# Load manually checked users (manually checked for eligibility in study)
man_checked_files = ['handcheck_liberal_users_DONE.xlsx', 'handcheck_conservative_users_DONE.xlsx']
eligibile_ids = np.array([])
for file in man_checked_files:
    checked_users = pd.read_excel(data_directory + 'data_derived/monitored_users/handcheck_users/' + file, 
                                  dtype = {'user_id': object})
    checked_users['user_id'] = checked_users['user_id_str'].str.replace("\"", "")
    checked_users = checked_users[pd.isna(checked_users.handcheck_remove)] #those not selected for removal
    eligibile_ids = np.append(eligibile_ids, checked_users['user_id'])
    del checked_users

# Remove inelgibile users (not correct ideology matched to news source; not in America)
eligible_set_of_users = user_pool[user_pool['user_id'].isin(eligibile_ids)]

# Remove users already in our final user dataset & who had errors (i.e., we weren't able to find their account after the 6 weeks)
eligible_set_of_users = eligible_set_of_users[~eligible_set_of_users['user_id_str'].isin(final_users.user_id_str)]
eligible_set_of_users = eligible_set_of_users[~eligible_set_of_users['user_id_str'].isin(error_users.user_id_str)]
eligible_set_of_users['news_source'].value_counts()


####################
# Add in replacement users
####################
updated_final_users = final_users.copy()
news_sources = final_users['news_source'].unique()
for source in news_sources:
    n_replacements = 1000 - final_users[final_users.news_source == source].shape[0]
    eligible_news_followers = eligible_set_of_users[eligible_set_of_users.news_source == source]
    replacement_users = eligible_news_followers.sample(n = n_replacements, random_state = 90041)
    updated_final_users = updated_final_users.append(replacement_users, ignore_index = True)
    
# Save
updated_final_users = updated_final_users.sort_values(by = 'news_source')    
updated_final_users.to_csv(output_name, index = False)






