#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Oct 26 15:18:08 2020

@author: ChrisTokita

SCRIPT
Update worker qualifications in MTurk so we can exclude/include specific workers who took our survey
"""

####################
# Load packages
####################
import pandas as pd
import dropbox
import json
import io
import boto3


####################
# Set important paths and parameters
####################
# Path to survey data on Dropbox
dropbox_dir = '/Information Cascades Project/data/'
path_to_survey_data = dropbox_dir + 'survey_data/'

# Get dropbox token
with open('../api_keys/dropbox_token/dropbox_token.json') as f:
    key = json.load(f)
dropbox_token = key.get('access_token')
del key

# Connect to dropbox
dbx = dropbox.Dropbox(dropbox_token)

# Get MTurk keys
with open('../api_keys/mturk_keys/mturk_key.json') as f:
    mturk_key = json.load(f)

###################
# (1) Update qualifications so we exclude previous taker of Rd 1 Survey
####################
'''
We deployed the Rd 1 survey over the weekend and got low response rates. 
Now that it's a new work week, we want to deploy it again.
To do that, we need to make sure people don't double take our survey.
'''
# Read in list of previous workers
worker_rd1_files = ['survey_data/MTurk_workers/workers_rd1_conservative_batch1.csv',
                    'survey_data/MTurk_workers/workers_rd1_liberal_batch1.csv',
                    'survey_data/MTurk_workers/workers_rd1_conservative_batch2.csv',
                    'survey_data/MTurk_workers/workers_rd1_liberal_batch2.csv',
                    'survey_data/MTurk_workers/workers_rd1_conservative_batch3.csv',
                    'survey_data/MTurk_workers/workers_rd1_liberal_batch3.csv',
                    'survey_data/MTurk_workers/workers_rd1_allideols_batch1.csv']
rd1_pt1_workers = []
for file in worker_rd1_files:
    _, res = dbx.files_download(dropbox_dir + file)
    with io.BytesIO(res.content) as stream:
        workers = pd.read_csv(stream)
        rd1_pt1_workers.append(workers)
        del workers
rd1_pt1_workers = pd.concat(rd1_pt1_workers)

# Connect to Mturk API    
mturk = boto3.client('mturk', 
                     aws_access_key_id = mturk_key['access_key_id'],
                     aws_secret_access_key = mturk_key['access_secret_key'],
                     region_name = 'us-east-1')

# Update qualifications of these workers
error_users = []
for worker_id in rd1_pt1_workers['WorkerId']:
    response = mturk.associate_qualification_with_worker(QualificationTypeId = '35TOCVOB5DIOAFPMWPYK6DGAGQE327', #qualification: "Took 1st Rd Survey Already"
                                                         WorkerId = worker_id,
                                                         IntegerValue = 1,
                                                         SendNotification = False)
    if response['ResponseMetadata']['HTTPStatusCode'] != 200:
        print("ERROR for user " + worker_id)
        error_users.append(worker_id)
        
        
###################
# (2) Update qualifications so we send follow up survey to qualified MTurk workers
####################        