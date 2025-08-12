# Gather a data set with a lot of posts

library(tidyverse)
devtools::load_all("../blueskynet")

# Authenticate
password       <- Sys.getenv("BLUESKY_APP_PASS")
identifier     <- Sys.getenv("BLUESKY_APP_USER")
auth_object    <- get_token(identifier, password)
token          <- auth_object$accessJwt
refresh_tok    <- auth_object$refreshJwt

# Get most recent profiles data
profiles <- read.csv("data/research_profiles_2025-05-09.csv")

# File to store posts
posts_file <- paste0("data/top_posts_", Sys.Date(), ".csv")

top_no = 500
post_limit = 100

# top_profiles <- profiles |>
#   slice_max(order_by = centrality, n = 3) |> 
#   pull(did)

# test_data <- top_profiles |> slice(1:3) 

# posts <- top_profiles |>
#   map_dfr(get_user_posts,
#           token = token,
#           filter = "posts_no_replies",
#           limit = 10) |>
#   mutate(handle = coalesce(reposted_by, author_handle))

posts <- profiles |> 
  slice_max(order_by = centrality, n = top_no) |>
  pull(did) |> 
  map_dfr(get_user_posts,
          token = token,
          filter = "posts_no_replies",
          limit = post_limit,
          .id = "index")

posts <- posts |> 
  mutate(handle = coalesce(reposted_by, author_handle))

posts |> write_csv(posts_file)


## DEBUG

temp <- get_user_posts("did:plc:x6ux2kntuoni6pgdilmyhmci", token)

req <- httr2::request('https://bsky.social/xrpc/app.bsky.feed.getAuthorFeed') |>
  httr2::req_url_query(actor = "did:plc:jtzxnbwxwbywld23yvnyokzf", filter = "posts_no_replies", limit = 5) |>
  httr2::req_auth_bearer_token(token = token) |>
  httr2::req_timeout(seconds = 30)

resp <- httr2::req_perform(req)
