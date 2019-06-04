#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Dec  9 11:31:35 2017

@author: ChrisTokita

Social Network Functions
"""
import numpy as np

# Seed random weighted network 
def seed_social_network(n, k):
    # create eventual 2d array
    network = []
    # go through individuals and select partners randomly
    individuals = np.array(range(0, n))
    for i in individuals:
        # drop self
        pot_partners = np.delete(individuals, i)
        sel_partners = np.random.choice(pot_partners, size = k, replace = False)
        row = np.repeat(0, n)
        row[sel_partners] = 1
        network.append(row)
    # bind and return
    network = np.vstack(network)
    return(network)