
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Dec  9 12:42:29 2017

@author: ChrisTokita

DESCRIPTION:
Script to run network-breaking cascade model on local machine
(single parameter combo, single replicate) 
"""

####################
# Load libraryies and packages
####################
import numpy as np
import pandas as pd
from util_scripts.socialnetworkfunctions import *
from util_scripts.thresholdfunctions import *
from util_scripts.stimulusfunctions import *
import copy

import matplotlib.pyplot as plt

####################
# Set parameters
####################
n = 200 #number of individuals
k = 4 #mean degree on networks
gamma = 0.9 #correlation between two information sources
psi = 0.1 #proportion of samplers
timesteps = 500000 #number of rounds simulation will run
p = 0.00001 # probability any individual forms a tie
q = 0.9 # probability incorrect individual breaks tie wtih an incorrect neighbor


####################
# Seed initial conditions
####################
# Seed individual's thresholds
thresh_mat = seed_thresholds(n = n, lower = 0, upper = 1)

# Assign type
type_mat = assign_type(n = n)

# Set up social network
adjacency = seed_social_network(n, k)
adjacency_initial = copy.copy(adjacency)

# Sampler number
psi_num = int(round(psi*n))


####################
# Run simulation
####################
for t in range(timesteps):
    # TESTING: print time step
    if t % 10000 == 0:
        print('Timestep = ' + str(t))
    
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
        # Break if it reaches stable state
        if np.array_equal(state_mat, state_mat_last) == True:
            break
    # Evaluate behavior (technically for all individuals, but functionally for only actives)
    actives = np.where(state_mat == 1)[0]
    true_stim = np.dot(type_mat, np.transpose(stim_sources))
    correct_state = true_stim > thresh_mat
    correct_state = np.ndarray.flatten(correct_state)
    incorrect_active = actives[correct_state[actives] == False]
    # Determine which incorrect individuals will break tie 
    break_connection = np.random.choice((True, False), size = len(incorrect_active), p = (q, 1-q))
    incorrect_active = incorrect_active[break_connection,]
    # Loop through incorrect active individuals and break links probabilistically
    for breaker in incorrect_active:
         # Assess behavior of interaction partners of focal individual
        breaker_neighbors = np.squeeze(adjacency[breaker,:])
        neighbor_behavior = breaker_neighbors * np.ndarray.flatten(state_mat) 
        perceived_incorrect = np.where(neighbor_behavior == 1)[0]
        # Break ties with one randomly-selected "incorrect" neighbor
        break_tie = np.random.choice(perceived_incorrect, size = 1, replace = False)
        adjacency[breaker, break_tie] = 0
    # Individuals probabilistically form ties
    form_connection = np.random.choice((True, False), size = n, p = (p, 1-p))
    former_individual = np.arange(n)[form_connection,]
    for former in former_individual:
        # Form new connection
        former_neighbors = np.squeeze(adjacency[former,:])
        potential_ties = np.where(former_neighbors == 0)[0]
        potential_ties = np.delete(potential_ties, np.where(potential_ties == former)) #prevent self-loop
        new_tie = np.random.choice(potential_ties, size = 1, replace = False)
        adjacency[former, new_tie] = 1

  
####################
# Save files
####################
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
dir_path = '../output/network_adjust/data/social_network_data/'
edge_file_name = dir_path + 'Edge-Gamma_' + str(gamma) + '.csv'
node_file_name = dir_path + 'Node-Gamma_' + str(gamma) + '.csv'
edgelist.to_csv(edge_file_name, index = False, header = True, sep = ",")
nodelist.to_csv(node_file_name, index = False, header = True, sep = ",")
      
####################
# Assess output
####################       
# Chance in adjacency
adjacency_delta = adjacency - adjacency_initial




