#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Jan 16 13:58:11 2020

@author: ChrisTokita

DESCRIPTION:
Script to process cascade data from during simulation. 
Cascades are recorded at the very beginning and end of the simulation.
"""

####################
# Load libraries and packages
####################
import pandas as pd
import os
import re
import copy


####################
# List files to be read
####################
# Directory where simulation data is found
casc_dir = '../data_sim/network_break/cascade_data/'  
tags = 'gamma' #file tags that designate runs from a particular simulation

# For output
outpath = '../data_derived/network_break/cascades/'
filetags = 'gammasweep' #added info after 'n<number>_fitness_<filetag>_

# List runs
runs = os.listdir(casc_dir)
runs = [run for run in runs if re.findall(tags + '[-.0-9]+', run)]
runs.sort()


####################
# Measure change in cascade dynamics (avg. in first 5000 timesteps vs. avg. in last 5000 timesteps)
####################
# Function to summarise data for beginning and end of cascade
def summarise_cascade(cascade_df):
    
    # Get window size
    t_window = int(cascade_df.shape[0] / 2)
    
    # Summarise by beginning (t<5000) and end of sim (t>=95000)
    begin = cascade_df.iloc[0:t_window, :]
    end = cascade_df.iloc[t_window:2*t_window, :]
    begin = begin.mean()
    end = end.mean()
    return begin, end


# Loop through runs
all_cascade = pd.DataFrame()

for run in runs:
    
    # Load statement
    print("Starting on \'" + run + "\'...")

     # Get gamma value
    gamma = float(re.search('gamma([-\.0-9]+)', run).group(1))
    
    # List social network files in that run's data folder
    run_files = os.listdir(casc_dir + run +'/')
    run_files.sort()
    
    # Create dataframe for parameter setting summary 
    headers = ['gamma', 'replicate', 
               'size_begin', 'size_end', 'size_diff',
               'bias_begin', 'bias_end', 'bias_diff']
    cascade_data = pd.DataFrame(columns = headers, dtype = float)
    
    # Loop through files of different gamma values
    for file in run_files:
        
        # Read
        cascade = pd.read_pickle(casc_dir + run +'/' + file)
        cascade = cascade.astype(float)
        rep = int(re.search('([0-9]+)', file).group(1))
        
        # Calculate additional statistics
        cascade['active_diff'] = abs(cascade['active_A'] - cascade['active_B'])
        cascade['active_diff_prop'] = cascade['active_diff'] / cascade['total_active']
        
        # Summarise data for beginngin and end of simulations
        cascade_begin, cascade_end = summarise_cascade(cascade)
        cascade_sum = pd.DataFrame({'gamma': [gamma],
                                    'replicate': [rep], 
                                    'size_begin': [cascade_begin.total_active],
                                    'size_end': [cascade_end.total_active],
                                    'size_diff': [cascade_end.total_active - cascade_begin.total_active], 
                                    'bias_begin': [cascade_begin.active_diff_prop], 
                                    'bias_end': [cascade_end.active_diff_prop], 
                                    'bias_diff': [cascade_end.active_diff_prop - cascade_begin.active_diff_prop]})
        
        # Append
        cascade_data = cascade_data.append(cascade_sum, ignore_index = True, sort = False)
    
    # Bind to larger dataframe for saving
    if all_cascade.empty:
        all_cascade = copy.deepcopy(cascade_data)
    else:
        all_cascade = all_cascade.append(cascade_data)
    
# Save to csv
all_cascade.to_csv('../data_derived/network_break/cascades/n' + str(n_of_interest) + '_gammasweep.csv',
                   index = False)


####################
# Rolling average of cascade dynamics
####################
# Load in data summary data from above
all_cascade = pd.read_csv('../data_derived/network_break/cascades/n' + str(n_of_interest) + '_gammasweep.csv')

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
cascade_rollingavg.to_csv('../data_derived/network_break/cascades/n' + str(n_of_interest) + '_rollingavg.csv',
                   index = False)