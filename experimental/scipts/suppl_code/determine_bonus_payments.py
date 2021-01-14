#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Jan 11 11:37:52 2021

@author: ChrisTokita

SCRIPT
Determine who will be paid bonus payments/prizes
"""

####################
# Load packages
####################
import pandas as pd
import xlwings
import dropbox
import json
import os
import shutil
import io
import boto3
import math


####################
# Set important paths and parameters
####################
# Path to survey data on Dropbox
dropbox_dir = '/Information Cascades Project/data/'
path_to_twitter_data = dropbox_dir + 'twitter_data/'
path_to_survey_data = dropbox_dir + 'survey_data/'

# File names of data files on DropBox
crosswalk_file = 'user_crosswalk.xlsx'
lowcorr_network_file = 'lowcorr_initial_network.csv'
highcorr_network_file = 'highcorr_initial_network.csv'

# Get dropbox token
with open('../../api_keys/dropbox_token/dropbox_token.json') as f:
    key = json.load(f)
dropbox_token = key.get('access_token')
del key, f

# Get MTurk keys
with open('../../api_keys/mturk_keys/mturk_key.json') as f:
    mturk_key = json.load(f)


####################
# Load our list of particpants and follow networks
####################
# Interface with Dropbox API
dbx = dropbox.Dropbox(dropbox_token)

# Load our user cross walk: make temporary directory, download/open encrypted file, read in data, and delete temporary directory
tmp_dir = "/Users/ChrisTokita/Documents/Research/Tarnita Lab/Information Cascades/information-cascades/experimental/data/tmp/"
os.makedirs(tmp_dir, exist_ok = True)
dbx.files_download_to_file(download_path = tmp_dir + crosswalk_file, path = dropbox_dir + crosswalk_file)
wb_crosswalk = xlwings.Book(tmp_dir + crosswalk_file) # this will prompt you to enter password in excel
sheet_crosswalk = wb_crosswalk.sheets['Sheet1']
user_crosswalk = sheet_crosswalk.range('A1').options(pd.DataFrame, header = True, index = False, expand='table').value
user_crosswalk['user_id'] = user_crosswalk['user_id_str'].str.replace("\"", "")
del wb_crosswalk, sheet_crosswalk
shutil.rmtree(tmp_dir)

# Load follow networks
_, res = dbx.files_download(path_to_twitter_data + lowcorr_network_file)
lowcorr_network = pd.read_csv(res.raw, index_col = 0)
del _, res

_, res = dbx.files_download(path_to_twitter_data + highcorr_network_file)
highcorr_network = pd.read_csv(res.raw, index_col = 0)
del _, res


####################
# Determine how many other participants each person followed
####################
lowcorr_follows = lowcorr_network.sum(axis = 1).reset_index()
lowcorr_follows = lowcorr_follows.rename(columns = {'index': 'user_id', 0: 'participants_followed'})

highcorr_follows = highcorr_network.sum(axis = 1).reset_index()
highcorr_follows = highcorr_follows.rename(columns = {'index': 'user_id', 0: 'participants_followed'})


####################
# Batch out by Mturk-recruited (bonus payment) and FB-recruited (raffle for gift card)
####################
# Merge in follow counts
follow_counts = lowcorr_follows.append(highcorr_follows, ignore_index = True)
follow_counts['user_id'] = follow_counts['user_id'].astype(str)
user_crosswalk = user_crosswalk.merge(follow_counts, on = 'user_id')

# Split into separate pools
mturk_participants = user_crosswalk[~pd.isnull(user_crosswalk.mturk_worker_id)].copy()
fb_participants = user_crosswalk[~pd.isnull(user_crosswalk.email)].copy()


####################
# Pay our Rd2 workers from MTurk
####################
# Read in list of previous workers
worker_rd2_files = ['MTurk_workers/workers_rd2_lowcorr1a.csv',
                    'MTurk_workers/workers_rd2_lowcorr1b.csv',
                    'MTurk_workers/workers_rd2_lowcorr2.csv',
                    'MTurk_workers/workers_rd2_lowcorr_final.csv',
                    'MTurk_workers/workers_rd2_lowcorr_final2.csv',
                    'MTurk_workers/workers_rd2_highcorr1a.csv',
                    'MTurk_workers/workers_rd2_highcorr1b.csv',
                    'MTurk_workers/workers_rd2_highcorr2.csv',
                    'MTurk_workers/workers_rd2_highcorr_final.csv',
                    'MTurk_workers/workers_rd2_highcorr_final2.csv']
rd2_workers = []
for file in worker_rd2_files:
    _, res = dbx.files_download(path_to_survey_data + file)
    with io.BytesIO(res.content) as stream:
        workers = pd.read_csv(stream)
        rd2_workers.append(workers)
        del workers
rd2_workers = pd.concat(rd2_workers)

# Determine who will get bonus payments based on 
# (1) participated in second round survey, and
# (2) followed 1 or more other participants ($0.50 per follow)
rd2_workers = rd2_workers[['WorkerId', 'AssignmentId']].copy()
rd2_workers = rd2_workers.rename(columns = {'WorkerId': 'mturk_worker_id'})
mturk_participants = mturk_participants.merge(rd2_workers, on = 'mturk_worker_id')
mturk_participants['bonus_owed'] = mturk_participants['participants_followed'] * 0.50
mturk_participants.loc[mturk_participants.bonus_owed > 2.50, 'bonus_owed'] = 2.50 #we only pay up to 5 follows
mturk_participants = mturk_participants[mturk_participants.bonus_owed > 0] #only include those we will pay

# Connect to Mturk API    
mturk = boto3.client('mturk', 
                     aws_access_key_id = mturk_key['access_key_id'],
                     aws_secret_access_key = mturk_key['access_secret_key'],
                     region_name = 'us-east-1')
payment_message = "Thank you for participating in the follow-up survey in our academic study on news consumption and social media use. You were shown a handful of random Twitter accounts and were asked to follow up to 5. As promised, we are paying $0.50 per account you followed--up to 5 accounts. We apologize for the long time it took to dispense this bonus payment, but we hope you had a good holiday season and New Year's."

# Pay bonuses
"""
WARNING: Only uncomment below if you have not paid. Otherwise, you will double pay. See below for information. 

PAYMENT SENT: YES
PAYMENT DATE: Jan 12, 2021 at 2:30 pm EST
NOTE: No errors among users. Do not uncomment below under any circumstance!
"""
# error_users = []
# for index, row in mturk_participants.iterrows():
#     response = mturk.send_bonus(WorkerId = row['mturk_worker_id'],
#                                 BonusAmount = str(row['bonus_owed']),
#                                 AssignmentId = row['AssignmentId'],
#                                 Reason = payment_message)
#     if response['ResponseMetadata']['HTTPStatusCode'] != 200:
#         print("ERROR for user " + row['mturk_worker_id'])
#         error_users.append(row['mturk_worker_id'])


####################
# Pay our workers from FB
####################
# Read in our surveys that were deployed to FB-recruited participants
fb_survey_data = []
tmp_dir = "/Users/ChrisTokita/Documents/Research/Tarnita Lab/Information Cascades/information-cascades/experimental/data/tmp/"
os.makedirs(tmp_dir, exist_ok = True)
for file in ['fb_lowcorr_rd2_raw.xlsx', 'fb_highcorr_rd2_raw.xlsx']:
    dbx.files_download_to_file(download_path = tmp_dir + file, path = path_to_survey_data + file)
    wb_survey = xlwings.Book(tmp_dir + file) # this will prompt you to enter password in excel
    sheet_survey = wb_survey.sheets['Sheet0']
    survey_data = sheet_survey.range('A1').options(pd.DataFrame, header = True, index = False, expand='table').value
    survey_data = survey_data.iloc[1:, :].copy() #first row is headers
    fb_survey_data.append(survey_data)
    del wb_survey, sheet_survey, survey_data
shutil.rmtree(tmp_dir)
fb_survey_data = pd.concat(fb_survey_data, ignore_index = True)

# Prep our twitter info on participants
_, res = dbx.files_download(path_to_twitter_data + 'participant_twitter_info.csv')
twitter_info = pd.read_csv(res.raw, dtype = {'user_id': object})
del _, res
fb_participants = fb_participants.merge(twitter_info[['user_id', 'user_name']], on = 'user_id') #should be 157 rows
fb_participants['username_lower'] = fb_participants['user_name'].str.lower()
fb_participants['email_lower'] = fb_participants['email'].str.lower()

# Match up participants based on email first
fb_survey_data['email_lower'] = fb_survey_data['email'].str.lower()
confirmed_fb_participants = fb_participants[fb_participants['email_lower'].isin(fb_survey_data.email_lower)].copy()

# Match up participants based on twitter username
fb_survey_data['username_lower'] = fb_survey_data['twitter_username'].str.lower()
fb_survey_data['username_lower'] = fb_survey_data['username_lower'].str.replace("@", "")
fb_survey_data['username_lower'] = fb_survey_data['username_lower'].str.replace(" ", "")
confirmed_fb_participants2 = fb_participants[fb_participants['username_lower'].isin(fb_survey_data.username_lower)].copy()
confirmed_fb_participants = confirmed_fb_participants.append(confirmed_fb_participants2, ignore_index = True)
confirmed_fb_participants = confirmed_fb_participants.drop_duplicates()
confirmed_fb_participants = confirmed_fb_participants.reset_index(drop = True)
del confirmed_fb_participants2

# Figure out unconfirmed participants
"""
NOTE: The remaining three rows of unconfirmed survey data all appear to be the same person, whose email nor username can be found in our participant database.
Therefore, they will be excluded from earning the prize.
"""
unmatched_fb_participants = fb_survey_data[~fb_survey_data['email_lower'].isin(confirmed_fb_participants.email_lower) & ~fb_survey_data['username_lower'].isin(confirmed_fb_participants.username_lower)]

# Determine who gets $50 cards (giving out to 1-out-of-every-20 participants)
n_giftcards = math.ceil((confirmed_fb_participants.shape[0] + 1) / 20) #be generous in giving them out (I add one incase we are on the cusp of the next 20-person batch)
confirmed_fb_participants['raffle_tickets'] = confirmed_fb_participants['participants_followed'] + 1 #participants get one ticket just for taking the survey, even if they don't follow anyone
confirmed_fb_participants.loc[confirmed_fb_participants.raffle_tickets > 6, 'raffle_tickets'] = 6 #can only get up to 6 tickets, one for survey and one for each of up to 5 follows
pay_these_participants = confirmed_fb_participants['email'].sample(n = n_giftcards, weights = confirmed_fb_participants['raffle_tickets'], replace = False, random_state = 609)
pay_these_participants = pd.DataFrame({'email': pay_these_participants})

tmp_dir = "/Users/ChrisTokita/Documents/Research/Tarnita Lab/Information Cascades/information-cascades/experimental/data/tmp/"
os.mkdir(tmp_dir)
pay_these_participants.to_csv(tmp_dir + 'TO_PAY_fb_participants_rd2.csv', index = False)
with open(tmp_dir + 'TO_PAY_fb_participants_rd2.csv', "rb") as f:
    dbx.files_upload(f.read(), path = path_to_survey_data + 'TO_PAY_fb_participants_rd2.csv', mode = dropbox.files.WriteMode.overwrite)
shutil.rmtree(tmp_dir)     