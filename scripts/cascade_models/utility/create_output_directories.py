#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Feb 12 15:17:06 2020

@author: ChrisTokita
"""

def create_output_directories(outpath, n, gamma):
    # Creates the output directories where simulation data will be stored. 
    #
    # INPUTS:
    # - outpath:       path to where simulation data directories will be created (string).
    # - n:             number of individuals in that simulation (float).
    # - gamma:         gamma value for that simulation (float).
    #
    # OUTPUTS:
    # - output_dirs:   list of full paths to the output directories that were created.
    
    output_name = "n" + str(n) + "_gamma" + str(gamma)
    data_dirs = ['cascade_data', 'social_network_data', 'thresh_data', 'type_data', 'behavior_data', 'fitness_data']
    data_dirs = [outpath + d + "/" for d in data_dirs]
    output_dirs = [d + output_name +  "/" for d in data_dirs]
    for x in np.arange(len(data_dirs)):
        # Check if directory already exisits. If not, create it.
        if not os.path.exists(data_dirs[x]):
            os.makedirs(data_dirs[x])
        # Check if specific run folder exists
        if not os.path.exists(output_dirs[x]):
            os.makedirs(output_dirs[x])
    return output_dirs