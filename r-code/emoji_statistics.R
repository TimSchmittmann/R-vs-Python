emoji_statistics = c()

emoji_statistics.sort_emoji_count_by_value = function(emoji_cnt) {
  sorted_by_value = order(emoji_cnt)
  return(sorted_by_value)
}

emoji_statistics.count_emojis_in_tweets_labels = function(tweet_file) {
  emoji_cnt = c()
  df = read.csv(tweet_file, sep=';', col.names = c("id","text"), colClasses = c("integer64", "character"))
  within(df, target<-data.frame(do.call('rbind', strsplit(as.character(target), ',', fixed=TRUE))))
  table(df)
  return(table(df))
}

emoji_statistics.write_emoji_cnt_file_from_label_extracted_tweet_file = function(tweet_file, emoji_cnt_file) {
  emoji_cnt = emoji_statistics.count_emojis_in_tweets_labels(tweet_file)
  emoji_cnt = emoji_statistics.sort_emoji_count_by_value(emoji_cnt)

  emoji_statistics.write_emoji_count(emoji_cnt, emoji_cnt_file)
}