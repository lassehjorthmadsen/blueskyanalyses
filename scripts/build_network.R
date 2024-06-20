# Build a network of researchers and others professions by expanding a smaller net

library(tidyverse)
library(htmlwidgets)
devtools::load_all("../blueskynet")

password <- Sys.getenv("BLUESKY_APP_PASS")
identifier <- Sys.getenv("BLUESKY_APP_USER")
auth_object <- get_token(identifier, password)
token <- auth_object$accessJwt
refresh_tok <- auth_object$refreshJwt

########################
# BUILD RESEARCH NETWORK
########################

file_name <- paste0("data/research_big_net_", Sys.Date(), ".rds")

# Get the researcher keywords
keywords <- read_lines(file = "data/research_keywords.txt")

# Get a saved net
net <- readRDS("data/research_big_net_2024-06-18.rds")

net <- net |>
  dplyr::distinct(.keep_all = TRUE) |>
  na.omit()

# Expand the net
# set.seed(100)
expnet <- expand_net(net = net,
                     keywords = keywords,
                     token = token,
                     refresh_tok = refresh_tok,
                     save_net = FALSE,
                     file_name = file_name,
                     threshold = 30,
                     max_iterations = 30,
                     sample_size = Inf)

# Save the result
expnet |> saveRDS(file_name)


##########################
# BUILD JOURNALIST NETWORK
##########################

net_file      <- paste0("data/journalist_clean_net_", Sys.Date(), ".rds")
profile_file  <- file_name |> str_replace("_clean_net_", "_profiles_")
widget_file   <- file_name |> str_replace("_clean_net_", "_widget_")
keywords_file <- "data/journalist_keywords.txt"

# Get the researcher keywords
keywords <- read_lines(file = keywords_file)
keywords_collapsed <- keywords |> paste0(collapse = "|")

# Get initial net based on key actor
key_actor <- "slooterman.bsky.social"
small_net <- init_net(key_actor, keywords, token)

# Expand the net 
expnet <- expand_net(net = small_net,
                     keywords = keywords,
                     token = token,
                     refresh_tok = refresh_tok,
                     save_net = FALSE,
                     file_name = file_name,
                     threshold = 0.005,
                     max_iterations = 30,
                     sample_size = Inf)

# ... or load one made earlier
net <- readRDS(net_file)

# Trim the net
net <- net |> trim_net(threshold = 0.05)

# Check
setequal(net$actor_handle, net$follows_handle) 

# Get profiles
profiles <- get_profiles(unique(net$actor_handle), token)

# Clean profiles
profiles <- profiles |> 
  select(-starts_with("V"), 
         -starts_with("associated"), 
         -avatar, -banner, -createdAt, -indexedAt) |>
  distinct(.keep_all = TRUE)

# Add metrics
profiles <- profiles |> add_metrics(net) 

# Create widget
widget <- create_widget(net, profiles)
  
# Save the result
net      |> saveRDS(net_file)
profiles |> saveRDS(profile_file)
profiles |> write.csv2(str_replace(profile_file, ".rds", ".csv"))
widget   |> saveRDS(widget_file)
widget   |> saveWidget(str_replace(widget_file, ".rds", ".html"))

                       