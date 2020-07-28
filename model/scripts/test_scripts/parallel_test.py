#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Jul 16 11:21:00 2019

@author: ChrisTokita
"""

####################
# Load libraryies and packages
####################
import multiprocessing as mp 
import numpy as np


####################
# Get CPU numbers
####################
cpus = mp.cpu_count()


####################
# Test
####################
np.random.RandomState(100)
arr = np.random.randint(0, 10, size=[200000, 5])
data = arr.tolist()
data[:5]





