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
from cascade_models.social_networks.local_assortativity import local_assortativity_continuous


####################
# List files to be read
####################
# Directory where simulation data is found
sn_dir = '../../../data_sim/network_break/social_network_data/' #social network data
type_dir = '../../../data_sim/network_break/type_data/' #type data
thresh_dir = '../../../data_sim/network_break/thresh_data/' #threshold data
tags = 'gamma' #file tags that designate runs from a particular simulation

# For output
outpath = '../../../data_derived/network_break/social_networks/threshold_sorting/'
filetags = '' #added info after 'assortativity'
if len(filetags) > 0:
    filetags = '_' + filetags

# List runs
runs = os.listdir(sn_dir)
runs = [run for run in runs if re.findall(tags + '[-.0-9]+', run)]
runs.sort()


####################
# Functions for analysis
####################
# Calculate difference in threshold between neighbors and focal individual
def calculate_neighor_threshold_stats(thresholds, network, types):
    """
    This function measure the average threshold difference and distance between individuals and their neighbors.
    
    INPUTS:
    - thresholds:   array of threshold values for all individuals in the network (numpy array).
    - network:      the network connecting individuals (numpy array).
    - types:        array of individual political types (numpy array).
    """
    
    # Prep data collection
    n_individuals = len(thresholds)
    neighbor_thresh_data = pd.DataFrame(columns = ['gamma', 'replicate', 'individual', 
                                                   'type', 'threshold', 'n_neighbors',
                                                   'mean_neighbor_thresh',
                                                   'mean_thresh_diff', 'mean_thresh_dist', 'mean_thresh_sim',
                                                   'n_low_thresh', 'n_high_thresh', 
                                                   'min_neighbor_thresh', 'max_neighbor_thresh',
                                                   'n_lower', 'n_higher'])
    
    # Loop through individuals in social system
    for i in np.arange(n_individuals):
        
        # Determine who are actual neighbors in network
        neighbors = network[i,:] > 0
        neighbor_thresholds = thresholds[neighbors]
        n_neighbors = len(neighbor_thresholds)
        
        # Calculate pariwise difference and distance in network
        diff = neighbor_thresholds - thresholds[i]
        dist = abs(neighbor_thresholds - thresholds[i])
        sim = 1 - dist
        mean_neighor_thresh = np.mean(neighbor_thresholds)
        mean_diff = np.mean(diff)
        mean_dist = np.mean(dist)
        mean_sim = np.mean(sim)
        
        # Calculate freq of low/high threshold neighbors
        n_lowthresh = sum(neighbor_thresholds < 0.25)
        n_highthresh = sum(neighbor_thresholds > 0.75)
        n_lower = sum(neighbor_thresholds < thresholds[i])
        n_higher = sum(neighbor_thresholds > thresholds[i])
        if n_neighbors > 0:
            min_thresh = np.min(neighbor_thresholds)
            max_thresh = np.max(neighbor_thresholds)
        else:
            min_thresh = max_thresh = np.nan
            
        # Append
        neighbor_thresh_data = neighbor_thresh_data.append({'gamma': gamma,
                                                            'replicate': replicate, 
                                                            'individual': i, 
                                                            'type': types[i], 
                                                            'threshold': thresholds[i], 
                                                            'n_neighbors': n_neighbors,
                                                            'mean_neighbor_thresh': mean_neighor_thresh,
                                                            'mean_thresh_diff': mean_diff, 
                                                            'mean_thresh_dist': mean_dist, 
                                                            'mean_thresh_sim': mean_sim,
                                                            'n_low_thresh': n_lowthresh, 
                                                            'n_high_thresh': n_highthresh, 
                                                            'min_neighbor_thresh': min_thresh,
                                                            'max_neighbor_thresh': max_thresh,
                                                            'n_lower': n_lower,
                                                            'n_higher': n_higher}, 
                                                           ignore_index = True)
    # Return dataframe
    return neighbor_thresh_data


# Calculate difference in threshold between neighbors and focal individual
def gather_neighbor_thresholds(thresholds, network):
    """
    This creates a pairwise list of all individuals and the thresholds of each of their neighbors in the network
    
    INPUTS:
    - thresholds:   array of threshold values for all individuals in the network (numpy array).
    - network:      the network connecting individuals (numpy array).
    """
    
    # Prep data collection
    n_individuals = len(thresholds)
    individual_id = np.array([])
    individual_threshold = np.array([])
    neighbor_threshold = np.array([])
    
    # Loop through individuals in social system
    for i in np.arange(n_individuals):
        
        # Determine who are actual neighbors in network
        neighbors = network[i,:] > 0
        
        # Add individual info
        neighbor_thresh = thresholds[neighbors]
        ind_id = np.repeat(i, len(neighbor_thresh))
        ind_thesh = np.repeat(thresholds[i], len(neighbor_thresh))
        individual_id = np.append(individual_id, ind_id)
        individual_threshold = np.append(individual_threshold, ind_thesh)
        neighbor_threshold = np.append(neighbor_threshold, neighbor_thresh)
        
        
    # Return dataframe
    network_threshold_data = pd.DataFrame({'individual': individual_id,
                                           'threshold': individual_threshold,
                                           'neighbor_threshold': neighbor_threshold})
    return network_threshold_data




####################
# Calculate thresholds differences and high/lower threshold individuals among individual's neighbors
####################
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
        replicate_data_initial = calculate_neighor_threshold_stats(thresholds, adjacency_initial, types)
        replicate_data_final = calculate_neighor_threshold_stats(thresholds, adjacency, types)
        
        # Add to main dataframe
        if 'neighbor_threshold_stats_initial' not in globals():
            neighbor_threshold_stats_initial = replicate_data_initial.copy()
        else: 
            neighbor_threshold_stats_initial = neighbor_threshold_stats_initial.append(replicate_data_initial, ignore_index = False)
            
        if 'neighbor_threshold_stats_final' not in globals():
            neighbor_threshold_stats_final = replicate_data_final.copy()
        else: 
            neighbor_threshold_stats_final = neighbor_threshold_stats_final.append(replicate_data_final, ignore_index = False)
        
        
# neighbor_threshold_stats_initial.to_csv(outpath + 'initial_neighbor_thresh_data.csv', index = False)
neighbor_threshold_stats_final.to_csv(outpath + 'final_neighbor_thresh_data.csv', index = False)



####################
# Focus in on gamma = 1 scenario to really get at threshold sorting dynamics, absent polarized information ecosystem.
####################
# List social network files in that run's data folder
sn_files = os.listdir(sn_dir + 'gamma1.0/')
sn_final = sorted( [file for file in sn_files if re.findall('sn_final_rep[0-9]+.npy', file)] )
sn_initial =  sorted( [file for file in sn_files if re.findall('sn_initial_rep[0-9]+.npy', file)] )
   
# List type and threshold data files in that run's data folder
type_files = sorted( os.listdir(type_dir + 'gamma1.0/') )
thresh_files = sorted( os.listdir(thresh_dir + 'gamma1.0/') )

# Loop through individual replicates and calculate changes in network
for replicate in np.arange(len(sn_final)):
   
   # Load network and threshold matrices
   adjacency = np.load(sn_dir + 'gamma1.0/' + sn_final[replicate])
   adjacency_initial = np.load(sn_dir + 'gamma1.0/' + sn_initial[replicate])
   thresholds = np.load(thresh_dir + 'gamma1.0/' + thresh_files[replicate]).flatten() #make 1d
   types = np.load(type_dir +  'gamma1.0/' + type_files[replicate])
   types = np.argmax(types == 1 , axis = 1) #get categorical types of individuals
   
   # Calculate difference with network neighbors' thresholds
   initial_threshold_network = gather_neighbor_thresholds(thresholds, adjacency_initial)
   final_threshold_network = gather_neighbor_thresholds(thresholds, adjacency)
   
   # Compile into dataframe and append to master dataframe
   if 'neighbor_thresholds_initial' not in globals():
       neighbor_thresholds_initial = initial_threshold_network.copy()
   else:
       neighbor_thresholds_initial = neighbor_thresholds_initial.append(initial_threshold_network, ignore_index = True)
   del initial_threshold_network
       
   if 'neighbor_thresholds_final' not in globals():
       neighbor_thresholds_final = final_threshold_network.copy()
   else:
       neighbor_thresholds_final = neighbor_thresholds_final.append(final_threshold_network, ignore_index = True)
   del final_threshold_network
      

# Add bin data
bin_edges = np.linspace(0, 1, 11)
bin_labels = [ round((bin_edges[i] + bin_edges[i+1]) / 2, 2) for i in np.arange(len(bin_edges)-1)]
neighbor_thresholds_initial['threshold_bin'] = pd.cut(neighbor_thresholds_initial['threshold'], bins = bin_edges, labels = bin_labels)
neighbor_thresholds_final['threshold_bin'] = pd.cut(neighbor_thresholds_final['threshold'], bins = bin_edges, labels = bin_labels)

# Save
# neighbor_thresholds_initial.to_csv(outpath + 'initial_raw_neighbor_thresholds.csv', index = False)
# neighbor_thresholds_final.to_csv(outpath + 'final_raw_neighbor_thresholds.csv', index = False)

####################
# Focus in on gamma = 1 and gamma = -1 scenario look at local assortativity of thresholds
####################
# Get gamma value
focus_runs = ['gamma1.0', 'gamma-1.0']
   
for run in focus_runs:
    
    # List social network files in that run's data folder
    gamma = int( re.search('gamma(.*[0-9]{1})\.0', run).group(1) )
    sn_files = os.listdir(sn_dir + run + '/')
    sn_final = sorted( [file for file in sn_files if re.findall('sn_final_rep[0-9]+.npy', file)] )
    sn_initial =  sorted( [file for file in sn_files if re.findall('sn_initial_rep[0-9]+.npy', file)] )
       
    # List type and threshold data files in that run's data folder
    type_files = sorted( os.listdir(type_dir + run + '/') )
    thresh_files = sorted( os.listdir(thresh_dir + run + '/') )
    
    # Loop through individual replicates and calculate local assortativity
    for replicate in np.arange(len(sn_final)):
        
        # Print progress
        if (replicate % 10) == 0:
            print("gamma = {}:\n    {}% done...".format(str(gamma), str(replicate)))
        
        # Load network and threshold matrices
        adjacency = np.load(sn_dir + run + '/' + sn_final[replicate])
        thresholds = np.load(thresh_dir + run + '/' + thresh_files[replicate]).flatten() #make 1d
     
        # Calculate local assortativity of nodes with regard to threshold
        alpha = 0
        local_assort_thresh = local_assortativity_continuous(network = adjacency, thresholds = thresholds, alpha = alpha)
        rep_data = pd.DataFrame({'gamma': np.repeat(gamma, len(local_assort_thresh)),
                                 'replicate': np.repeat(replicate, len(local_assort_thresh)),
                                 'threshold': thresholds,
                                 'local_assort_thresolds': local_assort_thresh})
        
        # Compile into dataframe and append to master dataframe
        if 'local_threshold_assort_data' not in globals():
            local_threshold_assort_data = rep_data.copy()
        else:
            local_threshold_assort_data = local_threshold_assort_data.append(rep_data, ignore_index = True)
        del rep_data
            
local_threshold_assort_data.to_csv(outpath + 'local_assort_thresholds.csv', index = False)

