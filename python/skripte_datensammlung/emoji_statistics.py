# -*- coding: utf-8 -*-
'''

@author: Tim Schmittmann
'''
import emoji
import regex
import csv
import emoji_helper

def sort_emoji_count_by_value(emoji_cnt):
    sorted_by_value = sorted(emoji_cnt.items(), key=lambda kv: kv[1])
    sorted_by_value.reverse()
    return sorted_by_value

def display_emoji_count(emoji_cnt):
    for emoji_tuple in emoji_cnt:
        print(emoji_tuple[0]+": "+str(emoji_tuple[1]))

def write_emoji_count(emoji_cnt, emoji_cnt_file):
    with open(emoji_cnt_file, 'w', encoding='utf-8', newline='') as csvfile:
        writer = csv.writer(csvfile, delimiter=';',
                            quoting=csv.QUOTE_MINIMAL)
        #writer.writeheader()
        writer.writerows(emoji_cnt)

def count_emojis_in_tweets_labels(tweet_file):
    emoji_cnt = {}
    with open(tweet_file, 'r', encoding='utf-8', newline='') as csvfile:
        reader = csv.reader(csvfile, delimiter=';')
        i = 0
        for row in reader:
            i += 1
            if i == 1 or len(row) < 2:
                continue
            for emoji in row[-1].split(','):
                if len(emoji) == 0:
                    continue
                try:
                    if emoji not in emoji_cnt:
                        emoji_cnt[emoji] = 0
                    emoji_cnt[emoji] += 1
                except Exception as e:
                    print(str(e))
    return emoji_cnt


def write_emoji_cnt_file_from_label_extracted_tweet_file(tweet_file, emoji_cnt_file):
    emoji_cnt = count_emojis_in_tweets_labels(tweet_file)
    emoji_cnt = sort_emoji_count_by_value(emoji_cnt)

    write_emoji_count(emoji_cnt, emoji_cnt_file)
    #display_emoji_count(emoji_cnt)