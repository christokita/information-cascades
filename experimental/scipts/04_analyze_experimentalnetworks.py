#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Jan 25 14:34:57 2021

@author: ChrisTokita

SCRIPT
Analyze experimental networks
"""

####################
# Load packages
####################
import pandas as pd
import numpy as np
import json
import dropbox
import xlwings
import os
import shutil
import matplotlib.pyplot as plt

# Decide which one
import networkx as nx
import igraph as ig


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

# Get dropbox token
with open('../api_keys/dropbox_token/dropbox_token.json') as f:
    key = json.load(f)
dropbox_token = key.get('access_token')
del key, f


####################
# Load our list of particpants & the networks
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

# Load our initial and final networks for each experimental treatment group
_, res = dbx.files_download(path_to_twitter_data + 'highcorr_initial_network.csv')
highcorr_network_initial = pd.read_csv(res.raw, index_col = 0)
highcorr_network_initial.index = highcorr_network_initial.columns #make sure indices are also dtype str
del _, res

_, res = dbx.files_download(path_to_twitter_data + 'highcorr_final_network.csv')
highcorr_network_final = pd.read_csv(res.raw, index_col = 0)
highcorr_network_final.index = highcorr_network_final.columns #make sure indices are also dtype str
del _, res

_, res = dbx.files_download(path_to_twitter_data + 'lowcorr_initial_network.csv')
lowcorr_network_initial = pd.read_csv(res.raw, index_col = 0)
lowcorr_network_initial.index = lowcorr_network_initial.columns #make sure indices are also dtype str
del _, res

_, res = dbx.files_download(path_to_twitter_data + 'lowcorr_final_network.csv')
lowcorr_network_final = pd.read_csv(res.raw, index_col = 0)
lowcorr_network_final.index = lowcorr_network_final.columns #make sure indices are also dtype str
del _, res

# Load survey data to get ideology scores
_, res = dbx.files_download(path_to_survey_data + survey_file)
survey_info = pd.read_csv(res.raw, dtype = {'qid': object})
del  _, res


####################
# Remove nodes that we were unable to access in the final round of data collection (t = ~4 weeks)
####################
# Load list of users we couldn't find
users_to_remove = pd.read_csv('/Volumes/CKT-DATA/information-cascades/experimental/data/error_users/error_users_2021-01-20-withtagging.csv', dtype = {'user_id': object, 'protected': bool})
users_to_remove['user_id'] = users_to_remove['user_id_str'].str.replace("\"", "")

# IMPORTANT: decide if we will include protected accounts and only excluded suspended/deleted accounts
users_to_remove = users_to_remove[users_to_remove.protected]

# Remove these nodes from our networks
def remove_missing_users(network, error_users):
    error_users = error_users[error_users['user_id'].isin(network.columns)]
    network = network.drop(columns = error_users['user_id'], index = error_users['user_id'])
    return network

highcorr_network_initial = remove_missing_users(highcorr_network_initial, users_to_remove) #drops 4 suspended accounts or 6 suspended/proected accounts
highcorr_network_final = remove_missing_users(highcorr_network_final, users_to_remove) #drops 4 suspended accounts or 6 suspended/proected accounts
lowcorr_network_initial = remove_missing_users(lowcorr_network_initial, users_to_remove) #drops 2 suspended accounts or 3 suspended/proected accounts
lowcorr_network_final = remove_missing_users(lowcorr_network_final, users_to_remove) #drops 2 suspended accounts or 3 suspended/proected accounts


####################
# Construct networks
####################
# Create complete list of users
users = user_crosswalk.merge(survey_info[['qid', 'ideology']], on = 'qid')

# Set ideology colors
ideology_pal = ['#006195', '#d54c54']

# Function to construct networkx object
def create_network_object(network, user_data):
    """
    Create a networkx network object for an experimental network.
    
    INPUTS:
    - network :      Adjacency matrix for experimental network (dataframe).
    - user_data :    Dataframe listing information (notably, ideology) about each participant in final user pool (dataframe).
    """
    
    # Grab node attributes
    user_nodes = pd.DataFrame({'user_id': network.columns})
    user_nodes = user_nodes.merge(user_data[['user_id', 'ideology']], on = 'user_id', how = 'left')
    types_map = {'liberal': 0, 'conservative': 1}
    user_nodes['ideology_numeric'] = user_nodes['ideology'].replace(types_map)
    
    # Make network and return
    g = ig.Graph.Adjacency(network.values.tolist(), mode = "directed")
    g.vs['user_id'] = user_nodes['user_id']
    g.vs['ideology'] = user_nodes['ideology']
    g.vs['ideology_numeric'] = user_nodes['ideology_numeric']
    return g

# Create network objects
g_highcorr_initial = create_network_object(network = highcorr_network_initial, user_data = users)
g_highcorr_final = create_network_object(network = highcorr_network_final, user_data = users)

g_lowcorr_initial = create_network_object(network = lowcorr_network_initial, user_data = users)
g_lowcorr_final = create_network_object(network = lowcorr_network_final, user_data = users)


####################
# Analyze ideological assortativity
####################
# Calculate absolute assortativity for each network
assort_highcorr_initial = g_highcorr_initial.assortativity_nominal(types = g_highcorr_initial.vs['ideology_numeric'], directed = True)
assort_highcorr_final = g_highcorr_final.assortativity_nominal(types = g_highcorr_final.vs['ideology_numeric'], directed = True)

assort_lowcorr_initial = g_lowcorr_initial.assortativity_nominal(types = g_lowcorr_initial.vs['ideology_numeric'], directed = True)
assort_lowcorr_final = g_lowcorr_final.assortativity_nominal(types = g_lowcorr_final.vs['ideology_numeric'], directed = True)

# Calculate shift in ideology
assortativity_change = pd.DataFrame({'treatment': ['high_corr', 'low_corr'],
                                     'assort_initial': [assort_highcorr_initial, assort_lowcorr_initial],
                                     'assort_final': [assort_highcorr_final, assort_lowcorr_final],
                                     'assort_shift': [assort_highcorr_final - assort_highcorr_initial, assort_lowcorr_final - assort_lowcorr_initial]})


####################
# Analyze tie breaks
####################
# Determine changes in network structure
highcorr_network_diff = highcorr_network_final - highcorr_network_initial
lowcorr_network_diff = lowcorr_network_final - lowcorr_network_initial

# Find tie breaks/adds
def compile_tie_changes(network_diff_matrix, user_data):
    change_locations = network_diff_matrix.values.nonzero()
    n_changes = len(change_locations[0])
    tiechanges = pd.DataFrame(columns = ['user_id', 'ideology', 'change', 'outgoing_user_id', 'outgoing_ideology', 'tie_type'])
    for i in range(n_changes):
        
        x = change_locations[0][i]
        y = change_locations[1][i]
        tie_change = network_diff_matrix.iloc[x, y]
        user_id = network_diff_matrix.index[x]
        outgoing_user_id = network_diff_matrix.columns[y]
        ideology = user_data.ideology[user_data.user_id == user_id]
        outgoing_ideology = user_data.ideology[user_data.user_id == outgoing_user_id]
        if ideology.iloc[0] == outgoing_ideology.iloc[0]:
            tie_type = 'same_ideology'
        elif ideology.iloc[0] != outgoing_ideology.iloc[0]:
            tie_type = 'diff_ideology'
        tiechanges = tiechanges.append({'user_id': user_id, 
                                        'ideology': ideology.iloc[0], 
                                        'change': tie_change, 
                                        'outgoing_user_id': outgoing_user_id, 
                                        'outgoing_ideology': outgoing_ideology.iloc[0],
                                        'tie_type': tie_type}, ignore_index = True)
    return tiechanges
    

highcorr_tiechanges = compile_tie_changes(highcorr_network_diff, users)
lowcorr_tiechanges = compile_tie_changes(lowcorr_network_diff, users)

# Determine same- vs. diff-ideology
highcorr_breaks_same = highcorr_tiechanges[(highcorr_tiechanges.tie_type == 'same_ideology') & (highcorr_tiechanges.change == -1)].shape[0]
highcorr_breaks_diff = highcorr_tiechanges[(highcorr_tiechanges.tie_type == 'diff_ideology') & (highcorr_tiechanges.change == -1)].shape[0]

lowcorr_breaks_same = lowcorr_tiechanges[(lowcorr_tiechanges.tie_type == 'same_ideology') & (lowcorr_tiechanges.change == -1)].shape[0]
lowcorr_breaks_diff = lowcorr_tiechanges[(lowcorr_tiechanges.tie_type == 'diff_ideology') & (lowcorr_tiechanges.change == -1)].shape[0]

highcorr_adds_same = highcorr_tiechanges[(highcorr_tiechanges.tie_type == 'same_ideology') & (highcorr_tiechanges.change == 1)].shape[0]
highcorr_adds_diff = highcorr_tiechanges[(highcorr_tiechanges.tie_type == 'diff_ideology') & (highcorr_tiechanges.change == 1)].shape[0]

lowcorr_adds_same = lowcorr_tiechanges[(lowcorr_tiechanges.tie_type == 'same_ideology') & (lowcorr_tiechanges.change == 1)].shape[0]
lowcorr_adds_diff = lowcorr_tiechanges[(lowcorr_tiechanges.tie_type == 'diff_ideology') & (lowcorr_tiechanges.change == 1)].shape[0]

tiechange_summary = pd.DataFrame({'treatment': ['high_corr', 'low_corr'],
                                 'breaks_same_ideol': [highcorr_breaks_same, lowcorr_breaks_same],
                                 'breaks_diff_ideol': [highcorr_breaks_diff, lowcorr_breaks_diff],
                                 'adds_same_ideol': [highcorr_adds_same, lowcorr_adds_same],
                                 'adds_diff_ideol': [highcorr_adds_diff, lowcorr_adds_diff]})

