
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
import pandas as pd
import util_scripts.socialnetworkfunctions as sn
import util_scripts.thresholdfunctions as th
import util_scripts.stimulusfunctions as st
import util_scripts.cascadefunctions as cs
import copy
import os

# Supress error warnings (not an issue for this script)
np.seterr(divide='ignore', invalid='ignore')

####################
# Define simulation function
####################

def sim_adjusting_network(replicate, n, k, gamma, psi, p, timesteps, outpath) :
    # Simulates a single replicate simulation of the network-breaking information cascade model. 
    #
    # INPUTS:
    # - replicate:   id number of replicate (int or float).
    # - n:           number of individuals in social system (int). n > 0.
    # - k:           mean out-degree of initial social network (int). k > 0.
    # - gamma:       correlation between information sources (float). gamma = [-1, 1].
    # - psi:         prop. of individuals sampling info source every time step (float). psi = (0, 1].
    # - p:           probability that randomly selected individual forms a new connection (float). p = [0, 1].
    # - timesteps:   length of simulation (int).
    # - outpath:     path to directory where output folders and files will be created (str). 
        
    ########## Seed initial conditions ##########
    # Set overall seed
    seed = int( (replicate + 1 + gamma) * 323 )
    np.random.seed(seed)
    # Seed individual's thresholds
    thresh_mat = th.seed_thresholds(n = n, lower = 0, upper = 1)
    # Assign type
    type_mat = th.assign_type(n = n)
    # Set up social network
    adjacency = sn.seed_social_network(n, k)
    adjacency_initial = copy.deepcopy(adjacency)
    # Sampler number
    psi_num = int(round(psi*n))
    # Cascade size data
    cascade_size = pd.DataFrame(columns = ['t', 'samplers', 'samplers_active', 'sampler_A', 'sampler_B', 'total_active', 'active_A', 'active_B'])
    # Cascade behavior data (correct/incorrect behavior)
    behavior_data = pd.DataFrame(np.zeros(shape = (n, 5)),
                                          columns = ['individual', 'true_positive', 'false_negative', 'true_negative', 'false_positive'])
    behavior_data['individual'] = np.arange(n)
    
    ########## Run simulation ##########
    for t in range(timesteps):
        # Generate stimuli for the round
        stim_sources = st.generate_stimuli(correlation = gamma, mean = 0)
        # Choose information samplers
        samplers = np.random.choice(range(0, n), size = psi_num, replace = False)
        # Get infromation samplers' type and  select correct stimuli
        samplers_type = type_mat[samplers]
        effective_stim = np.dot(samplers_type, np.transpose(stim_sources))
        # Assess stimuli
        samplers_react = effective_stim > thresh_mat[samplers]
        samplers_react = np.ndarray.flatten(samplers_react)
        # Set state matrix
        state_mat = np.zeros((n,1))
        samplers_active = samplers[samplers_react]
        state_mat[samplers_active] = 1
        # simulate cascade 
        state_mat = cs.simulate_cascade(network = adjacency, 
                                        states = state_mat, 
                                        thresholds = thresh_mat)
        # Get cascade data for beginning and end of simulation
        if (t < 5000 or t >= timesteps - 5000):
            cascade_size = cs.get_cascade_stats(t = t,
                                                samplers = samplers,
                                                active_samplers = samplers_active,
                                                states = state_mat, 
                                                types = type_mat, 
                                                stats_df = cascade_size)
        # Evaluate behavior of individuals relative to threshold and stimuli
        correct_state, behavior_data = cs.evaluate_behavior(states = state_mat, 
                                                            thresholds = thresh_mat, 
                                                            stimuli = stim_sources, 
                                                            types = type_mat,
                                                            behavior_df = behavior_data)
        # Randomly select one individual and if incorrect, break tie with one incorrect neighbor
        adjacency = break_tie(network = adjacency,
                              states = state_mat,
                              correct_behavior = correct_state)
        # Randomly select one individual to form new tie
        adjacency = make_tie(network = adjacency, 
                             connect_prob = p)
    
    ########## Save files ##########
    # Turn cascade data into df for easy use
    headers = ['t', 'samplers', 'samplers_active', 'sampler_A', 'sampler_B', 'total_active', 'active_A', 'active_B']
    cascade_df = pd.DataFrame(cascade_size, columns = headers)
    cascade_df['replicate'] = replicate
    # Create output folder
    output_name = "n" + str(n) + "_gamma" + str(gamma)
    data_dirs = ['cascade_data', 'social_network_data', 'thresh_data', 'type_data']
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
    rep_label = str(replicate)
    rep_label = rep_label.zfill(2)
    cascade_df.to_pickle(output_dirs[0] + "cascade_rep" + rep_label + ".pkl")
    np.save(output_dirs[1] + "sn_rep" + rep_label + ".npy", adjacency)
    np.save(output_dirs[1] + "sn_initial_rep" + rep_label + ".npy", adjacency_initial)
    np.save(output_dirs[2] + "thresh_rep" + rep_label + ".npy", thresh_mat)
    np.save(output_dirs[3] + "type_rep" + rep_label + ".npy", type_mat)
    
####################
# Define model-specific functions
####################
def break_tie(network, states, correct_behavior):
    # Randomly selects individual and breaks tie with active neighbor iff selected invidual is incorrect.
    #
    # INPUTS:
    # - network:      the network connecting individuals (numpy array).
    # - states:       matrix listing the behavioral state of every individual (numpy array).
    # - correct_behavior:   array indicating whether each individual behaved correctly (numpy array).
    
    actives = np.where(states == 1)[0]
    if sum(actives) > 0: #error catch when no individual are active
        breaker_active = np.random.choice(actives, size = 1)
        breaker_correct = correct_behavior[breaker_active]
        if not breaker_correct:
             # Assess behavior of interaction partners of focal individual
            breaker_neighbors = np.squeeze(network[breaker_active,:])
            neighbor_behavior = breaker_neighbors * np.ndarray.flatten(states) 
            perceived_incorrect = np.where(neighbor_behavior == 1)[0]
            # Break ties with one randomly-selected "incorrect" neighbor
            break_tie = np.random.choice(perceived_incorrect, size = 1, replace = False)
            network[breaker_active, break_tie] = 0
    return network
    
def make_tie(network, connect_prob):
    # Randomly selects individual and makes new tie with constant probability.
    #
    # INPUTS:
    # - network:      the network connecting individuals (numpy array).
    # - states:       matrix listing the behavioral state of every individual (numpy array).
    # - stims:         matrix of thresholds for each individual (numpy array).
    # - correct_behavior:   array indicating whether each individual behaved correctly (numpy array).
    
    n = network.shape[0] # Get number of individuals in system
    former_individual = np.random.choice(range(0, n), size = 1)
    form_connection = np.random.choice((True, False), p = (connect_prob, 1-connect_prob))
    if form_connection == True:
        former_neighbors = np.squeeze(network[former_individual,:])
        potential_ties = np.where(former_neighbors == 0)[0]
        potential_ties = np.delete(potential_ties, np.where(potential_ties == former_individual)) # Prevent self-loop
        new_tie = np.random.choice(potential_ties, size = 1, replace = False)
        network[former_individual, new_tie] = 1
    return network