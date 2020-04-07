#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Nov 25 11:45:37 2019

@author: ChrisTokita
"""

import numpy as np

def evaluate_behavior(states, thresholds, information, types):
    # Evaluates the behavior of active individuals in cascade relative to what they would do if they'd had direct access to info source.
    #
    # INPUTS:
    # - states:           array listing the behavioral state of every individual (numpy array).
    # - thresholds:       array of thresholds for each individual (numpy array).
    # - information:      array of stimuli/infromation values (numpy array).
    # - types:            array of type assignments for each individual (numpy array).
    
    relative_info = np.dot(types, np.transpose(information))
    correct_behavior = relative_info > thresholds
    correct_behavior = np.ndarray.flatten(correct_behavior)
    return correct_behavior