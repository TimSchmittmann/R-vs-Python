#@author: Tim Schmittmann
options(stringsAsFactors = FALSE)

emoji_helper = c()
emoji_helper.emojis_csv = "../data/manual_settings/emojis.csv"

emoji_helper.split_count = function(text) {
}

emoji_helper.get_emoji_mappings = function(emoji_mappings_file) {
  df = read.csv(emoji_mappings_file, sep=';', skip = 1, 
                strip.white=TRUE, encoding = "UTF-8",
                colClasses = c("character", "character"))
  emoji_mappings = list()
  for(i in 1:nrow(df)) {
    if (suppressWarnings(!is.na(as.numeric(as.character(df[i, 2]))))) {
      emoji_mappings[[df[i, 1]]] = df[i, 1]
    } else {
      for(emoji in strsplit(df[i, 1], ",")[[1]]) {
        emoji_mappings[[emoji]] = df[i,2] 
      }
    }
  }
  return(emoji_mappings)
}
