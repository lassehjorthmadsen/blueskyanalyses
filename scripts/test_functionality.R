# Test basic functionality of build_network()

library(tidyverse)
library(htmlwidgets)
devtools::load_all("../blueskynet")

# Authorization
password        <- Sys.getenv("BLUESKY_APP_PASS")
identifier      <- Sys.getenv("BLUESKY_APP_USER")
auth_object     <- get_token(identifier, password)
token           <- auth_object$accessJwt
refresh_tok     <- auth_object$refreshJwt

# Parameters
max_iterations  <- 1
key_actor       <- identifier

# File locations
keywords_file   <- "data/research_keywords.txt"

# Key words
keywords <- read_lines(file = keywords_file)

# Do the work
research_bundle <- build_network(key_actor = key_actor,
                                 keywords = keywords,
                                 token = token,
                                 refresh_tok = refresh_tok,
                                 threshold = 1,
                                 save_net = TRUE,
                                 max_iterations = max_iterations,
                                 sample_size = 5,
                                 file_name = net_file,
                                 prop = 1)

# Inspect the result
research_bundle$net 
research_bundle$profiles 
research_bundle$widget
