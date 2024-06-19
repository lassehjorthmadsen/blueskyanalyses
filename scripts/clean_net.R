# Trim the big net to the actual network we want and compute centrality

library(tidyverse)
library(tidygraph)
library(igraph)
devtools::load_all("../blueskynet")

file_name <- "data/research_big_net_2024-06-18.rds"
clean_file_name <- file_name |> str_replace("_big_", "_clean_")

# Get net from files 
net <- readRDS(file_name)
net_clean <- net |> trim_net(threshold = 30)

# Sanity checks
setequal(net_clean$actor_handle, net_clean$follows_handle)
net_clean |> count(follows_handle) |> arrange(n)

# Save
net_clean |> saveRDS(clean_file_name)
