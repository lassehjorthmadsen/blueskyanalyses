# Ad-hoc cleaning of net, so all profiles have keywords present

library(tidyverse)
devtools::load_all("../blueskynet")

password <- Sys.getenv("BLUESKY_APP_PASS")
identifier <- Sys.getenv("BLUESKY_APP_USER")
auth_object <- get_token(identifier, password)
token <- auth_object$accessJwt
refresh_tok <- auth_object$refreshJwt

# Get net from files 
net <- readRDS("data/bignet_2024-02-03.rds")

# Download fresh set of profiles
all_actors <- unique(net$actor_handle)
profiles <- all_actors |> get_profiles(token)

# Get the science keywords
keywords <- read_lines(file = "data/science_keywords.txt")
keywords <- paste(keywords, collapse = "|")

# Check for keyword match -- we only match about 2/3
profiles |> count(keymatch = str_detect(description, keywords))
matches <- profiles |> filter(str_detect(description, keywords)) 

# Save the good profiles
matches |> saveRDS("data/profiles_2024-02-03.rds")

# Clean net
clean_net <- net |> 
  filter(actor_handle %in% matches$handle,
         actor_handle %in% follows_handle,
         follows_handle %in% actor_handle,
         actor_handle != follows_handle)

# Repeat these two steps until network converges
# 1.
followers <- clean_net |> count(follows_handle, name = "followers") 

# 2.
clean_net <- clean_net |> 
  left_join(followers, by = c("actor_handle" = "follows_handle")) |> 
  filter(followers >= 30,
         actor_handle %in% follows_handle,
         follows_handle %in% actor_handle) |> 
  select(-followers)
  
# We should end up having same set of actors to the left and to the right
n_distinct(clean_net$actor_handle)
n_distinct(clean_net$follows_handle)
setdiff(clean_net$actor_handle, clean_net$follows_handle)

# Save everything
profiles |> filter(handle %in% clean_net$actor_handle) |> 
  saveRDS("data/clean_profiles_2024-02-03.rds")

clean_net |> saveRDS("data/clean_net_2024-02-03.rds")
