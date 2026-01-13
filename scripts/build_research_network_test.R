# Build a network of researchers

library(tidyverse)
devtools::load_all("../blueskynet")

# Authorization
password <- Sys.getenv("BLUESKY_APP_PASS")
identifier <- Sys.getenv("BLUESKY_APP_USER")
auth_object <- get_token(identifier, password)
token <- auth_object$accessJwt
refresh_tok <- auth_object$refreshJwt

# Parameters
threshold <- 0.01
max_iterations <- 1
sample_size <- 10

# File locations
keywords_file <- "data/research_keywords.txt"
key_actor <- "lassehjorthmadsen.bsky.social"
net_file <- paste0("data/research_net_", Sys.Date(), ".rds")
profile_file <- paste0("data/research_profiles_", Sys.Date(), ".csv")

# Key words
keywords <- read_lines(file = keywords_file)

# Do the work
research_bundle <- build_network(
  key_actor = key_actor,
  keywords = keywords,
  token = token,
  refresh_tok = refresh_tok,
  threshold = threshold,
  save_net = TRUE,
  max_iterations = max_iterations,
  sample_size = sample_size,
  file_name = net_file,
  prop = 1
)

# Save the result
research_bundle$net |> saveRDS(net_file)
research_bundle$profiles |> write.csv(profile_file, row.names = FALSE)
