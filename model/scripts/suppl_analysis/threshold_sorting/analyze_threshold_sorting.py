#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Feb  1 14:31:49 2021

@author: ChrisTokita

DESCRIPTION:
Script to analyze question of how threshold sorting might change in the network, even when news sources are identical.
We will mostly do this by looking at the average difference & distance between an individual and their neighbors.
"""

import numpy as np
import pandas as pd
import os
import re


####################
# List files to be read
####################
# Directory where simulation data is found
sn_dir = '../../../data_sim/network_break/social_network_data/' #social network data
type_dir = '../../../data_sim/network_break/type_data/' #type data
thresh_dir = '../../../data_sim/network_break/thresh_data/' #threshold data
tags = 'gamma' #file tags that designate runs from a particular simulation

# For output
outpath = '../../../data_derived/network_break/social_networks/'
filetags = '' #added info after 'assortativity'
if len(filetags) > 0:
    filetags = '_' + filetags

# List runs
runs = os.listdir(sn_dir)
runs = [run for run in runs if re.findall(tags + '[-.0-9]+', run)]
runs.sort()


####################
# Function for analysis
####################
def calculate_threshold_difference(thresholds, network):
    """
    This function measure the average threshold difference and distance between individuals and their neighbors.
    
    INPUTS:
    - thresholds:   array of threshold values for all individuals in the network (numpy array).
    - network:      the network connecting individuals (numpy array).
    """
    
    # Prep data collection
    n_thresholds = len(thresholds)
    threshold_diff = np.array([])
    threshold_dist = np.array([])
    
    # Loop through individuals in social system
    for i in np.arange(n_thresholds):
        
        # Determine who are actual neighbors in network
        neighbors = network[i,:] > 0
        
        # Calculate pariwise difference and distance in network
        diff = thresholds[neighbors] - thresholds[i]
        dist = abs(thresholds[neighbors] - thresholds[i])
        mean_diff = np.mean(diff)
        mean_dist = np.mean(dist)
        threshold_diff = np.append(threshold_diff, mean_diff)
        threshold_dist = np.append(threshold_dist, mean_dist)
        
    return threshold_diff, threshold_dist


####################
# Calculate thresholds differences among individuals in initial and final networks
####################
# Dataframe to hold data
threshold_diff_data = pd.DataFrame(columns = ['gamma', 'replicate', 'individual', 
                                              'type', 'threshold',
                                              'initial_thresh_diff', 'initial_thresh_dist',
                                              'final_thresh_diff', 'final_thresh_dist'])

# Loop through runs
for run in runs:
    
    # Load statement
    print("Network structural change: Starting on \'" + run + "\'...")
    
    # Get gamma value
    gamma = float(re.search('gamma([-\.0-9]+)', run).group(1))
    
     # List social network files in that run's data folder
    sn_files = os.listdir(sn_dir + run +'/')
    sn_final = sorted( [file for file in sn_files if re.findall('sn_final_rep[0-9]+.npy', file)] )
    sn_initial =  sorted( [file for file in sn_files if re.findall('sn_initial_rep[0-9]+.npy', file)] )
    
    # List type and threshold data files in that run's data folder
    type_files = sorted( os.listdir(type_dir + run +'/') )
    thresh_files = sorted( os.listdir(thresh_dir + run +'/') )
    
    # Loop through individual replicates and calculate changes in network
    for replicate in np.arange(len(sn_final)):
        
        # Load network and threshold matrices
        adjacency = np.load(sn_dir + run + '/' + sn_final[replicate])
        adjacency_initial = np.load(sn_dir + run + '/' + sn_initial[replicate])
        thresholds = np.load(thresh_dir + run + '/' + thresh_files[replicate]).flatten() #make 1d
        types = np.load(type_dir +  run + '/' + type_files[replicate])
        types = np.argmax(types == 1 , axis = 1) #get categorical types of individuals
        
        # Calculate difference with network neighbors' thresholds
        initial_thresh_diff, initial_thresh_dist = calculate_threshold_difference(thresholds, adjacency_initial)
        final_thresh_diff, final_thresh_dist = calculate_threshold_difference(thresholds, adjacency)
        
        # Compile into dataframe and append to master dataframe
        n = len(thresholds)
        replicate_data = pd.DataFrame(np.column_stack((np.repeat(gamma, n), np.repeat(replicate, n), np.arange(0, n), 
                                                       types, thresholds,
                                                       initial_thresh_diff, initial_thresh_dist,
                                                       final_thresh_diff, final_thresh_dist)),
                                    columns = threshold_diff_data.columns)
        threshold_diff_data = threshold_diff_data.append(replicate_data, ignore_index = True)
        
        
threshold_diff_data.to_csv(outpath + 'threshold_distance_data.csv', index = False)
