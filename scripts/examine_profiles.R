# Examine profile descriptions

library(tidyverse)
devtools::load_all("../blueskynet")

password <- Sys.getenv("BLUESKY_APP_PASS")
identifier <- Sys.getenv("BLUESKY_APP_USER")
auth_object <- get_token(identifier, password)
token <- auth_object$accessJwt
refresh_tok <- auth_object$refreshJwt

# Get a sample of profiles from a saved net 
profiles <- readRDS("data/clean_profiles_2024-02-03.rds") |> slice_sample(n = 2000)

# Get the science keywords
keywords <- read_lines(file = "data/science_keywords.txt")

# How many match our keywords?
profiles |> count(ac = str_detect(description, paste(keywords, collapse = "|")))

# Show sample descriptions
profiles |> 
  slice_sample(n = 1000) |> 
  rowwise() |> 
  mutate(no_matches = sum(str_detect(tolower(description), keywords)),
         matches = paste(keywords[str_detect(tolower(description), keywords)], collapse = "|")
         ) |> 
  ungroup() |> 
  filter(no_matches == 1) |> 
  select(handle, no_matches, matches, description) |> 
  DT::datatable()





