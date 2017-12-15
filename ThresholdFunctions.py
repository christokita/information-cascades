#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Dec  9 15:18:42 2017

@author: ChrisTokita

Threshold Functions
"""

import numpy as np
from scipy.stats import truncnorm
import matplotlib.pyplot as plt


# Seed thresholds
def seed_thresholds(n, mean, sd, low, high):
    # Calculate shape
    #a, b = (low - mean) / sd, (high - mean) / sd
    # Generate thresholds and return
    #thresholds = truncnorm.rvs(a = a, b = b, loc = mean, scale = sd, size = n)
    thresholds = np.random.normal(loc = mean, scale = sd, size = n)
    thresholds = np.matrix(thresholds)
    thresholds = np.reshape(thresholds, (n, 1))
    return thresholds

# Assign type
def assign_type(n):
    # Assign type randomly, equal probability
    types = []
    for i in range(n):
        ind_type = np.random.choice([1, 0], size = 2, replace = False)
        types.append(ind_type)
    types = np.matrix(types)
    return(types)

# Response threshold function
def response_threshold(stimulus, threshold):
    if stimulus > threshold:
        return(1)
    else:
        return(0)
