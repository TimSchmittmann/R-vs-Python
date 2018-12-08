# -*- coding: utf-8 -*-
'''

@author: Tim Schmittmann
'''
import emoji
import regex
import csv
import time

def split_count(text):
    emoji_list = []
    data = regex.findall(r'\X', text)
    for word in data:
        if any(char in emoji.UNICODE_EMOJI for char in word):
            emoji_list.append(word)

    return emoji_list

def get_emoji_mappings(emoji_mappings_file):
    emoji_mappings = {}
    with open(emoji_mappings_file, 'r', encoding='utf-8-sig', newline='') as csvfile:
        reader = csv.reader(csvfile, delimiter=';')
        i = 0
        for row in reader:
            i += 1
            if len(row) < 2:
                if len(row) < 1:
                    #print("skip empty row: ",i, row)
                    continue
                print("Error. Only single col in row: ",i, row)
                continue
            for emoji in row[0].split(','):
                emoji = emoji.strip(u'\u200d')
                try:
                    if(int(row[1]) > 0):
                        emoji_mappings[emoji] = row[0].strip(u'\u200d')
                except:
                    emoji_mappings[emoji] = row[1].strip(u'\u200d')
    return emoji_mappings

def write_missing_emojis_in_mapping_file(tweet_file, emoji_mappings_file):
    emoji_mappings = get_emoji_mappings(emoji_mappings_file)
    add_rows = {}
    with open(tweet_file, 'r', encoding='utf-8', newline='') as csvfile:
        reader = csv.reader(csvfile, delimiter=';')
        i = 0
        for row in reader:
            i += 1
            if i == 1:
                continue
            for emoji in row[-1].split(','):
                if emoji not in emoji_mappings:
                    add_rows[emoji] = [emoji,emoji]

    with open(emoji_mappings_file, 'a', encoding='utf-8', newline='', buffering=1) as mappings_file:
        writer = csv.writer(mappings_file, delimiter=';',
                        quoting=csv.QUOTE_MINIMAL)
        for emoji_row in add_rows.values():
            writer.writerow(emoji_row)

def get_emoji_excludes_from_file(emoji_excludes_file):
    excludes = {}
    with open(emoji_excludes_file, 'r', encoding='utf-8-sig', newline='') as excludes_file:
        reader = csv.reader(excludes_file, delimiter=';')
        for row in reader:
            try:
                excludes[row[0].strip(u'\u200d')] = 1
            except Exception as e:
                print(str(e))
    return excludes

if __name__ == '__main__':
    t1 = time.time()
    write_missing_emojis_in_mapping_file(tweet_file, emoji_mappings_file)
    #emoji_mappings = get_emoji_mappings(emoji_mappings_file)
#     tweets = map_emojis_in_tweets(tweet_file, emoji_mappings)
    #print(tweets)
    print("Extraction takes ",time.time()-t1,"s")
