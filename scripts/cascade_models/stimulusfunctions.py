#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Dec  9 17:59:20 2017

@author: ChrisTokita

DESCRIPTION:
Stimulus/Information Functions
"""

import numpy as np
import scipy as sp


def generate_stimuli(correlation, mean):
    # Generates a single pair of stimuli/infromation values for the two news sources.
    # Values are rescaled to the range [0, 1] using a logistic function.
    # ** This is currently the method used in the model. **
    #
    # INPUTS:
    # - correlation:   the correlation between the two information sources during random samples (float).
    # - mean:          average out-degree desired in social network (float or int).
    
    covar = [[1, correlation ], [correlation, 1]] 
    stims = np.random.multivariate_normal(mean = [mean, mean], cov = covar, size = 1) 
    stims_sig = 1 / (1 + np.exp(-stims+mean)) # Translate stims to 0 to 1 scale
    return stims_sig
    

def generate_stimuli_raw(correlation, mean):
    # Generates a single pair of stimuli/infromation values for the two news sources.
    # Values generated are raw and have NOT been scaled to the range [0, 1].
    #
    # INPUTS:
    # - correlation:   the correlation between the two information sources during random samples (float).
    # - mean:          average out-degree desired in social network (float or int).

    covar = [[1, correlation ], [correlation, 1]]
    stims = np.random.multivariate_normal(mean = [mean, mean], cov = covar, size = 1)
    return stims
    
    
def generate_stimuli_perc(correlation, mean):
    # Generates a single pair of stimuli/infromation values for the two news sources.
    # Values are rescaled to the range [0, 1] according to the percentile value of each stim.
    #
    # INPUTS:
    # - correlation:   the correlation between the two information sources during random samples (float).
    # - mean:          average out-degree desired in social network (foat or int).
    
    covar = [[1, correlation ], [correlation, 1]]
    stims = np.random.multivariate_normal(mean = [mean, mean], cov = covar, size = 1)
    stims_perc = sp.stats.norm.cdf(stims, loc = 0, scale = 1) # Translate stims to percentiles
    return stims_perc
    
    
def generate_stimuli_sig(correlation, mean):
    # Generates a single pair of stimuli/infromation values for the two news sources.
    # Values are rescaled to the range [0, 1] using a logistic function.
    # ** This is currently the method used in the model. Equivalent to generate_stimuli function. **
    #
    # INPUTS:
    # - correlation:   the correlation between the two information sources during random samples (float).
    # - mean:          average out-degree desired in social network (float or int).

    covar = [[1, correlation ], [correlation, 1]]
    stims = np.random.multivariate_normal(mean = [mean, mean], cov = covar, size = 1)
    stims_sig = 1 / (1 + np.exp(-stims))      # Translate stims to 0 to 1 scale
    return stims_sig