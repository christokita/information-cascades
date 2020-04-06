#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Nov 25 11:56:02 2019

@author: ChrisTokita
"""

import numpy as np
import igraph

 
def seed_social_network(n, k, network_type, directed = False):
    # This function generates a social network. 
    # If the network is undirected, only even <k> allows for use of all network types.
    # Otherwise, scale-free cannot handle creating an undirected graph with an odd mean degree <k>.
    #
    # INPUTS:
    # - n:   number of individuals in the social system (int).
    # - k:   average degree desired in social network (int).
    # - type:   type of network to generate: random, scale-free (str).    
    
    # Set up appropriate number of edges or degree
    if not directed:
        if k%2 != 0:
            raise Exception("WARNING: Cannot reliably generate undirected scale-free networks with odd mean degree <k> = 1, 3, 5, etc. Please select an even <k> to allow appropriate comparison between network types.")
        n_edges = int((n*k)/2)
        out_links = int(k/2)
        avg_degree = k
    elif directed:
        n_edges = n*k
        out_links = k
        avg_degree = k
    
    # Generate graph using Erdo-Renyi algorithm
    if network_type == "random":
        g = igraph.Graph.Erdos_Renyi(n = n, m = n_edges, directed = directed, loops = False)
    elif network_type == "scalefree":
        g = igraph.Graph.Barabasi(n = n, m = out_links, directed = directed, power = 1)
    elif network_type == "regular":
        g = igraph.Graph.K_Regular(n = n, k = avg_degree, directed = directed, multiple = False)
    elif network_type == "complete":
        g = igraph.Graph.Full(n = n, directed = directed, loops = False)
    # Make into adjacency matrix
    network = g.get_adjacency()
    network = np.array(network.data)
    
#    # Prevent loners
#    if sum( np.sum(network, axis = 1) == 0 ) > 0:
#        
#        # Find loners
#        loners = np.where(np.sum(network, axis = 1) == 0)[0]
#        number_of_breaks = len(loners) #numver of links that need to broken
#        
#        # Find and break links to keep mean degree the same
#        two_or_more = np.where(np.sum(network, axis = 1) > 1)[0]
#        break_links = np.random.choice(two_or_more, replace = False, size = number_of_breaks)
#        for break_link in break_links:
#            # Choose link at random and break/zero out
#            connections = np.where(network[break_link,] == 1)[0]
#            break_this = np.random.choice(connections, size = 1)
#            network[break_link, break_this] = 0
#            network[break_this, break_link] = 0
#            
#        # Add random links to loners
#        for loner in loners:
#            possible_connections = np.arange(0, n)
#            possible_connections = np.delete(possible_connections, loner)
#            new_connection = np.random.choice(possible_connections, size = 1)
#            network[loner, new_connection] = 1
            
    # Return
    return network