#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Sep  5 14:17:51 2019

@author: ChrisTokita
"""
####################
# Load libraryies and packages
####################
import pandas as pd
import numpy as np
import multiprocessing as mp 
import time
import sys
import math
import re

####################
# Define function to be run
####################
def test_function(x, rep):
    # Set overall seed
    np.random.seed(rep * 323)
    # Function
    exponent = np.random.randint(4, 9)
    to_sum = np.arange(10 ** exponent)
    out_val = math.sin(math.cos(sum(to_sum)))
    process = str(mp.current_process())
    process_clean = re.search('.*(Worker-[0-9]+),.*', process)
    process_clean = process_clean.group(1)
    time_now = time.strftime("%H:%M:%S")
    to_return = pd.DataFrame([[x, rep, exponent, time_now, process_clean]],
                             columns = ['Parameter', 'Rep', 'Exponent', 'Time', 'Process'])

    return(to_return, x)


####################
# Run function
####################
if __name__=='__main__':
    
    # Get CPU count and set pool
    cpus = mp.cpu_count()
    pool = mp.Pool(cpus)
    
    # Set parameters
    parameters = np.arange(3)
    replicates = 40
    
    # Loop through parameters
    for para in parameters:
        
        # Run
        reps = np.arange(replicates)
        para = [para] * len(reps)
        parallel_results = pool.starmap_async(test_function, zip(para, reps))
        
        # Get results
        parallel_results = parallel_results.get()
        dataframes = [r[0] for r in parallel_results]
        para_results = [r[1] for r in parallel_results]
        
        # Organize
        dataframe_results = pd.DataFrame(columns = ['Parameter', 'Rep', 'Exponent', 'Time', 'Process']) 
        for df in dataframes:
            dataframe_results = pd.concat([dataframe_results, df])
        dataframe_results = dataframe_results.sort_values(by = ['Process', 'Time'])
        
        # Mock-'save'
        print("---------- NEW Parameter run ----------")
        print("\n \n Printing dataframe: \n")
        print(dataframe_results)
        print("\n \n Printing parameters used: \n")
        print(para_results)
        
    # close pool
    pool.close()
    pool.join()