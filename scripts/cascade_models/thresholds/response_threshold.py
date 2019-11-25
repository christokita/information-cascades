#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Nov 25 11:54:09 2019

@author: ChrisTokita
"""

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
