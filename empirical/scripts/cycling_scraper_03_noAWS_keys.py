s#!/usr/bin/env python
# coding: utf-8

"""
PURPOSE: 
    - This script was written to scrape tweets with a collection of multiple Twitter tokens
    to get around Twitter's rate limiting efforts. It is designed to be a command line
    tool. It also writes the vast majority of it's actions to a logging file and creates a 
    .csv file that logs the Tweepy/Twitter errors that the script runs into - indicating
     which user IDs they occured on.

INPUT:
    1. A collection of Twitter API developer tokens (cycled through periodically to subvert
    Twitter's rate limit).
    2. A list of user ids to scrape.
    3. AWS S3 bucket locations where you'd like to save the files scraped.
    NOTE: See the args.parser section below to see all available options and their meaning.

OUTPUT:
    - Twitter data in NDJSON format where each line is one tweet. Files are saved
    directly to the S3 bucket that you indicate. 
    - Error Log - Saved to S3 bucket you indiciate.
    - Simplified Tweepy/Twitter - Saved to S3 bucket you indicate.

"""

############################
### Load Script Packages ###
############################

from ast import literal_eval as lit
from io import StringIO
from tqdm import tqdm

import argparse
import boto3
import botocore
import datetime as dt
import glob
import json
import logging
import os
import pandas as pd
import sys
import time
import traceback
import tweepy
import urllib3


"""
These keys are for AWS access to the S3 bucket. You'll have to go through the
process of setting these up beforehand on AWS. If you have boto3 (AWS's 
Python package) set up on your computer, you can configure boto3 
to have these locked into your code so you don't need them as variables. 
However, if you are running on a virtual machine you'll either need to
download boto3 and go through that process for each machine, or just
hardcode these in as variables. 

These are also included in my code below for the upload_data_2_s3() 
function. They are probably redundant there because you enter them
as global variables here, but I haven't tested this.
"""

ACCESS_KEY_ID = 'XXXXXXXXXXXXXXXXXXXXXX'
ACCESS_SECRET_KEY = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'


############################
##### Define Functions #####
############################

class twee:
    
    def load_tokens(path = str):
        """
        Function to load tokens into a dictionary. 
        
        INPUT: 
        - path (str) = path to a NDJSON file where each line is a set of Twitter tokens.
        
        OUTPUT:
        - all_tokens (dict) = dictionary of all tokens with keys ranging from 0,..,n where
        n is the total number of tokens. Each value of the dictionary holds the token keys.
        """
        
        logger.info(f"Loading tokens from: '{path}' ...")
        
        all_tokens = {}

        with open(path, "r") as f:
            for line in f:
                token = json.loads(line)
                all_tokens.update(token)

        
        count = 0 
        new_dict = {}
        for key, val in all_tokens.items():
            count += 1
            count_str = str(count)
            new_dict.update({count_str : val})
        
        logger.info(f"Tokens loaded successfully.\n")
        
        return new_dict
    
    def get_token(key, all_tokens):
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

    def get_next_token_key(all_tokens, curr_token):
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


    def set_api_keys(consumer_key = str, consumer_secret = str, access_token = str, access_token_secret = str):
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
                             retry_delay = 5)
            
            # Initialize the api before returning it
            _ = api.user_timeline(screenname = "@devs_mr", count = 1)
            
            logger.info(f"Successfully set the API keys.\n")

            return api

        except:
            logger.exception(f"!! Problem setting the API keys !!\n")
            sys.exit("Script Manually Killed.")
            
        
    
    def rate_limit_check(API, all_tokens):
        """
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
    
    def switch_token(API, all_tokens):
        # Get token
        curr_access_token = API.auth.access_token

        # Get the token key within our token dictionary
        next_token_key_str = twee.get_next_token_key(all_tokens, 
                                                     curr_token = curr_access_token)

        # Grab those token values
        consumer_key, consumer_secret, access_token, access_token_secret = twee.get_token(key = next_token_key_str,
                                                                                          all_tokens = all_tokens)

        # Set the new API object
        API = twee.set_api_keys(consumer_key = consumer_key, 
                                consumer_secret = consumer_secret, 
                                access_token = access_token, 
                                access_token_secret = access_token_secret)
        
        curr_access_token = API.auth.access_token
        logger.info(f"Switched to token: {curr_access_token}.")
        print(f"Switched to token: {curr_access_token}.")
        
        return API

    def print_error_response(user_id, reason, status_code):
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

    def save_2_machine(save_loc = str, data = str, user_id = str):
        """
        Function to save data in a specific directory on the user machine.

        INPUT:
        - save_loc (str) : the directory where you'd like to save the data file
        - data (list) : the data you'd like to upload. Each list item should be a 
            single tweet object/dictionary.

        """
        
        # If user provides different path to save file, use that
        if save_loc is not None:
            path = str(save_loc)

        # If not, use current working directory.
        else:
            path = os.getcwd()

        # write the file
        try:
            logger.info(f"Saving tweets for user ID --> {user_id}...")
            with open(f"{path}/{user_id}_tweets.json", "a", encoding='utf-8') as f:
                for tweet in data:
                    f.write(f"{json.dumps(tweet)}\n")

            logger.info(f"{user_ID}_tweets.json was successfully created.\n")
        
        # We will get a TypeError if we try to iterate over a non-existant object (i.e
        # 'data' with no data), so we capture this and move onto next user.
        except TypeError:
            logger.exception(f"No data for <{user_id}>. Moving on to next user ID.\n")
            
            twee.record_error(user = user_id, 
                         code = "N/A",
                         reason = "Couldn't Write File / No Data",
                         bucket = bucket_name)
            
        except:
            logger.exception(f"Encountered a problem saving data to machine for user ID <{user_id}>.")
            sys.exit("Script Manually Killed.")


    def upload_data_2_s3(bucket_name = str, data = str, user_id = str):
        """
        Function to save data in a specific S3 bucket.

        INPUT:
        - bucket_name (str) : the name of the bucket you'd like to upload to
        - data (list) : the data you'd like to upload. Each list item should be a 
            single tweet object/dictionary.

        """

        # Get date for the file name
        todays_date = dt.datetime.strftime(dt.datetime.now(), "%Y-%m-%d_%M:%S")

        # create filename
        FILE_NAME = f"{todays_date}__{user_id}.json"

        # Set access keys
        ACCESS_KEY_ID = 'XXXXXXXXXXXXXXXXXXXXXXXXXXX'
        ACCESS_SECRET_KEY = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'

        # Manipulate data into a .csv format and then upload it to the S3 bucket
        logger.info(f"Attempting to upload data to AWS/S3 for user ID <{user_id}>...")
        try:

            twee_dict = {}

            # Create a single dictionary with keys
            for num, tweet in enumerate(data):
                twee_dict.update({str(num) : tweet})

            # Convert this dictionary to a single json string
            json_data = json.dumps(twee_dict)

            s3 = boto3.resource(
                's3',
                aws_access_key_id=ACCESS_KEY_ID,
                aws_secret_access_key=ACCESS_SECRET_KEY)

            s3.Bucket(bucket_name).put_object(Key=FILE_NAME,
                                              Body=json_data)
            
            print(f"Data uploaded to the '{bucket_name}' bucket for user_id {user_id}.\n")
            logger.info(f"Data uploaded to the '{bucket_name}' bucket for user_id {user_id}.\n")
        # We will get a TypeError if we try to iterate over a non-existant object (i.e
        # all_tweets with no data), so we capture this and move onto next user.
        except TypeError:
            logger.exception(f"No data for <{user_id}>. Moving on to next user ID.")
        
        except:
            logger.info(f"There was a problem uploading data for <{user_id}>.")
            sys.exit("Script Manually Ended.")

            
    def upload_file_2_s3(file_name, bucket, object_name=None):
        """
        Upload a file to an S3 bucket

        Input
        - file_name (string) : file (on your disk) to upload
        - bucket (string) : bucket to upload to
        - object_name (string) : S3 object name (name of file) to use in S3 bucket.
            if not specified, then file_name is used

        Output:
        - True if file was uploaded
        - False otherwise
        """
        
        logger.info(f"Trying to upload a non-data file <{file_name}> to S3...")
        # If S3 object_name was not specified, use file_name
        if object_name is None:
            object_name = file_name

        # Upload the file
        s3_client = boto3.client('s3')
        try:
            response = s3_client.upload_file(file_name, bucket, object_name)
        except ClientError as e:
            logging.error(e)
            return False
        logger.info("Successfully uploaded file. \n")
        return True

    
    def create_error_file_name(bucket = str):
        """
        Create an errors file. This function checks the S3 bucket where you are
        saving errors and creates a new numbered file. The number in the filename
        will be one larger than the largest numbered errors file already in that bucket.

        Input
        - bucket (string) : Name of bucket to check existing errors files

        Output
        - errors_file_name (string) : Name of errors file to write errors to

        """

        match = "errors"
        
        # Get all objects in the bucket
        all_bucket_files = twee.get_all_s3_keys(bucket = bucket)
        
        if all_bucket_files[0] == " __ ":
            errors_file_name = "1-errors.csv"
            return errors_file_name
        
        else:
            # This checks if we have an s3 data object in this bucket already.
            existing_error_files = [f_name for f_name in all_bucket_files if match in f_name]

            error_count = [int(f_name.split("-")[0]) for f_name in existing_error_files]

            count = max(error_count) + 1

            errors_file_name = f"{count}-errors.csv"
            return errors_file_name

        
    def record_error(user = str, code = "N/A", reason = "N/A", bucket = str, file_name = str):
        """
        Function to write ONLY error messages into a file.

        INPUT:
        - user = the user ID on which the error occured
        - code = the Twitter error status code (if present)
        - reason = the Twitter error message/reason (if present)
        - bucket = the S3 bucket # that we were trying to upload data to

        OUTPUT:
        - a single .csv file `errors--{bucket}.csv` in which each row 
        a single error and the columns will be:
        | user | code | reason | bucket |
        """
        
        logger.info("Logging an error...")
        with open(file_name, "a") as f:
            f.write(f"{user},{code},{reason},{bucket}\n")

        logger.info("Error successfully logged.")
    
    
    def get_s3_object_data(object_summary):
        """
        This function takes in an S3 object that has been stored as a .csv file,
        retrieves the data, and places it into a pandas dataframe.

        Input:
        - object_summary :  S3 bucket object
            - What you'll see if you call ~ print(type(object_summary))
                - <class 'boto3.resources.factory.s3.ObjectSummary'>
            - What you'll  see if you call ~ print(object_summary)
                - s3.ObjectSummary(bucket_name='01--2020-05-21', key='2020-05-21_23:17__10228272__YouTube.csv') 

        Output:
        - pandas.core.frame.DataFrame (standard dataframe)

        Example usage:
        ```
        # Connect to the S3 "resources" client
        s3_bucket = boto3.resource('s3')

        # Get specific bucket
        bucket = s3_bucket.Bucket(bucket_name)

        # Iterate through all bucket objects
        for object_summary in bucket.objects.all():
            temp_data = get_s3_object_data(object_summary)
        ```

        """
        # Get data and convert it to a csv string, then to a dataframe
        csv_data = object_summary.get()['Body'].read().decode('utf-8')
        df = pd.read_csv(StringIO(csv_data), sep = ",", low_memory=False)

        return df
    
    
    def s3_file_exists(bucket, file_name):
        """
        Function to check if a file exists..
        """
        s3 = boto3.resource('s3')

        try:
            s3.Object(bucket, file_name).get()
        except botocore.exceptions.ClientError as e:
            if e.response['Error']['Code'] == "404":
                # The object does not exist.
                return False
            else:
                # Something else has gone wrong.
                raise Exception("Unknown error checking if S3 file exists...")
        else:
            # The object does exist.
            return True

    
    def get_s3_file_oldest_tweet(bucket, file_name):
        """
        Function to get the oldest tweet (represented via the
        smallest tweet number) for an existing S3 file.
        """

        # Activate the s3 client
        client = boto3.client('s3')

        # get the file object
        file_object = s3_obj.get_object(Bucket=bucket, 
                                         Key=file_name)

        # Decode the data via "utf-8" decoder
        data = file_object['Body'].read().decode('utf-8')

        # Convert to single json
        json_data = json.loads(s3_clientdata)

        # convert to dataframe
        frame = pd.DataFrame.from_dict(json_data, orient = "index")

        try:
            oldest_tweet_num = frame.id.min()
            oldest_tweet_num = oldest_tweet_num - 1

            return oldest_tweet_num

        except:
            tweet_ids_list = frame.loc[:,"id"].apply(lambda x: pd.to_numeric(x, errors='coerce', downcast= "integer")).dropna().astype(int)
            oldest_tweet_num = str(min(tweet_ids_list) - 1)
            return oldest_tweet_num
        
    
    def get_all_s3_keys(bucket):
        """
        Get a list of all keys (file names) in an S3 bucket.
        
        Input:
        - bucket (string) : name of S3 bucket you'd like to get keys (file names) from.

        Output:
        - keys (list) : A list of all keys (file names) in the provided bucket.

        """

        s3 = boto3.client('s3')

        keys = []

        kwargs = {'Bucket': bucket}
        try:
            while True:
                resp = s3.list_objects_v2(**kwargs)
                for obj in resp['Contents']:
                    keys.append(obj['Key'])

                try:
                    kwargs['ContinuationToken'] = resp['NextContinuationToken']
                except KeyError:
                    break

            return keys
        except KeyError:
            logger.info("No contents in the provided bucket.")
            keys = [" __ "]
            return keys


######################################
### Read in command line arguments ###
######################################

# Initiate the parser
parser = argparse.ArgumentParser()

# Add long and short argument
parser.add_argument(
    "-b", "--data_bucket",
    metavar = "Data Bucket", 
    help="Name of S3 bucket where you want to store tweet data."
    )
parser.add_argument(
    "-s", "--summary_bucket",
    metavar = "Scrape Summary Bucket",
    help = "Name of S3 bucket where you want to store log and error files."
    )
parser.add_argument(
    "-pb", '--previous_buckets',
    metavar = "Previous Buckets",
    nargs='+',
    help ="Name of S3 data buckets that have perviously been scraped into. User ID numbers taken from these data buckets will be skipped.",
    )
parser.add_argument(
    "-u", '--user_ids_path',
    metavar = "User ID Path",
    help ="Path to file of user ID numbers.",
    )
parser.add_argument(
    "-t", '--token_path',
    metavar = "Tokens File Path",
    help ="Path to file containing Twitter Tokens to use while scraping.",
    )
parser.add_argument(
    "-lp", '--local_path',
    metavar = "Local Directory",
    help ="Directory where you'd like to save scraped tweet files.",
    )


# Read parsed arguments from the command line into "args"
args = parser.parse_args()


############################
### Variables for Script ###
############################

"""
ADDING COMMAND LINE INPUTS:
See the "Read in command line arguments" section 
for details on what the below represent. For each
"parser.add_arguemnt()" call you will see a "help"
argument which describes what each arguement 
represents.
"""
bucket_name = args.data_bucket
scrape_details_files = args.summary_bucket
user_list_path = args.user_ids_path
token_file = args.token_path
previous_buckets = args.previous_buckets

#################################
### Set some random variables ###
#################################

# Set file name of caught Tweepy errors .csv document
errors_file_name = twee.create_error_file_name(bucket = scrape_details_files)

# Set date variable
todays_date = dt.datetime.strftime(dt.datetime.now(), "%Y-%m-%d_%H-%M")

errors_date = todays_date  ##### UNNECESSARY????

num_tweets_2_pull = 3200


#######################
### Create a Logger ###
#######################

# Creates a logger
logger = logging.getLogger(__name__)  

# Set log level of detail to write
logger.setLevel(logging.INFO)

# Define file handler and set logger formatter
log_filename = f"{todays_date}__{bucket_name}.log"
file_handler = logging.FileHandler(log_filename)
formatter = logging.Formatter('%(asctime)s : %(levelname)s : %(name)s : %(message)s')
file_handler.setFormatter(formatter)

# Add file handler to logger
logger.addHandler(file_handler)


############################
### Load User ID Numbers ###
############################

logger.info("Loading all User ID numbers...")

# Load Users
users = pd.read_csv(user_list_path, index_col = 0)

# Change them to strings
users.loc[:,"twitter_id"] = users.loc[:,"twitter_id"].astype(str)

# Convert to a simple list
all_user_ids = list(users.twitter_id)

logger.info("Removing user ID numbers we've already scraped...")

# Iterate through all previous buckets passed into the function
for prev_buck in previous_buckets:
    # Get list of existing files in that s3 bucket
    file_keys = twee.get_all_s3_keys(bucket = prev_buck)

    # Create list of only user ID numbers from those filenames
    s3_user_id_list = [file.split("__")[1] for file in file_keys]
    s3_user_id_list = [file.split(".")[0] for file in s3_user_id_list]

    # Drop those user ID numbers from the full list of user ID numbers to pull
    {all_user_ids.remove(this_id) for this_id in s3_user_id_list}

###########################
###   Initialize API    ###
###########################
logger.info("Loading Twitter tokens...")

# Load all tokens
all_tokens = twee.load_tokens(path = token_file)

# Set the initial token key to select the first token
token_key = "1"

logger.info("Initilizing the Twitter API with first token...")

# Select first token and it's details
consumer_key, consumer_secret, access_token, access_token_secret = twee.get_token(token_key, all_tokens)

# Use these details to activate the API object
API = twee.set_api_keys(consumer_key = consumer_key, 
                        consumer_secret = consumer_secret, 
                        access_token = access_token, 
                        access_token_secret = access_token_secret)


# Print/log run details.
print("Name of scraping file used here  :", sys.argv[0])
print("Scraping into bucket             :", bucket_name)
print("Logging into bucket              :", scrape_details_files)
print("Date of Scrape                   : ", todays_date)
print("Pulling this many tweets per user: ", num_tweets_2_pull)
print("Errors File Name                 : ", errors_file_name)
print("Number of Users being scraped    : ", len(all_user_ids), "\n")
print("Previous data buckets we are checking:\n", previous_buckets)
print("Scraping users stored here:\n", user_list_path)
print("Using tokens stored here:\n", token_file)

logger.info(f"Name of scraping file used here       : {sys.argv[0]}")
logger.info(f"Scraping into bucket                 : {bucket_name}")
logger.info(f"Logging into bucket                  : {scrape_details_files}")
logger.info(f"Date of Scrape                       : {todays_date}")
logger.info(f"Errors File Name: {previous_buckets} :")
logger.info(f"Pulling this many tweets per user    : {num_tweets_2_pull}")
logger.info(f"Number of Users being scraped        :\n{user_list_path}\n")
logger.info(f"Previous data buckets we are checking:\n{previous_buckets}")
logger.info(f"Scraping users stored in below path/file:\n{user_list_path}")
logger.info( f"Using tokens stored in below path/file:\n{token_file}" )


########################################
### Begin pulling data for each user ###
########################################

logger.info("Begin data pulling loop...")
print("Begining data pulling loop...")

for user_id in tqdm(all_user_ids, position = 0, leave=True):

    """
    Before doing anything, we check if we need to switch tokens.
    The below function returns True or False.
        True = "Yes, need to switch"
        False = "No, we don't need to switch"
    This ensures that we always have enough timeline requests 
    to pull a full an entire timeline (3,200 tweets)
    """
    result = twee.rate_limit_check(API, all_tokens)
    
    if (result == True):
        logger.info("Trying to switch tokens to ensure we don't hit a rate limit.")
        print("Trying to switch tokens to ensure we don't hit a rate limit.")

        # Call function to switch API tokens
        API = twee.switch_token(API, all_tokens)
        
    # Get token
    curr_access_token = API.auth.access_token

    logger.info(f"Pulling user ID --> {user_id}... || Using token: {curr_access_token}")
    print(f"Pulling user ID --> {user_id}... || Using token: {curr_access_token}")

    # Set empty list to fill with tweets
    all_tweets = [] 

    # Try and grab tweets.
    # Iterate through a user's timeline and grab tweets, placing them into all_tweets
    try:
        for tweet in tweepy.Cursor(
                API.user_timeline,
                user_id=user_id,
                include_entities=True,
                tweet_mode='extended').items(num_tweets_2_pull):

            # Append each tweet to all_tweets
            all_tweets.append(tweet._json)

        
        logger.info(f"Data successfully pulled for user ID --> {user_id}.")
        
        twee.upload_data_2_s3(bucket_name = bucket_name,
                              data = all_tweets,
                              user_id = user_id)

    #######################################
    ######## ERROR HANDLING BEGINS ########
    #######################################

    # If we get a RateLimit, we grab the smallest tweet ID and switch the API
    except tweepy.RateLimitError as error:
        # We shouldn't get this error, however, if we do, we try to switch
        # to handle it by switching to a new token. 
        # It is unclear if this works because you have to wait until you 
        # actual hit a rate limit, making it hard to test.            
        logger.info("We've hit a `tweepy.RateLimitError`. Trying to switch tokens.")

        try:
            # Call function to switch API tokens
            API = twee.switch_token(API, all_tokens)

            logger.info("Eureka! We've successfully switched the API keys/details.\n")

        except:
            # If it doesn't work, we just pass and continue waiting.
            logger.info("There seems to be some issue switching, so the script will simply wait.\n")
            pass

    # If we get any other error from Tweepy...
    except tweepy.TweepError as error:
        
        # If we run into a known Tweepy error, we catch and record it.
        try:
            # Get token
            curr_access_token = API.auth.access_token

            # Get the reason and status code (all of these and their meanings are listed on Twitter's site)
            reason = error.response.reason
            status_code = error.response.status_code


            # Status code 429 is "Too Many Requets" - if we hit this we try to switch tokens.
            if str(status_code) == "429":
                logger.info("We've hit a `tweepy.TweepError` code <429 || Too Many Requests>. Going to try and switch tokens.")

                try:

                    API = twee.switch_token(API, all_tokens)

                    logger.info("Eureka! We've successfully switched the API keys/details.\n")

                except:
                    # If it doesn't work, we just pass and continue waiting.
                    logger.info("There seems to be some issue switching, so the script will simply wait.\n")
                    continue

            # Status code 503 is "Service Temporarily Unavailable" - if we hit this we try to switch tokens.
            if str(status_code) == "503":
                logger.info("We've hit a `tweepy.TweepError` code <503 || Service Temporarily Unavailable>. Going to wait for 5 minutes.")
                print("We've hit a `tweepy.TweepError` code <503 || Service Temporarily Unavailable>. Going to wait for 5 minutes.")

                # Eventually I wrote a function to do the below without 10 lines of code. 
                # That code, however, is in a more complicated version of the scraper.
                # This is just to provide some visual feedback in the output/log.
                logger.info("~")
                print("~")
                time.sleep(60)
        
                logger.info("~ ~")
                print("~ ~")
                time.sleep(60)
        
                logger.info("~ ~ ~")
                print("~ ~ ~ ")
                time.sleep(60)
        
                logger.info("~ ~ ~ ~")
                print("~ ~ ~ ~")
                time.sleep(60)
        
                logger.info("~ ~ ~ ~ ~")
                print("~ ~ ~ ~ ~")
                time.sleep(60)
                try:

                    API = twee.switch_token(API, all_tokens)

                    logger.info("Eureka! We've successfully switched the API keys/details.\n")

                except:
                    # If it doesn't work, we just continue to the next user ID.
                    logger.info("There seems to be some issue switching, so the script will simply wait.\n")
                    continue

            # Status code 500 is "Internal Service Error" - if we hit this we try to switch tokens.
            if str(status_code) == "500":
                logger.info("We've hit a `tweepy.TweepError` code <500 || Internal Service Error>. Going to wait for 5 minutes.")
                print("We've hit a `tweepy.TweepError` code <500 || Internal Service Error>. Going to wait for 5 minutes.")

                logger.info("~")
                print("~")
                time.sleep(60)
        
                logger.info("~ ~")
                print("~ ~")
                time.sleep(60)
        
                logger.info("~ ~ ~")
                print("~ ~ ~ ")
                time.sleep(60)
        
                logger.info("~ ~ ~ ~")
                print("~ ~ ~ ~")
                time.sleep(60)
        
                logger.info("~ ~ ~ ~ ~")
                print("~ ~ ~ ~ ~")
                time.sleep(60)
                try:

                    API = twee.switch_token(API, all_tokens)

                    logger.info("Eureka! We've successfully switched the API keys/details.\n")

                except:
                    # If it doesn't work, we just continue to the next user ID.
                    logger.info("There seems to be some issue switching, so the script will simply wait.\n")
                    continue

            # Any other error, we print info and record.
            else:
                twee.print_error_response(user_id, reason, status_code)

                twee.record_error(user = user_id, 
                                  code = status_code,
                                  reason = reason,
                                  bucket = bucket_name,
                                  file_name = errors_file_name)
                
        # If we run into a weird Tweepy error we still record it but pass less detail
        except Exception as error:
            logger.exception(f"We've run into an unexpected Tweep Error\n\n{error}")
            twee.record_error(user = user_id, 
                                  code = "N/A",
                                  reason = "N/A",
                                  bucket = bucket_name,
                                  file_name = errors_file_name)
    
    # This attempts to catch a weird connection error that we've been running into     
    except urllib3.exceptions.NewConnectionError:
        logger.info("************ ---> !! New Connection Error !! <--- ************")
        logger.info("Going to wait for 5 minutes and then switch the token, just in case Twitter is trying to block us.")
        print("Going to wait for 5 minutes and then switch the token, just in case Twitter is trying to block us.")
        
        logger.info("~")
        print("~")
        time.sleep(60)
        
        logger.info("~ ~")
        print("~ ~")
        time.sleep(60)
        
        logger.info("~ ~ ~")
        print("~ ~ ~ ")
        time.sleep(60)
        
        logger.info("~ ~ ~ ~")
        print("~ ~ ~ ~")
        time.sleep(60)
        
        logger.info("~ ~ ~ ~ ~")
        print("~ ~ ~ ~ ~")
        time.sleep(60)
        
        logger.info("Wait period completed.")
        try:

            API = twee.switch_token(API, all_tokens)

            logger.info("Eureka! We've successfully switched the API keys/details.\n")

        except:
            # If it doesn't work, we just continue to the next user ID.
            logger.info("There seems to be some issue switching, so the script will simply wait.\n")
            continue

    # For other random errors, we record them as N/A because it's not related to Twitter
    except Exception as error:
        logger.exception(f"Encountered unknown error pulling user ID --> {user_id}.\n")
        twee.record_error(user = user_id, 
                                  code = "N/A",
                                  reason = "N/A",
                                  bucket = bucket_name,
                                  file_name = errors_file_name)
        continue

    # If I want to cancel the script from running, I can do so. This also should trigger the error/log files to be uploaded.
    except KeyboardInterrupt as error:
        logger.info(f"User Keyboard Interruption provided while pulling --> {user_id}. Working to upload errors and log...")

        twee.upload_file_2_s3(file_name = errors_file_name, 
                         bucket = scrape_details_files, 
                         object_name=None)

        twee.upload_file_2_s3(file_name = log_filename, 
                         bucket = scrape_details_files, 
                         object_name=None)
        
        logger.info(f"Uploaded errors and log succesfully.")
        
        logger.exception(error)
        sys.exit(f"User Keyboard Interruption while pulling --> {user_id}.\n")

# If the loop is completed, then we can upload our log and errors file.
logger.info("Completed Pulling Data Succesfully. Working to upload errors and log...\n")
try:
    twee.upload_file_2_s3(file_name = errors_file_name, 
                     bucket = scrape_details_files, 
                     object_name=None)

    twee.upload_file_2_s3(file_name = log_filename, 
                     bucket = scrape_details_files, 
                     object_name=None)
    
    logger.info(f"Uploaded errors and log succesfully.\n")

    logger.info("FIN.")
    print("FIN.")

# If the error/log upload fails we still print/log the finish, but print the error/feedback and provide instructions.
except Exception as error:
    logger.exception(error)
    logger.info(f"There was an issue uploading either the errors file or the log file to the bucket {scrape_details_files}. These files still exist on your machine, and can be manually uploaded by utilizing the twee.upload_file_2_s3() function.")
    print(f"There was an issue uploading either the errors file or the log file to the bucket {scrape_details_files}. These files still exist on your machine, and can be manually uploaded by utilizing the twee.upload_file_2_s3() function.")
    logger.info("FIN.")
    print("FIN.")





