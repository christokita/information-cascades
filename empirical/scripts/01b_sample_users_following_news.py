#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Aug  7 12:55:35 2020

@author: ChrisTokita, modified from Matt R. Deverna

SCRIPT
Get 1,000 followers of each of our four news sources of interest.
We will start with a broader 2,500 per news source and narrow this down with machine learning
such that we get 1k liberals from CBS & Vox and 1k conservatives from USA Today & Washington Examiner.
"""

####################
# Load packages and set path to data
####################
import pandas as pd
import numpy as np
import re
import os

# Path to datafiles
path_to_all_followers = '../data/news_source_followers/'
path_to_users_with_errors = '../data_derived/users_initial_errors/'
out_path = '../data_derived/monitored_users/'


####################
# Load in data
####################
# List files of interest
data_files = os.listdir(path_to_all_followers)
data_files = [f for f in data_files if re.search('followerinfo', f)]

# Function to bind data sets
def load_news_followers(news_source, data_files):
    
    # Relevant files
    relevant_files = [f for f in data_files if re.search(news_source, f)]
    all_data = None
    
    # Loop through files, load, and bind
    for file in relevant_files:
        df = pd.read_csv(path_to_all_followers + file, 
                         dtype = {'user_id': object, 'location': str, 'verified': bool, 'protected': bool},
                         lineterminator = '\n') #this prevents read errors from other symbols (e.g., '\r')
        if all_data is None:
            all_data = df
        else:
            all_data = all_data.append(df, ignore_index = True)
    return all_data

# Go through news sources and bind into large dataset
news_sources = ['cbsnews', 'usatoday', 'voxdotcom', 'dcexaminer']
news_followers = None
for news_source in news_sources:
    source_followers = load_news_followers(news_source, data_files)
    source_followers['news_source'] = news_source
    if news_followers is None:
        news_followers = source_followers
    else:
        news_followers = news_followers.append(source_followers, ignore_index = True)
    del source_followers
        
    
####################
# Filter down to users of interest
####################
# Onlys select users with 100 to 1,000 followers
filtered_followers = news_followers[(news_followers.followers >= 100) & (news_followers.followers <= 1000)]

# Onlys select users with 25 or more friends
filtered_followers = filtered_followers[filtered_followers.friends >= 25]

# Onlys select users with 100 or more tweets
filtered_followers = filtered_followers[filtered_followers.statuses >= 100]

# Remove verified and protected accounts
filtered_followers = filtered_followers[~filtered_followers.verified]
filtered_followers = filtered_followers[~filtered_followers.protected]

# Grab only users that appear to be in the USA based on "USA", state, or major city listing
filtered_followers['location'] = filtered_followers['location'].astype(str)
states_abbr = ["AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DC", "DE", "FL", "GA", "HI", "ID", 
               "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD", "MA", "MI", "MN", "MS", "MO", 
               "MT", "NE", "NV", "NH", "NJ", "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", 
               "RI", "SC", "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY", "USA"]
states_full = ["Alaska", "Alabama", "Arkansas", "American Samoa", "Arizona", 
               "California", "Colorado", "Connecticut", "District ", "of Columbia", 
               "Delaware", "Florida", "Georgia", "Guam", "Hawaii", "Iowa", "Idaho", 
               "Illinois", "Indiana", "Kansas", "Kentucky", "Louisiana", "Massachusetts", 
               "Maryland", "Maine", "Michigan", "Minnesota", "Missouri", "Mississippi", 
               "Montana", "North Carolina", "North Dakota", "Nebraska", "New Hampshire", 
               "New Jersey", "New Mexico", "Nevada", "New York", "Ohio", "Oklahoma", 
               "Oregon", "Pennsylvania", "Puerto Rico", "Rhode Island", "South Carolina", 
               "South Dakota", "Tennessee", "Texas", "Utah", "Virginia", "Virgin Islands", 
               "Vermont", "Washington", "Wisconsin", "West Virginia", "Wyoming", "United States"]
top_200_cities = ["New York", "Los Angeles", "Chicago", "Houston", "Phoenix", "Philadelphia", "San Antonio", 
                  "San Diego", "Dallas", "San Jose", "Austin", "Jacksonville", "Fort Worth", "Columbus", 
                  "Charlotte", "San Francisco", "Indianapolis", "Seattle", "Denver", "Washington", "Boston", 
                  "El Paso", "Nashville", "Detroit", "Oklahoma City", "Portland", "Las Vegas", "Memphis", 
                  "Louisville", "Baltimore", "Milwaukee", "Albuquerque", "Tucson", "Fresno", "Mesa", "Sacramento",
                  "Atlanta", "Kansas City", "Colorado Springs", "Omaha", "Raleigh", "Miami", "Long Beach", 
                  "Virginia Beach", "Oakland", "Minneapolis", "Tulsa", "Tampa", "Arlington", "New Orleans", 
                  "Wichita", "Bakersfield", "Cleveland", "Aurora", "Anaheim", "Honolulu", "Santa Ana", "Riverside",
                  "Corpus Christi", "Lexington", "Henderson", "Stockton", "Saint Paul", "Cincinnati", "St. Louis", 
                  "Pittsburgh", "Greensboro", "Lincoln", "Anchorage", "Plano", "Orlando", "Irvine", "Newark", 
                  "Durham", "Chula Vista", "Toledo", "Fort Wayne", "St. Petersburg", "Laredo", "Jersey City", 
                  "Chandler", "Madison", "Lubbock", "Scottsdale", "Reno", "Buffalo", "Gilbert", "Glendale", 
                  "North Las Vegas", "Winston–Salem", "Chesapeake", "Norfolk", "Fremont", "Garland", "Irving", 
                  "Hialeah", "Richmond", "Boise", "Spokane", "Baton Rouge", "Tacoma", "San Bernardino", "Modesto",
                  "Fontana", "Des Moines", "Moreno Valley", "Santa Clarita", "Fayetteville", "Birmingham", "Oxnard",
                  "Rochester", "Port St. Lucie", "Grand Rapids", "Huntsville", "Salt Lake City", "Frisco", "Yonkers", 
                  "Amarillo", "Glendale", "Huntington Beach", "McKinney", "Montgomery", "Augusta", "Aurora", "Akron",
                  "Little Rock", "Tempe", "Columbus", "Overland Park", "Grand Prairie", "Tallahassee", "Cape Coral", 
                  "Mobile", "Knoxville", "Shreveport", "Worcester", "Ontario", "Vancouver", "Sioux Falls", "Chattanooga", 
                  "Brownsville", "Fort Lauderdale", "Providence", "Newport News", "Rancho Cucamonga", "Santa Rosa", 
                  "Peoria", "Oceanside", "Elk Grove", "Salem", "Pembroke Pines", "Eugene", "Garden Grove", "Cary", 
                  "Fort Collins", "Corona", "Springfield", "Jackson", "Alexandria", "Hayward", "Clarksville", "Lakewood",
                  "Lancaster", "Salinas", "Palmdale", "Hollywood", "Springfield", "Macon", "Kansas City", "Sunnyvale", 
                  "Pomona", "Killeen", "Escondido", "Pasadena", "Naperville", "Bellevue", "Joliet", "Murfreesboro",
                  "Midland", "Rockford", "Paterson", "Savannah", "Bridgeport", "Torrance", "McAllen", "Syracuse",
                  "Surprise", "Denton", "Roseville", "Thornton", "Miramar", "Pasadena", "Mesquite", "Olathe", 
                  "Dayton", "Carrollton", "Waco", "Orange", "Fullerton", "Charleston"]
states_abbr = "|".join(states_abbr)
states_full = "|".join(states_full)
top_200_cities = "|".join(top_200_cities)
usa_pattern = states_abbr + "|" + states_full + "|" + top_200_cities #create giant matching pattern
filtered_followers = filtered_followers[filtered_followers['location'].str.contains(usa_pattern)] #filter here

# Some users follow several of these sources. 
# Let's drop them all in order to prevent some of users from being attached to multiple news sources of interest.
filtered_followers = filtered_followers.drop_duplicates(subset = ['user_id_str'], keep = False)
 
# Filter out users who inadvertently match the above patterns
country_list = np.genfromtxt("../data_derived/filtering_news_followers/country_list.txt", dtype = str, delimiter = "\n")
country_list = np.char.upper(country_list)
country_list = "|".join(country_list)
noncase_sensitive_bad_matches = ["canada", #matches on top city names like Vancouver and Ontario
                                 "ottawa", #due to matches with ontario
                                 "toronto", #same as above
                                 "hong kong", 
                                 "tokyo", #match on KY
                                 "PLANET EARTH"] #matches on NE, AR, etc.
noncase_sensitive_bad_matches = "|".join(noncase_sensitive_bad_matches)
filtered_followers = filtered_followers[~filtered_followers['location'].str.contains(country_list)] #filter here
filtered_followers = filtered_followers[~filtered_followers['location'].str.contains(noncase_sensitive_bad_matches, case = False)] #filter here


####################
# Sample an initial 3,000 per news source
####################
selected_followers = filtered_followers.groupby(['news_source']).sample(n = 3000, random_state = 323)

# Write out
selected_followers.to_csv(out_path + 'monitored_users_preliminary.csv', index = False)


####################
# In our selected list of users, replace those for whom we couldn't get full follower lists
####################
"""
Some of the above users had since made their account protected or possibly deleted their account.
Thus, we couldn't get all 3,000 follower ID lists for each pool of users. 
For those we couldn't get their follower list, we will replace them with users from the remaining eligible pool.
"""

# Get the remaining pool of eligble users
not_selected = filtered_followers[~filtered_followers['user_id_str'].isin(selected_followers['user_id_str'])]

# Load in our users who returned errors when pulling their follower ID list
error_files = os.listdir(path_to_users_with_errors)
error_users = None
for file in error_files:
    data = pd.read_csv(path_to_users_with_errors + file, dtype = {'user_id': object})
    if error_users is None:
        error_users = data
    else:
        error_users = error_users.append(data, ignore_index = True)
    del data
    
# Filter out these users from our selected set of users, determine how many new users we need to sample
selected_followers = selected_followers[~selected_followers['user_id_str'].isin(error_users['user_id_str'])]
needed_new_users = 3000 - selected_followers['news_source'].value_counts()

# Sample these new rows
not_selected = not_selected[~not_selected['user_id_str'].isin(error_users['user_id_str'])]
replacement_followers = None
for news_source in news_sources:
    eligible_outlet_followers = not_selected[not_selected.news_source == news_source]
    n = needed_new_users.loc[news_source]
    sampled_followers = eligible_outlet_followers.sample(n = n, random_state = 323)
    if replacement_followers is None:
        replacement_followers = sampled_followers
    else:
        replacement_followers = replacement_followers.append(sampled_followers, ignore_index = True)
    del sampled_followers
    
# Append to our selected user group and write out to file
selected_followers = selected_followers.append(replacement_followers, ignore_index = True)
selected_followers = selected_followers.sort_values(by = 'news_source').reset_index(drop = True)

# Remove carriage returns from description column because these cause errors when reading in as CSV
selected_followers['description'] = selected_followers['description'].str.replace('\r', ' ')

# Write out to file
selected_followers.to_csv(out_path + 'monitored_users_preliminary.csv', index = False)
