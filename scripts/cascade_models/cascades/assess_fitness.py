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
        stims, states, samplers, samplers_active = cs.simulate_stim_sampling(n = n,
                                                                             gamma = gamma,
                                                                             psi = psi,
                                                                             types = types,
                                                                             thresholds = thresholds)
        # Simulate information cascade 
        states = cs.simulate_cascade(network = network, 
                                      states = states, 
                                      thresholds = thresholds)
        # Collect behavior data
        cascade_stats = cs.get_cascade_stats(t = t,
                                             samplers = samplers,
                                             active_samplers = samplers_active,
                                             states = states, 
                                             types = types, 
                                             stats_df = cascade_stats)
        # Evaluate behavior of individuals relative to threshold and stimuli
        correct_state, behavior_stats = cs.evaluate_behavior(states = states, 
                                                              thresholds = thresholds, 
                                                              stimuli = stims, 
                                                              types = types,
                                                              behavior_df = behavior_stats)
        
    # Return
    return behavior_stats, cascade_stats