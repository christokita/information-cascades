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
# Parameters of files to be read
####################
# Set group size runs of intereset
n_of_interest = 200

# Directory where simulation data is found
sn_dir = '../data_sim/network_break/social_network_data/' #social network data
type_dir = '../data_sim/network_break/type_data/' #type data


####################
# Output example social network for plotting in Gephi
####################
# Read in data
outfile_name = 'n' + str(n_of_interest) + '_gammasweep_assortativity'
assort_data = pd.read_csv('../output/network_break/data_derived/social_networks/' + outfile_name + '.csv')

# Find high assortatiity graph
high_assort = assort_data[assort_data.Assortativity > 0.26] #grab high assort values
high_assort = high_assort[high_assort.Gamma.isin([-1, -0.9])] #grab gammas of interest
high_assort_ind = high_assort.Assortativity.idxmax() #get index of max value

# Grab corresponding graph and type matrix
high_assort_gamma = assort_data.Gamma[high_assort_ind] #get gamma value
begin_this_gamma = min(assort_data.index[assort_data.Gamma == high_assort_gamma]) #find where this gamma starts
high_assort_replicate = high_assort_ind - begin_this_gamma + 1 #determine replicate number of that gamma value
sn_path = sn_dir + 'n' + str(n_of_interest) + '_gamma' + str(high_assort_gamma) + '/'
sn_name = 'sn_rep' + str(high_assort_replicate).zfill(2) + '.npy'
type_path = type_dir + 'n' + str(n_of_interest) + '_gamma' + str(high_assort_gamma) + '/'
type_name = 'type_rep' + str(high_assort_replicate).zfill(2) + '.npy'
high_assort_graph = np.load(sn_path + sn_name) #load
high_assort_types = np.load(type_path + type_name) #load

# Prepre for gephi and save
high_assort_graph = pd.DataFrame(high_assort_graph, 
                                 columns = np.arange(0, n_of_interest), 
                                 index = np.arange(n_of_interest))
high_assort_types = pd.DataFrame({"Id": np.arange(0, n_of_interest), "Type": high_assort_types[:,0]})
filename = "examplenet_highassort"
high_assort_graph.to_csv('../output/network_break/data_derived/social_networks/' + filename + ".csv")
high_assort_types.to_csv('../output/network_break/data_derived/social_networks/' + filename + "_nodes.csv", index = False)
