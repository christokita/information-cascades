#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Dec  9 11:31:35 2017

@author: ChrisTokita

DESCRIPTION:
Social Network Functions
"""
import numpy as np
import igraph

# Seed random network 
def seed_social_network(n, k):
    # Generate graph using Erdo-Renyi algorithm
    g = igraph.Graph.Erdos_Renyi(n = n, m = n*k, directed = True, loops = False)
    # Make into adjacency matrix
    network = g.get_adjacency()
    network = np.array(network.data)
    # Prevent loners
    if sum( np.sum(network, axis = 1) == 0 ) > 0:
        # Find loners
        loners = np.where(np.sum(network, axis = 1) == 0)[0]
        number_of_breaks = len(loners) #numver of links that need to broken
        # Find and break links to keep mean degree the same
        two_or_more = np.where(sum(network) > 1)[0]
        break_links = np.random.choice(two_or_more, replace = False, size = number_of_breaks)
        for break_link in break_links:
            # Choose link at random and break/zero out
            connections = np.where(network[break_link,:] == 1)[0]
            break_this = np.random.choice(connections, size = 1)
            network[break_link, break_this] = 0
        # Add random links to loners
        for loner in loners:
            possible_connections = np.arange(0, n)
            possible_connections = np.delete(possible_connections, loner)
            new_connection = np.random.choice(possible_connections, size = 1)
            network[loner, new_connection] = 1
    # Return
    return(network)