# Follow the net

# NOTE: Bulk following is not allowed, my account was suspended for running this script #
# see: https://bsky.social/about/support/community-guidelines

library(tidyverse)
devtools::load_all("../blueskynet")

# Get token
password <- Sys.getenv("BLUESKY_APP_PASS")
identifier <- Sys.getenv("BLUESKY_APP_USER")
auth_object <- get_token(identifier, password)
token <- auth_object$accessJwt
refresh_tok <- auth_object$refreshJwt
my_did <- auth_object$did

# Get saved net and profiles
net <- read_rds("data/research_net_2025-05-09.rds")
profiles <- read_csv("data/research_profiles_2025-05-09.csv", show_col_types = FALSE)

# Get follows
follows <- get_follows(identifier, token)

# Follow the whole net (except those we already follow)
dids_to_follow <- profiles$did |> unique() |> setdiff(follows$did)

safely_follow_actor <- safely(follow_actor)

resps <- dids_to_follow |> 
  map(\(x) {
    safely_follow_actor(my_did = my_did, actor_did = x, token = token)
    Sys.sleep(runif(1, 0, 0.5))
    }, 
    .progress = TRUE)


# We may get
# ! HTTP 429 Too Many Requests.

# Examine responses
resps |> map(pluck("headers")) |> map_chr(pluck("RateLimit-Remaining")) |> tail() 
resps |> map(pluck("headers")) |> map_chr(pluck("RateLimit-Reset")) |> as.numeric() |> as.POSIXct() |> tail()

# Same drill for Mike
password <- Sys.getenv("BLUESKY_APP_PASS_MIKE")
identifier <- Sys.getenv("BLUESKY_APP_USER_MIKE")
auth_object <- get_token(identifier, password)
token <- auth_object$accessJwt
mike_did <- auth_object$did

follows <- get_follows(identifier, token)
profiles <- readRDS("data/clean_profiles_2024-02-03.rds")

dids <- profiles$did |> unique() |> setdiff(follows$did)
resps <- dids |> map(\(x) follow_actor(my_did = mike_did, actor_did = x, token = token))
