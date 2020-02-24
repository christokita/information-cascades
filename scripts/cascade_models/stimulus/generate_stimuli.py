#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Nov 25 11:00:22 2019

@author: ChrisTokita
"""

import numpy as np
import cascade_models.stimulus as st

def generate_stimuli(correlation, mean):
    # Generates a single pair of stimuli/infromation values for the two news sources.
    # Values are rescaled to the range [0, 1].
    #
    # INPUTS:
    # - correlation:   the correlation between the two information sources during random samples (float).
    # - mean:          average out-degree desired in social network (float or int).
    
    stims_sig = st.generate_stimuli_cdf(correlation, mean)
    return stims_sig


#def generate_stimuli(correlation, mean):
#    # Generates a single pair of stimuli/infromation values for the two news sources.
#    # Values are rescaled to the range [0, 1] using a logistic function.
#    # ** This is currently the method used in the model. **
#    #
#    # INPUTS:
#    # - correlation:   the correlation between the two information sources during random samples (float).
#    # - mean:          average out-degree desired in social network (float or int).
#    
#    covar = [[1, correlation ], [correlation, 1]] 
#    stims = np.random.multivariate_normal(mean = [mean, mean], cov = covar, size = 1) 
#    stims_sig = 1 / (1 + np.exp(-stims+mean)) # Translate stims to 0 to 1 scale
#    return stims_sig
    