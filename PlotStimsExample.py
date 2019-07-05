#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Mar 23 17:49:40 2018

@author: ChrisTokita
"""

import numpy as np
import scipy as sp
from SocialNetworkFunctions import *
from ThresholdFunctions import *
from StimulusFunctions import *
import copy
import matplotlib


mu = 0 #mean for thresholds
gamma = 0.5 # correlation between two information sources

for i in range(20000):      
    stim_sources = generate_stimuli(correlation = gamma, mean = mu)
    if i == 0:
        stims = stim_sources
    else:
        stims = np.vstack([stims, stim_sources])
    
matplotlib.pyplot.scatter(stims[:,0], stims[:,1], s = 0.25)