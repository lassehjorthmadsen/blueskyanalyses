# Compare networks and experiment with expansion function

library(tidyverse)
devtools::load_all("../blueskynet")

# Authorization
password <- Sys.getenv("BLUESKY_APP_PASS")
identifier <- Sys.getenv("BLUESKY_APP_USER")
auth_object <- get_token(identifier, password)
token <- auth_object$accessJwt
refresh_tok <- auth_object$refreshJwt

# Last used parameters:
# threshold       <- 0.01
# max_iterations  <- 100
# sample_size     <- Inf
# key_actor       <- "rossdahlke.bsky.social"

net1 <- read_rds("data/research_net_2025-09-19.rds")

# Last used parameters in cloud
# threshold       <- 0.01
# max_iterations  <- 5
# sample_size     <- Inf
# key_actor       <- "rossdahlke.bsky.social"

net2 <- read_rds("data/research_net_2025-11-18.rds")

# The Cloud net is 2705 short of the previous net
n_distinct(net1$actor_handle)
n_distinct(net2$actor_handle)

# Try expand function

# test parameters
threshold <- 0.01
max_iterations <- 1
sample_size <- Inf
keywords <- read_lines("data/research_keywords.txt")
net_file <- paste0("data/temp_research_net_", Sys.Date(), ".rds")

expanded_net <- expand_net(
  net = net2[1:2],
  keywords = keywords,
  token = token,
  refresh_tok = refresh_tok,
  save_net = TRUE,
  threshold = threshold,
  max_iterations = max_iterations,
  sample_size = sample_size
)

# The above doesn't work, because the final net have the same actors left and right side.
# Expand net takes output from init_net() as input, with has a single actor on the left, and
# multiple actors on the right.

temp <- get_profiles(unique(net2$actor_handle)[1:3], token)

research_bundle <- build_network(
  key_actors = unique(net2$actor_handle[1]),
  keywords = keywords,
  token = token,
  refresh_tok = refresh_tok,
  threshold = threshold,
  save_net = TRUE,
  max_iterations = max_iterations,
  sample_size = 10,
  file_name = net_file,
  prop = 1
)
