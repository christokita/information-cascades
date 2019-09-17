#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Sep  4 09:49:32 2019

@author: ChrisTokita

DESCRIPTION:
Script to analyze cascade patterns produced by simulations
"""

####################
# Load libraries and packages
####################
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import os
import re
import math
import copy


####################
# List files to be read
####################
# Set group size runs of intereset
n_of_interest = 200

# Directory where simulation data is found
cas_dir = '../data_sim/network_break/cascade_data/' 

# List runs
runs = os.listdir(cas_dir)
runs = [run for run in runs if re.findall(str(n_of_interest) + '_gamma[-.0-9]+', run)]

####################
# Measure cascade dynamics over time (simple average across replicates)
####################
all_cascade = pd.DataFrame()

# Loop through runs
for run in runs:
    
    # Load statement
    print("Starting on \'" + run + "\'...")

     # Get gamma value
    gamma = float(re.search('.*_gamma([-\.0-9]+)', run).group(1))
    
    # List social network files in that run's data folder
    run_files = os.listdir(cas_dir + run +'/')
    run_files.sort()
    
    # Create dataframe for parameter setting summary 
    headers = pd.read_pickle(cas_dir + run +'/' + run_files[0]).columns
    cascade_data = pd.DataFrame(columns = headers, dtype = float)
    
    # Loop through files of different gamma values, load, and append
    for file in run_files:
        cascade = pd.read_pickle(cas_dir + run +'/' + file)
        cascade_data = cascade_data.append(cascade, ignore_index = True)
            
    # Calculate additional statistics
    cascade_data = cascade_data.astype(float)
    cascade_data['active_diff'] = abs(cascade_data['active_A'] - cascade_data['active_B'])
    cascade_data['active_diff_prop'] = cascade_data['active_diff'] / cascade_data['total_active']
    
    # Create summary statistics
    cascade_sum = cascade_data.groupby(['t'])['total_active','active_diff_prop'].agg(['mean', 'count', 'std'])
    cascade_sum.columns = cascade_sum.columns.map('_'.join)
    ci95_total = []
    ci95_diff = []
    for j in np.arange(cascade_sum.shape[0]):
        # Calculate 95% CI
        mean_tot, count_tot, sd_tot, mean_diff, count_diff, sd_diff = cascade_sum.loc[j]
        error_tot = (1.96 * sd_tot) / math.sqrt(count_tot)
        error_diff = (1.96 * sd_diff) / math.sqrt(count_diff)
        ci95_total.append(error_tot)
        ci95_diff.append(error_diff)
    cascade_sum['total_active_error'] = ci95_total
    cascade_sum['active_diff_prop_error'] = ci95_diff
    
    # Bind to larger dataframe for saving
    cascade_sum['gamma'] = gamma
    cascade_sum['t'] = cascade_sum.index
    if all_cascade.empty:
        all_cascade = cascade_sum.copy(deep = True)
    else:
        all_cascade = all_cascade.append(cascade_sum)
    
# Save to csv
all_cascade.to_csv('../output/network_break/data_derived/cascades/n' + str(n_of_interest) + '_gammasweep.csv',
                   index = False)


####################
# Rolling average of cascade dynamics
####################
# Load in data summary data from above
all_cascade = pd.read_csv('../output/network_break/data_derived/cascades/n' + str(n_of_interest) + '_gammasweep.csv')

# Rolling average function
def weight_rolling_average(data, window, weight, metric_name):
    # Create return list
    roll_avg = pd.DataFrame(columns = ['start', 
                                       'end', 
                                       metric_name + '_mean',
                                       metric_name + '_error',
                                       metric_name + '_sd'])
    # Calculate how many windows
    windows = len(data) / window
    # Loop through data and calulate weighted rolling average
    for win in np.arange(windows):
        # Grab set of interest
        start = int(win * window)
        end = int((win + 1) * window)
        data_subset = data[start:end]
        weight_subset = weight[start:end]
        # Calculate
        win_avg = np.average(data_subset, weights = weight_subset)
        win_sd = math.sqrt(np.average((data_subset - win_avg)**2, weights = weight_subset))
        samples = np.sum(weight_subset)
        win_error = (1.96 * win_sd) / math.sqrt(samples)
        
        roll_avg = roll_avg.append({'start': start, 
                                    'end': end, 
                                    metric_name + '_mean': win_avg, 
                                    metric_name + '_error': win_error, 
                                    metric_name + '_sd': win_sd}, 
                                   ignore_index = True)
    # return
    return(roll_avg)
    
# Loop over gamma values
cascade_rollingavg = pd.DataFrame()
gammas = all_cascade['gamma'].unique()
for gamma in gammas:
    # Print message
    print("Calculating rolling average for gamma = " + str(gamma) + "...")
    # Subset data
    subset_cascade = all_cascade.loc[all_cascade['gamma'] == gamma]
    # Calculate
    act_avg = weight_rolling_average(data = subset_cascade['total_active_mean'],
                                       window = 500,
                                       weight = subset_cascade['total_active_count'],
                                       metric_name = 'active')
    bias_avg = weight_rolling_average(data = subset_cascade['active_diff_prop_mean'],
                                       window = 500,
                                       weight = subset_cascade['active_diff_prop_count'],
                                       metric_name = 'actdiff')
    # Merge 
    gamma_avg = pd.merge(act_avg, bias_avg, on = ['start', 'end'])
    # Return
    gamma_avg['gamma'] = gamma 
    if cascade_rollingavg.empty:
        cascade_rollingavg = gamma_avg.copy(deep = True)
    else:
        cascade_rollingavg = cascade_rollingavg.append(gamma_avg)
    
# Save rolling average to csv
cascade_rollingavg.to_csv('../output/network_break/data_derived/cascades/n' + str(n_of_interest) + '_rollingavg.csv',
                   index = False)