#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Nov 25 11:44:29 2019

@author: ChrisTokita
"""

import numpy as np
import copy

def simulate_cascade(network, states, thresholds):
    # Simulates a cascade given a network and a intial set of active nodes.
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
    