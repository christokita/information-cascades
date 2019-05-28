#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Dec  9 12:42:29 2017

@author: ChrisTokita

 Script to try out information cascaeds on networks
"""

import numpy as np
import pandas as pd
from SocialNetworkFunctions import *
from ThresholdFunctions import *
from StimulusFunctions import *
import copy

import matplotlib.pyplot as plt

##########
# Set parameters
##########
n = 500 #number of individuals
low = -1 #lowerbound for interaction strength
high = 1 #upperbound for interaction strength
mu = 0 #mean for thresholds
sigma = 1 #relative standard deviation for thresholds
gamma = 1 #correlation between two information sources
phi = 0.25 #change in value of interactions when indviduals adjust ties
timesteps = 500000 #number of rounds simulation will run


##########
# Seed initial conditions
##########
# Seed individual's thresholds
thresh_mat = seed_thresholds(n = n, mean = mu, sd = sigma, low = 0, high = 1000)

# Assign type
type_mat = assign_type(n = n)

# Set up social network
adjacency = seed_social_network(n, low, high)
adjacency_initial = copy.copy(adjacency)

# Cascade counter
cascade_count = 0

##########
# Run simulation
##########
for t in range(timesteps):
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
        # Printout for progress
        cascade_count = cascade_count + 1
        if cascade_count % 5000 == 0:
            print("CASCADE", cascade_count, "at t =", t)
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
        # Grab incorrect responses and randomly select one
        incorrect_responses = np.where(np.invert(eval_response))[0]
        focal_individual = np.random.choice(incorrect_responses, size = 1)
        # Assess behavior of interaction partners of focal individual
        perceived_incorrect = np.where(state_mat == state_mat[focal_individual])[0] 
        perceived_incorrect = perceived_incorrect[perceived_incorrect != focal_individual] #don't coutn self
        perceived_correct = np.where(state_mat == (1 - state_mat[focal_individual]))[0] 
        # Adjust ties
        adjacency[focal_individual, perceived_incorrect] = adjacency[focal_individual, perceived_incorrect] - phi
        adjacency[focal_individual, perceived_correct] = adjacency[focal_individual, perceived_correct] + phi
  
##########
# Save files
##########
# Convert adjacency matrix to edgelist
edgelist = []
for i in range(0, n):
    for j in range(0, n):
        row = [i, j, adjacency[i, j]]
        edgelist.append(row)
        
edgelist = pd.DataFrame(edgelist, columns = ['Source', 'Target', 'Weight'])
edgelist = edgelist[edgelist.Weight > 0] #keep only positive edges

# make node list
nodelist = pd.DataFrame({'Id': range(0, n),
                         'Threshold': thresh_mat[:,0],
                         'Type': type_mat[:,1]})
       
# Save
dir_path = 'output/social_networks/'
edge_file_name = dir_path + 'Edge-Gamma_' + str(gamma) + '.csv'
node_file_name = dir_path + 'Node-Gamma_' + str(gamma) + '.csv'
edgelist.to_csv(edge_file_name, index = False, header = True, sep = ",")
nodelist.to_csv(node_file_name, index = False, header = True, sep = ",")
      
##########
# Assess output
##########       
# Chance in adjacency
adjacency_delta = adjacency - adjacency_initial

plt.hist(np.ndarray.flatten(adjacency_delta))

plt.hist(np.ndarray.flatten(adjacency_initial))
plt.hist(np.ndarray.flatten(adjacency))




