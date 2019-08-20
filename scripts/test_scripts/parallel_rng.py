#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Aug 20 12:59:55 2019

@author: ChrisTokita

DESCRIPTION:
Testing random number generation in parallel
"""

####################
# Load libraryies and packages
####################
import numpy as np
import multiprocessing as mp
from util_scripts.thresholdfunctions import *
import matplotlib.pyplot as plt

####################
# Define function to run in parallel
####################
def test_parallel_rng(x):
    # Set seed
    np.random.seed(x*323)
    # Generate numbers and return
    temp = seed_thresholds(2, 0, 1)
    #temp2 = seed_thresholds(2, 0, 1)
    #temp = np.vstack((temp, temp2))
    return(temp)

####################
# Sim
####################
# Get CPU count and set pool
cpus = mp.cpu_count()
pool = mp.Pool(cpus)

# Generate thresholds
parallel_thresh = [pool.apply_async(test_parallel_rng, args = [rep])
                    for rep in range(4*2)]

thresh_matrices = [r.get() for r in parallel_thresh]

# Close and join
pool.close()
pool.join()

# Flatten
thresholds = np.hstack(thresh_matrices)
thresholds = np.transpose(thresholds)

####################
# Plot
####################
plt.scatter(thresholds[:,0], thresholds[:,1])

