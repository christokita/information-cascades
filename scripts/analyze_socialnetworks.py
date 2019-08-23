#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Aug 20 10:02:31 2019

@author: ChrisTokita

DESCRIPTION:
Script to analyze social network structure produced by simulations
"""

####################
# Load libraryies and packages
####################
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

####################
# Load data
####################
list_networks = np.load('../output/network_adjust/data/social_network_data/n500_gamma-0.5.npy')
list_networks_initial = np.load('../output/network_adjust/data/social_network_data/n500_gamma-0.5_initial.npy')


####################
# Measure assortativity
####################
# Calculate assortativity
g = igraph.Graph.Adjacency(np.ndarray.tolist(adjacency))
g.vs['Type'] = type_mat[:,0]
final_assort = g.assortativity(types1 = g.vs['Type'])