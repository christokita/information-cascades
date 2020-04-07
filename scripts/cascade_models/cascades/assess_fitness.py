#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Nov 25 11:47:27 2019

@author: ChrisTokita
"""

import numpy as np
import pandas as pd 
import cascade_models.cascades as cs

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
        info_values, states, samplers, samplers_active = cs.simulate_stim_sampling(n = n,
                                                                                   gamma = gamma,
                                                                                   psi = psi,
                                                                                   types = types,
                                                                                   thresholds = thresholds)
        # Simulate information cascade 
        states = cs.simulate_cascade(network = network, 
                                     states = states, 
                                     thresholds = thresholds,
                                     samplers = samplers)
        # Collect behavior data
        cascade_stats = cs.get_cascade_stats(t = t,
                                             samplers = samplers,
                                             active_samplers = samplers_active,
                                             states = states, 
                                             types = types, 
                                             stats_df = cascade_stats)
        # Evaluate behavior of individuals relative to threshold and stimuli
        correct_state, behavior_stats = evaluate_fitness_trial_behavior(states = states, 
                                                                        thresholds = thresholds, 
                                                                        information = info_values, 
                                                                        types = types,
                                                                        behavior_df = behavior_stats)
        
    # Return
    return behavior_stats, cascade_stats


def evaluate_fitness_trial_behavior(states, thresholds, information, types, behavior_df):
    # Evaluates the behavior of active individuals in the fitness trial cascade and updates data on correct/incorrect behavior.
    #
    # INPUTS:
    # - states:           array listing the behavioral state of every individual (numpy array).
    # - thresholds:       array of thresholds for each individual (numpy array).
    # - information:      array of stimuli/infromation values (numpy array).
    # - types:            array of type assignments for each individual (numpy array).
    # - behavior_df:      dataframe to store the behavioral performance of individuals (pandas dataframe).
    
    # Assess what all individuals would have done if they had sampled info directly
    correct_behavior = cs.evaluate_behavior(states = states, 
                                             thresholds = thresholds, 
                                             information = information, 
                                             types = types)
    correct_behavior = correct_behavior.reshape((-1, 1))
    
    # Assess error types, if desired by supplyin a behavior_df
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