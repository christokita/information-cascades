
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Dec  9 12:42:29 2017

@author: ChrisTokita

DESCRIPTION:
Function to run network-breaking cascade model
(one replicate simulation given certain parameter combination)
"""

####################
# Load libraries and packages
####################
import numpy as np
import cascade_models.social_networks as sn
import cascade_models.thresholds as th
import cascade_models.cascades as cs
import copy
import os


####################
# Define simulation function
####################

def sim_adjusting_network(replicate, n, k, gamma, psi, timesteps, outpath, network_type = "random") :
    """
    Simulates a single replicate simulation of the network-breaking information cascade model. 
    
    INPUTS:
    - replicate:      id number of replicate (int or float).
    - n:              number of individuals in social system (int). n > 0.
    - k:              mean out-degree of initial social network (int). k > 0.
    - gamma:          correlation between information sources (float). gamma = [-1, 1].
    - psi:            prop. of individuals sampling info source every time step (float). psi = (0, 1].
    - timesteps:      length of simulation (int).
    - outpath:        path to directory where output folders and files will be created (str). 
    - network_type:   type of network to intially generate. Default is random but accepts ["random", "scalefree"] (str).
    """    
    
    ########## Seed initial conditions ##########
    # Set overall seed
    seed = int( (replicate + 1 + gamma) * 323 )
    np.random.seed(seed)
    # Seed individual's thresholds
    thresh_mat = th.seed_thresholds(n = n, lower = 0, upper = 1)
    # Assign type
    type_mat = th.assign_type(n = n)
    # Set up social network
    adjacency = sn.seed_social_network(n, k, network_type = network_type)
    adjacency_initial = copy.deepcopy(adjacency)
    
    ########## Run simulation ##########
    for t in range(timesteps):
        # Initial information sampling
        info_values, state_mat, samplers, samplers_active = cs.simulate_stim_sampling(n = n,
                                                                                      gamma = gamma,
                                                                                      psi = psi,
                                                                                      types = type_mat,
                                                                                      thresholds = thresh_mat)
        # Simulate information cascade 
        state_mat = cs.simulate_cascade(network = adjacency, 
                                        states = state_mat, 
                                        thresholds = thresh_mat,
                                        samplers = samplers)
        # Evaluate behavior of individuals relative to threshold and stimuli
        correct_state = cs.evaluate_behavior(states = state_mat, 
                                             thresholds = thresh_mat, 
                                             information = info_values, 
                                             types = type_mat)
        # Adjust social network ties
        adjacency = adjust_tie(network = adjacency,
                               states = state_mat,
                               correct_behavior = correct_state)
    
    ########## Save files ##########
    # Create output folder
    output_name = "gamma" + str(gamma)
    data_dirs = ['social_network_data', 'thresh_data', 'type_data']
    data_dirs = [outpath + d + "/" for d in data_dirs]
    output_dirs = [d + output_name +  "/" for d in data_dirs]
    for x in np.arange(len(data_dirs)):
        # Check if directory already exisits. If not, create it.
        if not os.path.exists(data_dirs[x]):
            os.makedirs(data_dirs[x])
        # Check if specific run folder exists
        if not os.path.exists(output_dirs[x]):
            os.makedirs(output_dirs[x])
    # Save files
    rep_label = str(replicate).zfill(2)
    np.save(output_dirs[0] + "sn_final_rep" + rep_label + ".npy", adjacency)
    np.save(output_dirs[0] + "sn_initial_rep" + rep_label + ".npy", adjacency_initial)
    np.save(output_dirs[1] + "thresh_rep" + rep_label + ".npy", thresh_mat)
    np.save(output_dirs[2] + "type_rep" + rep_label + ".npy", type_mat)
    
####################
# Define model-specific functions
####################
def adjust_tie(network, states, correct_behavior):
    """
    Randomly selects active individual and breaks tie if incorrect.
    Another individual randomly forms tie iff a tie is broken in that round.

    INPUTS:
    - network:      the network connecting individuals (numpy array).
    - states:       matrix listing the behavioral state of every individual (numpy array).
    - correct_behavior:   array indicating whether each individual behaved correctly (numpy array).
    """
    
    actives = np.where(states == 1)[0]
    if sum(actives) > 0: #error catch when no individual are active
        individual_active = np.random.choice(actives, size = 1)
        individual_correct = correct_behavior[individual_active]
        individual_neighbors = np.where(network[individual_active,:] == 1)[1]
        
        if not individual_correct:
            
            # Break ties with one randomly-selected "incorrect" neighbor
            perceived_incorrect = [ind for ind in actives if ind in individual_neighbors] #which neighbors are active
            break_tie = np.random.choice(perceived_incorrect, size = 1, replace = False)
            network[individual_active, break_tie] = 0
            network[break_tie, individual_active] = 0 #undirected network, symmetric edges
            
            # Randomly select another individual to form a new tie
            max_connections = network.shape[0] - 1 #can't connect to self
            candidate_individuals = np.where(np.sum(network, axis = 1) != max_connections)[0] #list individuals who are not already connected to everyone
            former_individual = np.random.choice(candidate_individuals, size = 1)
            former_connections = np.squeeze(network[former_individual,:]) #get individual's neighbors
            potential_ties = np.where(former_connections == 0)[0]
            potential_ties = np.delete(potential_ties, np.where(potential_ties == former_individual)) # Prevent self-loop
            new_tie = np.random.choice(potential_ties, size = 1, replace = False)
            network[former_individual, new_tie] = 1
            network[new_tie, former_individual] = 1 #undirected network, symmetric edges
                
    return network