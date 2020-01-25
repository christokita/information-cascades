#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Jan 16 13:58:11 2020

@author: ChrisTokita

DESCRIPTION:
Script to analyze group-level information spread from fitness trials at end of simulations.
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
fit_dir = '../data_sim/thresh_adjust/fitness_data/' 
thresh_dir = '../data_sim/thresh_adjust/thresh_data/'
tags = 'muchlargeromega' #file tags that designate runs from a particular simulation

# For output
outpath = '../data_derived/thresh_adjust/cascades/'
filetags = 'muchlargeromega' #added info after 'n<number>_fitness_<filetag>_

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
all_cascade.to_csv(outpath + 'n' + str(n_of_interest) + '_cascadestats_' + filetags + '.csv',
                   index = False)
    