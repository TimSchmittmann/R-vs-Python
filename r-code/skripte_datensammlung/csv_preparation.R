# @author: Tim Schmittmann
#install.packages("Unicode")

source("emoji_helper.R")
source("csv_fixer.R")
source("emoji_statistics.R")
library(bit64)
library(dplyr)
library(stringr)
library(rvest)
library(Unicode)
library(tm)
library(ggplot2)

start_at = 0

# important settings. Excludes and Mappings are done by hand
excludes_filepath = "../data/manual_settings/emojis_to_exclude_1.csv"
# careful, this file gets overwritten by write_missing_emojis_in_mapping_file
emoji_mappings_filepath = "../data/manual_settings/emoji_mappings_2.csv"
csv_to_fix = "../data/trainingssets/top_1000_emoji_tweets_03_12_18"
emoji_cnt_infix = "_emoji_cnt"

# less important. Filenames for auto-generated files
read_initial_ext = ".csv"
fixed_line_endings_ext = "_1_fixed_line_endings.csv"
deduplicated_ext = "_2_deduplicated.csv"
sorted_ext = "_3_sorted.csv"
similar_removed_ext = "_4_removed_similar.csv"
labels_extracted_ext = "_5_labels_extracted.csv"
labels_mapped_ext = "_6_labels_mapped.csv"
labels_excluded_ext = "_7_labels_excluded.csv"

excludes = emoji_helper.get_emoji_excludes_from_file(excludes_filepath)

if(start_at < 1) { 
  csv_fixer.remove_linebreaks(csv_to_fix, read_initial_ext, fixed_line_endings_ext) 
  }
if(start_at < 2) { csv_fixer.remove_duplicates(csv_to_fix, fixed_line_endings_ext, deduplicated_ext) }
if(start_at < 3) { csv_fixer.sort_by_tweet_id(csv_to_fix, deduplicated_ext, sorted_ext) }
if(start_at < 4) { csv_fixer.remove_similar(csv_to_fix, sorted_ext, similar_removed_ext) }
#if(start_at < 5) { csv_fixer.show_similar_tweets_example(csv_to_fix, sorted_ext) }
if(start_at < 6) { csv_fixer.extract_emoji_labels(csv_to_fix, similar_removed_ext, labels_extracted_ext) }

csv_fixer.map_emoji_labels(csv_to_fix, labels_extracted_ext, labels_mapped_ext, emoji_mappings_filepath) 

if(start_at < 7) {
  # Count number of occurences in tweets (max +1 per tweet per emoji) for each emoji
  # Only look at final csv file
  emoji_statistics.write_emoji_cnt_file_from_label_extracted_tweet_file(paste0(csv_to_fix,labels_mapped_ext), paste0(csv_to_fix,emoji_cnt_infix,labels_mapped_ext))
}