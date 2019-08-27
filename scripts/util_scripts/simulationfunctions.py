#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Aug 26 09:58:21 2019

@author: ChrisTokita
"""

import numpy as np
import pandas as pd
from util_scripts.socialnetworkfunctions import *
from util_scripts.thresholdfunctions import *
from util_scripts.stimulusfunctions import *
import multiprocessing as mp 
import copy


# Simulation for network-breaking model
def network_breaking_model(timesteps, threshold_matrix, type_matrix, gamma, sampler_number, adjacency_matrix):
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
        former_neighbors = np.squeeze(adjacency[former_individual,:])
        potential_ties = np.where(former_neighbors == 0)[0]
        potential_ties = np.delete(potential_ties, np.where(potential_ties == former_individual)) #prevent self-loop
        new_tie = np.random.choice(potential_ties, size = 1, replace = False)
        adjacency[former_individual, new_tie] = 1
    # Return
    return(adjacency)