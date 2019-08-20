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


# Seed thresholds
def seed_thresholds(n, lower, upper):
    # Generate thresholds 
    thresholds = np.random.uniform(size = n, low = lower, high = upper)
    # Python uses a open-close range so make sure no values equal 0
    while sum(thresholds == 0) > 0:
        zero_vals = np.where(thresholds == 0)[0]
        for zero_val in zero_vals:
            thresholds[zero_val] = np.random.uniform(size = 1, low = lower, high = upper)
    # Reshape and return
    thresholds = np.reshape(thresholds, (n, 1))
    return thresholds

# Assign type
def assign_type(n):
    # Assign type randomly, equal probability
    types = []
    for i in range(n):
        ind_type = np.random.choice([1, 0], size = 2, replace = False)
        types.append(ind_type)
    types = np.array(types)
    return(types)

# Response threshold function
def response_threshold(stimulus, threshold):
    if stimulus > threshold:
        return(1)
    else:
        return(-1)
