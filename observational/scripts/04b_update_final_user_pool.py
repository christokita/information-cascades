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
import re

# High-level data directory
data_directory = "/Volumes/CKT-DATA/information-cascades/observational/" #path to external HD
#data_directory = "../" #path if done within local directory

# File paths
ideology_file = data_directory + 'data_derived/monitored_users/monitored_users_ideology_scores.csv'
users_file = data_directory + 'data_derived/monitored_users/monitored_users_preliminary.csv'
final_users_file = data_directory + 'data_derived/monitored_users/monitored_users_final-interim.csv'
path_to_users_with_errors = data_directory + 'data_derived/users_final_errors/'
output_name = data_directory + 'data_derived/monitored_users/monitored_users_final.csv'


####################
# Determine which users we were unable to get final (e.g., t + 6months) follower lists for
####################
error_users = pd.DataFrame(columns = ['user_id', 'user_id_str'])
error_files = os.listdir(path_to_users_with_errors)
error_files = [f for f in error_files if re.search("^[a-z]", f)]
for file in os.listdir(path_to_users_with_errors):
    error_list = pd.read_csv(path_to_users_with_errors + file, dtype = {'user_id': str})
    error_list['user_id'] = error_list['user_id_str'].str.replace("\"", "")
    error_users = error_users.append(error_list, ignore_index = True)
    del error_list