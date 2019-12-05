#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Aug 20 10:02:31 2019

@author: ChrisTokita

DESCRIPTION:
Script to analyze social network structure produced by simulations
"""

####################
# Load libraries and packages
####################
import numpy as np
import pandas as pd
import os
import re
import igraph
import copy

'''
####################
# Load individual data
####################
list_networks = np.load('../output/network_adjust/data/social_network_data/n200_gamma-0.5.npy')
list_networks_initial = np.load('../output/network_adjust/data/social_network_data/n200_gamma-0.5_initial.npy')
list_types = np.load('../output/network_adjust/data/type_data/n200_gamma-0.5.npy')
'''

####################
# List files to be read
####################
# Set group size runs of intereset
n_of_interest = 200

# Directory where simulation data is found
sn_dir = '../data_sim/network_break/social_network_data/' #social network data
type_dir = '../data_sim/network_break/type_data/' #type data

# For output
outpath = '../data_derived/network_break/social_networks/'
filetags = 'gammasweep' #added info after 'n<number>_assortativity

# List runs
runs = os.listdir(sn_dir)
runs = [run for run in runs if re.findall(str(n_of_interest) + '_gamma[-.0-9]+', run)]


####################
# Measure assortativity
####################
# Set array for data collection
assort_values = np.empty((0,3))

# Loop through runs
for run in runs:
    
    # Load statement
    print("Starting on \'" + run + "\'...")
    
    # Get gamma value
    gamma = float(re.search('.*_gamma([-\.0-9]+)', run).group(1))
    
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
        
        # Calculate assortativity
        g_final = igraph.Graph.Adjacency(np.ndarray.tolist(adjacency))
        g_final.vs['Type'] = type_mat[:,0]
        final_assort = g_final.assortativity(types1 = g_final.vs['Type'], directed = True)
        g_initial = igraph.Graph.Adjacency(np.ndarray.tolist(adjacency_initial))
        g_initial.vs['Type'] = type_mat[:,0]
        initial_assort = g_initial.assortativity(types1 = g_initial.vs['Type'], directed = True)
        
        # Return
        to_return = np.array([[gamma, final_assort, initial_assort]])
        assort_values = np.vstack([assort_values, to_return])
            
# Save
assort_data= pd.DataFrame(data = assort_values, columns = ['gamma', 'assort_final', 'assort_initial'])
assort_data.to_csv(outpath + 'n' + str(n_of_interest) + '_assortativity' + filetags + '.csv', index = False)

