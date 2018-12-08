# -*- coding: utf-8 -*-
'''

@author: Tim Schmittmann
'''

from __future__ import print_function
import twitter
import time
from langdetect import detect
import csv
import config
import math
import sys
import subprocess
from enum import Enum

Mode = Enum('Mode', 'PAST RECENT')
# Create an Api instance.
api = twitter.Api(consumer_key=config.CONSUMER_KEY,
                  consumer_secret=config.CONSUMER_SECRET,
                  access_token_key=config.ACCESS_TOKEN,
                  access_token_secret=config.ACCESS_TOKEN_SECRET)

emoji_cnt_csv_path = "data/manual_settings/emoji_cnt_used_for_twitter_api_requests.csv"
tweets_write_csv_base_path = "data/emoji_tweets/tweets_q3_emojis_"
tweets_write_csv_ext = ".csv"
mode = Mode.RECENT

def read_max_id(tweet_csv_filepath, mode=Mode.PAST):
    max_id = 9999999999999999999

    if mode == Mode.PAST:
        # go into the past starting from oldest tweet in file or starting from most recent if there is no file
        try:
            with open(tweet_csv_filepath, 'r', encoding='utf-8', newline='') as csvfile:
                reader = csv.reader(csvfile, delimiter=';')
                for row in reader:
                    try:
                        max_id = min(int(row[0]), max_id)
                    except:
                        pass
        except Exception as e:
            print(str(e))
    return max_id

    #return False # most recent tweets only

def read_min_id(tweet_csv_filepath, mode=Mode.PAST):
    if mode == Mode.PAST:
        # go into the past as far as API allows
        return 0

    # go into the past until you find already processed tweets
    # in that case min_id is the highest tweet id found in the csv
    min_id = 0
    try:
        with open(tweet_csv_filepath, 'r', encoding='utf-8', newline='') as csvfile:
            reader = csv.reader(csvfile, delimiter=';')
            for row in reader:
                try:
                    min_id = max(int(row[0]), min_id)
                except:
                    pass
    except Exception as e:
        print(str(e))
    return min_id

def get_all_emojis(emoji_cnt_csv_path):
    emojis = []
    with open(emoji_cnt_csv_path, 'r', encoding='utf-8', newline='') as csvfile:
        reader = csv.reader(csvfile, delimiter=';')
        for row in reader:
            emojis.append(row[0])
    return emojis

def init_and_exec_requests_and_writes(tweets_write_csv_path, query_emojis, mode=Mode.PAST):
    max_id = read_max_id(tweets_write_csv_path, mode)
    min_id = read_min_id(tweets_write_csv_path, mode)
    print("MaxID: "+str(max_id))
    print("MinID: "+str(min_id))

    fieldnames = [
        'tweet_id',
        'tweet_full_text',
        'tweet_created_at',
        'tweet_is_quote_status',
        'tweet_retweet_count',
        'tweet_favorite_count',
        'tweet_favorited',
        'tweet_retweeted',
        'tweet_possibly_sensitive',

        'user_id',
        'user_description',
        'user_followers_count',
        'user_friends_count',
        'user_listed_count',
        'user_favourites_count',
        'user_statuses_count',
    ]

    with open(tweets_write_csv_path, 'a', encoding='utf-8', newline='', buffering=1) as csvfile:
        writer = csv.DictWriter(csvfile, delimiter=';', fieldnames=fieldnames,
                            quoting=csv.QUOTE_MINIMAL)
        writer.writeheader()
        request_tweets(min_id, max_id, query_emojis, lambda search_result: write_tweet(writer, search_result))

def build_request_query(min_id, max_id, query_emojis):
    q = "%20OR%20".join(query_emojis)
    query = "lang=de&q="+q+"%20-filter%3Aretweets%20-filter%3Areplies&result_type=recent&count=100&tweet_mode=extended"
    #query = "lang=de&q=a%20OR%20b%20OR%20c%20OR%20d%20OR%20e%20OR%20f%20OR%20g%20OR%20h%20OR%20i%20OR%20j%20OR%20k%20OR%20l%20OR%20m%20OR%20n%20OR%20o%20OR%20p%20OR%20q%20OR%20r%20OR%20s%20OR%20t%20OR%20u%20OR%20v%20OR%20w%20OR%20x%20OR%20y%20OR%20z%20-filter%3Aretweets%20-filter%3Areplies&result_type=recent&count=100"
    if max_id is not False:
        query += "&max_id="+str(max_id)
    if min_id is not False:
        query += "&since_id="+str(min_id)
    return query

def request_tweets(min_id, max_id, query_emojis, write_cb, nr_of_requests = 999999):
    for i in range(nr_of_requests):
        print("Request "+str(i))
        query = build_request_query(min_id, max_id, query_emojis)
        print(query)
        try:
            search_result = api.GetSearch(raw_query=query)
            if max_id is not False:
                # Move further into the past with each request
                max_id = search_result[-1].id - 1
            if(len(search_result) == 0):
                print("Reached already processed tweets")
                break;
            # elif min_id is not False:
                # Get the most up to date tweets per request
                # min_id = search_result[0].id + 1
            #print(max_id)
            #print([s for s in search_result])
            write_cb(search_result)
            time.sleep(5)
        except Exception as e:
            print(str(e))
            if str(e) == 'list index out of range':
                break;
            time.sleep(30)

def write_tweet(writer, search_result):
    for tweet_dict in search_result:
        tweet_dict = tweet_dict.AsDict()
        try:
            if detect(tweet_dict['full_text']) != 'de':
                continue
        except:
            print("This text throws an error:", tweet_dict['full_text'])
            continue

        tweet = {}
        if 'id' in tweet_dict:
            tweet['tweet_id'] = tweet_dict['id']
        if 'full_text' in tweet_dict:
            tweet['tweet_full_text'] = tweet_dict['full_text']
        if 'created_at' in tweet_dict:
            tweet['tweet_created_at'] = tweet_dict['created_at']
        if 'is_quote_status' in tweet_dict:
            tweet['tweet_is_quote_status'] = tweet_dict['is_quote_status']
        if 'retweet_count' in tweet_dict:
            tweet['tweet_retweet_count'] = tweet_dict['retweet_count']
        if 'favorite_count' in tweet_dict:
            tweet['tweet_favorite_count'] = tweet_dict['favorite_count']
        if 'favorited' in tweet_dict:
            tweet['tweet_favorited'] = tweet_dict['favorited']
        if 'retweeted' in tweet_dict:
            tweet['tweet_retweeted'] = tweet_dict['retweeted']
        if 'possibly_sensitive' in tweet_dict:
            tweet['tweet_possibly_sensitive'] = tweet_dict['possibly_sensitive']
            
        if 'id' in tweet_dict['user']:
            tweet['user_id'] = tweet_dict['user']['id']
        if 'description' in tweet_dict['user']:
            tweet['user_description'] = tweet_dict['user']['description']
        if 'followers_count' in tweet_dict['user']:
            tweet['user_followers_count'] = tweet_dict['user']['followers_count']
        if 'friends_count' in tweet_dict['user']:
            tweet['user_friends_count'] = tweet_dict['user']['friends_count']
        if 'listed_count' in tweet_dict['user']:
            tweet['user_listed_count'] = tweet_dict['user']['listed_count']
        if 'favourites_count' in tweet_dict['user']:
            tweet['user_favourites_count'] = tweet_dict['user']['favourites_count']
        if 'statuses_count' in tweet_dict['user']:
            tweet['user_statuses_count'] = tweet_dict['user']['statuses_count']
        
        #print(str(tweet['id'])+": "+tweet_dict['created_at'])
        writer.writerow(tweet)
    #           fieldnames.update(tweet.keys())
    #            tweets.append(tweet)

def extract_inner_tweet_fields():
            '''
        for key in tweetDict:
            if key == 'user':
                for innerKey in tweetDict[key]:
                    tweet[key + "_" + innerKey] = tweetDict[key][innerKey]
            elif key == 'urls' or key == 'user_mentions':
                for j in range(len(tweetDict[key])):
                    for innerKey in tweetDict[key][j]:
                        tweet[key + "_" + str(j) + "_" + innerKey] = tweetDict[key][j][innerKey]
            else:
                tweet[key] = tweetDict[key]
        '''

def main(emoji_cnt_csv_path, tweets_write_csv_base_path, tweets_write_csv_ext, mode):
    emojis = get_all_emojis(emoji_cnt_csv_path)

    for j in range(0, math.ceil(len(emojis) / 45)):
        from_emoji = j*45
        to_emoji = min((j+1)*45, len(emojis))

        print("From emoji "+str(from_emoji)+" to emoji "+str(to_emoji))
        query_emojis = emojis[from_emoji:to_emoji]

        if len(query_emojis) > 0:
            tweets_write_csv_path = tweets_write_csv_base_path+str(from_emoji)+"-"+str(to_emoji)+tweets_write_csv_ext
            init_and_exec_requests_and_writes(tweets_write_csv_path, query_emojis, mode)

if __name__ == '__main__':
    while True:
        main(emoji_cnt_csv_path, tweets_write_csv_base_path, tweets_write_csv_ext, mode)
    