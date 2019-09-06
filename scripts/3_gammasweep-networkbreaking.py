
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Dec  9 12:42:29 2017

@author: ChrisTokita

DESCRIPTION:
Script to run network-breaking cascade model in parallel
(sweep across parameter value) 
"""

####################
# Load libraryies and packages
####################
import numpy as np
import pandas as pd
from util_scripts.socialnetworkfunctions import *
from util_scripts.thresholdfunctions import *
from util_scripts.stimulusfunctions import *
import multiprocessing as mp 
import copy
import sys


####################
# Set parameters
####################
# Import variables from bash script to allow cleaner parameter sweeps
gamma_low = float(sys.argv[1]) #sys.argv[0] is name of script
gamma_high  = float(sys.argv[2])
gamma_step  = float(sys.argv[3])

# Normal variables
n = 200 #number of individuals
k = 5 #mean degree on networks
gammas = np.round(np.arange(gamma_low, gamma_high + gamma_step/10, gamma_step), 3) #correlation between two information sources
psi = 0.1 #proportion of samplers
p = 0.005 # probability selected individual forms new connection
timesteps = 100000 #number of rounds simulation will run
reps = 100 #number of replicate simulations

#gammas = np.delete(gammas, np.where(gammas == -0.5))

####################
# Define simulation function
####################
def sim_adjusting_network(replicate, n, k, gamma, psi, p, timesteps) :
    
    ##### Seed initial conditions #####
    # Set overall seed
    np.random.seed((replicate + 1) * gamma * 323)
    # Seed individual's thresholds
    thresh_mat = seed_thresholds(n = n, lower = 0, upper = 1)
    # Assign type
    type_mat = assign_type(n = n)
    # Set up social network
    adjacency = seed_social_network(n, k)
    adjacency_initial = copy.copy(adjacency)
    # Sampler number
    psi_num = int(round(psi*n))
    # Cascade size data
    cascade_size = np.empty((0,8), dtype = int)
    
    ##### Run simulation #####
    for t in range(timesteps):
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
                # Stop cascade
                break
        # Get cascade data
        total_active = np.sum(state_mat)
        samplers_A = np.sum(type_mat[samplers_active][:,0])
        samplers_B = np.sum(type_mat[samplers_active][:,1])
        active_A = np.sum(np.ndarray.flatten(state_mat) * type_mat[:,0])
        active_B = np.sum(np.ndarray.flatten(state_mat) * type_mat[:,1])
        cascade_stats = np.array([t, 
                                  len(samplers),
                                  len(samplers_active), 
                                  int(samplers_A),
                                  int(samplers_B),
                                  int(total_active),
                                  int(active_A), 
                                  int(active_B)])
        cascade_size = np.vstack([cascade_size, cascade_stats])
        # Evaluate behavior (technically for all individuals, but functionally for only actives)
        actives = np.where(state_mat == 1)[0]
        true_stim = np.dot(type_mat, np.transpose(stim_sources))
        correct_state = true_stim > thresh_mat
        correct_state = np.ndarray.flatten(correct_state)
        # Randomly select one individual and if incorrect, break tie with one incorrect neighbor
        breaker_active = np.random.choice(actives, size = 1)
        breaker_correct = correct_state[breaker_active]
        if not correct_state[breaker_active]:
             # Assess behavior of interaction partners of focal individual
            breaker_neighbors = np.squeeze(adjacency[breaker_active,:])
            neighbor_behavior = breaker_neighbors * np.ndarray.flatten(state_mat) 
            perceived_incorrect = np.where(neighbor_behavior == 1)[0]
            # Break ties with one randomly-selected "incorrect" neighbor
            break_tie = np.random.choice(perceived_incorrect, size = 1, replace = False)
            adjacency[breaker_active, break_tie] = 0
        # Randomly select one individual to form new tie
        former_individual = np.random.choice(range(0, n), size = 1)
        form_connection = np.random.choice((True, False), p = (p, 1-p))
        if form_connection == True:
            # Form new connection
            former_neighbors = np.squeeze(adjacency[former_individual,:])
            potential_ties = np.where(former_neighbors == 0)[0]
            potential_ties = np.delete(potential_ties, np.where(potential_ties == former_individual)) #prevent self-loop
            new_tie = np.random.choice(potential_ties, size = 1, replace = False)
            adjacency[former_individual, new_tie] = 1
                    
    ##### Return data #####
    return(adjacency, adjacency_initial, type_mat, thresh_mat, cascade_size)

####################
# Sweep parameter in parallel in parallel
####################
if __name__=='__main__':
    # Sweep gamma values
    for gamma in gammas:
            
        # Get CPU count and set pool
        cpus = mp.cpu_count()
        pool = mp.Pool(cpus)
        
        # Set up iterable parameters for passing to starmap_asyn
        reps_array = np.arange(reps)
        n_array = [n] * len(reps_array)
        k_array = [k] * len(reps_array)
        gamma_array = [gamma] * len(reps_array)
        psi_array = [psi] * len(reps_array)
        p_array = [p] * len(reps_array)
        timesteps_array = [timesteps] * len(reps_array)
        
        # Run
        parallel_results = pool.starmap_async(sim_adjusting_network, 
                                             zip(reps_array, n_array, k_array, gamma_array, psi_array, timesteps_array))
        
        # Get data
        parallel_results = parallel_results.get()
        adj_matrices = [r[0] for r in parallel_results]
        adj_matrices_initial = [r[1] for r in parallel_results]
        type_matrices = [r[2] for r in parallel_results]
        thresh_matrices = [r[3] for r in parallel_results]
        cascade_stats =[r[4] for r in parallel_results]
        cascade_headers = [np.array(['t', 'samplers', 'samplers_active', 'sampler_A', 'sampler_B', 'total_active', 'active_A', 'active_B'])]
        cascade_stats = cascade_headers + cascade_stats
        
        # Close and join
        pool.close()
        pool.join()
          
        # Save files
        storage_path = "/scratch/gpfs/ctokita/InformationCascades/network_adjust/data/"
        run_info = "n" + str(n) + "_gamma" + str(gamma)
        np.save(storage_path + "social_network_data/" + run_info + ".npy", adj_matrices)
        np.save(storage_path + "social_network_data/" + run_info + "_initial.npy", adj_matrices_initial)
        np.save(storage_path + "type_data/" + run_info + ".npy", type_matrices)
        np.save(storage_path + "thresh_data/" + run_info + ".npy", thresh_matrices)
        np.save(storage_path + "cascade_data/" + run_info + ".npy", cascade_stats)


