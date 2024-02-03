# Build a network of scientists by expanding a smaller net

library(tidyverse)
devtools::load_all("../blueskynet")

password <- Sys.getenv("BLUESKY_APP_PASS")
identifier <- Sys.getenv("BLUESKY_APP_USER")
auth_object <- get_token(identifier, password)
token <- auth_object$accessJwt
refresh_tok <- auth_object$refreshJwt

file_name <- paste0("data/bignet_", Sys.Date(), ".rds")
profile_file_name <- paste0("data/profiles_", Sys.Date(), ".rds")

# Get the science keywords
keywords <- read_lines(file = "data/science_keywords.txt")

# The profiles I'm following form a starting point
follows <- get_follows(identifier, token)

# Now, get follows of follows: The network that we want
net <- follows$handle |> 
  as.list() |> 
  set_names() |> 
  map_dfr(get_follows, token, .id = "actor_handle", .progress = TRUE) |>
  select(actor_handle, follows_handle = handle)

# Or, get a saved net
net <- readRDS("data/bignet_2024-02-03.rds")

# Expand the net (can take a loooong time)
expnet <- expand_net(net = net,
                     keywords = keywords,
                     token = token,
                     refresh_tok = refresh_tok,
                     save_net = TRUE,
                     file_name = file_name,
                     threshold = 30,
                     max_iterations = 30,
                     sample_size = Inf)

# Save the result
expnet$expanded_net |> saveRDS(file_name)
expnet$profiles |> saveRDS(profile_file_name)
