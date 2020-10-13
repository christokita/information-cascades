########################################
# Created on Tues Oct 13 15:56:00 2020
# @author: ChrisTokita
#
# SCRIPT
# Estimate ideologies of users who created new ties or broke ties during observation period
########################################

####################
# Load packages and set important paths
####################
library(tweetscores)
library(jsonlite)
library(dplyr)
source("twitter_api_scraper/ideology_utility_functions.R")


# High-level data directory
data_directory <- "/Volumes/CKT-DATA/information-cascades/observational/" #path to external HD
# data_directory <- "../" #path if done within local directory

# File paths