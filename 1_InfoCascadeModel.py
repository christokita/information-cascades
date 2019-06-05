
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
n = 1000 #number of individuals
k = 5 #mean degree on networks
mu = 0 #mean for thresholds
sigma = 1 # standard deviation for thresholds
gamma = 0 #correlation between two information sources
psi = 0.1 #proportion of samplers
timesteps = 500000 #number of rounds simulation will run


##########
# Seed initial conditions
##########
# Seed individual's thresholds
thresh_mat = seed_thresholds(n = n, mean = mu, sd = sigma)

# Assign type
type_mat = assign_type(n = n)

# Set up social network
adjacency = seed_social_network(n, k)
adjacency_initial = copy.copy(adjacency)

# Sampler number
psi_num = int(round(psi*n))


##########
# Run simulation
##########
for t in range(timesteps):
    # Generate stimuli for the round
    stim_sources = generate_stimuli(correlation = gamma, mean = mu)
    # Choose information samplers
    samplers = np.random.choice(range(0, n), size = psi_num, replace = False)
    # Get infromation samplers' type and  select correct stimuli
    samplers_type = type_mat[samplers]
    effective_stim = np.dot(samplers_type, np.transpose(stim_sources))
    # Assess stimuli
    samplers_react = effective_stim > thresh_mat[samplers]
    samplers_react = np.ndarray.flatten(samplers_react)
    # Set state matrix
    state_mat = np.full((n, 1), -1)
    samplers_active = samplers[samplers_react]
    state_mat[samplers_active, 0] = 1
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
    # Evaluate stable state vs actual threshold for active individuals
    actives = np.where(state_mat == 1)[0]
    true_stim = np.dot(type_mat[actives,:], np.transpose(stim_sources))
    correct_state = true_stim > thresh_mat[actives,:]
    correct_state = np.ndarray.flatten(correct_state)
    # Grab incorrect responses and randomly select one
    incorr_actives = actives[~correct_state]
    focal_individual = np.random.choice(incorr_actives, size = 1)
    # Assess behavior of interaction partners of focal individual
    
    # FIX STARTING HERE
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




