#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Nov 25 11:44:29 2019

@author: ChrisTokita
"""

import numpy as np
import copy

def simulate_cascade(network, states, thresholds, samplers):
    """
    Simulates a cascade given a network and a intial set of active nodes.
    We assume original info samplers who did not become active will not participate in the subsequent cascade.
    
    INPUTS:
    - network:      the network connecting individuals (numpy array).
    - states:       array listing the behavioral state of every individual (numpy array).
    - thresholds:   matrix of thresholds for each individual (numpy array).
    - samplers:     list of samplers that originally tuned into information sources (numpy array).
    """
    
    # Determine activity state of information samplers.
    # This prevents samplers from later being swept up in a cascade.
    sampler_states = states[samplers]
    
    
    # Allow cacade to play out.
    cascade_happening = True
    while cascade_happening: 
        
        # Individual assess social information relative to thresholds
        active_neighbors = np.dot(network, states)
        degree = np.sum(network, axis = 1, keepdims = True)
        social_stim = np.divide(active_neighbors, degree, out = np.zeros_like(active_neighbors), where = degree!=0) #returns zero where divide-by-zero would otherwise happen. (Only replaces zeros in 'out' at specified 'where' locations)
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