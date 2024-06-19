# Get and save current profile information from actors in a net

library(tidyverse)
devtools::load_all("../blueskynet")

file_name <- "data/research_clean_net_2024-06-18.rds"

profile_file_name <- file_name |> 
  str_replace("_net_", "_profiles_") |> 
  str_replace("rds", "csv")

keywords_file <- "data/research_keywords.txt"

# Get tokens
password <- Sys.getenv("BLUESKY_APP_PASS")
identifier <- Sys.getenv("BLUESKY_APP_USER")
auth_object <- get_token(identifier, password)
token <- auth_object$accessJwt
refresh_tok <- auth_object$refreshJwt

# Get data from files 
net_clean <- readRDS(file_name)
keywords <- read_lines(keywords_file) |> paste(collapse = "|")

# Download fresh set of profiles
all_actors <- unique(net_clean$actor_handle)
profiles <- all_actors |> get_profiles(token)

# Light cleaning
profiles <- profiles |> 
  select(-starts_with("V"), -starts_with("associated"), -avatar, -banner) |>
  distinct(.keep_all = TRUE)

# Sanity checks
n_distinct(profiles)
n_distinct(profiles$handle)
nrow(profiles)

# We miss a few, possibly because of anonymity?
setdiff(net_clean$actor_handle, profiles$handle) |> length()

# Check for keyword match -- almost all matches (why the exceptions?)
profiles |> count(keymatch = str_detect(tolower(description), keywords))

# Save
profiles |> write_csv(profile_file_name)
