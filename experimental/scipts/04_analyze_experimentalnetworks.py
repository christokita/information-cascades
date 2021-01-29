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
import igraph as ig


####################
# Set important paths and parameters
####################
# Path to survey data on Dropbox
dropbox_dir = '/Information Cascades Project/data/'
path_to_survey_data = dropbox_dir + 'survey_data/'
path_to_twitter_data = dropbox_dir + 'twitter_data/'
outpath = '/Volumes/CKT-DATA/information-cascades/experimental/' #external HD
 
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
users_to_remove = pd.read_csv(outpath + 'data/error_users/error_users_2021-01-20-withtagging.csv', dtype = {'user_id': object, 'protected': bool})
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
assortativity_change = pd.DataFrame({'info_ecosystem': ['high_correlation', 'low_correlation'],
                                     'assort_initial': [assort_highcorr_initial, assort_lowcorr_initial],
                                     'assort_final': [assort_highcorr_final, assort_lowcorr_final],
                                     'assort_shift': [assort_highcorr_final - assort_highcorr_initial, assort_lowcorr_final - assort_lowcorr_initial]})

del g_highcorr_initial, g_highcorr_final, g_lowcorr_initial, g_lowcorr_final

####################
# Analyze ideological assortativity, with only tie breaks or new ties considered
####################
# Determine changes in network structure
highcorr_network_diff = highcorr_network_final - highcorr_network_initial
lowcorr_network_diff = lowcorr_network_final - lowcorr_network_initial

# Create final networks with only broken ties or new ties taken into account
def calculate_assort_with_breaksnews_only(initial_network, diff_network, user_data):
    
    # Replace new ties with zero
    network_breaksonly = diff_network.mask(diff_network == 1).fillna(0)
    g_breaksonly = create_network_object(network = initial_network + network_breaksonly, user_data = user_data)
    assort_breaksonly = g_breaksonly.assortativity_nominal(g_breaksonly.vs['ideology_numeric'], directed = True)

    # Don't remove broken ties
    network_newtiesonly = diff_network.mask(diff_network == -1).fillna(0)
    g_newtiesonly = create_network_object(network = initial_network + network_newtiesonly, user_data = user_data)
    assort_newtiesonly = g_newtiesonly.assortativity_nominal(g_newtiesonly.vs['ideology_numeric'], directed = True)

    return assort_breaksonly, assort_newtiesonly

    
# Calculate assortativity only accounting for new or broken ties, and add to summary dataframe
assort_highcorr_breaksonly, assort_highcorr_newtiesonly = calculate_assort_with_breaksnews_only(highcorr_network_initial, highcorr_network_diff, users)
assort_lowcorr_breaksonly, assort_lowcorr_newtiesonly = calculate_assort_with_breaksnews_only(lowcorr_network_initial, lowcorr_network_diff, users)

assortativity_change['assort_final_breaksonly'] = [assort_highcorr_breaksonly, assort_lowcorr_breaksonly]
assortativity_change['assort_final_newtiesonly'] = [assort_highcorr_newtiesonly, assort_lowcorr_newtiesonly]
assortativity_change['assort_shift_breaksonly'] = assortativity_change['assort_final_breaksonly'] - assortativity_change['assort_initial']
assortativity_change['assort_shift_newtiesonly'] = assortativity_change['assort_final_newtiesonly'] - assortativity_change['assort_initial']

# Write to file
assortativity_change.to_csv(outpath + 'data_derived/assortativity_data.csv', index = False,)


####################
# Analyze tie breaks at treatment group level
####################

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

del highcorr_breaks_same, lowcorr_breaks_same, highcorr_breaks_diff, lowcorr_breaks_diff, highcorr_adds_same, highcorr_adds_diff, lowcorr_adds_same, lowcorr_adds_diff

####################
# Functions to determine tie breaks at individual level
####################
# Calculate baseline composition of followers
def baseline_ideological_composition(initial_network, user_data):
    """
    This funciton will determine the number/fraction of same- and different-ideology of friends/followers in the initial network.
    Friends/followers depends on the orientation of the matrix initial_network. If given normally, it will calculate composition of friends. If transposed, it will calculate composition of followers.
    We will loop over columns, since the column will indicate who is following the user listed at the top of the column
    The network matrix is directed from row -> column, meaning a value indicates that the row individual is following the column individual
    """
    baseline_composition = pd.DataFrame(columns = ['user_id', 'ideology', 'initial_same_n', 'initial_diff_n', 'initial_same_freq', 'initial_diff_freq'])
    for user_id, row in initial_network.iterrows():
        ties = row[row == 1]
        ties_ideology = pd.DataFrame({'user_id': ties.index})
        ties_ideology = ties_ideology.merge(user_data[['user_id', 'ideology']], on = 'user_id', how = 'left')
        user_ideology = user_data.ideology[user_data.user_id == user_id].iloc[0]
        n_same_ideology = sum(ties_ideology.ideology == user_ideology)
        n_diff_ideology = sum(ties_ideology.ideology != user_ideology)
        if len(ties) > 0:
            freq_same_ideology = n_same_ideology / (n_same_ideology + n_diff_ideology)
            freq_diff_ideology = n_diff_ideology / (n_same_ideology + n_diff_ideology)
        else: 
            freq_same_ideology = freq_diff_ideology = np.nan
        baseline_composition = baseline_composition.append({'user_id': user_id,
                                                            'ideology': user_ideology,
                                                            'initial_same_n': n_same_ideology, 
                                                            'initial_diff_n': n_diff_ideology, 
                                                            'initial_same_freq': freq_same_ideology, 
                                                            'initial_diff_freq': freq_diff_ideology},
                                                           ignore_index = True)
    return baseline_composition

# Calculate relative cross-ideology unfollows
def relative_crossideol_unfollows(diff_network, initial_network, user_data, social_connections = None):
    
    # Grab users, prepare data to analyze friends or followers, and calculate baseline composition of those connections
    user_data = user_data[user_data['user_id'].isin(initial_network.columns)]
    if social_connections == 'friends':
        pass
    elif social_connections == 'followers':
        initial_network = initial_network.transpose()
        diff_network = diff_network.transpose()
    else:
        ValueError("You must specify if you want to analyze friends or followers of particpants.") 
    baseline_follower_composition = baseline_ideological_composition(initial_network, user_data)

    
    tie_change_stats = pd.DataFrame(columns = ['user_id', 'tiebreak_sameideol_n', 'tiebreak_diffideol_n', 'newtie_sameideol_n', 'newtie_diffideol_n', 'tiebreak_sameideol_freq', 'tiebreak_diffideol_freq'])
    for user_id,row in diff_network.iterrows():
        # Determine new/broken ties
        tie_breaks = pd.DataFrame({'user_id': row.index[row == -1]})
        new_ties = pd.DataFrame({'user_id': row.index[row == 1]})
        tie_breaks = tie_breaks.merge(user_data[['user_id', 'ideology']], on = 'user_id', how = 'left')
        new_ties = new_ties.merge(user_data[['user_id', 'ideology']], on = 'user_id', how = 'left')
        n_tiebreaks = tie_breaks.shape[0]
        n_newties = new_ties.shape[0]
        
        # Deterime if same/diff ideology
        user_ideology = user_data.ideology[user_data.user_id == user_id].iloc[0]
        n_tiebreaks_same = sum(tie_breaks.ideology == user_ideology)
        n_tiebreaks_diff = sum(tie_breaks.ideology != user_ideology)
        n_newties_same = sum(new_ties.ideology == user_ideology) 
        n_newties_diff = sum(new_ties.ideology != user_ideology) 
        
        # Determine fraction of ideol tie breaks
        if n_tiebreaks > 0:
            freq_tiebreaks_same = n_tiebreaks_same / (n_tiebreaks_same + n_tiebreaks_diff)
            freq_tiebreaks_diff = n_tiebreaks_diff / (n_tiebreaks_same + n_tiebreaks_diff)
        else: 
            freq_tiebreaks_same = freq_tiebreaks_diff = np.nan
            
        # Append
        tie_change_stats = tie_change_stats.append({'user_id': user_id, 
                                                    'n_tiebreaks': n_tiebreaks,
                                                    'n_newties': n_newties,
                                                    'tiebreak_sameideol_n': n_tiebreaks_same, 
                                                    'tiebreak_diffideol_n': n_tiebreaks_diff, 
                                                    'newtie_sameideol_n': n_newties_same, 
                                                    'newtie_diffideol_n': n_newties_diff, 
                                                    'tiebreak_sameideol_freq': freq_tiebreaks_same, 
                                                    'tiebreak_diffideol_freq': freq_tiebreaks_diff},
                                                   ignore_index = True)
    # Combine and return
    full_data_set = baseline_follower_composition.merge(tie_change_stats, on = 'user_id')
    return full_data_set


####################
# Analyze rate tie changes (loss of followers, i.e., being unfollowed)
####################
# Calculate relative rate of cross-ideology tie breaks
highcorr_followerchange_stats = relative_crossideol_unfollows(diff_network = highcorr_network_diff, 
                                                         initial_network = highcorr_network_initial, 
                                                         user_data = users,
                                                         social_connections = "followers")
highcorr_followerchange_stats['delta_tiebreak_diff'] = highcorr_followerchange_stats['tiebreak_diffideol_freq'] - highcorr_followerchange_stats['initial_diff_freq']

lowcorr_followerchange_stats = relative_crossideol_unfollows(diff_network = lowcorr_network_diff, 
                                                        initial_network = lowcorr_network_initial, 
                                                        user_data = users,
                                                        social_connections = "followers")
lowcorr_followerchange_stats['delta_tiebreak_diff'] = lowcorr_followerchange_stats['tiebreak_diffideol_freq'] - lowcorr_followerchange_stats['initial_diff_freq']

# Join together and output
highcorr_followerchange_stats['info_ecosystem'] = 'high_correlation'
lowcorr_followerchange_stats['info_ecosystem'] = 'low_correlation'
followerchange_stats = highcorr_followerchange_stats.append(lowcorr_followerchange_stats, ignore_index = True)
followerchange_stats = followerchange_stats.drop(columns = ['ideology']) #drop ideology for anonymity
followerchange_stats.to_csv(outpath + 'data_derived/follower_change_data.csv', index = False)


####################
# Analyze rate tie changes (loss of friends, i.e., act of unfollowing)
####################
# Calculate relative rate of cross-ideology tie breaks
highcorr_friendchange_stats = relative_crossideol_unfollows(diff_network = highcorr_network_diff, 
                                                         initial_network = highcorr_network_initial, 
                                                         user_data = users,
                                                         social_connections = "friends")
highcorr_friendchange_stats['delta_tiebreak_diff'] = highcorr_friendchange_stats['tiebreak_diffideol_freq'] - highcorr_friendchange_stats['initial_diff_freq']

lowcorr_friendchange_stats = relative_crossideol_unfollows(diff_network = lowcorr_network_diff, 
                                                        initial_network = lowcorr_network_initial, 
                                                        user_data = users,
                                                        social_connections = "friends")
lowcorr_friendchange_stats['delta_tiebreak_diff'] = lowcorr_friendchange_stats['tiebreak_diffideol_freq'] - lowcorr_friendchange_stats['initial_diff_freq']

# Join together and output
highcorr_friendchange_stats['info_ecosystem'] = 'high_correlation'
lowcorr_friendchange_stats['info_ecosystem'] = 'low_correlation'
friendchange_stats = highcorr_friendchange_stats.append(lowcorr_friendchange_stats, ignore_index = True)
friendchange_stats = friendchange_stats.drop(columns = ['ideology']) #drop ideology for anonymity
friendchange_stats.to_csv(outpath + 'data_derived/friend_change_data.csv', index = False)
