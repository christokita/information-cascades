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


####################
# Parameters of files to be read
####################
# For output
outpath = '../data_derived/network_break/social_networks/'
filetags = '' #added info for save file
if len(filetags) > 0:
    filetags = '_' + filetags
    
# Directory where simulation data is found
sn_dir = '../data_sim/network_break/social_network_data/' #social network data
type_dir = '../data_sim/network_break/type_data/' #type data
thresh_dir = '../data_sim/network_break/thresh_data/' #threshold data


#################### 
# Read in data
####################
assort_file = [file for file in os.listdir(outpath) if re.findall('assortativity.*.csv', file)]
if len(assort_file) > 1:
    print("WARNING: more than one file matched search pattern for assortativity data.")
    assort_data = None
else:
    assort_data = pd.read_csv(outpath + assort_file[0])

####################
# Functions for getting example networks
####################
# Utility functions
def grab_graph(data, index):
    # Determine properties about graph
    assortativity = data.assort_final[index]
    gamma = data.gamma[index] #get gamma value
    replicate = int(data.replicate[index]) #determine replicate number of that gamma value
    
    # Load graph
    sn_path = sn_dir + 'gamma' + str(gamma) + '/'
    sn_name = 'sn_final_rep' + str(replicate).zfill(2) + '.npy'
    graph = np.load(sn_path + sn_name) #load
    return graph, gamma, assortativity, replicate

def grab_node_properties(gamma, replicate):
    # Grab corresponding type data
    type_path = type_dir + 'gamma' + str(gamma) + '/'
    type_name = 'type_rep' + str(replicate).zfill(2) + '.npy'
    types = np.load(type_path + type_name) #load
    
    # Grab corresponding threshold data  
    thresh_path = thresh_dir + 'gamma' + str(gamma) + '/'
    thresh_name = 'thresh_rep' + str(replicate).zfill(2) + '.npy'
    thresholds = np.load(thresh_path + thresh_name) #load
    
    return types, thresholds

# Function to select a graph based on a desired gamma value
def get_network_by_gamma(gamma, outpath, filename, filetags, method, manual_index = 0):
    # This function can take a single gamma value or a list of gamma values and then select and save an example network.
    # User can specify the method desired:
    # - "max": Select the highest assortativity value (works with one or multiple gamma values)
    # - "average": Select a value representative of the average assortativity (works best with a single gamma value)
    
    # find graph from specified gamma
    filtered_data = assort_data[assort_data['gamma'].isin (gamma)] # accepts single or list of valuess
    if method == "average":
        filtered_assort_mean = np.mean(filtered_data['assort_final'])
        filtered_data = filtered_data[(filtered_data['assort_final'] > filtered_assort_mean - 0.01) &\
                                    (filtered_data['assort_final'] < filtered_assort_mean + 0.01)]
        filtered_data = filtered_data.sort_values(by = ['assort_final'], ascending = False)
    elif method == "max":
        filtered_data = filtered_data.sort_values(by = ['assort_final'], ascending = False)
        print("\nMethod 'max' selected. Showing the top 10 graphs in this gamma range:\n")
        print(filtered_data.iloc[0:10,:])
    selected_index = filtered_data.index[manual_index]
    
    # Grab corresponding graph and node properties
    graph, gamma, assort_value, replicate = grab_graph(data = filtered_data, index = selected_index)
    types, thresholds = grab_node_properties(gamma = gamma, replicate = replicate)
    
    # Prepre for gephi and save
    n_individuals = graph.shape[0]
    graph_table = pd.DataFrame(graph, 
                               columns = np.arange(0, n_individuals), 
                               index = np.arange(n_individuals))
    node_table = pd.DataFrame({"Id": np.arange(0, n_individuals), 
                               "Type": types[:,0],
                               "Threshold": thresholds[:,0]})
    graph_table.to_csv("%s%s_network%s.csv" % (outpath, filename, filetags))
    node_table.to_csv("%s%s_nodes%s.csv" % (outpath, filename, filetags), index = False)
    print("\n---\nGraph selected\nGamma = %1.1f\nReplicate = %d\nAssortativity = %1.3f" % (gamma, replicate, assort_value))


####################
# High Assortativity example graph
####################
    
# Grab highest assortativity values
gammas = np.round(np.arange(-1, 0.5, 0.1), 1) #list of one or more gamma values desired
#gammas = [-1, 0.9, 0.8, 0.7, 0.6, 0.5, 0.4, 0.3, 0.2, 0.1, 0.0] #list of one or more gamma values desired
method = 'max' #'max' or 'average'
filename = 'example_highassort'
index = 0 #index of which graph to select from filtered subset, DEFAULT = 0
    
get_network_by_gamma(gamma = gammas, 
                     outpath = outpath, 
                     filename = filename, 
                     filetags = filetags,
                     method = method, 
                     manual_index = index)


# Grab average value for a high-assortativity gamma value
gammas = [0.0] #list of one or more gamma values desired
method = 'average' #'max' or 'average'
filename = 'example_gamma0.0'
index = 3 #index of which graph to select from filtered subset, DEFAULT = 0
# Note indices 0, 3 are good
    
get_network_by_gamma(gamma = gammas, 
                     outpath = outpath, 
                     filename = filename, 
                     filetags = filetags,
                     method = method, 
                     manual_index = index)



####################
# Lower Assortativity example graphs
####################

gammas = [0.7] #list of one or more gamma values desired
method = 'average' #'max' or 'average'
filename = 'example_gamma0.7'
index = 0 #index of which graph to select from filtered subset, DEFAULT = 0
    
get_network_by_gamma(gamma = gammas, 
                     outpath = outpath, 
                     filename = filename, 
                     filetags = filetags,
                     method = method, 
                     manual_index = index)


gammas = [0.5] #list of one or more gamma values desired
method = 'average' #'max' or 'average'
filename = 'example_gamma0.5'
index = 0 #index of which graph to select from filtered subset, DEFAULT = 0
    
get_network_by_gamma(gamma = gammas, 
                     outpath = outpath, 
                     filename = filename, 
                     filetags = filetags,
                     method = method, 
                     manual_index = index)


####################
# No Assortativity example graph
####################

gammas = [1.0] #list of one or more gamma values desired
method = 'average' #'max' or 'average'
filename = 'example_gamma1.0'
index = 0 #index of which graph to select from filtered subset, DEFAULT = 0
    
get_network_by_gamma(gamma = gammas, 
                     outpath = outpath, 
                     filename = filename, 
                     filetags = filetags,
                     method = method, 
                     manual_index = index)

