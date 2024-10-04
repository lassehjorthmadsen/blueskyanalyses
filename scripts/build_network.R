# Build a network of researchers and others professions by expanding a smaller net

library(tidyverse)
library(htmlwidgets)
devtools::load_all("../blueskynet")

password <- Sys.getenv("BLUESKY_APP_PASS")
identifier <- Sys.getenv("BLUESKY_APP_USER")
auth_object <- get_token(identifier, password)
token <- auth_object$accessJwt
refresh_tok <- auth_object$refreshJwt

###########################
# RE-BUILD RESEARCH NETWORK
###########################

file_name <- paste0("data/research_big_net_", Sys.Date(), ".rds")

# Get the researcher keywords
keywords <- read_lines(file = "data/research_keywords.txt")

# Get a saved net
net <- readRDS("data/research_big_net_2024-06-18.rds")

net <- net |>
  dplyr::distinct(.keep_all = TRUE) |>
  na.omit()

# Expand the net
# set.seed(100)
expnet <- expand_net(net = net,
                     keywords = keywords,
                     token = token,
                     refresh_tok = refresh_tok,
                     save_net = FALSE,
                     file_name = file_name,
                     threshold = 30,
                     max_iterations = 30,
                     sample_size = Inf)

# Save the result
expnet |> saveRDS(file_name)



##########################
# BUILD RESEARCH NETWORK
##########################

keywords_file <- "data/research_keywords.txt"
key_actor     <- "rossdahlke.bsky.social"
net_file      <- paste0("data/research_net_", Sys.Date(), ".rds")
profile_file  <- paste0("data/research_profiles_", Sys.Date(), ".csv")
widget_file   <- paste0("data/research_widget_", Sys.Date(), ".html")

keywords <- read_lines(file = keywords_file)

research_bundle <- build_network(key_actor = key_actor,
                               keywords = keywords,
                               token = token,
                               refresh_tok = refresh_tok,
                               threshold = 0.025)

# Save the result
research_bundle$net      |> saveRDS(net_file)
research_bundle$profiles |> write.csv2(profile_file, row.names = FALSE)
research_bundle$widget   |> saveWidget(widget_file)


##########################
# BUILD JOURNALIST NETWORK
##########################

keywords_file <- "data/journalist_keywords.txt"
key_actor     <- "slooterman.bsky.social"
net_file      <- paste0("data/journalist_net_", Sys.Date(), ".rds")
profile_file  <- paste0("data/journalist_profiles_", Sys.Date(), ".csv")
widget_file   <- paste0("data/journalist_widget_", Sys.Date(), ".html")

keywords <- read_lines(file = keywords_file)

# Small demo
journalist_bundle <- build_network(key_actor = key_actor,
                                   keywords = keywords,
                                   token = token,
                                   refresh_tok = refresh_tok,
                                   threshold = 0.2,
                                   max_iterations = 1,
                                   sample_size = 10)

# The real deal  
journalist_bundle <- build_network(key_actor = key_actor,
                                   keywords = keywords,
                                   token = token,
                                   refresh_tok = refresh_tok,
                                   threshold = 0.025)

# Save the result
journalist_bundle$net      |> saveRDS(net_file)
journalist_bundle$profiles |> write.csv2(profile_file, row.names = FALSE)
journalist_bundle$widget   |> saveWidget(widget_file)


##########################
# BUILD ARTIST NETWORK
##########################

keywords_file <- "data/artist_keywords.txt"
key_actor     <- "miraongchua.com"
net_file      <- paste0("data/artist_net_", Sys.Date(), ".rds")
profile_file  <- paste0("data/artist_profiles_", Sys.Date(), ".csv")
widget_file   <- paste0("data/artist_widget_", Sys.Date(), ".html")

keywords <- read_lines(file = keywords_file)

artist_bundle <- build_network(key_actor = key_actor,
                                   keywords = keywords,
                                   token = token,
                                   refresh_tok = refresh_tok,
                                   threshold = 0.025)

# Save the result
artist_bundle$net      |> saveRDS(net_file)
artist_bundle$profiles |> write.csv2(profile_file, row.names = FALSE)
artist_bundle$widget   |> saveWidget(widget_file)

############################
# BUILD DATA SCIENCE NETWORK
############################

keywords_file <- "data/data_scientist_keywords.txt"
key_actor     <- "nataliafavila.bsky.social"
net_file      <- paste0("data/data_science_net_", Sys.Date(), ".rds")
profile_file  <- paste0("data/data_science_profiles_", Sys.Date(), ".csv")
widget_file   <- paste0("data/data_science_widget_", Sys.Date(), ".html")

keywords <- read_lines(file = keywords_file)

data_science_bundle <- build_network(key_actor = key_actor,
                               keywords = keywords,
                               token = token,
                               refresh_tok = refresh_tok,
                               threshold = 0.025)

# Save the result
data_science_bundle$net      |> saveRDS(net_file)
data_science_bundle$profiles |> write.csv2(profile_file, row.names = FALSE)
data_science_bundle$widget   |> saveWidget(widget_file)


############################
# BUILD WRITER NETWORK
############################

keywords_file <- "data/writer_keywords.txt"
key_actor     <- "neilhimself.neilgaiman.com"
net_file      <- paste0("data/writer_net_", Sys.Date(), ".rds")
profile_file  <- paste0("data/writer_profiles_", Sys.Date(), ".csv")
widget_file   <- paste0("data/writer_widget_", Sys.Date(), ".html")

keywords <- read_lines(file = keywords_file)

writer_bundle <- build_network(key_actor = key_actor,
                                     keywords = keywords,
                                     token = token,
                                     refresh_tok = refresh_tok,
                                     threshold = 0.025)

# Save the result
writer_bundle$net      |> saveRDS(net_file)
writer_bundle$profiles |> write.csv2(profile_file, row.names = FALSE)
writer_bundle$widget   |> saveWidget(widget_file)


############################
# BUILD BOARD GAME NETWORK
############################

keywords_file <- "data/board_game_keywords.txt"
key_actor     <- "hours.bsky.social"
net_file      <- paste0("data/board_game_net_", Sys.Date(), ".rds")
profile_file  <- paste0("data/board_game_profiles_", Sys.Date(), ".csv")
widget_file   <- paste0("data/board_game_widget_", Sys.Date(), ".html")

keywords <- read_lines(file = keywords_file)

board_game_bundle <- build_network(key_actor = key_actor,
                               keywords = keywords,
                               token = token,
                               refresh_tok = refresh_tok,
                               threshold = 0.025)

# Save the result
board_game_bundle$net      |> saveRDS(net_file)
board_game_bundle$profiles |> write.csv2(profile_file, row.names = FALSE)
board_game_bundle$widget   |> saveWidget(widget_file)


################################
# BUILD CLIMATE ACTIVIST NETWORK
################################

keywords_file <- "data/climate_activist_keywords.txt"
key_actor     <- "fightclimatechange.bsky.social"
net_file      <- paste0("data/climate_activist_net_", Sys.Date(), ".rds")
profile_file  <- paste0("data/climate_activist_profiles_", Sys.Date(), ".csv")
widget_file   <- paste0("data/climate_activist_widget_", Sys.Date(), ".html")

keywords <- read_lines(file = keywords_file)

climate_activist_bundle <- build_network(key_actor = key_actor,
                                    keywords = keywords,
                                    token = token,
                                    refresh_tok = refresh_tok,
                                    threshold = 0.025)

# Save the result
climate_activist_bundle$net      |> saveRDS(net_file)
climate_activist_bundle$profiles |> write.csv2(profile_file, row.names = FALSE)
climate_activist_bundle$widget   |> saveWidget(widget_file)
