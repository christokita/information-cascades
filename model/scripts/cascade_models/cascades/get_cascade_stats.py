#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Nov 25 11:46:23 2019

@author: ChrisTokita
"""
import numpy as np
import pandas as pd 

def get_cascade_stats(t, samplers, active_samplers, states, types, stats_df):
    """
    Captures the relevant statistics about cascades for use:
    (1) Cascade size over the first X time steps and last X time steps
    (2) Cascade bias over the first X time steps and last X time steps
    
    INPUTS:
    - t:                 time step (int).
    - samplers:          array of original samplers of information that round (numpy array).
    - active_samplers:   array of samplers who became active upon sampling info (numpy array).
    - states:            array listing the behavioral state of every individual (numpy array).
    - types:             array of type assignments for each individual (numpy array).
    - stats_df:          data frame for storing the statistics (numpy array).
    """
    
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