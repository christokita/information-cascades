#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Oct 28 11:15:43 2019

@author: ChrisTokita

DESCRIPTION:
Script to analyze fitness trials at end of simulations
"""

####################
# Load libraries and packages
####################
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt #occasionally use for on the spot plotting
import os
import re
import copy


####################
# List files to be read
####################
# Set group size runs of intereset
n_of_interest = 200

# Directory where simulation data is found
fit_dir = '../data_sim/thresh_adjust/fitness_data/' 
thresh_dir = '../data_sim/thresh_adjust/thresh_data/'
tags = 'gamma' #file tags that designate runs from a particular simulation

# For output
outpath = '../data_derived/thresh_adjust/cascades/'
filetags = 'gammasweep' #added info after 'n<number>_fitness_<datatype>_

# List runs
runs = os.listdir(fit_dir)
runs = [run for run in runs if re.findall(str(n_of_interest) + '_' + tags + '[-.0-9]+', run)]


####################
# Measure information spread (group-level fitness)
####################
# Loop through runs
all_cascade = pd.DataFrame()

for run in runs:
    
    # Load statement
    print("Starting on \'" + run + "\'...")
    
     # Get gamma value
    gamma = float(re.search('.*_gamma([-\.0-9]+)', run).group(1))
    
    # List social network files in that run's data folder
    run_files = os.listdir(fit_dir + run +'/')
    run_files = [file for file in run_files if re.findall('size', file)] #grab only cascade size files
    run_files.sort()
    
    # Create dataframe for parameter setting summary 
    cascade_data = pd.DataFrame()
    
    # Loop through files of different gamma values
    for file in run_files:
        
        # Read
        cascade = pd.read_pickle(fit_dir + run +'/' + file)
        cascade = cascade.astype(float)
        rep = int(re.search('([0-9]+)', file).group(1))
        
        # Calculate additional statistics
        cascade['active_diff'] = abs(cascade['active_A'] - cascade['active_B'])
        cascade['active_diff_prop'] = cascade['active_diff'] / cascade['total_active']
        
        # Identifying variables, remove time steps
        cascade['gamma'] = gamma
        cascade['replicate'] = rep
        cascade = cascade.drop(columns = ['t'])
        
        # Summarise data for that replicate and append
        cascade_sum = cascade.mean().to_frame().T
        if cascade_data.empty:
            cascade_data = copy.deepcopy(cascade_sum)
        else:
            cascade_data = cascade_data.append(cascade_sum, ignore_index = True, sort = False)
    
    # Bind to larger dataframe for saving
    if all_cascade.empty:
        all_cascade = copy.deepcopy(cascade_data)
    else:
        all_cascade = all_cascade.append(cascade_data, ignore_index = True, sort = False)
    
    # Clean up
    del(cascade_data, cascade_sum)
        
# Write to CSV
all_cascade.to_csv(outpath + 'n' + str(n_of_interest) + '_fitness_cascadesize_' + filetags + '.csv',
                   index = False)
    

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
    gamma = float(re.search('.*_gamma([-\.0-9]+)', run).group(1))
    
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

            
# Write to CSV
all_behavior.to_csv(outpath + 'n' + str(n_of_interest) + '_fitness_allbehavior_' + filetags + '.csv',
                   index = False)
summarized_behav.to_csv(outpath + 'n' + str(n_of_interest) + '_fitness_behaviorsum_scalefree' + filetags + '.csv',
                   index = False)