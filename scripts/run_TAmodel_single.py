#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Dec  9 12:42:29 2017

@author: ChrisTokita

DESCRIPTION:
Script to run threshold-adjusting (TA) cascade model on local machine.
(single parameter combo, numerous replicates) 
"""
import model_threshadjusting as model
import numpy as np

##########
# Set parameters
##########
n = 200 #number of individuals
k = 6 #mean degree on networks
gamma = -0.5 #correlation between two information sources
psi = 0.1 #proportion of samplers
phi = 0.01 #amount threhsold decreases if individual is correct in behavior
omega = 0.01 #amount threhsold increases if individual is incorrect in behavior
timesteps = 3 * 1000000 #number of rounds simulation will run
reps = 1 #number of replicate simulations

outpath = '../data_sim/thresh_adjust/'


##########
# Run model
##########
for rep in np.arange(reps):
    model.sim_adjusting_thresholds(replicate = rep,        
                                    n = n, 
                                    k = k,  
                                    gamma = gamma, 
                                    psi = psi, 
                                    phi = phi,
                                    omega = omega,
                                    timesteps = timesteps,
                                    outpath = outpath)


