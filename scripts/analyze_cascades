#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Sep  4 09:49:32 2019

@author: ChrisTokita

DESCRIPTION:
Script to analyze cascade patterns produced by simulations
"""

####################
# Load libraryies and packages
####################
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import os
import re
import math


####################
# List files to be read
####################
# Set group size runs of intereset
n_of_interest = 200

# Find files
all_files = os.listdir('../output/network_adjust/data/cascade_data/')
pars_of_interest = [file for file in all_files if re.findall(str(n_of_interest) + '_gamma[-.0-9]+.npy', file)]
pars_of_interest = [re.sub('.npy', '', file) for file in pars_of_interest]


####################
# Measure cascade dynamics over time (simple average across replicates)
####################
# Dataframe to collect results
all_cascade = pd.DataFrame(columns = ['t', 'gamma', 'mean', 'count', 'std', 'error'], dtype = float)

# Loop through files of different gamma values
for file in pars_of_interest:
    
    print(file)
    
    # Get gamma value
    gamma = float(re.search('.*_gamma([-\.0-9]+)', file).group(1))
    
    # Load list of cascade data for that parameter setting
    list_cascades = np.load('../output/network_adjust/data/cascade_data/' + file + '.npy')
    headers = list_cascades[0] # item 0 is the headers of the matrices
    list_cascades = list_cascades[1:len(list_cascades)] # the rest are the actual data arrays

    # Loop thorugh individual cascade array and append
    cascade_data = pd.DataFrame(columns = headers, dtype = float)
    for i in np.arange(len(list_cascades)): 
        # Grab array
        cascade_array = list_cascades[i]
        cascade_array = pd.DataFrame(cascade_array, columns = headers)
        # Add to average array (this solution requires all arrays to be the same size)
        cascade_data = cascade_data.append(cascade_array, ignore_index = True)
        
        
    # Calculate additional statistics
    cascade_data['active_diff'] = abs(cascade_data['active_A'] - cascade_data['active_B'])
    cascade_data['active_diff_prop'] = cascade_data['active_diff'] / cascade_data['total_active']
    
    # Create summary statistics
    cascade_sum = cascade_data.groupby(['t'])['total_active','active_diff_prop'].agg(['mean', 'count', 'std'])
    cascade_sum.columns = cascade_sum.columns.map('_'.join)
    ci95_total = []
    ci95_diff = []
    for j in np.arange(cascade_diff.shape[0]):
        # Calculate 95% CI
        mean_tot, count_tot, sd_tot, mean_diff, count_diff, sd_diff = cascade_diff.loc[j]
        error_tot = (1.96 * sd_tot) / math.sqrt(count_tot)
        error_diff = (1.96 * sd_diff) / math.sqrt(count_diff)
        ci95_total.append(error_tot)
        ci95_diff.append(error_diff)
    cascade_sum['total_active_error'] = ci95_total
    cascade_sum['actove_diff_prop_error'] = ci95_diff
    # Bind to larger dataframe for saving
    cascade_sum['gamma'] = gamma
    cascade_sum['t'] = cascade_sum.index
    all_cascade = all_cascade.append(cascade_sum)
    
# Save to csv
all_cascade.to_csv('../output/network_adjust/data_derived/cascades/n' + str(n_of_interest) + '_gammasweep.csv',
                   index = False)


####################
# Running average of cascade dynamics
####################
# Load in data summary data from above
all_cascade = pd.read_csv('../output/network_adjust/data_derived/cascades/n' + str(n_of_interest) + '_gammasweep.csv')

# Rolling average function
def weight_rolling_average(data, window, weight):
    # Create return list
    roll_avg = pd.DataFrame(columns = ['start', 'end', 'mean', 'error', 'sd'])
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
        roll_avg = roll_avg.append({'start': start, 'end': end, 'mean': win_avg, 'error': win_error, 'sd': win_sd}, 
                                   ignore_index = True)
    # return
    return(roll_avg)
    
# Loop over gamma values
gammas = all_cascade['gamma'].unique()
for gamma in gammas:
    # Subset data
    subset_cascade = all_cascade.loc[all_cascade['gamma'] == gamma]
    # Calculate
    gamma_avg = weight_rolling_average(data = subset_cascade['mean'],
                                       window = 500,
                                       weight = subset_cascade['count'])
    # Return
    gamma_avg['gamma'] = gamma 