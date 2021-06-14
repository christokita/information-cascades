#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Dec  9 12:42:29 2017

@author: ChrisTokita

DESCRIPTION:
Script to run fitness trials on a high-performance computing cluster.
(can be swept across parameter, numerous replicates) 

NOTE: This is for the threshold-adjusting addition of the model in our supplemental simulation for manuscript revision. Place in main /scripts folder before running.

This script depends on a slurm script to call this script.
"""

####################
# Load libraries and packages
####################
import sys 
# sys.path.append('../../') #add scripts folder so we can import our cacades_model module
# sys.path.insert(1, '/home/ctokita/information-cascades/scripts/')

import numpy as np
import cascade_models.cascades as cs
import sys
import os

#NOTE: sys.argv[0] is name of script

##########
# Set parameters
##########
# Set path to directory containing simulation data of interest (and where fitness data will be saved)
directory = '/scratch/gpfs/ctokita/information-cascades/network_break/__suppl_sims/threshold_adjustment/'

# Set parameters for fitness trials
fit_trial_length = 10000
psi = 0.1
gamma_trial_value = None #if we want to test all networks under same gamma value (instead of gamma of model simulation)
trial_tags = "" #leave empty unless you are manually setting gamma_trial_value to a 'highcorr' or 'lowcorr' info ecosystem (lowcorr = -0.9; highcorr = 0.9)

# Prep trial tags
if len(trial_tags) > 0:
    trial_tags = trial_tags + "_"

# Get gamma value and replicate number for this core to test from slurm script
gamma = float(sys.argv[1]) #correlation between two information sources
rep = int(sys.argv[2]) #replicate ID number

# If we don't have a preset gamma value, let the fitness trial gamma be the same as the model simulation.
if gamma_trial_value is None:
    gamma_trial_value = gamma

##########
# Run fitness trial
##########
# Check if this gamma exists in the data (some runs will not use as many gamma values)
sn_dir_exists = os.path.exists(directory + 'social_network_data/gamma' + str(gamma))
thresh_dir_exists = os.path.exists(directory + 'thresh_data/gamma' + str(gamma))
type_dir_exists = os.path.exists(directory + 'type_data/gamma' + str(gamma))
if sn_dir_exists + thresh_dir_exists + type_dir_exists != 3:
    sys.exit(0)
    
# Create fitness data directory
if not os.path.exists(directory + "fitness_data/"):
            os.makedirs(directory + "fitness_data/")

# Get social network, thresholds, and type data.
initial_sn = np.load(directory + 'social_network_data/gamma' + str(gamma) + '/sn_initial_rep' + str(rep).zfill(2) + '.npy')
final_sn = np.load(directory + 'social_network_data/gamma' + str(gamma) + '/sn_final_rep' + str(rep).zfill(2) + '.npy')
initial_thresholds = np.load(directory + 'thresh_data/gamma' + str(gamma) + '/thresh_initial_rep' + str(rep).zfill(2) + '.npy')
final_thresholds = np.load(directory + 'thresh_data/gamma' + str(gamma) + '/thresh_rep' + str(rep).zfill(2) + '.npy')
types = np.load(directory + 'type_data/gamma' + str(gamma) + '/type_rep' + str(rep).zfill(2) + '.npy') 

# Pre-casacde transformation fitness assessment
pre_behavior, pre_cascades = cs.assess_fitness(gamma = gamma_trial_value, 
                                               psi = psi, 
                                               trial_count = fit_trial_length, 
                                               network = initial_sn, 
                                               thresholds = initial_thresholds, 
                                               types = types,
                                               trial = "pre")

# Post-casacde transformation fitness assessment
post_behavior, post_cascades = cs.assess_fitness(gamma = gamma_trial_value, 
                                                 psi = psi, 
                                                 trial_count = fit_trial_length, 
                                                 network = final_sn, 
                                                 thresholds = final_thresholds, 
                                                 types = types,
                                                 trial = "post")

# Create directory for this gamma
if not os.path.exists(directory + "fitness_data/" + trial_tags + "gamma" + str(gamma) + "/"): 
        os.makedirs(directory + "fitness_data/" + trial_tags + "gamma" + str(gamma) + "/")
        
# Save
pre_behavior.to_pickle(directory + "fitness_data/" + trial_tags + "gamma" + str(gamma) + "/pre_behavior_rep" + str(rep).zfill(2) + ".pkl")
pre_cascades.to_pickle(directory + "fitness_data/" + trial_tags + "gamma" + str(gamma) + "/pre_cascades_rep" + str(rep).zfill(2) + ".pkl")
post_behavior.to_pickle(directory + "fitness_data/" + trial_tags + "gamma" + str(gamma) + "/post_behavior_rep" + str(rep).zfill(2) + ".pkl")
post_cascades.to_pickle(directory + "fitness_data/" + trial_tags + "gamma" + str(gamma) + "/post_cascades_rep" + str(rep).zfill(2) + ".pkl")