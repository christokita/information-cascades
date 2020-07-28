#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Nov 25 11:53:42 2019

@author: ChrisTokita
"""

import numpy as np

def assign_type(n):
    # Assigns a type randomly to each individual.
    # Each individual has an equal change of getting a given type, but we split types equally.
    #
    # INPUTS:
    # - n:       the number of individuals in the social system (int).

    if n % 2 != 0:
        raise Exception("ERROR: cannot split selected number of individuals into two even groups")
    else:
        half = int(n/2)
        type_choices = np.random.choice(np.arange(n), size = n, replace = False)
        typeL = type_choices[:half]
        typeR = type_choices[half:]
        types = np.zeros((n, 2))
        types[typeL, 0] = 1
        types[typeR, 1] = 1
        return types


def assign_type_probailistic(n):
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
