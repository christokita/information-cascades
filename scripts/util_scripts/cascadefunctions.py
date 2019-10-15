#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Dec  9 17:59:20 2017

@author: ChrisTokita

DESCRIPTION:
Cascade Functions
"""

import numpy as np
import scipy as sp    
    

def simulate_cascade(network, states, thresholds):
    # Simulates a cascade given a network and a intial set of active nodes.
    #
    # INPUTS:
    # - network:      the network connecting individuals (numpy array).
    # - states:       matrix listing the behavioral state of every individual (numpy array).
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
        if np.array_equal(states, states_last) == True:
            
            # Stop cascade
            return states
            break
        
def evaluate_behavior(states, thresholds, stimuli, types):
    # Evaluates the behavior of active individuals in the cascade. 
    #
    # INPUTS:
    # - states:       matrix listing the behavioral state of every individual (numpy array).
    # - thresholds:   matrix of thresholds for each individual (numpy array).
    # - stimuli:      matrix of stimuli/infromation values (numpy array).
    # - types:        matrix of type assignments for each individual (numpy array).
    
    actives = np.where(states == 1)[0]
    true_stim = np.dot(types, np.transpose(stimuli))
    correct = true_stim > thresholds
    correct = np.ndarray.flatten(correct_state)
    return correct