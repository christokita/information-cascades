#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Nov 25 11:01:16 2019

@author: ChrisTokita
"""

import numpy as np
import scipy as sp

def generate_stimuli_percentile(correlation, mean):
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