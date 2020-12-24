#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Dec  4 23:18:40 2020

@author: ChrisTokita

SCRIPT:
Pull down sample tweets from news accounts of interest.
"""

####################
# Load packages, set paths to data
####################
import pandas as pd
import numpy as np
from datetime import date
import json
import os
import re
import tweepy
import twitter_api_scraper.twee as twee

# High-level data directory and outpath
data_directory = '/Volumes/CKT-DATA/information-cascades/observational/'
outpath = data_directory + 'data/news_source_tweets/'

# Twitter tokens
token_file = '../api_keys/twitter_tokens/ckt_tokens1.json'


####################
# Parameters of interest
####################
focal_sources = ['CBSNews', 'USATODAY', 'voxdotcom', 'dcexaminer']
reference_sources = ['Reuters', 'AP']
news_sources = focal_sources + reference_sources


####################
# Prep Twitter API
####################
# Load our tokens
all_tokens = twee.load_tokens(path = token_file)
token_key = "1"
token = all_tokens[token_key] #only use one token!
del all_tokens, token_key

# OAuth authenticate, using the keys and tokens
auth = tweepy.OAuthHandler(token['consumer_key'], token['consumer_secret'])
auth.set_access_token(token['access_token'], token['access_token_secret'])

# Creation of the actual interface, using authentication
API = tweepy.API(auth,
                 wait_on_rate_limit=True,
                 wait_on_rate_limit_notify=True,
                 retry_count = 1, 
                 retry_delay = 5,
                 timeout = 10)


####################
# Get tweets
####################
# Get tweets from Twitter API and save raw JSONs of tweets
raw_tweet_jsons = []
tweets_per_page = 200 #can only get up to 200 tweets per page
max_tweets = 3200 #can only get up to 3200 tweets per account, per Twitter API policy
for news_source in news_sources:     
    
    tweet_file = news_source + '_' + str(date.today()) + '.json'
    tweet_count = 0
    for page in tweepy.Cursor(API.user_timeline, screen_name = news_source, count = tweets_per_page, include_entities = True, tweet_mode = 'extended').pages(max_tweets / tweets_per_page):
        
        # Save raw tweets to file just in case we need more info, append to list
        for tweet in page:
            raw_tweet_jsons.append(tweet._json)
            with open(outpath + tweet_file, "a") as outfile:
                json.dump(tweet._json, outfile)
                outfile.write('\n')
        
        # Progress update
        tweet_count += tweets_per_page
        print( "{}: {} / {} tweets grabbed.".format(news_source, tweet_count, max_tweets) )
    
  
    
####################
# Define custom function to load and parse JSON tweet data
####################
def tweet_parser(filename):
    """
    Parse JSON tweet data and return a compiled dataset
    
    INPUT:
    - filename: path to specific JSON file containing tweet data (string).
    
    OUTPUT:
    - tweet_data: dataframe of all tweet data in the specified file, with a subset of the relevant data headings (pandas dataframe).
    """
    
    with open(filename,) as json_file:
        # Parse each individual tweet in data set 
        for tweet in json_file:
    
            # Load individual tweet
            tweet_obj = json.loads(tweet)

            # Get tweet attributes of interest
            user_id = tweet_obj['user']['id_str']
            user_name = tweet_obj['user']['screen_name']
            tweet_time = tweet_obj['created_at']
            tweet_id = tweet_obj['id_str']
            favorite_count = tweet_obj['favorite_count']
            retweet_count = tweet_obj['retweet_count']
            is_quote = 'quoted_status' in tweet_obj
            is_retweet = 'retweeted_status' in tweet_obj
            tweet_url = "https://twitter.com/" + user_name + "/status/" + str(tweet_id)
            RTofselfRT = False #flag that finds  RT of self-RT by finding 'quoted_status' in 'retweeted_status'
            
            # Parse other tweet information based on tweet type
            # If the object is a retweet, we will treat that as the main tweet body for text and urls.
            if is_retweet:
                retweet_obj = tweet_obj['retweeted_status']
                retweet_id = retweet_obj['id_str']
                retweet_user_id = retweet_obj['user']['id_str']
                retweet_user_name = retweet_obj['user']['screen_name']
                tweet_text, url, url_expanded, url_count, is_extended = get_tweet_text(retweet_obj)
    
                # This catches where someone RT a self-RT.
                if 'quoted_status' in retweet_obj:
                    RTofselfRT = True
                
            else:
                tweet_text, url, url_expanded, url_count, is_extended = get_tweet_text(tweet_obj)
                retweet_id = retweet_user_id = retweet_user_name = np.nan
                
            # If object is quoted tweet, the quoted tweet text and urls will be handled separately.
            if is_quote:
                quoted_obj = tweet_obj['quoted_status']
                quoted_id = quoted_obj['id_str']
                quoted_user_id =  quoted_obj['user']['id_str']
                quoted_user_name = quoted_obj['user']['screen_name']
                quoted_text, quoted_url, quoted_url_expanded, quoted_url_count, quote_extended = get_tweet_text(quoted_obj)
            else: 
                quoted_id = quoted_user_id = quoted_user_name = np.nan
                quoted_text = quoted_url = quoted_url_expanded = quoted_url_count=quote_extended = np.nan
                
            # Catch for quoted tweets that quoted since-deleted tweet (would be missing quoted_status object)
            quoted_tweet_deleted = False
            if tweet_obj['is_quote_status']:
                is_quote = True
                quoted_tweet_deleted = True
            
            # Append to tweet dataframe
            this_tweet = pd.DataFrame({'user_id': user_id, 
                                       'user_name': user_name,
                                       'tweet_time': tweet_time,
                                       'tweet_text': tweet_text,
                                       'tweet_id': tweet_id,
                                       'urls': url,
                                       'urls_expanded': url_expanded,
                                       'url_count': url_count,
                                       'favorite_count': favorite_count,
                                       'retweet_count': retweet_count,
                                       'is_quote': is_quote,
                                       'is_retweet': is_retweet, 
                                       'is_extended_tweet': is_extended,
                                       'retweeted_user_id': retweet_user_id,
                                       'retweeted_user_name': retweet_user_name,
                                       'retweet_id': retweet_id,
                                       'quoted_user_id': quoted_user_id,
                                       'quoted_user_name': quoted_user_name,
                                       'quoted_id': quoted_id,
                                       'quoted_text': quoted_text,
                                       'quoted_urls': quoted_url,
                                       'quoted_urls_expanded': quoted_url_expanded,
                                       'quoted_url_count': quoted_url_count,
                                       'quoted_is_extended': quote_extended,
                                       'quoted_tweet_deleted': quoted_tweet_deleted,
                                       'RTofselfRT': RTofselfRT,
                                       'tweet_url': tweet_url}, index = [0])
            try:
                tweet_data = tweet_data.append(this_tweet, ignore_index = True, sort = False)
            except:
                tweet_data = this_tweet
            
    return tweet_data



def get_tweet_text(tweet_object):
    """
    Function to get tweet text and URLs from tweet data.
    
    INPUT
    - tweet_object: JSON-parsed data. Can be main tweet object, retweeted_status object, or quoted_status object
    """
    
    # If extended tweet (>140 char), go to proper sub-object.
    is_extended_tweet = 'extended_tweet' in tweet_object
    if is_extended_tweet:
        extended_tweet_object = tweet_object['extended_tweet']
        tweet_text = extended_tweet_object['full_text']
        url_collection = extended_tweet_object['entities']['urls']
    else: 
        url_collection = tweet_object['entities']['urls']
        tweet_text = tweet_object['full_text']
        
    # Parse urls (can contain multiple and are in nested list)
    url, url_expanded, url_count = parse_urls(url_collection)
    return tweet_text, url, url_expanded, url_count, is_extended_tweet


def parse_urls(url_collection):
    """
    Function to parse a collection of URLs
    
    INPUT
    - url_collection: the URL object from the tweet object or sub-object (retweet_status or quoted_status)
    """
    
    url_count = len(url_collection)
    if url_count > 0:
        urls_list = []
        urls_expanded_list = []
        for url_set in url_collection:
            urls_list.append(url_set['url'])
            urls_expanded_list.append(url_set['expanded_url'])
        url = ",".join(urls_list)
        url_expanded = ",".join(urls_expanded_list)
    else:
        url = ""
        url_expanded = ""
    return url, url_expanded, url_count

# Parse tweets
tweet_json_files = os.listdir(outpath)
tweet_json_files = [file for file in tweet_json_files if re.match('.*\.json', file)] #this will include tweets pulled down earlier
news_tweets = pd.DataFrame()
for file in tweet_json_files:
    source_tweets = tweet_parser(filename = outpath + file)
    news_tweets = news_tweets.append(source_tweets, ignore_index = True)
    del source_tweets
    print("DONE: " + file)
 
# Drop duplicates (in case we pulled tweets from same exact time before)
news_tweets = news_tweets.drop_duplicates(subset = ['user_id', 'tweet_id'])
news_tweets.to_csv(outpath + 'news_source_tweets.csv', index = False)