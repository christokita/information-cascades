#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu May 28 10:13:46 2020

@author: ChrisTokita
"""

import numpy as np
import networkx as nx
import copy


def local_assortativity(network, types, alpha):
    """
    This function measures local assortativity according to recent methods (based on Peel, Delvenne, Lambiotte 2018).
    This is for categorical traits (e.g., political type).
    It will return a local assortativity value for each individual in the network.
    
    INPUTS:
    - network:   the network connecting individuals (numpy array).
    - types:     the categorical type of each individual (numpy array).
    - alpha:     the size of the neighborhood when calculating assortativity. 0 is entirely local, 1 is entirely global (float).
    """
    
    # Get degree and probability transition matrix (adjacency matrix normalized by degree)
    # The latter will get used in random walk algorithm to determine graph kernel for each node.
    degree = network.sum(axis = 1, keepdims = True)
    nonzero_entries = (degree > 0).flatten() #boolean index on where zero-degree individuals are
    normalized_network = copy.deepcopy(network.astype(float)) #create normalized network, and convert to float for division
    normalized_network[nonzero_entries] = normalized_network[nonzero_entries] / degree[nonzero_entries] #divide row by degree to get proportion of edges for each individual
    
    # Calculate global assortativity measures
    a_g, Q_max = global_assort_values(network, types)
    
    # Calculate local assortativity
    categorized_connections = connections_by_type(normalized_network, types)
    weights = personalized_page_rank(network, alpha)
    local_assort = np.array([])
    for i in range(network.shape[0]): #loop over individuals
        # If individual has degree of zero, they have no local assortativity
        if degree[i] == 0: 
            local_assort = np.append(local_assort, np.nan)
        else:
            # Otherwise calculate local assortativity
            deviation_from_global = 0 #portion in the sum of equation [6] in paper
            for t in np.unique(types):
                this_type = types == t
                e_gg = weights[i, this_type] @ categorized_connections[this_type, t] #e_gg(l) value
                deviation_from_global += e_gg - a_g[t]**2
            # Normalize by Q_max per equation [6] in paper
            r_l = deviation_from_global / Q_max
            local_assort = np.append(local_assort, r_l)
        
    #Return values
    return local_assort
    

def global_assort_values(network, types):
    """
    Function that will calculate Qmax and a_g for use in calculating assortativity
    
    INPUTS:
    - network:   the network connecting individuals (numpy array).
    - types:     the categorical type of each individual (numpy array).
    """
    
    m = np.sum(network) / 2 #total number of unique edges
    a_g = np.array([])
    for t in np.unique(types):
        this_type = np.where(types == t)[0]
        type_subnetwork = network[this_type,:]
        normalized_degree = np.sum(type_subnetwork, axis = 1) / (2*m)
        a_g = np.append(a_g, np.sum(normalized_degree))
    Q_max = 1 - np.sum(a_g**2)
    return a_g, Q_max


def connections_by_type(normalized_network, types):
    # Function that determines how many connections each individual has to individuals of a particular type.
    # Returns an array where each row is an individual and each column is a type (e.g., type 0 and type 1).
    #
    # INPUTS:
    # - normalized_network:   the network connecting individuals, with each row normalized by degree. (numpy array).
    # - types:                the categorical type of each individual (numpy array).
    
    categorized_connections = np.zeros((normalized_network.shape[0], len(np.unique(types))))
    for t in np.unique(types):
        this_type = np.where(types == t)[0]
        type_connections = normalized_network[:,this_type] #only look at connections to individuals to type t
        categorized_connections[:,t] = np.sum(type_connections, axis = 1)
    return categorized_connections


def calculate_distance(network):
    # Function to create distance matrix for the network.
    #
    # INPUTS:
    # - network: the network connecting individuals (numpy array).
    
    g = nx.from_numpy_matrix(network)
    distance_matrix = np.zeros(network.shape)
    # Loop over all individuals and connections
    for i in range(network.shape[0]): 
        for j in range(network.shape[1]):
            try:
                p = nx.shortest_path(g, i, j)
                distance_matrix[i,j] = len(p) - 1 #includes starting node in shortest path
            except:
                distance_matrix[i,j] = np.nan
    return distance_matrix


def personalized_page_rank(network, alpha):
    # Function to calcualte the personalized page rank for each individual.
    # Returns a matrix the same dimensions as the network, where each row will have the page rank for that individual.
    #
    # INPUTS:
    # - normalized_network:   the network connecting individuals, with each row normalized by degree (numpy array).
    # - alpha:                the return probability for the walker (float).

    zero_degrees = np.where(np.sum(network, axis = 1) == 0)[0] #individuals that aren't connected to anyone
    page_rank_values = np.zeros_like(network, dtype = float)
    g = nx.from_numpy_matrix(network)
    for i in range(network.shape[0]): 
        if i in zero_degrees:
            pagerank_vals = np.zeros(network.shape[0])
            pagerank_vals[i] = 1
        else:
            personal_dict = {i: 1}
            personalized_pagerank = nx.pagerank(g, alpha = alpha, personalization = personal_dict)
            pagerank_vals = list(personalized_pagerank.values())
        page_rank_values[i,:] = np.array(pagerank_vals)
    return page_rank_values
       

def local_assortativity_continuous(network, thresholds, alpha):
    """
    This function measures local assortativity according to recent methods (based on Peel, Delvenne, Lambiotte 2018; specficially see the supplement for using this metric on scalar attributes).
    This is for continuous traits (e.g., thresholds).
    It will return a local assortativity value for each individual in the network.
    
    The forumla is:
        local_assortativity = SUM_ij [ weight_random_walk (A_ij / k_i) xhat_i * xhat_j ]
        
        where xhat_i is the standardized value of x_i, i.e., xhat_i = (x_i - mean(x)) / std(x)
    
    INPUTS:
    - network:      the network connecting individuals (numpy array).
    - threhsolds:   the threshold of each individual (numpy array).
    - alpha:        the size of the neighborhood when calculating assortativity. 0 is entirely local, 1 is entirely global (float).
    """
    
    # Get degree and probability transition matrix (adjacency matrix normalized by degree)
    # The latter will get used in random walk algorithm to determine graph kernel for each node.
    degree = network.sum(axis = 1, keepdims = True)
    nonzero_entries = (degree > 0).flatten() #boolean index on where zero-degree individuals are
    normalized_network = copy.deepcopy(network.astype(float)) #create normalized network, and convert to float for division
    normalized_network[nonzero_entries] = normalized_network[nonzero_entries] / degree[nonzero_entries] #divide row by degree to get proportion of edges for each individual
    
    # Standardize thresholds      
    # threshold_mean = np.mean(thresholds)
    threshold_std = np.std(thresholds) 
    threshold_mean = np.average(thresholds, weights = degree.flatten(), axis = 0)
    threshold_std = np.sqrt( np.average((thresholds - threshold_mean)**2, weights = degree.flatten(), axis = 0) )
    
    threshold_deviation = (thresholds - threshold_mean).flatten() / threshold_std
    
    # Calculate each individual's correlation with immediate neighbors
    local_thresh_corr = np.array([])
    for i in range(network.shape[0]): #select focal individual to calculate local assort for 
        pearson_corr = (threshold_deviation[i] * threshold_deviation)
        corr_weighed_by_network = normalized_network[i,:] @ pearson_corr
        local_thresh_corr = np.append(local_thresh_corr, corr_weighed_by_network)
    
    # Calculate local assortativity by weighing the neighbors (and neighbors of neighbors) correlation with their respective neighbors
    # according to local walk (probability of this represented by personalized page rank)
    weights = personalized_page_rank(network, alpha)
    local_assort = weights @ local_thresh_corr

    # Individuals without any neighbors cannot have local assortativity by definition
    zero_degree = np.where(degree == 0)[0]
    local_assort[zero_degree] = np.nan
        
    #Return values
    return local_assort
    