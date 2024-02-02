# Ad-hoc cleaning of net, so all profiles have keywords present

library(tidyverse)
devtools::load_all("../blueskynet")

password <- Sys.getenv("BLUESKY_APP_PASS")
identifier <- Sys.getenv("BLUESKY_APP_USER")
auth_object <- get_token(identifier, password)
token <- auth_object$accessJwt
refresh_tok <- auth_object$refreshJwt

# Get net and profiles from files 
net <- readRDS("data/bignet_2024-01-31.rds")
profiles <- readRDS("data/profiles_2024-01-31.rds") 

# Or, download fresh set of profiles
all_actors <- unique(net$actor_handle)
profiles <- all_actors |> get_profiles(token)

# Get the science keywords
keywords <- read_lines(file = "data/science_keywords.txt")
keywords <- paste(keywords, collapse = "|")

# Check for keyword match -- we only match about half
profiles |> count(keymatch = str_detect(description, keywords))

matches <- profiles |> filter(str_detect(description, keywords)) 

# Save the good profiles
profiles |> saveRDS("data/profiles_2024-01-31.rds")

# Clean and save net
net_cleaned <- net |> 
  filter(actor_handle %in% matches$handle) |> 
  add_count(follows_handle) |> 
  filter(n > 30) |> 
  select(-n)

# Check
sum(!net_cleaned$actor_handle %in% matches$handle)

# Save everything
matches |> saveRDS("data/profiles_2024-01-31.rds")
net_cleaned |> saveRDS("data/bignet_2024-01-31.rds")
