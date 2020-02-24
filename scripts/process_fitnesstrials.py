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
raw_data = True

# Directory where simulation data is found
fit_dir = '../data_sim/network_break/__suppl-sim/long-sim/fitness_data/'  
thresh_dir = '../data_sim/network_break/__suppl-sim/long-sim/thresh_data/'
tags = 'gamma' #file tags that designate runs from a particular simulation

# For output
outpath = '../data_derived/network_break/__suppl_analysis/sim_length/'
filetags = '10^6steps' #added info after e.g., 'fitness_<filetag>_

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
    
    # Create dataframess for summarized and raw casacde data, if desired
    cascade_summarized = pd.DataFrame()
    all_cascade = pd.DataFrame()
    
     # Get gamma value
    gamma = float(re.search('[a-z]+([-\.0-9]+)', run).group(1))
    
    # List cascade and and behavior files
    all_files = os.listdir(fit_dir + run +'/')
    replicates = [re.search('(rep[0-9]+)', file).group(1) for file in all_files]
    replicates = list(set(replicates)) #get unique values
    replicates.sort()
    
    # Loop through replciate simulations within that parameter run
    for replicate in replicates:
        
        # Read in files and get replicate number
        cascade = pd.read_pickle(fit_dir + run +'/fitness_cascades_' + replicate + '.pkl')
        cascade = cascade.astype(float)
        behavior = pd.read_pickle(fit_dir + run +'/fitness_behavior_' + replicate + '.pkl')
        thresholds = np.load(thresh_dir + run + '/thresh_' + replicate + '.npy')
        rep = int(re.search('([0-9]+)', replicate).group(1))
        
        # Calculate additional statistics: Cascades
        cascade['avg_cascade_size'] = cascade['total_active'] / cascade ['samplers_active']
        cascade['active_diff'] = abs(cascade['active_A'] - cascade['active_B'])
        cascade['cascade_bias'] = cascade['active_diff'] / cascade['total_active']
        cascade['gamma'] = gamma
        cascade['replicate'] = rep
        
        # Calculate additional statistics: Behavior
        behavior = behavior.drop(columns = 'individual')
        behavior['threshold'] = thresholds
        behavior['sensitivity'] = behavior.true_positive / (behavior.true_positive + behavior.false_negative)
        behavior['specificity'] = behavior.true_negative / (behavior.true_negative + behavior.false_positive)
        behavior['precision'] = behavior.true_positive / (behavior.true_positive + behavior.false_positive)
        behavior['gamma'] = gamma
        behavior['replicate'] = rep
        
        # Append raw cascde data to larger dataframe, if desired
        if all_cascade.empty and raw_data == True:
            all_cascade = copy.deepcopy(cascade)
        elif raw_data == True:
            all_cascade = all_cascade.append(cascade, ignore_index = True)
            
        # Append raw behavior data to larger dataframe
        if fitness_behavior.empty:
            fitness_behavior = copy.deepcopy(behavior)
        else:
            fitness_behavior = fitness_behavior.append(behavior, ignore_index = True)
        
        # Summarise cascade data for that replicate and append
        cascade = cascade.drop(columns = ['t']) #drop time step column for summarizing
        cascade_sum = cascade.mean().to_frame().T
        if fitness_cascades.empty:
            fitness_cascades = copy.deepcopy(cascade_sum)
        else:
            fitness_cascades = fitness_cascades.append(cascade_sum, ignore_index = True, sort = False)
    
    # Save raw data for that parameter run if desired
    if raw_data == True:
        if not os.path.isdir(outpath + 'raw_fitness_cascade_data/'):
            os.mkdir(outpath + 'raw_fitness_cascade_data/')
        all_cascade.to_csv(outpath + 'raw_fitness_cascade_data/fitness_cascades_' + filetags + '_gamma' + str(gamma) + '.csv',
                       index = False)
        del(all_cascade)
    
        
# Write to CSV
fitness_cascades.to_csv(outpath + 'fitness_cascadestats_' + filetags + '.csv',
                   index = False)
fitness_behavior.to_csv(outpath + 'fitness_behavior_' + filetags + '.csv',
                   index = False)
    