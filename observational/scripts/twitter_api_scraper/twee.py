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
import pandas as pd
import tweepy
import json
import sys
import boto3


####################
# Establish API scraper class
####################
def load_tokens(path, logger):
    """
    Function to load tokens into a dictionary. 
    
    INPUT: 
    - path (str) = path to a NDJSON file where each line is a set of Twitter tokens.
    
    OUTPUT:
    - all_tokens (dict) = dictionary of all tokens with keys ranging from 0,..,n where
    n is the total number of tokens. Each value of the dictionary holds the token keys.
    """
    
    logger.info(f"Loading tokens from: '{path}' ...")
    
    token_dict = {}
    count = 0 
    with open(path, "r") as f:
        for line in f:
            count += 1
            count_str = str(count)
            token = json.loads(line)
            token_dict.update({count_str : token})
    
    logger.info(f"Tokens loaded successfully.\n")
    
    return token_dict

def get_token(key, all_tokens, logger):
    """
    Function used to grab a set of Twitter access tokens/keys.

    INPUT: 
    - key (str) : The key to grab from within 'all_tokens'
    - all_tokens (dict) : set of Twitter access tokens/keys 

    OUTPUT: Twitter access tokens/keys
    - consumer_key (str)
    - consumer_secret (str)
    - access_token (str)
    - access_token_secret (str)
    """
    
    logger.info(f"Grabbing specific token using key: <{key}>.")
    
    try:
        token_set = all_tokens.get(key)

        consumer_key = token_set.get('consumer_key')
        consumer_secret = token_set.get('consumer_secret')
        access_token = token_set.get('access_token')
        access_token_secret = token_set.get('access_token_secret')
        
        logger.info(f"Twitter access tokens/keys grabbed successfully.\n")

        return consumer_key, consumer_secret, access_token, access_token_secret

    except AttributeError as e:
        logger.exception(f"!! The passed key <{key}> doesn't exist within the 'all_tokens' dictionary passed !!")
        sys.exit("Script Manually Killed.")

    except Exception as e:
        logger.exception("Unknown error.")
        sys.exit("Script Manually Killed.")
        
        
def get_next_token_key(all_tokens, curr_token, logger):
    """
    Function to get the next token key. 

    INPUT:
    - all_tokens (dict) : set of Twitter access tokens/keys
    - curr_token (str) : the current Twitter "access_token" being utilized

    OUTPUT:
    - next_token_key_str (str) : the next dictionary key to utilize in "get_token()"
    to change to a new set of access tokens/keys.
    """
    
    logger.info(f"Trying to grab the dictionary key within 'all_tokens'...")
    
    # Get the total number of tokens
    num_of_tokens = pd.Series(list(all_tokens.keys())).astype(int).max()
    
    try:
        for key, value in all_tokens.items():
            if value.get("access_token") == curr_token:
                next_token_key_int = int(key) + 1            # make integer to add and check if last token

                # If the next token key is higher than the total number of tokens that we have
                if next_token_key_int > num_of_tokens:
                    # Set token key to use back to 1 and start the cycle over
                    next_token_key_int = 1

                # Now we set the key back to a string so that we can call our dictionary
                next_token_key_str = str(next_token_key_int) # string to call next token
                logger.info(f"Successfully grabbed token key.\n")
                return next_token_key_str
        
        raise AttributeError(f"Could not cycle to next token. Token provided <{curr_token}> does not match any tokens within 'all_tokens' dictionary.\n")
        
    except:
        logger.exception("Could not cycle to next token!\n")
        sys.exit("Script Manually Killed.")


def set_api_keys(consumer_key, consumer_secret, access_token, access_token_secret, logger):
    """Function to set API tokens 
    
    INPUTS: found via "https://developer.twitter.com/en/apps/" --> "apps" --> select "app details"
    - consumer_key = Twitter "API Key"
    - consumer_secret = Twitter "API Key Secret"
    - access_token = Twitter "Access Token"
    - access_token_secret = Twitter "Access Token Secret"
    """
    
    logger.info(f"Working to set the API keys...")
    
    try:
        # OAuth authenticate, using the keys and tokens
        auth = tweepy.OAuthHandler(consumer_key, consumer_secret)
        auth.set_access_token(access_token, access_token_secret)

        # Creation of the actual interface, using authentication
        api = tweepy.API(auth,
                         wait_on_rate_limit=True,
                         wait_on_rate_limit_notify=True,
                         retry_count = 1, 
                         retry_delay = 5,
                         timeout = 20)
        
        # Initialize the api before returning it
        _ = api.user_timeline(id = "@ChrisTokita", count = 1)
        
        logger.info(f"Successfully set the API keys.\n")

        return api

    except:
        logger.exception(f"!! Problem setting the API keys !!\n")
        sys.exit("Script Manually Killed.")
        
        
def rate_limit_check(API, all_tokens, logger):
    """
    Function to test whether or not we need to cycle to the next
    api token/key.
    
    """
    
    access_token = API.auth.access_token
    remaining_timeline_requests = API.last_response.headers["x-rate-limit-remaining"]
    max_requests = API.last_response.headers["x-rate-limit-limit"]
    
    if int(remaining_timeline_requests) == 0:
        logger.info(f"We have hit our rate limit, so we will now switch tokens.")
        
        # Print/Log details of this check...
        print(f"    Remaining Timeline Requests : {remaining_timeline_requests} / {max_requests}")
        print(f"    Access Token                : {access_token}")
        logger.info(f"    Remaining Timeline Requests : {remaining_timeline_requests} / {max_requests}")
        logger.info(f"    Access Token                : {access_token}")
        return True

    else:
        return False
    

def rate_limit_check_og(API, all_tokens, logger):
    """
    Original function from MSD
    Function to test whether or not we need to cycle to the next
    api token/key.
    
    """
    
    access_token = API.auth.access_token
    remaining_timeline_requests = API.last_response.headers["x-rate-limit-remaining"]
    
    if int(remaining_timeline_requests) <= 165:
        # 165
        logger.info(f"We need 160 remaining requests to pull 3200 tweets. We're close, so now we switch tokens.")
        
        # Print/Log details of this check...
        print(f"    Remaining Timeline Requests : {remaining_timeline_requests}")
        print(f"    Access Token                : {access_token}")
        logger.info(f"    Remaining Timeline Requests : {remaining_timeline_requests}")
        logger.info(f"    Access Token                : {access_token}")
        return True

    else:
        return False


def get_remaining_timeline_requests(API):
    """
    A convenience function for getting the exact # of remaining
    timeline requets. 
    """
    remaining_timeline_requests = API.last_response.headers["x-rate-limit-remaining"]
    return remaining_timeline_requests


def switch_token(API, all_tokens, logger):
    # Get token
    curr_access_token = API.auth.access_token

    # Get the token key within our token dictionary
    next_token_key_str = get_next_token_key(all_tokens = all_tokens, 
                                            curr_token = curr_access_token,
                                            logger = logger)

    # Grab those token values
    consumer_key, consumer_secret, access_token, access_token_secret = get_token(key = next_token_key_str,
                                                                                 all_tokens = all_tokens,
                                                                                 logger = logger)

    # Set the new API object
    API = set_api_keys(consumer_key = consumer_key, 
                       consumer_secret = consumer_secret, 
                       access_token = access_token, 
                       access_token_secret = access_token_secret,
                       logger = logger)
    
    curr_access_token = API.auth.access_token
    logger.info(f"Switched to token: {curr_access_token}.")
    print(f"Switched to token: {curr_access_token}.")
    
    return API


def print_error_response(user_id, reason, status_code, logger):
    """
    Function to print an error response.
    """
    errorResponse = '''

    ********
    TweepError Captured. Details below...

    User ID #   : {}
    Reason      : {}
    Status Code : {}

    Details on Status Codes can be found below...
        ---> https://developer.twitter.com/en/docs/basics/response-codes.html

    Moving on to next ...
    ********
    '''.format(user_id, reason, status_code)

    logger.exception(f"\nEncountered a problem pulling user ID --> {user_id}.\n")
    logger.exception(f"Token used at the time: {curr_access_token}.\n")

    logger.info(errorResponse)
    print(errorResponse)
    
    
def upload_file(file_name, bucket, logger, aws_key, aws_secret_key, object_name=None):
    """
    Upload a file to an S3 bucket.
    This function is from AWS examples.

    INPUTS:
    - file_name: File to upload
    - bucket: Bucket to upload to
    - logger: logger object
    - object_name: S3 object name. If not specified then file_name is used
    
    OUTPUTS:
    - Returns True if file was uploaded, else False
    """

    # If S3 object_name was not specified, use file_name
    if object_name is None:
        object_name = file_name


    s3 = boto3.resource('s3',
                        aws_access_key_id = aws_key,
                        aws_secret_access_key = aws_secret_key)
    
    # Upload the file
    s3_client = boto3.client('s3')
    
    try:
        response = s3_client.upload_file(file_name, bucket, object_name)
    except ClientError as e:
        logger.error(f"There is an issue uploading the data to the s3 bucket.")
        return False
    return True


