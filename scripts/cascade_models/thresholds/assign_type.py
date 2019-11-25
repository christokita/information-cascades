#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Nov 25 11:53:42 2019

@author: ChrisTokita
"""

import numpy as np

def assign_type(n):
    # Assigns a type randomly to each individual.
    # Each individual has an equal change of getting a given type.
    #
    # INPUTS:
    # - n:       the number of individuals in the social system (int).

    types = []
    for i in range(n):
        ind_type = np.random.choice([1, 0], size = 2, replace = False)
        types.append(ind_type)
    types = np.array(types)
    return types
