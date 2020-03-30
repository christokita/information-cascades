#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Dec  9 12:42:29 2017

@author: ChrisTokita

DESCRIPTION:
Script to run network-breaking cascade model on local machine
(single parameter combo, numerous replicates) 
"""
import model_networkbreaking as model
import numpy as np

##########
# Set parameters
##########
n = 200 #number of individuals
k = 5 #mean degree on networks
gamma = -0.5 #correlation between two information sources
psi = 0.1 #proportion of samplers
timesteps = 1000000 #number of rounds simulation will run
reps = 1 #number of replicate simulations

outpath = '../data_sim/network_break/'


##########
# Run model
##########
for rep in np.arange(reps):
    model.sim_adjusting_network(replicate = rep, 
                                n = n, 
                                k = k, 
                                gamma = gamma, 
                                psi = psi, 
                                p = p, 
                                timesteps = timesteps,
                                outpath = outpath)


