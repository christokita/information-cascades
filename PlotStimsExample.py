#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Mar 23 17:49:40 2018

@author: ChrisTokita
"""

import numpy as np
from SocialNetworkFunctions import *
from ThresholdFunctions import *
from StimulusFunctions import *
import copy
import matplotlib


mu = 0 #mean for thresholds
gamma = 0.2 # correlation between two information sources

stims = list()

for i in range(100):
    stim_sources = generate_stimuli(correlation = gamma, mean = mu)
    stims.append(stim_sources)
    
matplotlib.pyplot.scatter(x)