
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Dec  9 12:42:29 2017

@author: ChrisTokita

DESCRIPTION:
Function to run threshold-adjusting cascade model
(one replicate simulation given certain parameter combination)
"""

####################
# Load libraries and packages
####################
import numpy as np
import pandas as pd
import cascade_models.social_networks as sn
import cascade_models.thresholds as th
import cascade_models.cascades as cs
import copy
import os


####################
# Define simulation function
####################

def sim_adjusting_thresholds(replicate, n, k, gamma, psi, phi, omega, timesteps, outpath, sim_tag, network_type = "random") :
    # Simulates a single replicate simulation of the network-breaking information cascade model. 
    #
    # INPUTS:
    # - replicate:      id number of replicate (int or float).
    # - n:              number of individuals in social system (int). n > 0.
    # - k:              mean out-degree of initial social network (int). k > 0.
    # - gamma:          correlation between information sources (float). gamma = [-1, 1].
    # - psi:            prop. of individuals sampling info source every time step (float). psi = (0, 1].
    # - phi:            amount threhsold changes if individual is correct in behavior (float).
    # - omega:          amount threhsold changes if individual is incorrect in behavior (float).
    # - timesteps:      length of simulation (int).
    # - outpath:        path to directory where output folders and files will be created (str). 
    # - sim_tag:        added infomation to add to file names when saving model output (str).
    # - network_type:   type of network to intially generate. Default is random but accepts ["random", "scalefree"] (str).
        
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
    # Cascade size data
    cascade_size = pd.DataFrame(columns = ['t', 'samplers', 'samplers_active', 'sampler_A', 'sampler_B', 'total_active', 'active_A', 'active_B'])
    # Cascade behavior data (correct/incorrect behavior)
    behavior_data = pd.DataFrame(np.zeros(shape = (n, 5)),
                                          columns = ['individual', 'true_positive', 'false_negative', 'true_negative', 'false_positive'])
    behavior_data['individual'] = np.arange(n)
    
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
                                        thresholds = thresh_mat)
        # Evaluate behavior of individuals relative to threshold and stimuli
        correct_state, behavior_data = cs.evaluate_behavior(states = state_mat, 
                                                            thresholds = thresh_mat, 
                                                            information = info_values, 
                                                            types = type_mat,
                                                            behavior_df = behavior_data)
        # Randomly select one individual and adjust thresholds according to behavior (correct/incorrect)
        thresh_mat = adjust_thresh(thresholds =  thresh_mat,
                                   states = state_mat,
                                   correct_behavior = correct_state,
                                   phi = phi,
                                   omega = omega)
    
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
    np.save(output_dirs[1] + "sn_rep" + rep_label + ".npy", adjacency)
    np.save(output_dirs[1] + "sn_initial_rep" + rep_label + ".npy", adjacency_initial)
    np.save(output_dirs[2] + "thresh_rep" + rep_label + ".npy", thresh_mat)
    np.save(output_dirs[3] + "type_rep" + rep_label + ".npy", type_mat)
    
####################
# Define model-specific functions
####################
def adjust_thresh(thresholds, states, correct_behavior, phi, omega):
    # Randomly selects active individual and adjusts threshold depending on whether their behavior was correct/incorrect.
    #
    # INPUTS:
    # - thresholds:         matrix of thresholds for each individual (numpy array).
    # - states:             matrix listing the behavioral state of every individual (numpy array).
    # - correct_behavior:   array indicating whether each individual behaved correctly (numpy array).
    
    actives = np.where(states == 1)[0]
    if sum(actives) > 0: #error catch when no individual are active
        
        # Select avtive individual and adjust threshold accordingly
        adjuster_active = np.random.choice(actives, size = 1)
        adjuster_correct = correct_behavior[adjuster_active]
        if adjuster_correct:
            thresholds[adjuster_active] -= phi #decrease threshold if correct (positive reinforcement)
        elif not adjuster_correct:
            thresholds[adjuster_active] += omega#decrease threshold if incorrect (negative reinforcement)
            
        # Enforce  threshold boundary [0, 1]
        if thresholds[adjuster_active] > 1:
            thresholds[adjuster_active] = 1
        elif thresholds[adjuster_active] < 0:
            thresholds[adjuster_active] = 0
            
    return thresholds