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
sn_dir = '../data_sim/network_break/__suppl_sims/adjust_tie_function/social_network_data/' #social network data
type_dir = '../data_sim/network_break/__suppl_sims/adjust_tie_function/type_data/' #type data
thresh_dir = '../data_sim/network_break/__suppl_sims/adjust_tie_function/thresh_data/' #threshold data

# For output
outpath = '../data_derived/network_break/__suppl_analysis/adjust_tie_function/social_networks/'
filetags = 'adjusttie' #added info for save file
if len(filetags) > 0:
    filetags = '_' + filetags

####################
# Output example of highly assortative social network for plotting in Gephi
####################
# Read in data
assort_file = [file for file in os.listdir(outpath) if re.findall('assortativity.*.csv', file)]
if len(assort_file) > 1:
    print("WARNING: more than one file matched search pattern for assortativity data.")
    assort_data = None
else:
    assort_data = pd.read_csv(outpath + assort_file[0])

# Find high assortativity graph
assort_percentile = np.percentile(assort_data.assort_final, 95)
high_assort = assort_data[assort_data.assort_final > assort_percentile] #grab high assort values
high_assort = high_assort[high_assort.gamma < 0] #grab gammas of interest
high_assort = high_assort.sort_values(by = ['assort_final'], ascending = False)
high_assort_ind = high_assort.assort_final.idxmax() #get index of max value

high_assort_ind = high_assort.index[5] #manual override

# Grab corresponding graph 
high_assort_value = high_assort.assort_final[high_assort_ind]
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
high_assort_graph.to_csv(outpath + filename + "_network" + filetags + ".csv")
high_assort_nodes.to_csv(outpath + filename + "_nodes" + filetags + ".csv", index = False)



####################
# Output example of approx. assort = 0 for gamma = 1.0
####################
# Find high assortativity graph
low_assort = assort_data[assort_data.gamma == 1] #grab gammas of interest
low_assort = low_assort[(low_assort.assort_final > -0.001) & (low_assort.assort_final < 0.001)] #grab gammas of interest

low_assort_ind = low_assort.index[0] #manual override


# Grab corresponding graph 
low_assort_value = low_assort.assort_final[low_assort_ind]
low_assort_gamma = assort_data.gamma[low_assort_ind] #get gamma value
begin_this_gamma = min(assort_data.index[assort_data.gamma == low_assort_gamma]) #find where this gamma starts
low_assort_replicate = low_assort_ind - begin_this_gamma + 1 #determine replicate number of that gamma value
sn_path = sn_dir + 'gamma' + str(low_assort_gamma) + '/'
sn_name = 'sn_final_rep' + str(low_assort_replicate).zfill(2) + '.npy'
low_assort_graph = np.load(sn_path + sn_name) #load

# Grab corresponding type data
type_path = type_dir + 'gamma' + str(low_assort_gamma) + '/'
type_name = 'type_rep' + str(low_assort_replicate).zfill(2) + '.npy'
low_assort_types = np.load(type_path + type_name) #load

# Grab corresponding threshold data  
thresh_path = thresh_dir + 'gamma' + str(low_assort_gamma) + '/'
thresh_name = 'thresh_rep' + str(low_assort_replicate).zfill(2) + '.npy'
low_assort_thresh = np.load(thresh_path + thresh_name) #load

# Prepre for gephi and save
n_individuals = low_assort_graph.shape[0]
low_assort_graph = pd.DataFrame(low_assort_graph, 
                                 columns = np.arange(0, n_individuals), 
                                 index = np.arange(n_individuals))
low_assort_nodes = pd.DataFrame({"Id": np.arange(0, n_individuals), 
                                  "Type": low_assort_types[:,0],
                                  "Threshold": low_assort_thresh[:,0]})
filename = "examplenet_lowassort"
low_assort_graph.to_csv(outpath + filename + "_network" + filetags + ".csv")
low_assort_nodes.to_csv(outpath + filename + "_nodes" + filetags + ".csv", index = False)
