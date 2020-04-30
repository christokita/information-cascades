#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Feb 13 09:59:28 2020

@author: ChrisTokita

DESCRIPTION:
Script to process fitness trial data.
"""

####################
# Load libraries and packages
####################
import pandas as pd
import numpy as np
import os
import re
import copy

####################
# List files to be read
####################
# Set if you want to output raw cascade data (each time step of each trial))
raw_data = False

# Directory where simulation data is found
fit_dir = '../data_sim/network_break/fitness_data/'  
thresh_dir = '../data_sim/network_break/thresh_data/'
tags = 'gamma' #file tags that designate runs from a particular simulation

# For output
outpath = '../data_derived/network_break/fitness_trials/'
filetags = '' #added info, particularly for suppl simulations e.g., 'fitness_<filetag>_
if len(filetags) > 0:
    filetags = '_' + filetags

# List runs
runs = os.listdir(fit_dir)
runs = [run for run in runs if re.findall(tags + '[-.0-9]+', run)]
runs.sort()


####################
# Load and bind fitness trial data, both cascades and indvidiual behavior
####################
# Dataframes to hold data
fitness_cascades = pd.DataFrame() #this will be summarized data because cascade data is so large
fitness_behavior = pd.DataFrame()

# Loop through runs of model (different parameter combinations)
for run in runs:
    
    # Load statement
    print("Starting on \'" + run + "\'...")
    
    # Create dataframess for summarized and raw cascade data, if desired
    cascade_summarized = pd.DataFrame()
    all_cascade_pre = pd.DataFrame()
    all_cacade_post = pd.DataFrame()
    
     # Get gamma value
    gamma = float(re.search('[a-z]+([-\.0-9]+)', run).group(1))
    
    # List cascade and and behavior files
    all_files = os.listdir(fit_dir + run +'/')
    replicates = [re.search('(rep[0-9]+)', file).group(1) for file in all_files]
    replicates = list(set(replicates)) #get unique values
    replicates.sort()
    
    # Loop through replciate simulations within that parameter run
    for replicate in replicates:
        
        # Get replicate number 
        rep = int(re.search('([0-9]+)', replicate).group(1))
        
        ##### Cascade data #####
        # Read in data, both pre- and post- main model simulation
        pre_cascade = pd.read_pickle(fit_dir + run +'/pre_cascades_' + replicate + '.pkl')
        post_cascade = pd.read_pickle(fit_dir + run +'/post_cascades_' + replicate + '.pkl')
        cascade = pre_cascade.append(post_cascade, ignore_index = True)
        
        # Calculate additional statistics: Cascades
        cascade['avg_cascade_size'] = cascade['total_active'] / cascade ['samplers_active']
        cascade['active_diff'] = abs(cascade['active_A'] - cascade['active_B'])
        cascade['cascade_bias'] = cascade['active_diff'] / cascade['total_active']
        cascade['gamma'] = gamma
        cascade['replicate'] = rep
        
        ##### Behavior data #####
        # Read in data, both pre- and post- main model simulation
        pre_behavior = pd.read_pickle(fit_dir + run +'/pre_behavior_' + replicate + '.pkl')
        post_behavior = pd.read_pickle(fit_dir + run +'/post_behavior_' + replicate + '.pkl')
        thresholds = np.load(thresh_dir + run + '/thresh_' + replicate + '.npy')
        behavior = pre_behavior.append(post_behavior, ignore_index = True)

        # Calculate additional statistics: Behavior
        behavior = behavior.drop(columns = 'individual')
        behavio[['true_positive']] = behavior.true_positive / trial_length
        behavio['true_positive'] = behavior.true_positive / trial_length
        behavior['threshold'] = np.tile(thresholds, (2, 1)) #repeat entire array twice since pre and post are bound together
        behavior['sensitivity'] = behavior.true_positive / (behavior.true_positive + behavior.false_negative)
        behavior['specificity'] = behavior.true_negative / (behavior.true_negative + behavior.false_positive)
        behavior['precision'] = behavior.true_positive / (behavior.true_positive + behavior.false_positive)
        behavior['gamma'] = gamma
        behavior['replicate'] = rep
        
        # Append raw cascde data to larger dataframe, if desired
        if raw_data == True:
            pre = cascade[cascade['trial'] == "pre"]
            post = cascade[cascade['trial'] == "post"]
            if all_cascade_pre.empty:
                all_cascade_pre = copy.deepcopy(pre)
                all_cascade_post = copy.deepcopy(post)
            else:
                all_cascade_pre = all_cascade_pre.append(pre, ignore_index = True)
                all_cascade_post = all_cascade_post.append(post, ignore_index = True)
            del pre, post
            
        # Append raw behavior data to larger dataframe
        if fitness_behavior.empty:
            fitness_behavior = copy.deepcopy(behavior)
        else:
            fitness_behavior = fitness_behavior.append(behavior, ignore_index = True)
        
        # Summarise cascade data for that replicate and append
        cascade = cascade.drop(columns = ['t']) #drop time step column for summarizing
        cascade_sum = cascade.groupby('trial').mean().reset_index()
        if fitness_cascades.empty:
            fitness_cascades = copy.deepcopy(cascade_sum)
        else:
            fitness_cascades = fitness_cascades.append(cascade_sum, ignore_index = True, sort = False)
    
    # Save raw data for that parameter run if desired
    if raw_data == True:
        if not os.path.isdir(outpath + 'raw_fitness_cascade_data/'):
            os.mkdir(outpath + 'raw_fitness_cascade_data/')
        all_cascade_pre.to_csv(outpath + 'raw_fitness_cascade_data/pre_cascades' + filetags + '_gamma' + str(gamma) + '.csv',
                               index = False)
        all_cascade_post.to_csv(outpath + 'raw_fitness_cascade_data/post_cascades' + filetags + '_gamma' + str(gamma) + '.csv',
                                index = False)
        
        
        
        del all_cascade_pre, all_cascade_post
    
        
# Write to CSV
fitness_cascades.to_csv(outpath + 'fitness_cascadestats' + filetags + '.csv',
                   index = False)
fitness_behavior.to_csv(outpath + 'fitness_behavior' + filetags + '.csv',
                   index = False)
    