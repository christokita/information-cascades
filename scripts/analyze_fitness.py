#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Oct 28 11:15:43 2019

@author: ChrisTokita

DESCRIPTION:
Script to analyze individual fitness from fitness trials at end of simulations.
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
# Set group size runs of intereset
n_of_interest = 200

# Directory where simulation data is found
fit_dir = '../data_sim/network_break/fitness_data/' 
thresh_dir = '../data_sim/network_break/thresh_data/'
tags = 'gamma' #file tags that designate runs from a particular simulation

# For output
outpath = '../data_derived/network_break/fitness/'
filetags = 'gamma' #added info after 'n<number>_fitness_<filetag>_

# List runs
runs = os.listdir(fit_dir)
runs = [run for run in runs if re.findall(str(n_of_interest) + '_' + tags + '[-.0-9]+', run)]


####################
# Measure behavior/information use (individual-level fitness)
####################
# Dataframes for collecting data
all_behavior = pd.DataFrame()
summarized_behav = pd.DataFrame()

# Loop through runs
for run in runs:
    
    # Load statement
    print("Starting on \'" + run + "\'...")
    
    # Get gamma value
    gamma = float(re.search('.*_[a-z]+([-\.0-9]+)', run).group(1))
    
     # Get replicates in beahvior directory
    run_files = os.listdir(fit_dir + run +'/')
    run_files = [file for file in run_files if re.findall('behav', file)] #grab only cascade size files
    reps = [re.search(".*(rep[0-9]{2}).*", file).group(1) for file in run_files]
    reps.sort()
    
    # Loop through replicate simulations
    for rep in reps:
        
        # Read in files
        behavior = pd.read_pickle(fit_dir + run +'/fit_behav_' + rep + '.pkl')
        thresholds = np.load(thresh_dir + run + '/thresh_' + rep + '.npy')
        
        # Combine into one dataframe and calculate fitness measures
        behavior = behavior.drop(columns = 'individual')
        behavior['threshold'] = thresholds
        behavior['sensitivity'] = behavior.true_positive / (behavior.true_positive + behavior.false_negative)
        behavior['specificity'] = behavior.true_negative / (behavior.true_negative + behavior.false_positive)
        behavior['precision'] = behavior.true_positive / (behavior.true_positive + behavior.false_positive)
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

            
# Write to CSV
all_behavior.to_csv(outpath + 'n' + str(n_of_interest) + '_fitness_allbehavior_' + filetags + '.csv',
                   index = False)
summarized_behav.to_csv(outpath + 'n' + str(n_of_interest) + '_fitness_behaviorsum_' + filetags + '.csv',
                   index = False)