#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Jan 16 13:58:11 2020

@author: ChrisTokita

DESCRIPTION:
Script to process fitness trial cascade data.
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
raw_data = False #set true if you want to output raw cascades data (each time step)

# Directory where simulation data is found
fit_dir = '../data_sim/network_break/fitness_data/'  
tags = 'gamma' #file tags that designate runs from a particular simulation

# For output
outpath = '../data_derived/network_break/cascades/'
filetags = 'gammasweep' #added info after 'n<number>_fitness_<filetag>_

# List runs
runs = os.listdir(fit_dir)
runs = [run for run in runs if re.findall(str(n_of_interest) + '_' + tags + '[-.0-9]+', run)]
runs.sort()


####################
# Measure information spread (group-level fitness)
####################
# Loop through runs
summarized_cascade = pd.DataFrame()

for run in runs:
    
    # Load statement
    print("Starting on \'" + run + "\'...")
    
    # Create datafrane for raw data, if desired
    all_cascade = pd.DataFrame()
    
     # Get gamma value
    gamma = float(re.search('.*_[a-z]+([-\.0-9]+)', run).group(1))
    
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
        
        # Add to raw data dataframe
        if all_cascade.empty and raw_data == True:
            all_cascade = copy.deepcopy(cascade)
        elif raw_data == True:
            all_cascade = all_cascade.append(cascade, ignore_index = True)

        # Summarise data for that replicate and append
        cascade = cascade.drop(columns = ['t']) #drop time step column
        cascade_sum = cascade.mean().to_frame().T
        if summarized_cascade.empty:
            summarized_cascade = copy.deepcopy(cascade_sum)
        else:
            summarized_cascade = summarized_cascade.append(cascade_sum, ignore_index = True, sort = False)
    
    # Save raw data for that gamma if desired
    if raw_data == True:
        if not os.path.isdir(outpath + 'raw_cascade_data/'):
            os.mkdir(outpath + 'raw_cascade_data/')
        all_cascade.to_csv(outpath + 'raw_cascade_data/' + 'n' + str(n_of_interest) + '_cascadesraw_' + filetags + '_gamma' + str(gamma) + '.csv',
                       index = False)
        del(all_cascade)
    
        
# Write to CSV
summarized_cascade.to_csv(outpath + 'n' + str(n_of_interest) + '_cascadestats_' + filetags + '.csv',
                   index = False)
    