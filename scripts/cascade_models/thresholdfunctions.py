#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Dec  9 15:18:42 2017

@author: ChrisTokita

DESCRIPTION:
Threshold Functions
"""

import numpy as np
from scipy.stats import truncnorm
import matplotlib.pyplot as plt


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


def assign_type(n):
    # Assigns a type randomly to each individual.
    # Each individual has an equal change of getting a given type.
    #
    # INPUTS:
    # - n:       the number of individuals in the social system (int).

    types = []
    for i in range(n):
        ind_type = np.random.choice([1, 0], size = 2, replace = False)
        types.append(ind_type)
    types = np.array(types)
    return types


def response_threshold(stimulus, threshold):
    # Response threshold function dictating the behavioral state of individuals.
    # ** Not currently in use **
    #
    # INPUTS:
    # - stimulus:    stimulus value that the threshold is compared against (float).
    # - threshold:   threshold value of individual (float).
    
    if stimulus > threshold:
        return 1
    else:
        return 0
