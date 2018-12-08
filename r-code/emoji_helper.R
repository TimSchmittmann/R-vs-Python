#@author: Tim Schmittmann

emoji_helper = c()

emoji_helper.split_count = function(text) {
}

emoji_helper.get_emoji_mappings = function(emoji_mappings_file) {
  df = read.csv(emoji_mappings_file, sep=';', col.names = c("tweet_id","tweet_full_text"), colClasses = c("integer64", "character"))
  
}

emoji_helper.write_missing_emojis_in_mapping_file = function(tweet_file, emoji_mappings_file) {
  df = read.csv(tweet_file, sep=';', col.names = c("tweet_id","tweet_full_text"), colClasses = c("integer64", "character"))
  
  #write.csv(df, emoji_mappings_file)
}

  
emoji_helper.get_emoji_excludes_from_file = function(emoji_excludes_file) {
  excludes = c()
  df = read.csv(emoji_excludes_file, sep=';', col.names = c("emoji"), colClasses = c("character"), encoding = "UTF-8")
  
  return(excludes)
}