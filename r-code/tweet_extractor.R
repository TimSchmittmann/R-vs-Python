#@author: Tim Schmittmann

library(twitteR)
library(emojifont)
source("config.R")
library(showtext)
library(gmp)
library(stringi)
load.emojifont('EmojiOne.ttf')

showtext_auto()

# Create an Api instance.
setup_twitter_oauth(consumer_key, consumer_secret, access_token, access_secret)

emoji_cnt_csv_path = "data/manual-settings/emoji_cnt_used_for_twitter_api_requests.csv"
tweets_write_csv_base_path = "data/emoji_tweets/tweets_q3_emojis_"
tweets_write_csv_ext = ".csv"

Mode <- function() {
  list(RECENT = "RECENT", PAST = "PAST")
}

mode = Mode()$RECENT

read_max_id = function(tweet_csv_filepath, mode=Mode()$PAST) {
  max_id = 9999999999999999999

  if(mode == Mode()$PAST) {
    # go into the past starting from oldest tweet in file or starting from most recent if there is no file
    tryCatch({
      data = read.csv(tweet_csv_filepath, sep=';', col.names = c("id","text"), colClasses = c("integer64", "character"))
      max_id = min(data$id, na.rm=TRUE)
    }, error= function(e) {
      print(e)
    })
  }
  return(max_id)
}

read_min_id = function(tweet_csv_filepath, mode=Mode()$PAST) {
  if(mode == Mode()$PAST) {
    # go into the past as far as API allows
    return(0)
  }

  # go into the past until you find already processed tweets
  # in that case min_id is the highest tweet id found in the csv
  min_id = 0
  tryCatch({
    data = read.csv(tweet_csv_filepath, sep=';', col.names = c("id","text"), colClasses = c("integer64", "character"))
      min_id = max(data[,"id"], na.rm=TRUE)
  }, error = function(e) {
    print(e)
  })
  return(min_id)
}

exec_request_query = function(min_id, max_id, query_emojis) {
  q = paste(query_emojis, collapse="%20OR%20")
  query = paste0(q,"%20-filter%3Aretweets%20-filter%3Areplies&tweet_mode=extended")
  query_max_id = NULL
  query_since_id = NULL
  
  if(max_id != FALSE) {
    query_max_id = max_id
  }
  if(min_id != FALSE) {
    query_since_id = min_id
  }
  search = twitteR::searchTwitter(query, 
                                 n = 100, sinceID = query_since_id, maxID = query_max_id,
                                 lang = "de", resultType = "recent")
  search_result = twitteR::twListToDF(search)
  return(search_result)

}

request_tweets = function(min_id, max_id, query_emojis, write_cb, nr_of_requests = 3) {
  data = NULL
  for(i in 1:nr_of_requests) {
    print(paste0("Request ",i))
    tryCatch({
      search_result = exec_request_query(min_id, max_id, query_emojis)
      if(max_id != FALSE) {
        # Move further into the past with each request
        options(digits=20)
        max_id = as.bigz(tail(search_result[,'id'],1)) - 1
      }
      if(length(search_result) == 0) {
        print("Reached already processed tweets")
        break;
      }
      if(is.null(data)) {
        data = search_result[,c("id","text")]
      } else {
        data = rbind(data, search_result[,c("id","text")])
      }
      #write_cb(search_result)
      Sys.sleep(5)
    }, error = function(e) {
      print(e)
      if(e == 'list index out of range') {
        break;
      }
      Sys.sleep(30)
    })
  }
  return(data)
}

init_and_exec_requests_and_writes = function(tweets_write_csv_path, query_emojis, mode=Mode()$PAST) {
  max_id = read_max_id(tweets_write_csv_path, mode)
  min_id = read_min_id(tweets_write_csv_path, mode)
  print(paste0("MaxID: ",max_id))
  print(paste0("MinID: ",min_id))

  fieldnames = c(
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
    'user_statuses_count'
  )

  data = request_tweets(min_id, max_id, query_emojis)
  write.table(x=data[,c("id","text")],  row.names=FALSE, file=tweets_write_csv_path, sep=";", fileEncoding = "UTF-8", append = TRUE)
}


get_all_emojis = function (emoji_cnt_csv_path) {
  data = read.csv(emoji_cnt_csv_path, sep=';', header=F, encoding="UTF-8")
  names(data) = c('emoji', 'cnt')
 
  return(data[0:100,1])
}

main = function(emoji_cnt_csv_path, tweets_write_csv_base_path, tweets_write_csv_ext, mode=Mode()$PAST) {
  emojis = get_all_emojis(emoji_cnt_csv_path)
  #print(emojis)
  for (j in 0:ceiling(length(emojis) / 20)) {
    from_emoji = j*20
    to_emoji = min((j+1)*20, length(emojis))
    
    print(paste("From emoji ",from_emoji," to emoji ",to_emoji))
    query_emojis = emojis[from_emoji:to_emoji]
    
    if(length(query_emojis) > 0) {
      tweets_write_csv_path = paste0(tweets_write_csv_base_path,from_emoji,"-",to_emoji,tweets_write_csv_ext)
      init_and_exec_requests_and_writes(tweets_write_csv_path, query_emojis, mode)
    }
  }
}

while(TRUE) {
  main(emoji_cnt_csv_path, tweets_write_csv_base_path, tweets_write_csv_ext, mode)
}
