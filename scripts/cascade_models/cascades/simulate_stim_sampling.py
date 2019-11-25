#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Nov 25 11:43:45 2019

@author: ChrisTokita
"""

import numpy as np
import cascade_models.stimulus as st

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
    