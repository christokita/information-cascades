#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Feb 12 15:17:06 2020

@author: ChrisTokita
"""
import numpy as np
import os

def create_output_directories(outpath, directory_names, n, gamma):
    """
    Creates the output directories where simulation data will be stored. 
    
    INPUTS:
    - outpath:       path to where simulation data directories will be created (string).
    - n:             number of individuals in that simulation (float).
    - gamma:         gamma value for that simulation (float).
    
    OUTPUTS:
    - output_dirs:   list of full paths to the output directories that were created.
    """
    
    output_name = "n" + str(n) + "_gamma" + str(gamma)
    directory_names = ['cascade_data', 'social_network_data', 'thresh_data', 'type_data', 'behavior_data', 'fitness_data']
    data_directories = [outpath + d + "/" for d in directory_names]
    output_directories = [d + output_name +  "/" for d in data_directories]
    for x in np.arange(len(data_directories)):
        # Check if directory already exisits. If not, create it.
        if not os.path.exists(data_directories[x]):
            os.makedirs(data_directories[x])
        # Check if specific run folder exists
        if not os.path.exists(output_directories[x]):
            os.makedirs(output_directories[x])
    return output_directories