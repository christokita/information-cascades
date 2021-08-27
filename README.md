# Information cascade model of politically polarized social networks
Focusing on information cascades and the news environment, we explore a potentially overlooked driver of political polarization that could be reorganizing social networks along political lines. Specifically, we explore how the information ecosystem (i.e., the collection of news outlets available to society) can create information cascades that cause individuals to adjust their social ties and sort into political "echo chambers"---even when people do not know each other's political identities. A quick rundown of this project from the significance statement in our paper:

>Prominent accounts argue that the media is an important driver of political polarization, but evidence is mixed on whether partisan media coverage pushes people’s opinions to the extreme. We instead propose another way that partisan media can foster polarization: by altering people’s social connections and reorganizing social networks along political lines. Specifically, using computational modeling and social media data, we explore how people may adjust their social ties to avoid conflicting information presented by their preferred news source and the behavior of friends who may be reacting to other news sources. We show that polarized media causes people to lose opposite-ideology social connections and sort into information-depriving “echo chambers,” even when they do not know each other’s political identity.

## Overview
These are the scripts and simulated data (the empirical data is stored on an external harddrive) for:

> Tokita CK, Guess AM, & Tarnita CE. (Submitted). How polarized information ecosystems can reorganize social networks.

Most of this project is written in Python. Python scripts are used to construct the model, simulate the model, and analyze model outputs. R is used exclusively for plotting purposes, because I feel that ggplot2 is still an unmatched plotting package when compared to alternatives in Python.

This project had three main components that can be found in different subdirectories within this repository:
* **model**: the theoretical & computational model that is at the core of this project.
* **observational**: the main empirical test of model predictions that collected and analyzed data from Twitter.
* **experimental**: an additional empirical test in which we deployed a digital experiment on Twitter.

## Necessary packages for this model
* **Python**: All Python packages for this project can be found in `<requirements.txt>` and can easily be installed with `<pip install -r requirements.txt>` from command line.
* **R**: dplyr, ggplot2, tweetR

## Components of this repository
Each subdirectory has the following general structure:
* *data* or *data_sim*: raw data either from Twitter (*data*) or the model (*data_sim*)
* *data_derived*: data resulting from the cleaning, organizing, and analysis of the raw data found in */data*
* *scripts*: all R and Python scripts for the projects, including scripts for simulation of the model, cleaning of data, analysis, and data visualization.
* *output*: end products from our project pipelines. Mostly plots. 
* *slurm_scripts*: contains the batch scripts necessary to run some of the scripts on a SLURM HPC cluster.

### model/
This subdirectory contains all the scripts to run, analyze, and visualize the computational model. Scripts are labeled by the function they perform and have the follow schema:
* **model_**: main mathematical/computational component of the the main network-breaking (NB) or the threshold-adjusting (TA) model
* **run_**: these scripts will run the model in various formats which are denoted at the end of the scipt name, e.g., _parallel, _single, _hpc. 
* **process_**: these scripts will process and compile the simulated model data
* **plot_**: visualize the processed/analyzed data

### observational/
Scripts here are largely numbered by the order that one must follow to sample news sources, sample specific users of these news sources, monitor their follower networks, and analyze the rate of cross-ideology unfollowing. The one **analyze_** script is the main statistical analysis that assesses whether different information ecosystems do affect the rate of cross-ideology unfollowing, and the **plot_** scripts plot various analysis from this data set.

### experimental/
As with the observational study subdirectory, scripts here are numbered in the order necessary to process the survey data, monitor the experimental social networks, and analyze/plot the experimental networks. Note that the survey data here is stored in an encrypted format on an externally on a password protected DropBox in order to protect participant privacy, per IRB regulations.

