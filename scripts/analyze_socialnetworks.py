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

# List runs
runs = os.listdir(sn_dir)
runs = [run for run in runs if re.findall(str(n_of_interest) + '_gamma[-.0-9]+', run)]


####################
# Measure assortativity
####################
# Set array for data collection
assort_values = np.empty((0,2))

# Loop through runs
for run in runs:
    
    # Load statement
    print("Starting on \'" + run + "\'...")
    
    # Get gamma value
    gamma = float(re.search('.*_gamma([-\.0-9]+)', run).group(1))
    
    # List social network files in that run's data folder
    sn_files = os.listdir(sn_dir + run +'/')
    social_networks = [file for file in sn_files if re.findall('sn_rep[0-9]+.npy', file)] #sn data also has initial networks
    social_networks.sort()
    
    # List type data files in that run's data folder
    type_files = os.listdir(type_dir + run +'/')
    type_files.sort()
    
    # Warning and error catch
    if len(social_networks) != len(type_files):
        print("The number of replicates do not match in the social network and type data directories.")
        break
    
     # Loop through individual replicates and calculate assortativity
    for i in np.arange(len(social_networks)):
        
        # Load network and threshold matrices
        adjacency = np.load(sim_dir + run + '/' + social_networks[i])
        type_mat = np.load(type_dir +  run + '/' + type_files[i])
        
        # Calculate assortativity
        g = igraph.Graph.Adjacency(np.ndarray.tolist(adjacency))
        g.vs['Type'] = type_mat[:,0]
        final_assort = g.assortativity(types1 = g.vs['Type'])
        
        # Return
        to_return = np.array([[gamma, final_assort]])
        assort_values = np.vstack([assort_values, to_return])
            
# Save
assort_data= pd.DataFrame(data = assort_values, columns = ['Gamma', 'Assortativity'])
outfile_name = 'n200_gammasweep_assortativity'
assort_data.to_csv('../output/network_break/data_derived/social_networks/' + outfile_name + '.csv', index = False)