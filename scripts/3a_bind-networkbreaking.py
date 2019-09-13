#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Dec  9 12:42:29 2017

@author: ChrisTokita

DESCRIPTION:
Script to run network-breaking cascade model on HPC cluster
(can be swept across parameter, numerous replicates) 

This script depends on a slurm script to call this script and provide certain parameter values,
namely the replicate number (taken from a slurm array) and possibly the gamma value.
"""

####################
# Load libraries and packages
####################
import numpy as np
import pandas as pd
import os
import re
import math


####################
# Parameters of interest (i.e., which files should be read and compiled)
####################
n_of_interest = 200 #group size runs of intereset
model = "network_break" #which model: "network_break" or "thresh_adjust"
top_dir = '../data_sim/' #folder where raw data are located (must end with '/')
save_dir = '../data_compiled/' + model + '/'

####################
# List files to be read
####################
# Get directories of interest
all_dirs = os.listdir(top_dir + model + '/')
data_dirs = [d for d in all_dirs if "_data" in d]

# Separate directories by how data will be handled
list_dirs = [d for d in data_dirs if not "cascade" in d]
bind_dirs = [d for d in data_dirs if "cascade" in d]

# Loop through list files
for list_d in list_dirs:
    # Find runs
    all_runs = os.listdir(top_dir + model + '/' + list_d + '/')
    # Loop through runs and compile
    for run in all_runs:
        # List files
        all_files = os.listdir(top_dir + model + '/' + list_d + '/' + run + '/')
        all_files.sort()
        # Loop through files 
        list_data = []
        full_path = top_dir + model + '/' + list_d + '/' + run + '/'
        for file in all_files:
            this_data = np.load(full_path + file)
            list_data.append(this_data)
        # Save
        save_path = save_dir + list_d + '/' + run + '.npy'
        np.save(save_path, list_data)
        


