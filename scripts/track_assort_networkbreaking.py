
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Dec  9 12:42:29 2017

@author: ChrisTokita

DESCRIPTION:
Run the model once, in which we track assortativity and the breaking/forming of ties over time.
**To run this script, make sure it is in the scripts/ directory.**
"""

# Settings for simulation
save_plot = True
outpath = "/scratch/gpfs/ctokita/information-cascades/"


##########
# Set parameters
##########
n = 200 #number of individuals
k = 5 #mean degree on networks
gamma = -0.9 #correlation between two information sources
psi = 0.1 #proportion of samplers
timesteps = 5*1000000 #number of rounds simulation will run
reps = 1 #number of replicate simulations

####################
# Load libraries and packages
####################
import numpy as np
import pandas as pd
import cascade_models.social_networks as sn
import cascade_models.thresholds as th
import cascade_models.cascades as cs
import igraph

# Supress error warnings (not an issue for this script)
np.seterr(divide='ignore', invalid='ignore')

####################
# Define simulation function
####################

def sim_adjusting_network(replicate, n, k, gamma, psi, timesteps, outpath, network_type = "random") :
    # Simulates a single replicate simulation of the network-breaking information cascade model. 
    #
    # INPUTS:
    # - replicate:      id number of replicate (int or float).
    # - n:              number of individuals in social system (int). n > 0.
    # - k:              mean out-degree of initial social network (int). k > 0.
    # - gamma:          correlation between information sources (float). gamma = [-1, 1].
    # - psi:            prop. of individuals sampling info source every time step (float). psi = (0, 1].
    # - timesteps:      length of simulation (int).
    # - outpath:        path to directory where output folders and files will be created (str). 
    # - network_type:   type of network to intially generate. Default is random but accepts ["random", "scalefree"] (str).
        
    ########## Seed initial conditions ##########
    # Set overall seed
    seed = int( (replicate + 1 + gamma) * 323 )
    np.random.seed(seed)
    # Seed individual's thresholds
    thresh_mat = th.seed_thresholds(n = n, lower = 0, upper = 1)
    # Assign type
    type_mat = th.assign_type(n = n)
    # Set up social network
    adjacency = sn.seed_social_network(n, k, network_type = network_type)
    
    #Capture assortativity and network breaks over time!
    assort_time = pd.DataFrame(columns = ['t', 'assort_type'])
    tie_changes = pd.DataFrame(columns = ['t', 'breaks', 'new_ties'])
    break_count = 0
    form_count = 0
    
    ########## Run simulation ##########
    for t in range(timesteps):
        # Initial information sampling
        info_values, state_mat, samplers, samplers_active = cs.simulate_stim_sampling(n = n,
                                                                                      gamma = gamma,
                                                                                      psi = psi,
                                                                                      types = type_mat,
                                                                                      thresholds = thresh_mat)
        # Simulate information cascade 
        state_mat = cs.simulate_cascade(network = adjacency, 
                                        states = state_mat, 
                                        thresholds = thresh_mat,
                                        samplers = samplers)
        # Evaluate behavior of individuals relative to threshold and stimuli
        correct_state = cs.evaluate_behavior(states = state_mat, 
                                             thresholds = thresh_mat, 
                                             information = info_values, 
                                             types = type_mat)
        # ALT model format: Adjust ties
        adjacency, formed_tie, broken_tie = adjust_tie(network = adjacency,
                                                       states = state_mat,
                                                       correct_behavior = correct_state)
        
        # Sum up tie forms/breaks
        break_count += broken_tie
        form_count += formed_tie
        # Measure assortativity and add assortativity/tie changes to dataframe
        if (t % 5000) == 0:
            g = igraph.Graph.Adjacency(np.ndarray.tolist(adjacency))
            g.vs['Type'] = type_mat[:,0]
            assort_type = g.assortativity(types1 = g.vs['Type'], directed = True)
            assort_time = assort_time.append({'t': t, 'assort_type': assort_type}, ignore_index = True)
            tie_changes = tie_changes.append({'t': t, 'breaks': break_count, 'new_ties': form_count}, ignore_index = True)
            break_count = 0
            form_count = 0
            
    
    ########## Output files ##########
    return assort_time, tie_changes

    
####################
# Define model-specific functions
####################
def adjust_tie(network, states, correct_behavior):
    # Randomly selects active individual and breaks tie if incorrect.
    # Another individual randomly forms like iff a tie is broken in that round.
    #
    # INPUTS:
    # - network:      the network connecting individuals (numpy array).
    # - states:       matrix listing the behavioral state of every individual (numpy array).
    # - correct_behavior:   array indicating whether each individual behaved correctly (numpy array).
    
    actives = np.where(states == 1)[0]
    tie_formed = 0
    tie_broken = 0
    if sum(actives) > 0: #error catch when no individual are active
        individual_active = np.random.choice(actives, size = 1)
        individual_correct = correct_behavior[individual_active]
        individual_neighbors = np.where(network[individual_active,:] == 1)[1]
        
        if not individual_correct:
            
            # Break ties with one randomly-selected "incorrect" neighbor
            perceived_incorrect = [ind for ind in actives if ind in individual_neighbors] #which neighbors are active
            break_tie = np.random.choice(perceived_incorrect, size = 1, replace = False)
            network[individual_active, break_tie] = 0
            network[break_tie, individual_active] = 0 #undirected network, symmetric edges
            tie_broken += 1
            
            # Randomly select another individual to form a new tie
            max_connections = network.shape[0] - 1 #can't connect to self
            candidate_individuals = np.where(np.sum(network, axis = 1) != max_connections)[0] #list individuals who are not already connected to everyone
            former_individual = np.random.choice(candidate_individuals, size = 1)
            former_connections = np.squeeze(network[former_individual,:]) #get individual's neighbors
            potential_ties = np.where(former_connections == 0)[0]
            potential_ties = np.delete(potential_ties, np.where(potential_ties == former_individual)) # Prevent self-loop
            new_tie = np.random.choice(potential_ties, size = 1, replace = False)
            network[former_individual, new_tie] = 1
            network[new_tie, former_individual] = 1 #undirected network, symmetric edges
            tie_formed += 1
                
    return network, tie_formed, tie_broken





##########
# Run model
##########
assort_over_time, tiechanges_over_time = sim_adjusting_network(replicate = 0, 
                                                               n = n, 
                                                               k = k, 
                                                               gamma = gamma, 
                                                               psi = psi, 
                                                               timesteps = timesteps,
                                                               outpath = outpath)


##########
# Plot
##########
import seaborn as sns
import matplotlib.pyplot as plt

# Set up the figure with subplots
f, axes = plt.subplots(1, 2, figsize=(8, 4), sharex=True)
sns.despine()

# Assortativity over time
sns.lineplot(x = "t", y = "assort_type", data = assort_over_time, ax = axes[0], color = '#34495e')
plt.ylabel("Assortativity")
plt.ticklabel_format(style ='sci', axis='x', scilimits=(0,0))

# Breaks and new ties over time
tiechanges = pd.melt(tiechanges_over_time, id_vars = "t", value_vars = ["breaks", "new_ties"])
sns.lineplot(x = "t", y = "value", hue = "variable", data = tiechanges, estimator = None, ax = axes[1], palette = ['#e74c3c', '#3498db'])
plt.ylabel("Count")
plt.ticklabel_format(style ='sci', axis='x', scilimits=(0,0))

f.suptitle("Assortativity over time for $\gamma =$ " + str(gamma))

if save_plot:
    f.savefig(outpath + 'assorttime_gamma' + str(gamma) + '.png')


