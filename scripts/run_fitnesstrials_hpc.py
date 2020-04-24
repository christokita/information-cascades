#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Dec  9 12:42:29 2017

@author: ChrisTokita

DESCRIPTION:
Script to run fitness trials on a high-performance computing cluster.
(can be swept across parameter, numerous replicates) 

This script depends on a slurm script to call this script.

[INSERT more description]
"""

####################
# Load libraries and packages
####################
import numpy as np
import cascade_models.cascades as cs
import sys
import os

#NOTE: sys.argv[0] is name of script

##########
# Set parameters
##########
# Set path to directory containing simulation data of interest (and where fitness data will be saved)
directory = '/scratch/gpfs/ctokita/information-cascades/'

# Set parameters for fitness trials
fit_trial_length = 10000
psi = 0.1

# Get gamma value and replicate number for this core to test from slurm script
gamma = float(sys.argv[1]) #correlation between two information sources
rep = int(sys.argv[2]) #replicate ID number

##########
# Run fitness trial
##########
# Create fitness data directory
if not os.path.exists(directory + "fitness_data/"):
            os.makedirs(directory + "fitness_data/")

# Check if this gamma exists in the data (some runs will not use as many gamma values)
sn_dir_exists = os.path.exists(directory + 'social_network_data/gamma' + str(gamma))
thresh_dir_exists = os.path.exists(directory + 'thresh_data/gamma' + str(gamma))
type_dir_exists = os.path.exists(directory + 'type_data/gamma' + str(gamma))
if sn_dir_exists + thresh_dir_exists + type_dir_exists != 3:
    sys.exit(0)

# Get social network, thresholds, and type data.
initial_sn = np.load(directory + 'social_network_data/gamma' + str(gamma) + '/sn_initial_rep' + str(rep).zfill(2) + '.npy')
final_sn = np.load(directory + 'social_network_data/gamma' + str(gamma) + '/sn_final_rep' + str(rep).zfill(2) + '.npy')
thresholds = np.load(directory + 'thresh_data/gamma' + str(gamma) + '/thresh_rep' + str(rep).zfill(2) + '.npy')
types = np.load(directory + 'type_data/gamma' + str(gamma) + '/type_rep' + str(rep).zfill(2) + '.npy') 

# Pre-casacde transformation fitness assessment
pre_behavior, pre_cascades = cs.assess_fitness(gamma = gamma, 
                                               psi = psi, 
                                               trial_count = fit_trial_length, 
                                               network = initial_sn, 
                                               thresholds = thresholds, 
                                               types = types)

# Post-casacde transformation fitness assessment
post_behavior, post_cascades = cs.assess_fitness(gamma = gamma, 
                                                 psi = psi, 
                                                 trial_count = fit_trial_length, 
                                                 network = final_sn, 
                                                 thresholds = thresholds, 
                                                 types = types)

# Create directory for this gamma
if not os.path.exists(directory + "fitness_data/gamma" + str(gamma) + "/"): 
        os.makedirs(directory + "fitness_data/gamma" + str(gamma) + "/")
        
# Save
pre_behavior.to_pickle(directory + "fitness_data/gamma" + str(gamma) + "/pre_behavior_rep" + str(rep).zfill(2) + ".pkl")
pre_cascades.to_pickle(directory + "fitness_data/gamma" + str(gamma) + "/pre_cascades_rep" + str(rep).zfill(2) + ".pkl")
post_behavior.to_pickle(directory + "fitness_data/gamma" + str(gamma) + "/post_behavior_rep" + str(rep).zfill(2) + ".pkl")
post_cascades.to_pickle(directory + "fitness_data/gamma" + str(gamma) + "/post_cascades_rep" + str(rep).zfill(2) + ".pkl")