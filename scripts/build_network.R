# Build a network of researchers and others professions by expanding a smaller net

library(tidyverse)
devtools::load_all("../blueskynet")

password <- Sys.getenv("BLUESKY_APP_PASS")
identifier <- Sys.getenv("BLUESKY_APP_USER")
auth_object <- get_token(identifier, password)
token <- auth_object$accessJwt
refresh_tok <- auth_object$refreshJwt

########################
# BUILD RESEARCH NETWORK
########################

file_name <- paste0("data/research_big_net_", Sys.Date(), ".rds")

# Get the researcher keywords
keywords <- read_lines(file = "data/research_keywords.txt")

# Get a saved net
net <- readRDS("data/research_big_net_2024-06-18.rds")
net <- readRDS("data/research_big_net_2024-02-03.rds")

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
expnet$expanded_net |> saveRDS(file_name)


##########################
# BUILD JOURNALIST NETWORK
##########################

file_name <- paste0("data/journalist_bignet_", Sys.Date(), ".rds")

# Get the researcher keywords
keywords <- read_lines(file = "data/journalist_keywords.txt")

# Get a saved net
key_actor <- 

net <- tibble("actor_handle" = "slooterman.bsky.social", "follows_handle" = "mcgowankat.bsky.social")


# Expand the net 
expnet <- expand_net(net = net,
                     keywords = keywords,
                     token = token,
                     refresh_tok = refresh_tok,
                     save_net = FALSE,
                     file_name = file_name,
                     threshold = 1,
                     max_iterations = 30,
                     sample_size = Inf)

# Save the result
expnet$expanded_net |> saveRDS(file_name)
