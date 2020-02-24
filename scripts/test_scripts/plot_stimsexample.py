#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Mar 23 17:49:40 2018

@author: ChrisTokita

DESCRIPTION:
Plot stimulus values under the different methods 
found in util_scripts/stimulusfunctions.py
"""

####################
# Load libraryies and packages
####################
import numpy as np
import scipy as sp
import cascade_models.social_networks as sn
import cascade_models.thresholds as th
import cascade_models.cascades as cs
import cascade_models.stimulus as st
import copy
import matplotlib.pyplot as plt


####################
# Generate different stim values
####################
mu = 0 #mean for thresholds
gamma = -0.2 # correlation between two information sources

for i in range(20000):      
    stim_sources_perc = st.generate_stimuli_percentile(correlation = gamma, mean = mu)
    stim_sources_raw = st.generate_stimuli_raw(correlation = gamma, mean = mu)
    stim_sources_sig = st.generate_stimuli_sigmoid(correlation = gamma, mean = mu)
    if i == 0:
        stims_perc = stim_sources_perc
        stims_raw = stim_sources_raw
        stims_sig = stim_sources_sig
    else:
        stims_perc = np.vstack([stims_perc, stim_sources_perc])
        stims_raw = np.vstack([stims_raw, stim_sources_raw])
        stims_sig = np.vstack([stims_sig, stim_sources_sig])

####################
# Plot for visualization of difference
####################
# Set plot dimensions
fig = plt.figure(figsize=(15,5))
   
# Plot different subplots     
plt.subplot(1, 3, 1)
plt.scatter(stims_perc[:,0], stims_perc[:,1], s = 0.25)
plt.title('Percentile')

plt.subplot(1, 3, 2)
plt.scatter(stims_raw[:,0], stims_raw[:,1], s = 0.25)
plt.title('Raw')

plt.subplot(1, 3, 3)
plt.scatter(stims_sig[:,0], stims_sig[:,1], s = 0.25)
plt.title('Sigmoid Func.')

plt.show()

# Check mean and sd of raw values
np.mean(stims_raw[:,0])
np.mean(stims_raw[:,1])
np.std(stims_raw[:,0])
np.std(stims_raw[:,1])