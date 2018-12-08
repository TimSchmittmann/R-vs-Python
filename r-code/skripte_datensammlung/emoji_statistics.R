emoji_statistics = c()

emoji_statistics.sort_emoji_count_by_value = function(emoji_cnt) {
  emoji_cnt = emoji_cnt[order(emoji_cnt$cnt, decreasing = TRUE),]
  return(emoji_cnt)
}

emoji_statistics.count_emojis_in_tweets_labels = function(tweet_file) {
  emoji_cnt = list()
  df = read.csv(tweet_file, sep=';', col.names = c("id","text","target"), colClasses = c("integer64", "character",  "character"))
  for(i in 1:nrow(df)) {
    for(emoji in strsplit(df[i,"target"], ',', fixed=TRUE)[[1]]) {
      if(emoji %in% names(emoji_cnt)) {
        emoji_cnt[[emoji]] = emoji_cnt[[emoji]] + 1
      } else {
        emoji_cnt[[emoji]] = 1
      }
    }
  }
  return(data.frame(emojis=names(emoji_cnt), cnt=unlist(emoji_cnt)))
}

emoji_statistics.write_emoji_cnt_file_from_label_extracted_tweet_file = function(tweet_file, emoji_cnt_file) {
  emoji_cnt = emoji_statistics.count_emojis_in_tweets_labels(tweet_file)
  emoji_cnt = emoji_statistics.sort_emoji_count_by_value(emoji_cnt)
  
  write.csv2(emoji_cnt, emoji_cnt_file, row.names = FALSE)
  
}