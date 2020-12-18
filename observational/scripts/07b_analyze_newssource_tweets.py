#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Dec  7 15:58:00 2020

@author: ChrisTokita

SCRIPT:
Analyze tweets from news sources to determine correlation/similarity in coverage.
"""

####################
# Load packages, set paths to data
####################
import pandas as pd
import numpy as np
import nltk
import sklearn.feature_extraction as fe
import sklearn.metrics as met
import matplotlib.pyplot as plt


# High-level data directory and outpath
data_directory = '/Volumes/CKT-DATA/information-cascades/observational/'

# Path to data
tweet_file = data_directory + 'data/news_source_tweets/news_source_tweets.csv'
outpath = data_directory + 'data_derived/news_source_tweets/'

# Load tweet data
tweets = pd.read_csv(tweet_file, dtype = {'user_id': object, 'tweet_id': object})
tweets['quoted_text'] = tweets['quoted_text'].astype(str).replace(r"^nan$", "", regex = True)


####################
# Prep data: clean tweets, tokenize words, stem words
####################
# Create month-day category
tweets['tweet_time'] = pd.to_datetime(tweets['tweet_time'], format = '%a %b %d %H:%M:%S %z %Y')
tweets['tweet_time_EST'] = tweets['tweet_time'].dt.tz_convert('America/New_York')
tweets['tweet_month'] = tweets['tweet_time'].dt.strftime("%Y-%m")
tweets['tweet_day'] = tweets['tweet_time'].dt.strftime("%Y-%m-%d")
tweets['tweet_hourbreakdown'] = tweets['tweet_time'].dt.hour // 12
tweets['tweet_12hour'] = tweets['tweet_day'].astype(str) + "_" + tweets['tweet_hourbreakdown'].astype(str) + "qtr"

# Select time period of analysis
tweets['tweet_period'] = tweets['tweet_day']

# Add quoted text to full tweet text
tweets['all_text'] = tweets['tweet_text'] + tweets['quoted_text']

# Remove URLs and non-words
tweets['all_text'] = tweets['all_text'].str.lower()
tweets['all_text'] = tweets['all_text'].replace(r"https?:\/\/.*[\r\n]*", "", regex = True) #remove URLs
tweets['all_text'] = tweets['all_text'].replace(r"#\w+", "", regex = True) #remove hashtags
tweets['all_text'] = tweets['all_text'].replace(r"\n", " ", regex = True) #replace line breaks with spaces
tweets['all_text'] = tweets['all_text'].replace(r"[^a-zA-z ]", " ", regex = True) #remove punctuation and numbers
tweets['all_text'] = tweets['all_text'].replace(r"\s+", " ", regex = True) #remove extra spaces

# Create cleaned word list for each tweet
tweets['cleaned_words'] = np.nan
for index, row in tweets.iterrows():
    # Tokenize words
    tokenized = nltk.tokenize.word_tokenize(row['all_text'])
    
    # Remove stop words
    stop_words = set(nltk.corpus.stopwords.words('english')) 
    no_stop_words = [word for word in tokenized if word not in stop_words]
    
    # Stem words
    stemmer = nltk.stem.PorterStemmer()
    stemmed = [stemmer.stem(word) for word in no_stop_words]
    
    # Add cleaned word list
    tweets.loc[index, 'cleaned_words'] = ' '.join(stemmed)


# Gather by time period of tweet
tweets['time_period_words'] = tweets.groupby(['user_name', 'tweet_period'])['cleaned_words'].transform(lambda x: ' '.join(x))
news_words = tweets[['user_name', 'tweet_period', 'time_period_words']].drop_duplicates()


####################
# Calcualte baseline similarity of AP against itself
####################
'''
We will randomly split each set of tweets from the same time period into two sets. 
We will then compare the same time period against itselt.
'''

# Grab AP tweets and split into two samples
AP_tweets = tweets[tweets.user_name == "AP"].copy()
AP_tweets['sub_sample'] = AP_tweets.groupby(['tweet_period'])['user_name'].transform(lambda x: np.random.choice([0, 1], size = len(x), replace = True))

# Gather by time period of tweet
AP_tweets['time_period_words'] = AP_tweets.groupby(['tweet_period', 'sub_sample'])['cleaned_words'].transform(lambda x: ' '.join(x))
AP_words = AP_tweets[['user_name', 'tweet_period', 'sub_sample', 'time_period_words']].drop_duplicates()
AP_words = AP_words.sort_values('tweet_period')

# Vectorise the data, calculate similarity
words = AP_words['time_period_words']
vec = fe.text.TfidfVectorizer()
X = vec.fit_transform(words)
similarity_AP = met.pairwise.cosine_similarity(X)

# Function to determine similarity of AP against itself 
def grab_same_time_similairty_AP(similarity_matrix, tweet_data):
    similairty_scores = np.array([])
    for period in tweet_data['tweet_period'].unique():
        source_0_row = np.where( (tweet_data['sub_sample'] == 0) & (tweet_data['tweet_period'] == period) )[0]
        source_1_row = np.where( (tweet_data['sub_sample'] == 1) & (tweet_data['tweet_period'] == period) )[0]
        similairty_scores = np.append(similairty_scores, similarity_matrix[source_0_row, source_1_row])
    return similairty_scores
        
# Determine baseline similairity
baseline_similarity = grab_same_time_similairty_AP(similarity_AP, AP_words)

####################
# Calcualte cosine similarity between day of coverage for each news source
####################
# Vectorise the data
words = news_words['time_period_words']
vec = fe.text.TfidfVectorizer()
X = vec.fit_transform(words)

# Calculate the pairwise cosine similarities (depending on the amount of data that you are going to have this could take a while)
S = met.pairwise.cosine_similarity(X)

# Function to grab appropriate similairty scores from matrix
def grab_same_time_similairty(similarity_matrix, tweet_data, news_source_1, news_source_2):
    similairty_scores = np.array([])
    mutual_time_periods = np.intersect1d(tweet_data.tweet_period[tweet_data.user_name == news_source_1], tweet_data.tweet_period[tweet_data.user_name == news_source_1])
    for period in mutual_time_periods:
        source_1_row = np.where( (tweet_data['user_name'] == news_source_1) & (tweet_data['tweet_period'] == period) )[0]
        source_2_row = np.where( (tweet_data['user_name'] == news_source_2) & (tweet_data['tweet_period'] == period) )[0]
        similairty_scores = np.append(similairty_scores, similarity_matrix[source_1_row, source_2_row])
    return similairty_scores

# See similarity between AP and Reuters, our control news sources that we anticipate should be the most correlated.
reuters_similarity = grab_same_time_similairty(S, news_words, news_source_1 = "AP", news_source_2 = "Reuters")

# Similarity between our various news sources and AP
dcexaminer_similarity = grab_same_time_similairty(S, news_words, news_source_1 = "AP", news_source_2 = "dcexaminer")
usatoday_similarity = grab_same_time_similairty(S, news_words, news_source_1 = "AP", news_source_2 = "USATODAY")
vox_similarity = grab_same_time_similairty(S, news_words, news_source_1 = "AP", news_source_2 = "voxdotcom")
cbs_similarity = grab_same_time_similairty(S, news_words, news_source_1 = "AP", news_source_2 = "CBSNews")

# Plot similarity scores
plt.hist(dcexaminer_similarity, bins = 30, color = "red", alpha = 0.5)
plt.hist(vox_similarity, bins = 30, color = "blue", alpha = 0.5)
plt.hist(usatoday_similarity, bins = 30, color = "orange", alpha = 0.5)
plt.hist(cbs_similarity, bins = 30, color = "green", alpha = 0.5)


####################
# Attempt to determine correlation
####################
# Function to convert cosine similarity into our correlation metric
def calculate_gamma_correlation(similarity_scores, baseline_similarity_scores):
    mean_similarity = np.mean(similarity_scores)
    mean_baseline = np.mean(baseline_similarity_scores)
    normed_scores = mean_similarity / mean_baseline
    correlation_metric = 2*normed_scores - 1
    return correlation_metric

# Calculate gammas 
gamma_reuters = calculate_gamma_correlation(reuters_similarity, baseline_similarity)
gamma_usatoday = calculate_gamma_correlation(usatoday_similarity, baseline_similarity)
gamma_cbs = calculate_gamma_correlation(cbs_similarity, baseline_similarity)
gamma_dcexaminer = calculate_gamma_correlation(dcexaminer_similarity, baseline_similarity)
gamma_vox = calculate_gamma_correlation(vox_similarity, baseline_similarity)

# Output similarity scores
news_correlations = pd.DataFrame([['AP', 'AP', np.mean(baseline_similarity), 1.0],
                                 ['Reuters', 'AP', np.mean(reuters_similarity), gamma_reuters],
                                 ['USATODAY', 'AP', np.mean(usatoday_similarity), gamma_usatoday],
                                 ['CBSNews', 'AP', np.mean(cbs_similarity), gamma_cbs],
                                 ['dcexaminer', 'AP', np.mean(dcexaminer_similarity), gamma_dcexaminer],
                                 ['voxdotcom', 'AP', np.mean(vox_similarity), gamma_vox]],
                                 columns = ['news_source', 'reference_news_source', 'mean_cos_similarity', 'estimated_gamma'])
news_correlations.to_csv(outpath + 'estimated_gamma_cosinesim.csv', index = False)

