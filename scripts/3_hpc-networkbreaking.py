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

####################
# Load libraries and packages
####################
import model_networkbreaking as model
import sys

#NOTE: sys.argv[0] is name of script

##########
# Set parameters
##########
n = 200 #number of individuals
k = 6 #mean degree on networks
gamma = float(sys.argv[1]) #correlation between two information sources
psi = 0.1 #proportion of samplers
timesteps = 1000000 #number of rounds simulation will run
rep = int(sys.argv[2]) #replicate ID number

outpath = '/scratch/gpfs/ctokita/information-cascades/network_break/'


##########
# Run model
##########
model.sim_adjusting_network(replicate = rep, 
                            n = n, 
                            k = k, 
                            gamma = gamma, 
                            psi = psi, 
                            timesteps = timesteps,
                            outpath = outpath)

