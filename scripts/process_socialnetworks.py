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
sn_dir = '../data_sim/network_break/social_network_data/' #social network data
type_dir = '../data_sim/network_break/type_data/' #type data
thresh_dir = '../data_sim/network_break/thresh_data/' #threshold data
tags = 'gamma' #file tags that designate runs from a particular simulation

# For output
outpath = '../data_derived/network_break/social_networks/'
filetags = '' #added info after 'assortativity'
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
assort_values = np.empty((0,6))

# Loop through runs
for run in runs:
    
    # Load statement
    print("Assortativity: Starting on \'" + run + "\'...")
    
    # Get gamma value
    gamma = float(re.search('gamma([-\.0-9]+)', run).group(1))
    
    # List social network files in that run's data folder
    sn_files = os.listdir(sn_dir + run +'/')
    sn_final = sorted( [file for file in sn_files if re.findall('sn_final_rep[0-9]+.npy', file)] )
    sn_initial = sorted( [file for file in sn_files if re.findall('sn_initial_rep[0-9]+.npy', file)] )
    
    # List type and threshold data files in that run's data folder
    type_files = sorted( os.listdir(type_dir + run +'/') )
    thresh_files = sorted( os.listdir(thresh_dir + run +'/') )
    
    # Warning and error catch
    if len(sn_final) != len(type_files):
        print("The number of replicates do not match in the social network and type data directories.")
        break
    
     # Loop through individual replicates and calculate assortativity
    for i in np.arange(len(sn_final)):
        
        # Load network and threshold matrices
        adjacency = np.load(sn_dir + run + '/' + sn_final[i])
        adjacency_initial = np.load(sn_dir + run + '/' + sn_initial[i])
        types = np.load(type_dir +  run + '/' + type_files[i])
        thresholds = np.load(thresh_dir + run + '/' + thresh_files[i])
        rep = int(re.search('([0-9]+)', sn_final[i]).group(1))
        
        # Calculate assortativity by type
        g_final = igraph.Graph.Adjacency(np.ndarray.tolist(adjacency), mode = 'undirected')
        g_final.vs['Type'] = types[:,1] #second column is equivalent to saying type 0 or type 1
        final_assort_type = g_final.assortativity_nominal(types = g_final.vs['Type'], directed = False) #type categories are nominal, despite being numbers
        g_initial = igraph.Graph.Adjacency(np.ndarray.tolist(adjacency_initial), mode = 'undirected')
        g_initial.vs['Type'] = types[:,1] #second column is equivalent to saying type 0 or type 1
        initial_assort_type = g_initial.assortativity_nominal(types = g_initial.vs['Type'], directed = False)
        
        # Calculate assortativity by threshold
        g_final.vs['Threshold'] = thresholds.flatten()
        final_assort_thresh = g_final.assortativity(types1 = g_final.vs['Threshold'], directed = False)
        g_initial.vs['Threshold'] = thresholds.flatten()
        initial_assort_thresh = g_initial.assortativity(types1 = g_initial.vs['Threshold'], directed = False)
        
        # Return
        to_return = np.array([gamma, rep, final_assort_type, initial_assort_type, final_assort_thresh, initial_assort_thresh])
        assort_values = np.vstack([assort_values, to_return])

# Save
if not os.path.exists(outpath):
    os.makedirs(outpath)
assort_data = pd.DataFrame(data = assort_values, columns = ['gamma', 'replicate', 'assort_type_final', 'assort_type_initial', 
                                                            'assort_thresh_final', 'assort_thresh_initial'])
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
    
    # Dataframe to hold data
    network_change_data = pd.DataFrame(columns = ['gamma', 'replicate', 'individual', 
                                                  'type', 'theshold',
                                                  'degree', 'degree_initial',
                                                  'centrality', 'centrality_initial',
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
        thresholds = np.load(thresh_dir + run + '/' + thresh_files[replicate]).flatten() #make 1d
        types = np.load(type_dir +  run + '/' + type_files[replicate])
        types = types[:, 1] #second column is equivalent to saying type 0/L or type 1/R
        
        # Determine changes in network connections
        degree_initial = np.sum(adjacency_initial, axis = 1)
        degree = np.sum(adjacency, axis = 1)
        adjacency_diff = adjacency - adjacency_initial
        
        # Determine centrality 
        g_final = igraph.Graph.Adjacency(np.ndarray.tolist(adjacency), mode = 'undirected')
        g_initial = igraph.Graph.Adjacency(np.ndarray.tolist(adjacency_initial), mode = 'undirected')
        centrality = g_final.evcent(directed = False)
        centrality_initial = g_initial.evcent(directed = False)
        
        # Determine frequency of new social ties and social tie breaks by individual type
        same_type_adds = np.array([])
        same_type_breaks = np.array([])
        diff_type_adds = np.array([])
        diff_type_breaks = np.array([])
        for i in np.arange(len(types)):
            # Classify neighbors by type (in relation to selected individual's type)
            same_type_individuals = np.where(types == types[i])[0]
            diff_type_individuals = np.where(types != types[i])[0]
            # Classify new ties and breaks by the type of individual
            all_adds, all_breaks = np.where(adjacency_diff[i, :] == 1)[0], np.where(adjacency_diff[i, :] == -1)[0]
            same_adds = [x for x in all_adds if x in same_type_individuals]
            same_breaks = [x for x in all_breaks if x in same_type_individuals]
            diff_adds = [x for x in all_adds if x in diff_type_individuals]
            diff_breaks = [x for x in all_breaks if x in diff_type_individuals]
            # Count
            same_type_adds = np.append(same_type_adds, len(same_adds))
            same_type_breaks = np.append(same_type_breaks, len(same_breaks))
            diff_type_adds = np.append(diff_type_adds, len(diff_adds))
            diff_type_breaks = np.append(diff_type_breaks, len(diff_breaks))
            
        # Compile into dataframe and append to master dataframe
        n = len(thresholds)
        replicate_data = pd.DataFrame(np.column_stack((np.repeat(gamma, n), np.repeat(replicate, n), np.arange(0, n), 
                                                       types, thresholds,
                                                       degree, degree_initial,
                                                       centrality, centrality_initial,
                                                       same_type_adds, same_type_breaks, 
                                                       diff_type_adds, diff_type_breaks)),
                                    columns = network_change_data.columns)
        network_change_data = network_change_data.append(replicate_data, ignore_index = True)
        del replicate_data
            
    # Save
    network_change_data.to_csv(outpath + 'network_change/networkchange_gamma' + str(gamma) + filetags + '.csv', index = False)
    del network_change_data

    