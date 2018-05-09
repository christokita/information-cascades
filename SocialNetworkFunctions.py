#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Dec  9 11:31:35 2017

@author: ChrisTokita

Social Network Functions
"""
import numpy as np

# Seed random weighted network 
def seed_social_network(n, low, high):
    # create array of edges
    connections = np.random.uniform(low, high, n * n)
    # turn into array and set diagonal to 0 (no self-connection)
    network = np.split(connections, n)
    network = np.array(network)
    np.fill_diagonal(network, 0)
    return(network)