#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Aug 20 10:02:31 2019

@author: ChrisTokita

DESCRIPTION:
Script to analyze social network structure produced by simulations
"""

####################
# Load libraryies and packages
####################
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import os
import re
import igraph

####################
# Load individual data
####################
list_networks = np.load('../output/network_adjust/data/social_network_data/n200_gamma-0.5.npy')
list_networks_initial = np.load('../output/network_adjust/data/social_network_data/n200_gamma-0.5_initial.npy')
list_types = np.load('../output/network_adjust/data/type_data/n200_gamma-0.5.npy')


####################
# List files to be read
####################
# Set group size runs of intereset
n_of_interest = 200

# Find files
all_files = os.listdir('../output/network_adjust/data/social_network_data/')
pars_of_interest = [file for file in all_files if re.findall(str(n_of_interest) + '_gamma[-.0-9]+.npy', file)]
pars_of_interest = [re.sub('.npy', '', file) for file in pars_of_interest]

####################
# Measure assortativity
####################
assort_values = np.empty((0,2))

for file in pars_of_interest:
    
    # Get gamma value
    gamma = float(re.search('.*_gamma([-\.0-9]+)', file).group(1))
    
    # Load network and threshold matrices
    list_networks = np.load('../output/network_adjust/data/social_network_data/' + file + '.npy')
    list_types = np.load('../output/network_adjust/data/type_data/' + file + '.npy')
    
    # Loop through individual replicates  and calculate assortativity
    for i in np.arange(len(list_networks)):
        # Get exact network and type matrix
        adjacency = list_networks[i]
        type_mat = list_types[i]
        # Calculate assortativity
        g = igraph.Graph.Adjacency(np.ndarray.tolist(adjacency))
        g.vs['Type'] = type_mat[:,0]
        final_assort = g.assortativity(types1 = g.vs['Type'])
        # Return
        to_return = np.array([[gamma, final_assort]])
        assort_values = np.vstack([assort_values, to_return])
        
# Save
header = np.array([''])
outfile_name = 'n200_gammasweep_assortativity'
np.savetxt('../output/network_adjust/data_derived/social_networks/' + outfile_name + '.csv', assort_values)