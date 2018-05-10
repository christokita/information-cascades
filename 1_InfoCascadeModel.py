#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Dec  9 12:42:29 2017

@author: ChrisTokita

 Script to try out information cascaeds on networks
"""

import numpy as np
from SocialNetworkFunctions import *
from ThresholdFunctions import *
from StimulusFunctions import *
import copy

##########
# Set parameters
##########
n = 1000 #number of individuals
low = -0.05 #lowerbound for interaction strength
high = 0.05 #upperbound for interaction strength
mu = 0 #mean for thresholds
sigma = 1 #relative standard deviation for thresholds
gamma = -1 # correlation between two information sources
rounds = 10 #number of rounds simulation will run


##########
# Seed initial conditions
##########
# Seed individual's thresholds
thresh_mat = seed_thresholds(n = n, mean = mu, sd = sigma, low = 0, high = 1000)

# Assign type
type_mat = assign_type(n = n)

# Set up social network
adjacency = seed_social_network(n, low, high)


##########
# Run simulation
##########
for round in range(rounds):
    # Generate stimuli for the round
    stim_sources = generate_stimuli(correlation = gamma, mean = mu)
    # Choose random individual to sample stimulus
    sampler_individual = np.random.choice(range(0, n), size = 1)
    # Get individual's type and therefore select correct stimulus
    sampler_individual_type = type_mat[sampler_individual]
    effective_stim = np.dot(sampler_individual_type, np.transpose(stim_sources))
    # Assess with response threshold
    sampler_reaction = response_threshold(stimulus = effective_stim, 
                                        threshold = thresh_mat[sampler_individual])
    # If action allow cascade
    if sampler_reaction == 1:
        print("CASCADE!")
        # Start action state matrix
        state_mat = np.zeros((n, 1))
        state_mat[sampler_individual, 0] = 1
        state_mat_sum  = copy.copy(state_mat)
        # simulate cascade 
        for t in range(1000000):
            # Weight neighbor info
            neighbor_state = np.dot(adjacency, state_mat)
            # Threshold calculation
            turn_on = neighbor_state > thresh_mat
            turn_off = neighbor_state < thresh_mat
            # Update
            state_mat_last = copy.copy(state_mat)
            state_mat[turn_on] = 1
            #state_mat[turn_off] = 0
            state_mat_sum = state_mat + state_mat_sum
            # Break if it reaches stable state
            if np.array_equal(state_mat, state_mat_last) == True:
                break
        # Evaluate stable state vs actual threshold
        true_stim = np.dot(type_mat, np.transpose(stim_sources))
        correct_state = true_stim > thresh_mat
        correct_state = correct_state.astype(int)
        eval_response = state_mat == correct_state
        
        
            



