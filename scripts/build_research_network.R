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
                                 threshold = 0.01)

# Save the result
research_bundle$net      |> saveRDS(net_file)
research_bundle$profiles |> write.csv2(profile_file, row.names = FALSE)
research_bundle$widget   |> saveWidget(widget_file)


###########################
# RE-BUILD RESEARCH NETWORK
###########################

# In case we want to expand an existing net, rather that build a new one

net_file      <- paste0("data/research_net_", Sys.Date(), ".rds")
profile_file  <- paste0("data/research_profiles_", Sys.Date(), ".csv")
widget_file   <- paste0("data/research_widget_", Sys.Date(), ".html")

# Get the researcher keywords
keywords <- read_lines(file = "data/research_keywords.txt")

# Get a saved net
net <- readRDS("research_net_2024-10-09.rds")

# net <- net |>
#   dplyr::distinct(.keep_all = TRUE) |>
#   na.omit()

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
expnet |> saveRDS(net_file)

