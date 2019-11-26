#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Nov 25 11:56:02 2019

@author: ChrisTokita
"""

import numpy as np
import igraph

 
def seed_social_network(n, k, type = "random"):
    # This function generates a social network.
    #
    # INPUTS:
    # - n:   number of individuals in the social system (int).
    # - k:   average degree desired in social network (int).
    # - type:    
    
    # Generate graph using Erdo-Renyi algorithm
    if type == "random":
        g = igraph.Graph.Erdos_Renyi(n = n, m = n*k, directed = True, loops = False)
    elif type == "scalefree":
        g = igraph.Graph.Barabasi(n = n, m = k, directed = True, power = 1)
    # Make into adjacency matrix
    network = g.get_adjacency()
    network = np.array(network.data)
    
    # Prevent loners
    if sum( np.sum(network, axis = 1) == 0 ) > 0:
        
        # Find loners
        loners = np.where(np.sum(network, axis = 1) == 0)[0]
        number_of_breaks = len(loners) #numver of links that need to broken
        
        # Find and break links to keep mean degree the same
        two_or_more = np.where(np.sum(network, axis = 1) > 1)[0]
        break_links = np.random.choice(two_or_more, replace = False, size = number_of_breaks)
        for break_link in break_links:
            # Choose link at random and break/zero out
            connections = np.where(network[break_link,] == 1)[0]
            break_this = np.random.choice(connections, size = 1)
            network[break_link, break_this] = 0
            
        # Add random links to loners
        for loner in loners:
            possible_connections = np.arange(0, n)
            possible_connections = np.delete(possible_connections, loner)
            new_connection = np.random.choice(possible_connections, size = 1)
            network[loner, new_connection] = 1
            
    # Return
    return network