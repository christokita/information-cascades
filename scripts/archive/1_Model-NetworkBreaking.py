
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Dec  9 12:42:29 2017

@author: ChrisTokita

 Script to try out information cascaeds on networks
"""

##########
# Load libraryies and packages
##########
import numpy as np
import pandas as pd
from socialnetworkfunctions import *
from thresholdfunctions import *
from stimulusfunctions import *
import copy

import matplotlib.pyplot as plt

##########
# Set parameters
##########
n = 500 #number of individuals
k = 5 #mean degree on networks
gamma = -0.5 #correlation between two information sources
psi = 0.1 #proportion of samplers
timesteps = 500000 #number of rounds simulation will run
#adjust_num = 10000


##########
# Seed initial conditions
##########
# Seed individual's thresholds
thresh_mat = seed_thresholds(n = n, lower = 0, upper = 1)

# Assign type
type_mat = assign_type(n = n)

# Set up social network
adjacency = seed_social_network(n, k)
adjacency_initial = copy.copy(adjacency)

# Sampler number
psi_num = int(round(psi*n))

# Adjust counter
adjust_count = 0

##########
# Run simulation
##########
for t in range(timesteps):
#while adjust_count <= adjust_num:
    # Generate stimuli for the round
    stim_sources = generate_stimuli(correlation = gamma, mean = 0)
    # Choose information samplers
    samplers = np.random.choice(range(0, n), size = psi_num, replace = False)
    # Get infromation samplers' type and  select correct stimuli
    samplers_type = type_mat[samplers]
    effective_stim = np.dot(samplers_type, np.transpose(stim_sources))
    # Assess stimuli
    samplers_react = effective_stim > thresh_mat[samplers]
    samplers_react = np.ndarray.flatten(samplers_react)
    # If no one reacts, do next time step
    if sum(samplers_react) == 0:
        continue
    # Set state matrix
    state_mat = np.zeros((n,1))
    samplers_active = samplers[samplers_react]
    state_mat[samplers_active, 0] = 1
    state_mat_sum  = copy.copy(state_mat)
    # simulate cascade 
    for step in range(1000000):
        # Weight neighbor info
        neighbor_state = np.dot(adjacency, state_mat)
        degree = np.sum(adjacency, axis = 1, keepdims = True)
        social_stim = neighbor_state / degree
        # Threshold calculation
        turn_on = social_stim > thresh_mat
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
    incorrect_actives = actives[~correct_state]
    if len(incorrect_actives) == 0:
        continue
    else:
        # Count number of adjustments so far and print update
        adjust_count = adjust_count + 1
        if adjust_count % 500 == 0:
            print("Network update " + str(adjust_count), " at t=", t)
        # Choose individual to readjust ties
        focal_individual = np.random.choice(incorrect_actives, size = 1)
        # Assess behavior of interaction partners of focal individual
        focal_individual_neighbors = np.squeeze(adjacency[focal_individual,:])
        neighbor_behavior = focal_individual_neighbors * np.ndarray.flatten(state_mat) 
        perceived_incorrect = np.where(neighbor_behavior == 1)[0]
        # Adjust ties
        break_tie = np.random.choice(perceived_incorrect, size = 1, replace = False)
        new_tie = np.where(focal_individual_neighbors == 0)[0]
        new_tie = np.delete(new_tie, np.where(new_tie == focal_individual)) #prevent self-loop
        #new_tie = np.random.choice(new_tie, size = len(perceived_incorrect), replace = False)
        new_tie = np.random.choice(new_tie, size = 1, replace = False)
        adjacency[focal_individual, perceived_incorrect] = 0
        adjacency[focal_individual, new_tie] = 1

    
  
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
dir_path = 'output/network_adjust/social_networks/'
edge_file_name = dir_path + 'Edge-Gamma_' + str(gamma) + '.csv'
node_file_name = dir_path + 'Node-Gamma_' + str(gamma) + '.csv'
edgelist.to_csv(edge_file_name, index = False, header = True, sep = ",")
nodelist.to_csv(node_file_name, index = False, header = True, sep = ",")
      
##########
# Assess output
##########       
# Chance in adjacency
adjacency_delta = adjacency - adjacency_initial




