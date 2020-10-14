#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Oct 13 16:38:00 2020

@author: ChrisTokita

SCRIPT
Determine the new broken ties (i.e., new follows and unfollows) among the followers of our monitored users over the 6 week period.
"""

####################
# Load packages, set paths to data
####################
import pandas as pd
import numpy as np
import tweepy
import twitter_api_scraper.twee as twee
import math

# Twitter tokens
token_file = '../api_keys/twitter_tokens/ag_tokens2.json'

# path to data
data_directory = '/Volumes/CKT-DATA/information-cascades/observational/'
dir_initial_followers = data_directory + 'data_derived/user_followers_initial/'
dir_final_followers = data_directory + 'data_derived/user_followers_final/'
final_user_file = data_directory + 'data_derived/monitored_users/monitored_users_final.csv'
output_data_path = data_directory + 'data_derived/monitored_users/changed_ties.csv'
output_summary_path = data_directory + 'data_derived/monitored_users/changed_ties_user_summary.csv'


####################
# Load data
####################
final_users = pd.read_csv(final_user_file, dtype = {'user_id': str})
final_users['user_id'] = final_users['user_id_str'].str.replace("\"", "") #make sure user id is correct by using string form


####################
# Determine new and broken social ties (followers) among users
####################
changed_ties = [] #collect specific followers that formed or broke ties
tie_change_summary = [] #summarise the change in followers for each of our users
for user_id in final_users['user_id']:
    
    # Print progress
    five_percent_chunk = len(final_users['user_id']) / 20
    progress = np.where(user_id == final_users['user_id'])[0]
    if progress % five_percent_chunk == 0:
        progress = 100 * progress/len(final_users['user_id'])
        print('%d%% done...' %  int(progress))
    del five_percent_chunk, progress
    
    # Load initial and final follower lists
    initial_followers = pd.read_csv(dir_initial_followers + 'followerIDs_' + user_id + '.csv', dtype = {'user_id': str})
    initial_followers['user_id'] = initial_followers['user_id_str'].str.replace("\"", "")
    final_followers = pd.read_csv(dir_final_followers + 'followerIDs_' + user_id + '.csv', dtype = {'user_id': str})
    final_followers['user_id'] = final_followers['user_id_str'].str.replace("\"", "")
    
    # Determine new and broken social ties
    broken_ties = np.setdiff1d(initial_followers['user_id'], final_followers['user_id'])
    new_ties = np.setdiff1d(final_followers['user_id'], initial_followers['user_id'])
    n_initial_followers = len(initial_followers['user_id'])
    n_final_followers = len(final_followers['user_id'])
    del initial_followers, final_followers
    
    # Summarise changes in this user's followers and append to total dataset
    user_change_summary = pd.DataFrame({'user_id': user_id, 'user_id_str': "\"" + user_id + "\"", 
                                        'initial_follower_count': n_initial_followers, 'final_follower_count': n_final_followers,
                                        'new_follows': len(new_ties), 'unfollows': len(broken_ties),
                                        'net_change': len(new_ties) - len(broken_ties), 'total_change': len(new_ties) + len(broken_ties)}, index = [0])
    tie_change_summary.append(user_change_summary)
    
    # Create data frame of this users tie change data and append to total dataset
    user_changed_ties = pd.DataFrame({'user_id': user_id, 'user_id_str': "\"" + user_id + "\"", 
                                    'follower_id': np.append(new_ties, broken_ties), 'follower_id_str': "\"" + np.append(new_ties, broken_ties) + "\"",
                                    'tie_change': np.nan })
    user_changed_ties.loc[user_changed_ties['follower_id'].isin(broken_ties), 'tie_change'] = "broken" #mark broken ties
    user_changed_ties.loc[user_changed_ties['follower_id'].isin(new_ties), 'tie_change'] = "new" #mark new ties
    changed_ties.append(user_changed_ties)
    del user_changed_ties, broken_ties, new_ties
    
# Join together list of dataframes
changed_ties = pd.concat(changed_ties)
changed_ties = changed_ties.reset_index(drop = True)
tie_change_summary = pd.concat(tie_change_summary)
tie_change_summary = tie_change_summary.reset_index(drop = True)
  
# Save summary
tie_change_summary.to_csv(output_summary_path, index = False)  

####################
# Prep Twitter API to search the users who broke/formed ties
####################
# Load our tokens
all_tokens = twee.load_tokens(path = token_file)
token_key = "1"
token = all_tokens[token_key] #only use one token!
del all_tokens, token_key

# OAuth authenticate, using the keys and tokens
auth = tweepy.OAuthHandler(token['consumer_key'], token['consumer_secret'])
auth.set_access_token(token['access_token'], token['access_token_secret'])

# Creation of the actual interface, using authentication
API = tweepy.API(auth,
                 wait_on_rate_limit=True,
                 wait_on_rate_limit_notify=True,
                 retry_count = 1, 
                 retry_delay = 5,
                 timeout = 10)


####################
# Check which users are suspended/can't be found
####################
# We can only search 100 users at a time, so loop through chunks of 100 users
chunks = math.ceil(len(changed_ties) / 100)
changed_ties_complete = []
for i in np.arange(chunks):
            
    # Print progress
    five_percent_chunk = round( chunks / 20 )
    if i % five_percent_chunk == 0:
        progress = 100 * round(i/chunks, 2)
        print('%d%% done...' %  int(progress))
        del progress

    # Look up set of users
    user_chunk = changed_ties.iloc[100*i:100*(i+1)]
    user_search_results = API.lookup_users(user_ids = list(user_chunk['follower_id']) )
    
    # Process search results
    user_info = []
    for row in user_search_results:
        info = pd.DataFrame({'follower_id': row.id_str, 'protected': row.protected}, index = [0])
        user_info.append(info)
        del info
    user_info = pd.concat(user_info)
    user_info = user_info.reset_index(drop = True)
    
    # Merge in user info and append to total dataset
    user_chunk = user_chunk.merge(user_info, how = 'left', on = 'follower_id')
    user_chunk['found_on_twitter'] = True
    user_chunk.loc[pd.isna(user_chunk['protected']), 'found_on_twitter'] = False
    changed_ties_complete.append(user_chunk)
    
# Bind together and save
changed_ties_complete = pd.concat(changed_ties_complete)
changed_ties_complete.to_csv(output_data_path, index = False)
    
