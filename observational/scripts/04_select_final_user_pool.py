#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Sep  1 10:47:15 2020

@author: ChrisTokita

SCRIPT
Get our final list of 1k users for each news outlet.
We will aim to get 1k liberal followers of CBS and Vox, & 1k coservative followers of USA Today and Washington Examiner.
"""

####################
# Load packages, set paths to data
####################
import pandas as pd
import numpy as np

# High-level data directory
data_directory = "/Volumes/CKT-DATA/information-cascades/observational/" #path to external HD
#data_directory = "../" #path if done within local directory

# File paths
output_name = "final_monitored_users_ideology_scores.csv"
ideology_file = data_directory + 'data_derived/monitored_users/monitored_users_ideology_scores.csv'
users_file = data_directory + 'data_derived/monitored_users/monitored_users_preliminary.csv'
final_users_file = data_directory + 'data_derived/monitored_users/monitored_users_final.csv'


####################
# Load data to create set to handcheck
####################
# load and merge user data with ideology scores
users_data = pd.read_csv(users_file, dtype = {'user_id': object})
users_data['user_id'] = users_data['user_id_str'].str.replace("\"", "")
ideology_data = pd.read_csv(ideology_file, dtype = {'user_id': object})
ideology_data['user_id'] = ideology_data['user_id_str'].str.replace("\"", "")
ideology_data = ideology_data.drop(columns = ['user_name', 'friend_count'])
users_data = users_data.merge(ideology_data, on = ['user_id', 'user_id_str'], how = 'outer')

# Filter to ideological users of interest
conservative_users = users_data[users_data['news_source'].isin(['usatoday', 'dcexaminer'])]
conservative_users = conservative_users[conservative_users.ideology_corresp > 0]
liberal_users = users_data[users_data['news_source'].isin(['cbsnews', 'voxdotcom'])]
liberal_users = liberal_users[liberal_users.ideology_corresp < 0]

# Output for handcheck
conservative_users['handcheck_remove'] = ''
liberal_users['handcheck_remove'] = ''
conservative_users.to_excel(data_directory + 'data_derived/monitored_users/handcheck_users/handcheck_conservative_users.xlsx', index = False)
liberal_users.to_excel(data_directory + 'data_derived/monitored_users/handcheck_users/handcheck_liberal_users.xlsx', index = False)


####################
# Read in manually checked users, update our pool of users
####################
# Load manually checked liberal users
liberals_checked = pd.read_excel(data_directory + 'data_derived/monitored_users/handcheck_users/handcheck_liberal_users_DONE.xlsx', dtype = {'user_id': object})
liberals_checked['user_id'] = liberals_checked['user_id_str'].str.replace("\"", "")
liberals_checked = liberals_checked[pd.isna(liberals_checked.handcheck_remove)] #those not selected for removal
liberals_checked_IDs = liberals_checked['user_id']

# Load manually checked conservative users
conservatives_checked = pd.read_excel(data_directory + 'data_derived/monitored_users/handcheck_users/handcheck_conservative_users_DONE.xlsx', dtype = {'user_id': object})
conservatives_checked['user_id'] = conservatives_checked['user_id_str'].str.replace("\"", "")
conservatives_checked = conservatives_checked[pd.isna(conservatives_checked.handcheck_remove)] #those not selected for removal
conservative_checked_IDs = conservatives_checked['user_id']
del conservatives_checked, liberals_checked, conservative_users, liberal_users

# Create final set of users
checked_IDs = liberals_checked_IDs.append(conservative_checked_IDs)
eligible_set_of_users = users_data[users_data['user_id'].isin(checked_IDs)]
eligible_set_of_users = eligible_set_of_users.drop(columns = ['issue'])

####################
# Select our final set of 1k users from each news source
####################
final_users = eligible_set_of_users.groupby(['news_source']).sample(n = 1000, random_state = 90041)
final_users.to_csv(final_users_file, index = False)
