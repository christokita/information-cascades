#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Dec  9 12:42:29 2017

@author: ChrisTokita

DESCRIPTION:
Script to run network-breaking cascade model on local machine in parallel
(single parameter combo, numerous replicates) 
"""

####################
# Load libraries and packages
####################
import model_networkbreaking as model
import multiprocessing as mp
import numpy as np
import sys

#NOTE: sys.argv[0] is name of script

##########
# Set parameters
##########
n = 200 #number of individuals
k = 6 #mean degree on networks
gamma = 0 #correlation between two information sources
psi = 0.1 #proportion of samplers
timesteps = 1000000 #number of rounds simulation will run
reps = 8 #number of replicates

outpath = '../data_sim/network_break/'


##########
# Run model
##########
# Get CPU count and set pool
cpus = mp.cpu_count()
pool = mp.Pool(cpus)

# loop through reps
for rep in np.arange(reps):
    # Set up iterable parameters for passing to starmap_asyn
    reps_array = np.arange(reps)
    n_array = [n] * len(reps_array)
    k_array = [k] * len(reps_array)
    gamma_array = [gamma] * len(reps_array)
    psi_array = [psi] * len(reps_array)
    timesteps_array = [timesteps] * len(reps_array)
    outpath_array = [outpath] * len(reps_array)
    
    # Run
    out = pool.starmap_async(model.sim_adjusting_network, 
                            zip(reps_array, 
                                n_array, 
                                k_array, 
                                gamma_array, 
                                psi_array, 
                                timesteps_array,
                                outpath_array))

# Close and join
pool.close()
pool.join()


