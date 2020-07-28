#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Sep 13 13:44:23 2019

@author: ChrisTokita
"""

import re
import os

#directory = '../../data_sim/network_break/'
directory = '/scratch/gpfs/ctokita/InformationCascades/network_break/'

top_dirs = os.listdir(directory)
top_dirs = [d for d in top_dirs if "." not in d]

for t_d in top_dirs:

    dirs = os.listdir(directory + t_d + '/')
    
    for d in dirs:
        files = os.listdir(directory + t_d + '/' + d + '/')
        for file in files:
            new_num = re.search("[^0-9]*([0-9]+)[^0-9]*", file).group(1)
            new_num = new_num.zfill(2)
            new_file_name = re.sub("[0-9]+", new_num, file)
            os.rename(directory + t_d + '/' + d + '/' + file, directory + t_d + '/' + d + '/' + new_file_name)