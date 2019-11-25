#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Nov 25 11:53:09 2019

@author: ChrisTokita
"""

import numpy as np

def seed_thresholds(n, lower, upper):
    # Generates thresholds for each individual.
    #
    # INPUTS:
    # - n:       the number of individuals in the social system (int).
    # - lower:   lower bound for threshold values (float).
    # - upper:   upper bound for threshold values (float).
    
    thresholds = np.random.uniform(size = n, low = lower, high = upper)
    while sum(thresholds == 0) > 0:  # Python uses a open-close range so make sure no values equal 0
        zero_vals = np.where(thresholds == 0)[0]
        for zero_val in zero_vals:
            thresholds[zero_val] = np.random.uniform(size = 1, low = lower, high = upper)
    thresholds = np.reshape(thresholds, (n, 1)) # Make into desired shape for use in simulations
    return thresholds