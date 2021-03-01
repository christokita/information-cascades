# Information Cascade Model 
Exploring how the information ecosystem (i.e., the collection of news outlets available to society) can reorganize social networks and result in "echo chambers," even when people do not know each other's political identities.

## Overview
These are the scripts and simulated data (the empirical data is stored on an external harddrive) for:

> Tokita CK, Guess AM, & Tarnita CE. (Submitted). How polarized information ecosystems can reorganize social networks.

Most of this project is written in Python. Python scripts are used to construct the model, simulate the model, and analyze model outputs. R is used exclusively for plotting purposes, because I feel that ggplot2 is still an unmatched plotting package when compared to alternatives in Python.

This project had three main components that can be found in different subdirectories within this repository:
* **model**: the theoretical & computational model that is at the core of this project.
* **observational**: the main empirical test of model predictions that collected and analyzed data from Twitter.
* **experimental**: an additional empirical test in which we deployed a digital experiment on Twitter.

## Components of this repository
Each subdirectory has the following general structure:
* *data* or *data_sim*: raw data either from Twitter (*data*) or the model (*data_sim*)
* *data_derived*: data resulting from the cleaning, organizing, and analysis of the raw data found in */data*
* *scripts*: all R and Python scripts for the projects, including scripts for simulation of the model, cleaning of data, analysis, and data visualization.
* *output*: end products from our project pipelines. Mostly plots. 

### model/
This subdirectory ...

## Necessary packages for this model
All packages for this model can be installed by running script [*forthecoming feature*]. The packages that will be necessary to simulate this model and generate model outputs are:

* **Python**: numpy, pandas, dplython, igraph, scipy, re, copy, os
* **R**: dplyr, ggplot2

## Components of this repository
* **model**: this folder containt all the scripts, data, and output of the cascade model.
* **empirical**: this folder contains all the scirpts, data, and output of the analysis of Twitter data.
