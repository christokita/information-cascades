#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Aug 21 11:37:58 2019

@author: ChrisTokita

DESCRIPTION:
Script to test whether assortative/modular networks can be generated
"""

####################
# Load libraryies and packages
####################
import sys
sys.path.insert(0, '../')

import numpy as np
import pandas as pd
import igraph
from util_scripts.socialnetworkfunctions import *
from util_scripts.thresholdfunctions import *
import matplotlib.pyplot as plt
import copy

####################
# Attempt algorithm to create assortativity 
####################
def assortify_network(network, type_vector, assortativity):
    # This function requires:
    # - network: an adjacency network
    # - type_vetor: a vector describing the type (as int) of each individual
    # - assortativity: desired level of assortativity
    
    # Calculate sampling probability from desired assortativity
    p = (assortativity + 1) / 2
    # Number of individuals
    num_ind = len(network)
    # Get degrees of individuals
    degrees = np.sum(network, axis = 1)
    # Loop through individuals
    for i in range(num_ind):
        # Grab individual's row and type
        row = adjacency[i,]
        ind_type = type_vector[i]
        # Determine which individuals are same type and different type
        same_type = np.where(type_vector == ind_type)[0]
        same_type = np.delete(same_type, np.where(same_type == i)[0]) #remove focal individual from list
        diff_type = np.where(type_vector != ind_type)[0]
        # Create new base row
        new_row = np.zeros(num_ind, dtype = int)
        # Create new connections
        for neighbor in range(degrees[i]):
            # Determine if neighbor will be same or different type
            same = np.random.choice([True, False], size = 1, p = [p, 1 - p])
            # Select new connection
            if same == True:
                # Select one of those of the same type
                new_tie = np.random.choice(same_type)
                # Remove new time from same_type list to prevent re-sampling
                same_type = np.delete(same_type, np.where(same_type == new_tie)[0]) 
            else:
                # Select one of those of the same type
                new_tie = np.random.choice(diff_type)
                # Remove new time from same_type list to prevent re-sampling
                diff_type = np.delete(diff_type, np.where(diff_type == new_tie)[0]) 
            # Form new connection
            new_row[new_tie] = 1
        # Insert new row
        adjacency[i,] = new_row
    # Return new adjacency matrix
    return(adjacency)

####################
# Test algorithm
####################
##### Set paramters #####
n = 500 #number of individuals
k = 4 #mean degree on network

##### Generate network #####
# Assign type
type_mat = assign_type(n = n)
type_vector = type_mat[:,0]

# Set up social network
adjacency = seed_social_network(n, k)
adjacency_initial = copy.copy(adjacency)

##### Generate assortative network #####
# Generate assortative network
adjacency = assortify_network(network = adjacency, type_vector = type_vector, assortativity = 0.9)

# Turn into igraph objects (adjacency matrices need to be lists)
g = igraph.Graph.Adjacency(np.ndarray.tolist(adjacency))
g_initial = igraph.Graph.Adjacency(np.ndarray.tolist(adjacency_initial))

# Assign types
g.vs['Type'] = type_vector
g_initial.vs['Type'] = type_vector

##### Assess #####
# Measure assortativity
final_assort = g.assortativity(types1 = g.vs['Type'])
initial_assort = g_initial.assortativity(types1 = g_initial.vs['Type'])

print(final_assort)
print(initial_assort)

'''
# Measure modularity
def measure_modularity(graph):
    # Get community membership
    dendrogram = graph.community_edge_betweenness()
    membership = dendrogram.as_clustering().membership
    # Calculate modularity
    modularity = graph.modularity(membership)
    return(modularity)
    
measure_modularity(g)

measure_modularity(g_initial)
'''

####################
# Run many samples of algorithm
####################
##### Set paramters #####
n = 500 #number of individuals
k = 4 #mean degree on network
replicates = 500
assorts = np.round(np.arange(-1, 1.01, 0.05), 3) #round to deal with weird float values

##### Run algorithm #####
# Set up results list
alg_results = pd.DataFrame({'AssortValue' : [], 'ResultAssort' : []})

# Loop through assortativity values
for assort in assorts:
    # Print progress message
    print("Starting Assortatvity = " + str(assort))
    
    # Loop through replicates
    for rep in range(replicates):
        # Print progress message
        if (rep/replicates * 100) % 10 == 0:
            prog = int(rep/replicates * 100)
            print("..." + str(prog) + "%")
        
        # Generate initial network
        type_mat = assign_type(n = n)
        type_vector = type_mat[:,0]
        adjacency = seed_social_network(n, k)
        adjacency_initial = copy.copy(adjacency)
        
        # Run algorithm
        adj_assort = assortify_network(network = adjacency, type_vector = type_vector, assortativity = assort)

        # Calculate assortativity
        g = igraph.Graph.Adjacency(np.ndarray.tolist(adjacency))
        g.vs['Type'] = type_vector
        final_assort = g.assortativity(types1 = g.vs['Type'])
        
        # Return values
        to_return = pd.Series([assort, final_assort], index = alg_results.columns)
        alg_results = alg_results.append(to_return, ignore_index=True)