#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Dec  9 12:42:29 2017

@author: ChrisTokita

DESCRIPTION:
Script to run network-breaking cascade model on HPC cluster
(can be swept across parameter, numerous replicates) 

This script depends on a slurm script to call this script and provide certain parameter values,
namely the replicate number (taken from a slurm array) and possibly the gamma value.
"""
from model_networkbreaking import *
import multiprocessing as mp
import sys

#NOTE: sys.argv[0] is name of script

##########
# Set parameters
##########
n = 200 #number of individuals
k = 5 #mean degree on networks
#gamma = sys.argv[1] #correlation between two information sources
gamma = 0 #correlation between two information sources
psi = 0.1 #proportion of samplers
p = 0.005 # probability selected individual forms new connection
timesteps = 1000 #number of rounds simulation will run
reps = 8 #number of replicates

#outpath = '/scratch/gpfs/ctokita/InformationCascades/network_break/'
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
    p_array = [p] * len(reps_array)
    timesteps_array = [timesteps] * len(reps_array)
    outpath_array = [outpath] * len(reps_array)
    
    # Run
    out = pool.starmap_async(sim_adjusting_network, 
                            zip(reps_array, 
                                n_array, 
                                k_array, 
                                gamma_array, 
                                psi_array, 
                                p_array, 
                                timesteps_array,
                                outpath_array))

# Close and join
pool.close()
pool.join()


