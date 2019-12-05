#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Oct 24 14:36:36 2019

@author: ChrisTokita

DESCRIPTION:
Script to analyze behavior of individuals
"""

####################
# Load libraries and packages
####################
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import os
import copy
import re


####################
# List files to be read
####################
# Set group size runs of intereset
n_of_interest = 200

# Directory where simulation data is found
behav_dir = '../data_sim/network_break/behavior_data/' 
thresh_dir = '../data_sim/network_break/thresh_data/'

# List runs
runs = os.listdir(behav_dir)
runs = [run for run in runs if re.findall(str(n_of_interest) + '_gamma[-.0-9]+', run)]


####################
# Measure fitness of individuals as inferred from behaviors
####################
# Dataframes for collecting data
all_behavior = pd.DataFrame()
summarized_behav = pd.DataFrame()

# Loop through runs
for run in runs:
    
    # Load statement
    print("Starting on \'" + run + "\'...")

     # Get gamma value
    gamma = float(re.search('.*_gamma([-\.0-9]+)', run).group(1))
    
    # Get replicates in beahvior directory
    files = os.listdir(behav_dir + run +'/')
    reps = [re.search(".*(rep[0-9]{2}).*", file).group(1) for file in files]
    reps.sort()
    
    # Loop through replicate simulations
    for rep in reps:
        
        # Read in files
        behavior = pd.read_pickle(behav_dir + run +'/behavior_' + rep + '.pkl')
        thresholds = np.load(thresh_dir + run + '/thresh_' + rep + '.npy')
        
        # Combine into one dataframe and calculate fitness measures
        behavior = behavior.drop(columns = 'individual')
        behavior['threshold'] = thresholds
        behavior['correct_message'] = behavior.true_positive / (behavior.true_positive + behavior.false_negative)
        behavior['incorrect_message'] = behavior.false_positive / (behavior.false_positive + behavior.true_negative)
        behavior['gamma'] = gamma
        behavior['replicate'] = int(re.search('.*([0-9]+).*', rep).group(1))
        
        # Add to raw data dataframe
        if all_behavior.empty:
            all_behavior = copy.deepcopy(behavior)
        else:
            all_behavior = all_behavior.append(behavior, ignore_index = True)
            
        # Summarize and add to data-summarizing dataframe
        behavior_sum = behavior.drop(columns = 'threshold')
        behavior_sum = behavior_sum.mean(skipna = True)
        behavior_sum = behavior_sum.to_frame().T #flip so categories remain on column
        if summarized_behav.empty:
            summarized_behav = copy.deepcopy(behavior_sum)
        else:
            summarized_behav = summarized_behav.append(behavior_sum, ignore_index = True)
            
# Save
all_behavior.to_csv('../data_derived/network_break/data_derived/cascades/n' + str(n_of_interest) + 'allbehavior_gammasweep.csv',
                   index = False)
summarized_behav.to_csv('../data_derived/network_break/data_derived/cascades/n' + str(n_of_interest) + 'behaviorsum_gammasweep.csv',
                   index = False)