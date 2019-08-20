#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Dec  9 17:59:20 2017

@author: ChrisTokita

Stimulus/Information Functions
"""

import numpy as np
import scipy as sp

# Generate correlated stimuli (method used in simulations)
def generate_stimuli(correlation, mean):
    # Create covariation matrix
    covar = [[1, correlation ], [correlation, 1]]
    # Generate stimuli
    stims = np.random.multivariate_normal(mean = [mean, mean], cov = covar, size = 1)
    # Translate stims to 0 to 1 scale
    stims_sig = 1 / (1 + np.exp(-stims))
    return(stims_sig)
    
# Generate correlated stimuli (returned as raw values)
def generate_stimuli_raw(correlation, mean):
    # Create covariation matrix
    covar = [[1, correlation ], [correlation, 1]]
    # Generate stimuli
    stims = np.random.multivariate_normal(mean = [mean, mean], cov = covar, size = 1)
    return(stims)
    
# Generate correlated stimuli (returned as percentile)
def generate_stimuli_perc(correlation, mean):
    # Create covariation matrix
    covar = [[1, correlation ], [correlation, 1]]
    # Generate stimuli
    stims = np.random.multivariate_normal(mean = [mean, mean], cov = covar, size = 1)
    # Translate stims to percentiles
    stims_perc = sp.stats.norm.cdf(stims, loc = 0, scale = 1)
    return(stims_perc)
    
# Generate correlated stimuli (returned using sigmoid function)
def generate_stimuli_sig(correlation, mean):
    # Create covariation matrix
    covar = [[1, correlation ], [correlation, 1]]
    # Generate stimuli
    stims = np.random.multivariate_normal(mean = [mean, mean], cov = covar, size = 1)
     # Translate stims to 0 to 1 scale
    stims_sig = 1 / (1 + np.exp(-stims))
    return(stims_sig)