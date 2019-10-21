#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Dec  9 17:59:20 2017

@author: ChrisTokita

DESCRIPTION:
Cascade Functions
"""

import numpy as np
import pandas as pd 
import copy
    

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
        
        
def evaluate_behavior(states, thresholds, stimuli, types, behavior_df):
    # Evaluates the behavior of active individuals in the cascade and updates data on correct/incorrect behavior.
    #
    # INPUTS:
    # - states:       array listing the behavioral state of every individual (numpy array).
    # - thresholds:   array of thresholds for each individual (numpy array).
    # - stimuli:      array of stimuli/infromation values (numpy array).
    # - types:        array of type assignments for each individual (numpy array).
    # - behavior_df:  dataframe to store the behavioral performance of individuals (pandas dataframe).
    
    # Assess what all individuals would have done if they had sampled info directly
    true_stim = np.dot(types, np.transpose(stimuli))
    correct_behavior = true_stim > thresholds
    
    # Assess error types
    true_positive = (states == 1) & correct_behavior #did behavior when they should have
    true_negative = (states == 0) & ~correct_behavior  #did NOT do behavior when they should NOT have
    false_positive = (states == 1) & ~correct_behavior  #did behavior when they should NOT have
    false_negative = (states == 0) & correct_behavior  #did NOT do behavior when they should have
    
    # Update behavior tracking data
    behavior_df['true_positive'] = behavior_df['true_positive'] + np.ndarray.flatten(true_positive)
    behavior_df['true_negative'] = behavior_df['true_negative'] + np.ndarray.flatten(true_negative)
    behavior_df['false_positive'] = behavior_df['false_positive'] + np.ndarray.flatten(false_positive)
    behavior_df['false_negative'] = behavior_df['false_negative'] + np.ndarray.flatten(false_negative)
    correct_behavior = np.ndarray.flatten(correct_behavior)
    return correct_behavior, behavior_df


def get_cascade_stats(t, samplers, active_samplers, states, types, stats_df):
    # Captures the relevant statistics about cascades for use:
    # (1) Cascade size over the first X time steps and last X time steps
    # (2) Cascade bias over the first X time steps and last X time steps
    #
    # INPUTS:
    # - t:                 time step (int).
    # - samplers:          array of original samplers of information that round (numpy array).
    # - active_samplers:   array of samplers who became active upon sampling info (numpy array).
    # - states:            array listing the behavioral state of every individual (numpy array).
    # - types:             array of type assignments for each individual (numpy array).
    # - stats_df:          data frame for storing the statistics (numpy array).
    
    total_active = np.sum(states)
    samplers_A = np.sum(types[active_samplers][:,0])
    samplers_B = np.sum(types[active_samplers][:,1])
    active_A = np.sum(np.ndarray.flatten(states) * types[:,0])
    active_B = np.sum(np.ndarray.flatten(states) * types[:,1])
    column_names = stats_df.columns
    cascade_stats = pd.DataFrame([[t,
                                  len(samplers),
                                  len(active_samplers), 
                                  int(samplers_A),
                                  int(samplers_B),
                                  int(total_active),
                                  int(active_A), 
                                  int(active_B)]],
                                columns = column_names)
    stats_df = stats_df.append(cascade_stats, ignore_index = True)
    return stats_df