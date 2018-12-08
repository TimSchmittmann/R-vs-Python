#@author: Tim Schmittmann
library(stringdist)

csv_fixer = c()

csv_fixer.remove_similar = function(csv_to_fix, read_ext, write_ext) {
    df = read.csv(paste0(csv_to_fix, read_ext), sep=';', skip=1, header=FALSE, colClasses = c("integer64", "character"), encoding="UTF-8")
    names(df) = c("tweet_id","tweet_full_text")
    df = df[,c("tweet_id","tweet_full_text")]
    indices_to_drop = c()
    sim_mat = stringdistmatrix(df$tweet_full_text, df$tweet_full_text, method = "jaccard", q=2)
    for(i in 1:(length(sim_mat[,1])-1)) {
      for(j in (i+1):(length(sim_mat[1,])-1)) {
         if(sim_mat[i,j] < 0.5) {
           indices_to_drop = c(indices_to_drop, j)
         }
      }
    }
    df = df[-indices_to_drop, ]
    
    write.csv2(df, paste0(csv_to_fix,write_ext), row.names = FALSE)
}

csv_fixer.remove_header_rows = function(csv_to_fix, read_ext, write_ext) {
  df = read.csv(paste0(csv_to_fix, read_ext), sep=';', skip=1, header=FALSE, colClasses = c("integer64", "character"), encoding="UTF-8")
  names(df) = c("tweet_id","tweet_full_text")
  df = df[,c("tweet_id","tweet_full_text")]
  
  df = df[!df$tweet_id == "tweet_id"]
  
  write.csv2(df, paste0(csv_to_fix,write_ext), row.names = FALSE)
}

csv_fixer.remove_linebreaks = function(csv_to_fix, read_ext, write_ext) {
  df = read.csv(paste0(csv_to_fix, read_ext), sep=';', skip=1, header=FALSE, colClasses = c("integer64", "character"), encoding="UTF-8")
  names(df) = c("tweet_id","tweet_full_text")
  df = df[,c("tweet_id","tweet_full_text")]
  df$tweet_full_text = mapply(gsub, pattern = "\n",
                              replacement = " ", df$tweet_full_text)
  df$tweet_full_text = mapply(gsub, pattern = "\r",
                              replacement = " ", df$tweet_full_text)
  write.csv2(df, paste0(csv_to_fix,write_ext), row.names = FALSE)
}

csv_fixer.remove_duplicates = function(csv_to_fix, read_ext, write_ext) {
  df = read.csv(paste0(csv_to_fix, read_ext), sep=';', skip=1, header=FALSE, colClasses = c("integer64", "character"), encoding="UTF-8")
  names(df) = c("tweet_id","tweet_full_text")
  df = df[,c("tweet_id","tweet_full_text")]
  
  df = df[!duplicated(df[,"tweet_full_text"]),]
  
  write.csv2(df, paste0(csv_to_fix,write_ext), row.names = FALSE)
}

csv_fixer.sort_by_tweet_id = function(csv_to_fix, read_ext, write_ext) {
  df = read.csv(paste0(csv_to_fix, read_ext), sep=';', skip=1, header=FALSE, colClasses = c("integer64", "character"), encoding="UTF-8")
  names(df) = c("tweet_id","tweet_full_text")
  df = df[,c("tweet_id","tweet_full_text")]
  
  df = df[order(df$tweet_id, decreasing = TRUE),]
  
  write.csv2(df, paste0(csv_to_fix,write_ext), row.names = FALSE)
}

csv_fixer.exclude_emoji_labels = function(csv_to_fix, read_ext, write_ext, emoji_excludes) {
  df = read.csv(paste0(csv_to_fix, read_ext), sep=';', skip=1, header=FALSE, colClasses = c("integer64", "character"), encoding="UTF-8")
  names(df) = c("tweet_id","tweet_full_text")
  df = df[,c("tweet_id","tweet_full_text")]
  
  write.csv(df, paste0(csv_to_fix,write_ext))
  
  write.csv2(df, paste0(csv_to_fix,write_ext), row.names = FALSE)
}


csv_fixer.map_emoji_labels = function(csv_to_fix, read_ext, write_ext, emoji_mappings_file) {
  mappings = emoji_helper.get_emoji_mappings(emoji_mappings_file)
  df = read.csv(paste0(csv_to_fix, read_ext), sep=';', skip=1, header=FALSE, colClasses = c("integer64", "character", "character"), encoding="UTF-8")
  names(df) = c("tweet_id","tweet_full_text","target")
  df = df[,c("tweet_id","tweet_full_text","target")]
  
  for (name in names(mappings)) {
    tryCatch({
      if(!is.null(mappings[[name]])) {
        gsub(name, mappings[[name]], df[,"target"], fixed=TRUE)
      }
    }, error=function(e) {
      print(e)
    })
  }
  write.csv2(df, paste0(csv_to_fix,write_ext), row.names = FALSE)
}

csv_fixer.extract_emoji_labels = function(csv_to_fix, read_ext, write_ext) {
  df = read.csv(paste0(csv_to_fix, read_ext), sep=';', skip=1, header=FALSE, colClasses = c("integer64", "character"), encoding="UTF-8")
  names(df) = c("tweet_id","tweet_full_text")
  df = df[,c("tweet_id","tweet_full_text")]

  #version with "official" mappings. Does not find emojis with large bytecode.
  #em_dict = emoji_helper.get_emoji_dict()
  #matchto <- em_dict$unicode
  #df[,"target"] = ""
  #for(emoji in as.character(em_dict$unicode)) {
  #  cnt = str_count(df[,"tweet_full_text"], fixed(emoji))
  #  df[cnt == 1,"target"] = paste(df[cnt == 1,"target"], emoji, set=",") 
  #}

  df[, "tweet_full_text"] = gsub("<U+FE0F>", "", df[, "tweet_full_text"], fixed=TRUE)
  df[, "targets"] = str_extract_all(df[,"tweet_full_text"], '<U\\+[0-9A-F]+>') %>% 
                      lapply(paste, collapse = ",") %>%
                      unlist(use.names=FALSE) 
  df[,"tweet_full_text"] = gsub('<U\\+[0-9A-F]+>', "", df[,"tweet_full_text"])
  write.csv2(df, paste0(csv_to_fix,write_ext), row.names = FALSE)
}

