#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Feb 12 15:16:12 2020

@author: ChrisTokita
"""
import sys
import numpy as np
import pandas as pd

def save_model_data(output_directories, output_tags, data_list, replicate):
    # Saves simulation from model
    # ** Not currently in use **
    #
    # INPUTS:
    # - output_directories:   list of full paths to output directores (list of str)
    # - output_tags:          
    # - data_list: 
    # - replicate:

    # Create replicate label for saving the data
    replicate_label = str(replicate)
    replicate_label = replicate_label.zfill(2)
    replicate_label = "_rep" + replicate_label
    
    # Check if number of output directories, output_tags, and data files match
    if not len(output_directories) == len(output_tags) == len(data_list):
        print("ERROR: the number of data directories and data files do not match.")
        sys.exit(1)
        
    # Loop through output directories and save corresponding
    for i in np.arange(len(output_directories)):
        if len(data_list[i]) == 1:
            data = data_list[i]
            output_data(ouput_directory = output_directories[i],
                        output_tag = output_tags[i],
                        replicate_label = replicate_label,
                        data = data,
                        element_in_datalist = i)
        else:
            for j in np.arange(len(data_list)):
                data = data_list[i][j]
                output_data(ouput_directory = output_directories[i],
                            output_tag = output_tags[i][j],
                            replicate_label = replicate_label,
                            data = data,
                            element_in_datalist = i)                
            
def output_data(ouput_directory, output_tag, replicate_label, data, element_in_datalist):
    #
    if isinstance(data, np.ndarray):
        np.save(ouput_directory + output_tag + replicate_label + ".npy", data)
    elif isinstance(data, pd.DataFrame):
        data.to_pickle(ouput_directory + output_tag + replicate_label + ".pkl")
    else: 
        print("ERROR: Canot save element" + str(element_in_datalist) + " in the data list is not a known data type. Check whether numpy array or pandas dataframe.")
    