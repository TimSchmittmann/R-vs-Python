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

# https://github.com/today-is-a-good-day/emojis
emoji_helper.get_emoji_dict = function() {
  # read in emoji dictionary
  # I used to get the dictionary from Felipe: https://github.com/felipesua
  # but he put it down, so I uploaded the csv file to my github profile: 
  # https://raw.githubusercontent.com/today-is-a-good-day/emojis/master/emojis.csv
  # input your custom path to file
  emDict_raw <- read.csv2(emoji_helper.emojis_csv) %>% 
    select(EN, ftu8, unicode) %>% 
    rename(description = EN, r.encoding = ftu8)
  
  # plain skin tones
  skin_tones <- c("light skin tone", 
                  "medium-light skin tone", 
                  "medium skin tone",
                  "medium-dark skin tone", 
                  "dark skin tone")
  
  # remove plain skin tones and remove skin tone info in description
  emDict <- emDict_raw %>%
    # remove plain skin tones emojis
    filter(!description %in% skin_tones) %>%
    # remove emojis with skin tones info, e.g. remove woman: light skin tone and only
    # keep woman
    filter(!grepl(":", description)) %>%
    mutate(description = tolower(description)) %>%
    mutate(unicode = as.u_char(unicode))
  # all emojis with more than one unicode codepoint become NA 
}