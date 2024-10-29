# Build a network of researchers 

library(tidyverse)
library(htmlwidgets)
devtools::load_all("../blueskynet")

password <- Sys.getenv("BLUESKY_APP_PASS")
identifier <- Sys.getenv("BLUESKY_APP_USER")
auth_object <- get_token(identifier, password)
token <- auth_object$accessJwt
refresh_tok <- auth_object$refreshJwt

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
                                 threshold = 40,
                                 save_net = TRUE,
                                 max_iterations = 30,
                                 sample_size = Inf,
                                 file_name = net_file)

# Save the result
research_bundle$net      |> saveRDS(net_file)
research_bundle$profiles |> write.csv2(profile_file, row.names = FALSE)
research_bundle$widget   |> saveWidget(widget_file)


###########################
# RE-BUILD RESEARCH NETWORK
###########################

# In case we want to expand an existing net, rather that build a new one

# To-do: Figure out the best way to do that; maybe just just init_net() on
# the full set of "left-hand-side" handles in the net to be updated. The
# idea being, we have a set of "accepted" members, that may have aquired
# more followings and thus potential new members since last update?

threshold    <- 40
net_file     <- "data/research_net_2024-10-23.rds"
profile_file <- paste0("data/research_profiles_", Sys.Date(), ".csv")
widget_file  <- paste0("data/research_widget_", Sys.Date(), ".html")
keywords     <- read_lines(file = "data/research_keywords.txt")

# Get a saved net
net <- readRDS(net_file)

# Expand the net
expnet <- expand_net(net = net,
                     keywords = keywords,
                     token = token,
                     refresh_tok = refresh_tok,
                     save_net = FALSE,
                     file_name = net_file,
                     threshold = threshold,
                     max_iterations = 30,
                     sample_size = Inf)

# Trim the net
net <- expnet |> trim_net(threshold = threshold)

# Get profiles
profiles <- get_profiles(unique(net$actor_handle), token)

# Add metrics
profiles <- profiles |> add_metrics(net)

# Word frequencies in descriptions
freqs <- profiles$description |> word_freqs()

# Create widget
widget <- create_widget(net, profiles)

# Save the results
net      |> saveRDS(net_file)
profiles |> write.csv2(profile_file, row.names = FALSE)
profiles |> saveRDS(str_replace(profile_file, "csv", "rds"))
widget   |> saveWidget(widget_file)
