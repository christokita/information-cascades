#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Dec  9 17:59:20 2017

@author: ChrisTokita

Stimulus/Information Functions
"""

import numpy as np
import scipy as sp

# Generate correlated stimuli
def generate_stimuli(correlation, mean):
    # Create covariation matrix
    covar = [[1, correlation ], [correlation, 1]]
    # Generate stimuli
    stims = np.random.multivariate_normal(mean = [mean, mean], cov = covar, size = 1)
    # Translate stims to percentiles
    stims_perc = sp.stats.norm.cdf(stims)
    return(stims_perc)