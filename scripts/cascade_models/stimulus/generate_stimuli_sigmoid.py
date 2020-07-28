#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Nov 25 11:01:30 2019

@author: ChrisTokita
"""

import numpy as np

def generate_stimuli_sigmoid(correlation, mean):
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