#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Aug 20 10:02:31 2019

@author: ChrisTokita

DESCRIPTION:
Script to process social network data produced by simulations.
"""

####################
# Load libraries and packages
####################
import numpy as np
import pandas as pd
import os
import re
import igraph


####################
# List files to be read
####################
# Directory where simulation data is found
sn_dir = '../data_sim/network_break/__suppl-sim/scale-free-network/social_network_data/' #social network data
type_dir = '../data_sim/network_break/__suppl-sim/scale-free-network/type_data/' #type data
tags = 'gamma' #file tags that designate runs from a particular simulation

# For output
outpath = '../data_derived/network_break/__suppl_analysis/other_network_types/'
filetags = 'scalefree' #added info after 'n<number>_assortativity
if len(filetags) > 0:
    filetags = '_' + filetags

# List runs
runs = os.listdir(sn_dir)
runs = [run for run in runs if re.findall(tags + '[-.0-9]+', run)]
runs.sort()


####################
# Measure assortativity
####################
# Set array for data collection
assort_values = np.empty((0,4))

# Loop through runs
for run in runs:
    
    # Load statement
    print("Starting on \'" + run + "\'...")
    
    # Get gamma value
    gamma = float(re.search('gamma([-\.0-9]+)', run).group(1))
    
    # List social network files in that run's data folder
    sn_files = os.listdir(sn_dir + run +'/')
    sn_final = [file for file in sn_files if re.findall('sn_rep[0-9]+.npy', file)] 
    sn_initial = [file for file in sn_files if re.findall('sn_initial_rep[0-9]+.npy', file)] 
    sn_final.sort()
    sn_initial.sort()
    
    # List type data files in that run's data folder
    type_files = os.listdir(type_dir + run +'/')
    type_files.sort()
    
    # Warning and error catch
    if len(sn_final) != len(type_files):
        print("The number of replicates do not match in the social network and type data directories.")
        break
    
     # Loop through individual replicates and calculate assortativity
    for i in np.arange(len(sn_final)):
        
        # Load network and threshold matrices
        adjacency = np.load(sn_dir + run + '/' + sn_final[i])
        adjacency_initial = np.load(sn_dir + run + '/' + sn_initial[i])
        type_mat = np.load(type_dir +  run + '/' + type_files[i])
        rep = int(re.search('([0-9]+)', sn_final[i]).group(1))
        
        # Calculate assortativity
        g_final = igraph.Graph.Adjacency(np.ndarray.tolist(adjacency))
        g_final.vs['Type'] = type_mat[:,0]
        final_assort = g_final.assortativity(types1 = g_final.vs['Type'], directed = True)
        g_initial = igraph.Graph.Adjacency(np.ndarray.tolist(adjacency_initial))
        g_initial.vs['Type'] = type_mat[:,0]
        initial_assort = g_initial.assortativity(types1 = g_initial.vs['Type'], directed = True)
        
        # Return
        to_return = np.array([[gamma, rep, final_assort, initial_assort]])
        assort_values = np.vstack([assort_values, to_return])
            
# Save
assort_data = pd.DataFrame(data = assort_values, columns = ['gamma', 'replicate', 'assort_final', 'assort_initial'])
assort_data.to_csv(outpath + 'assortativity' + filetags + '.csv', index = False)


####################
# Measure network structural change (breaks from start to finish)
####################
# Create directory to store individual files
if not os.path.exists(outpath + 'network_change/'):
    os.makedirs(outpath + 'network_change/')

# Loop through runs
for run in runs:
    
    # Load statement
    print("Starting on \'" + run + "\'...")
    
    # Get gamma value
    gamma = float(re.search('gamma([-\.0-9]+)', run).group(1))
    
     # List social network files in that run's data folder
    sn_files = os.listdir(sn_dir + run +'/')
    sn_final = [file for file in sn_files if re.findall('sn_rep[0-9]+.npy', file)] 
    sn_initial = [file for file in sn_files if re.findall('sn_initial_rep[0-9]+.npy', file)] 
    sn_final.sort()
    sn_initial.sort()
    
    # List type data files in that run's data folder
    type_files = os.listdir(type_dir + run +'/')
    type_files.sort()
    
    # Dataframe to hold data
    network_change_data = pd.DataFrame(columns = ['gamma', 'replicate', 'individual',
                                                  'out_degree', 'out_degree_initial',
                                                  'in_degree', 'in_degree_initial',
                                                  'same_type_adds', 'same_type_breaks', 
                                                  'diff_type_adds', 'diff_type_breaks'])

    
    # Warning and error catch
    if len(sn_final) != len(type_files):
        print("The number of replicates do not match in the social network and type data directories.")
        break
    
     # Loop through individual replicates and calculate changes in network
    for replicate in np.arange(len(sn_final)):
        
        # Load network and threshold matrices
        adjacency = np.load(sn_dir + run + '/' + sn_final[replicate])
        adjacency_initial = np.load(sn_dir + run + '/' + sn_initial[replicate])
        type_mat = np.load(type_dir +  run + '/' + type_files[replicate])
        
        # Determine changes in network connections
        out_degree_initial = np.sum(adjacency_initial, axis = 1)
        in_degree_initial = np.sum(adjacency_initial, axis = 0)
        out_degree = np.sum(adjacency, axis = 1)
        in_degree = np.sum(adjacency, axis = 0)
        adjacency_diff = adjacency - adjacency_initial
        
        # Determine frequency of new social ties and social tie breaks by individual type
        individual_type = type_mat[:, 1] #second column is equivalent to saying type 0 or type 1
        for i in np.arange(len(individual_type)):
            # Classify neighbors by type (in relation to selected individual's type)
            same_type_individuals = np.where(individual_type == individual_type[i])[0]
            diff_type_individuals = np.where(individual_type != individual_type[i])[0]
            # Classify new ties and breaks by the type of individual
            all_adds, all_breaks = np.where(adjacency_diff[i, :] == 1)[0], np.where(adjacency_diff[i, :] == -1)[0]
            same_type_adds = [x for x in all_adds if x in same_type_individuals]
            same_type_breaks = [x for x in all_breaks if x in same_type_individuals]
            diff_type_adds = [x for x in all_adds if x in diff_type_individuals]
            diff_type_breaks = [x for x in all_breaks if x in diff_type_individuals]
            # Count
            same_type_adds, same_type_breaks = len(same_type_adds), len(same_type_breaks)
            diff_type_adds, diff_type_breaks = len(diff_type_adds), len(diff_type_breaks)
            # Compile into dataframe row
            data_row = pd.DataFrame(data = [[gamma, replicate, i, 
                                             out_degree[i], out_degree_initial[i],
                                             in_degree[i], in_degree_initial[i],
                                             same_type_adds, same_type_breaks, 
                                             diff_type_adds, diff_type_breaks]],
                                    columns = network_change_data.columns)
            network_change_data = network_change_data.append(data_row, ignore_index = True)
            
    # Save
    network_change_data.to_csv(outpath + 'network_change/networkchange' + filetags + str(gamma) + '.csv', index = False)
    del(network_change_data)