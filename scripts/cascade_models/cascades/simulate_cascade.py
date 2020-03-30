#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Nov 25 11:44:29 2019

@author: ChrisTokita
"""

import numpy as np
import copy

def simulate_cascade(network, states, thresholds, samplers):
    # Simulates a cascade given a network and a intial set of active nodes.
    # We assume original info samplers who did not become active will not participate in the subsequent cascade.
    #
    # INPUTS:
    # - network:      the network connecting individuals (numpy array).
    # - states:       array listing the behavioral state of every individual (numpy array).
    # - thresholds:   matrix of thresholds for each individual (numpy array).
    # - samplers:     list of samplers that originally tuned into information sources (numpy array).
    
    # Determine activity state of information samplers.
    # This prevents samplers from later being swept up in a cascade.
    sampler_states = states[samplers]
    
    
    # Allow cacade to play out.
    cascade_happening = True
    while cascade_happening: 
        
        # Individual assess social information relative to thresholds
        neighbor_state = np.dot(network, states)
        degree = np.sum(network, axis = 1, keepdims = True)
        social_stim = neighbor_state / degree
        social_stim[np.isnan(social_stim)] = 0 #replace nan values (individuals with no links) with zero social stim
        turn_on = social_stim > thresholds
        
        # Update behavior, making sure samplers remain in original state (i.e., 0 remains 0)
        states_last = copy.deepcopy(states)
        states[turn_on] = 1
        states[samplers] = sampler_states
        
        # Stop once cascade reaches stable state
        if np.array_equal(states, states_last):
            cascade_happening = False
            
    # Return post-cascade behavioral states
    return states
        
def simulate_cascade_old(network, states, thresholds):
    # Simulates a cascade given a network and a intial set of active nodes.
    # Former method in which samplers can later become active
    #
    # INPUTS:
    # - network:      the network connecting individuals (numpy array).
    # - states:       array listing the behavioral state of every individual (numpy array).
    # - thresholds:   matrix of thresholds for each individual (numpy array).
    
    for step in range(1000000): # High number of steps to allow casacde to reach equilibrium
        
        # Weight neighbor info
        neighbor_state = np.dot(network, states)
        degree = np.sum(network, axis = 1, keepdims = True)
        social_stim = neighbor_state / degree
        
        # Threshold calculation
        turn_on = social_stim > thresholds
        
        # Update
        states_last = copy.deepcopy(states)
        states[turn_on] = 1
        
        # Break if it reaches stable state
        if np.array_equal(states, states_last):
            
            # Stop cascade
            return states
            break
    