library(tidyverse)
devtools::load_all()

# Get token
password <- Sys.getenv("BLUESKY_APP_PASS")
identifier <- Sys.getenv("BLUESKY_APP_USER")
auth_object <- get_token(identifier, password)
token <- auth_object$accessJwt
my_did <- auth_object$did

# Get my followers and follows
followers <- get_followers(identifier, token)
follows <- get_follows(identifier, token)

# Compare followers vs follows
followers |> nrow()
follows |> nrow()

cat("Mutual follows:", length(intersect(followers$did, follows$did)), "\n")

follows_only <- setdiff(follows$did, followers$did)
cat("People I follow who don't follow back:", length(follows_only), "\n")

# Get follows records
follow_records <- get_all_follow_records(my_did, token)

follow_rec_df  <- follow_records |>
  map(flatten) |>
  map_dfr(as_tibble) |>
  select(-`$type`) |>
  mutate(rkey = str_extract(uri, "[^/]+$"))

# Unfollow 8907 random actors that don't follow me
rkeys_to_unfollow <- follow_rec_df |>
  filter(subject %in% follows_only) |>
  slice_sample(n = 8907) |>
  pull(rkey)

safely_unfollow_actor <- safely(unfollow_actor)

resp <- rkeys_to_unfollow |>
  map(\(x) {
    safely_unfollow_actor(my_did, x, token)
    Sys.sleep(runif(1, 0, 0.1))
    },
    .progress = TRUE)

