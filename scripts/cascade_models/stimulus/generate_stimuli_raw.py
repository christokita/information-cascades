#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Nov 25 11:00:54 2019

@author: ChrisTokita
"""

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