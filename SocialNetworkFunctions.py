#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Dec  9 11:31:35 2017

@author: ChrisTokita

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
   # Return
    return(network)