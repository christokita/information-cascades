#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Aug 20 10:02:31 2019

@author: ChrisTokita

DESCRIPTION:
Script to process social network data and get single example network.
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

####################
# Parameters of files to be read
####################
# Directory where simulation data is found
sn_dir = '../data_sim/network_break/__suppl_sims/identical_thresholds_p0_longsim/social_network_data/' #social network data
type_dir = '../data_sim/network_break/__suppl_sims/identical_thresholds_p0_longsim/type_data/' #type data
thresh_dir = '../data_sim/network_break/__suppl_sims/identical_thresholds_p0_longsim/thresh_data/' #threshold data

# For output
outpath = '../data_derived/network_break/__suppl_analysis/identical_thresholds_p0_longsim/social_networks/'
filetags = 'identicalthresh_p0_10^6' #added info for save file
if len(filetags) > 0:
    filetags = '_' + filetags

####################
# Output example social network for plotting in Gephi
####################
# Read in data
assort_file = [file for file in os.listdir(outpath) if re.findall('assortativity.*.csv', file)]
if len(assort_file) > 1:
    print("WARNING: more than one file matched search pattern for assortativity data.")
    assort_data = None
else:
    assort_data = pd.read_csv(outpath + assort_file[0])

# Find high assortatiity graph
assort_percentile = np.percentile(assort_data.assort_final, 95)
high_assort = assort_data[assort_data.assort_final > assort_percentile] #grab high assort values
high_assort = high_assort[high_assort.gamma.isin([-1, -0.9])] #grab gammas of interest
high_assort_ind = high_assort.assort_final.idxmax() #get index of max value

# Grab corresponding graph 
high_assort_gamma = assort_data.gamma[high_assort_ind] #get gamma value
begin_this_gamma = min(assort_data.index[assort_data.gamma == high_assort_gamma]) #find where this gamma starts
high_assort_replicate = high_assort_ind - begin_this_gamma + 1 #determine replicate number of that gamma value
sn_path = sn_dir + 'gamma' + str(high_assort_gamma) + '/'
sn_name = 'sn_final_rep' + str(high_assort_replicate).zfill(2) + '.npy'
high_assort_graph = np.load(sn_path + sn_name) #load

# Grab corresponding type data
type_path = type_dir + 'gamma' + str(high_assort_gamma) + '/'
type_name = 'type_rep' + str(high_assort_replicate).zfill(2) + '.npy'
high_assort_types = np.load(type_path + type_name) #load

# Grab corresponding threshold data  
thresh_path = thresh_dir + 'gamma' + str(high_assort_gamma) + '/'
thresh_name = 'thresh_rep' + str(high_assort_replicate).zfill(2) + '.npy'
high_assort_thresh = np.load(thresh_path + thresh_name) #load

# Prepre for gephi and save
n_individuals = high_assort_graph.shape[0]
high_assort_graph = pd.DataFrame(high_assort_graph, 
                                 columns = np.arange(0, n_individuals), 
                                 index = np.arange(n_individuals))
high_assort_nodes = pd.DataFrame({"Id": np.arange(0, n_individuals), 
                                  "Type": high_assort_types[:,0],
                                  "Threshold": high_assort_thresh[:,0]})
filename = "examplenet_highassort"
high_assort_graph.to_csv(outpath + "examplenet_network" + filetags + ".csv")
high_assort_nodes.to_csv(outpath + "examplenet_nodes" + filetags + ".csv", index = False)
