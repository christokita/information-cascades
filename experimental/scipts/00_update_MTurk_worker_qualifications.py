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
import os
import xlwings
import shutil


####################
# Set important paths and parameters
####################
# Path to survey data on Dropbox
dropbox_dir = '/Information Cascades Project/data/'
path_to_survey_data = dropbox_dir + 'survey_data/'

# Path to specific files
wave_file = 'survey_wave_tracker.xlsx'

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
'''
We now need to deploy the round 2 survey in 3 waves. 
To do that, we will assign six total qualifications--one for each of the three waves in each of the two treatment gruops.
'''

# Make temporary directory, download encrypted survey wave data sheet, read into pandas, and delete temporary files
tmp_dir = "/Users/ChrisTokita/Documents/Research/Tarnita Lab/Information Cascades/information-cascades/experimental/data/tmp/"
os.makedirs(tmp_dir, exist_ok = True)
dbx = dropbox.Dropbox(dropbox_token)
dbx.files_download_to_file(download_path = tmp_dir + wave_file, path = path_to_survey_data + wave_file)
wb_waves = xlwings.Book(tmp_dir + wave_file) # this will prompt you to enter password in excel
sheet_waves = wb_waves.sheets['Sheet1']
wave_data = sheet_waves.range('A1').options(pd.DataFrame, header = True, index = False, expand='table').value
del wb_waves, sheet_waves
shutil.rmtree(tmp_dir)

# Construct out set of qualifications by wave and treatment
wave_quals = pd.DataFrame([['0', 1, '307M1J5IKZIHRH9CVRY04DY5DLREM8'],
                           ['0', 2, '3LJ6LLBDMCSCC178S6PXJYBS26E6AV'],
                           ['0', 3, '3LQV637WQC6HVBC0YKPTE9VYKOZ6BQ'],
                           ['1', 1, '3PO9K4KN95EWCJJGRM85SYTV080Y7V'],
                           ['1', 2, '3QY4EA3YB4FSP5S4FA1RTHMC5A23HX'],
                           ['1', 3, '3RAGKB98R1X0CXOZ1R0B6YPQBS6Y8I']],
                          columns = ['hi_corr', 'survey_wave', 'wave_qualification_id'])

treatment_quals = pd.DataFrame([['0', '3URP6LWYVRUJ9TN4WI9039EOZAFU97'],
                                ['1', '3YUA2D3Z1TSULP0CPTJSHTMZXB0WUZ']], 
                               columns = ['hi_corr', 'treatment_qualification_id'])

# Determine which worker gets which qualification
workers = wave_data[['mturk_worker_id', 'hi_corr', 'survey_wave']].copy()
workers = workers[~pd.isna(workers.mturk_worker_id)].copy()
workers = workers.merge(wave_quals, on = ['hi_corr', 'survey_wave'])
workers = workers.merge(treatment_quals, on = ['hi_corr'])

workers[['survey_wave', 'hi_corr']].value_counts()
workers[['treatment_qualification_id', 'hi_corr']].value_counts()

# Connect to Mturk API    
mturk = boto3.client('mturk', 
                     aws_access_key_id = mturk_key['access_key_id'],
                     aws_secret_access_key = mturk_key['access_secret_key'],
                     region_name = 'us-east-1')

# Update qualifications of follow-up survey workers
error_users = []
for index, row in workers.iterrows():
    worker_id = row.mturk_worker_id
    wave_qual_id = row.wave_qualification_id
    treat_qual_id = row.treatment_qualification_id
    hi_corr = row.hi_corr
    response1 = mturk.associate_qualification_with_worker(QualificationTypeId = wave_qual_id, #wave-specific ID
                                                          WorkerId = worker_id,
                                                          IntegerValue = 1,
                                                          SendNotification = False)
    response2 = mturk.associate_qualification_with_worker(QualificationTypeId = treat_qual_id, #treatment-specific ID
                                                          WorkerId = worker_id,
                                                          IntegerValue = 1,
                                                          SendNotification = False)
    response3 = mturk.associate_qualification_with_worker(QualificationTypeId = '3ASQQ0AAXJVMI9AX5XSWFERQ2DWSBY', #elgible for follow-up survey
                                                            WorkerId = worker_id,
                                                            IntegerValue = 1,
                                                            SendNotification = False)
    if (response1['ResponseMetadata']['HTTPStatusCode'] != 200) or (response2['ResponseMetadata']['HTTPStatusCode'] != 200) or (response3['ResponseMetadata']['HTTPStatusCode'] != 200):
        print("ERROR for user " + worker_id)
        error_users.append(worker_id)
        
        
        
###################
# (3) Update qualifications to mark workers who have already taken the follow-up survey
####################        

# Read in list of previous workers
worker_rd2_files = ['survey_data/MTurk_workers/workers_rd2_highcorr1a.csv',
                    'survey_data/MTurk_workers/workers_rd2_lowcorr1a.csv',
                    'survey_data/MTurk_workers/workers_rd2_highcorr1b.csv',
                    'survey_data/MTurk_workers/workers_rd2_lowcorr1b.csv',
                    'survey_data/MTurk_workers/workers_rd2_highcorr2.csv',
                    'survey_data/MTurk_workers/workers_rd2_lowcorr2.csv']

rd2_workers = []
for file in worker_rd2_files:
    _, res = dbx.files_download(dropbox_dir + file)
    with io.BytesIO(res.content) as stream:
        workers = pd.read_csv(stream)
        rd2_workers.append(workers)
        del workers
rd2_workers = pd.concat(rd2_workers)


# Connect to Mturk API    
mturk = boto3.client('mturk', 
                     aws_access_key_id = mturk_key['access_key_id'],
                     aws_secret_access_key = mturk_key['access_secret_key'],
                     region_name = 'us-east-1')

# Update qualifications of these workers
error_users = []
for worker_id in rd2_workers['WorkerId']:
    response = mturk.associate_qualification_with_worker(QualificationTypeId = '3DUIEQIYL6JPQIMALARAW7CNPSFY2G', #qualification: "Took Rd 2"
                                                         WorkerId = worker_id,
                                                         IntegerValue = 1,
                                                         SendNotification = False)
    if response['ResponseMetadata']['HTTPStatusCode'] != 200:
        print("ERROR for user " + worker_id)
        error_users.append(worker_id)
        