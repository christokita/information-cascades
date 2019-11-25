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
import cascade_models.stimulus as st
import copy

def simulate_stim_sampling(n, gamma, psi, types, thresholds):
    # Simulates initial sampling of information sources.
    #
    # INPUTS:
    # - n:            number of individuals in the social system (int).
    # - gamma:        correlation between information sources (float). 
    # - psi:          fraction of group that directly sample stimuli each round (float).
    # - types:        array of type assignments for each individual (numpy array).
    # - thresholds:   matrix of thresholds for each individual (numpy array).
    
    # Generate stimuli for the round and have randomly-chosen samplers react
    stims = st.generate_stimuli(correlation = gamma, mean = 0)
    sampler_count = int(round(psi * n))
    samplers = np.random.choice(range(0, n), size = sampler_count, replace = False)
    samplers_type = types[samplers]
    effective_stim = np.dot(samplers_type, np.transpose(stims))
    samplers_react = effective_stim > thresholds[samplers]
    samplers_react = np.ndarray.flatten(samplers_react)
    
    # Set state matrix
    states = np.zeros((n,1))
    samplers_active = samplers[samplers_react]
    states[samplers_active] = 1
    return stims, states, samplers, samplers_active
    

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


def assess_fitness(n, gamma, psi, trial_count, network, thresholds, types):
    # Runs X many cascades with final network to assess information spread and individual fitness
    #
    # INPUTS:
    # - n:             number of individuals in the social system (int).
    # - gamma:         correlation between information sources (float). Inherited from main sim.
    # - psi:           fraction of group that directly sample stimuli each round (float).
    # - trial_count:   number of cascades to run as assessment of fitness (int).
    # - network:       the network connecting individuals (numpy array).
    # - thresholds:    matrix of thresholds for each individual (numpy array).
    # - types:         array of type assignments for each individual (numpy array).
    
    # Dataframes to collect fitness trial data
    cascade_stats = pd.DataFrame(columns = ['t', 'samplers', 'samplers_active', 'sampler_A', 'sampler_B', 'total_active', 'active_A', 'active_B'])
    behavior_stats = pd.DataFrame(np.zeros(shape = (n, 5)),
                                    columns = ['individual', 'true_positive', 'false_negative', 'true_negative', 'false_positive'])
    behavior_stats['individual'] = np.arange(n)
    
    # Run trials
    for t in np.arange(trial_count):
        # Initial information sampling
        stims, states, samplers, samplers_active = simulate_stim_sampling(n = n,
                                                                         gamma = gamma,
                                                                         psi = psi,
                                                                         types = types,
                                                                         thresholds = thresholds)
        # Simulate information cascade 
        states = simulate_cascade(network = network, 
                                  states = states, 
                                  thresholds = thresholds)
        # Collect behavior data
        cascade_stats = get_cascade_stats(t = t,
                                         samplers = samplers,
                                         active_samplers = samplers_active,
                                         states = states, 
                                         types = types, 
                                         stats_df = cascade_stats)
        # Evaluate behavior of individuals relative to threshold and stimuli
        correct_state, behavior_stats = evaluate_behavior(states = states, 
                                                          thresholds = thresholds, 
                                                          stimuli = stims, 
                                                          types = types,
                                                          behavior_df = behavior_stats)
    
    # Return
    return behavior_stats, cascade_stats