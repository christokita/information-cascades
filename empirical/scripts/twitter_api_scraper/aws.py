#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Aug  7 15:27:17 2020

@author: ChrisTokita, modified from Matt R. Deverna

SCRIPT
Key functionality for interacting with Twitter API and S3 data buckets
"""

####################
# Load packages
####################
import logging
import sys
import os
import json
import boto3
from botocore.exceptions import ClientError
import pandas as pd


####################
# Preliminary AWS functions
####################
def get_aws_keys(file):
    """
    Get the AWS IAM user access key and secret access key.
    
    INPUTS:
    - file: NDJSON file containing key and secret key. Assumes just one set per file.
    """

    with open(file, "r") as f:
        keys = json.load(f)
    access_key = keys.get('access_key_id')
    secret_access_key = keys.get('access_secret_key')
    return access_key, secret_access_key
     

####################
# AWS s3 bucket functions
####################
def upload_df_to_s3(data, bucket, logger, aws_key, aws_secret_key, object_name=None):
    """
    Upload a file to an S3 bucket. We default to 'us-east-1' region, i.e., Virginia.

    INPUTS
    - data: dataframe to upload
    - bucket: Bucket to upload to
    - logger: logger object
    - aws_key, aws_secret_key: keys for AWS access
    - object_name: S3 object name. If not specified then file_name is used
    
    OUTPUTS
    - Returns True if file was uploaded, else False
    """
    
    logger.info(f"Trying to upload a file <{object_name}> to S3...")
    
    # Write temporary file for saving purposes
    tmp_dir = 'tmp_' + object_name + '/'
    tmp_file = tmp_dir + object_name + '.csv'
    os.mkdir(tmp_dir)
    data.to_csv(tmp_file, index = False)
    

    # Upload the file
    s3 = boto3.resource('s3',
                        aws_access_key_id = aws_key,
                        aws_secret_access_key = aws_secret_key)

    try:
        s3.meta.client.upload_file(tmp_file, bucket, object_name + '.csv')
        print(f"Data <{object_name}> uploaded to the '{bucket}' bucket.\n")
        logger.info(f"Data <{object_name}> uploaded to the '{bucket}' bucket.\n")
        os.remove(tmp_file)
        os.rmdir(tmp_dir)
    except:
        logger.info(f"There was a problem uploading data for <{object_name}>.")
        os.remove(tmp_file)
        os.rmdir(tmp_dir)
        sys.exit("Script Manually Ended.")
        

def load_csv_from_s3(file, bucket, logger, aws_key, aws_secret_key):
    """
    Function that checks if a function already exists in our s3 bucket of interest.
    
    INPUTS
    - object_name: S3 object name. If not specified then file_name is used
    - bucket: Bucket to upload to
    - logger: logger object
    - aws_key, aws_secret_key: keys for AWS access
    
    OUTPUT
    Returns True if file exists, otherwise False.
    """
    
    logger.info(f"Checking if file <{file}> already exists in S3 bucket <{bucket}>...")
    
    # Connect
    s3 = boto3.client('s3',
                      aws_access_key_id = aws_key,
                      aws_secret_access_key = aws_secret_key)
    
    # Load
    obj = s3.get_object(Bucket = bucket, Key = file)
    df = pd.read_csv(obj['Body'], dtype = str)
    return df


def check_if_file_on_s3(file, bucket, logger, aws_key, aws_secret_key):
    """
    Function that checks if a function already exists in our s3 bucket of interest.
    
    INPUTS
    - object_name: S3 object name. If not specified then file_name is used
    - bucket: Bucket to upload to
    - logger: logger object
    - aws_key, aws_secret_key: keys for AWS access
    
    OUTPUT
    Returns True if file exists, otherwise False.
    """
    
    logger.info(f"Checking if file <{file}> already exists in S3 bucket <{bucket}>...")
    
    # Connect
    s3 = boto3.resource('s3',
                        aws_access_key_id = aws_key,
                        aws_secret_access_key = aws_secret_key)
    s3_bucket = s3.Bucket(bucket)
    
    # Check
    objs = list(s3_bucket.objects.filter(Prefix = file))
    if any([o.key == file for o in objs]):
        return True
    else:
        return False
