# Examine net descriptions

library(tidyverse)
devtools::load_all("../blueskynet")

# Get saved net and profiles
oldnet <- readRDS("data/research_big_net_2024-02-03.rds")
net <- readRDS("data/research_big_net_2024-06-18.rds")
profiles <- readRDS("data/research_profiles_2024-06-18.rds")

# Do we have duplicates? Yes. Figure out if this is because of a bug?
n_distinct(net)
nrow(net)

clean_net <- net |> distinct(.keep_all = TRUE)

# Confirm that everyone on the left side is being followed by at least 30
# actors on the right side. That's not the case. Why? Two reasons I can think of:
# 1) Along the way we added too much to the net because of bugs?
# 2) The original starting point (Mike's follows) don't all meet the 30 threshold.

followers <- net |> count(follows_handle, name = "followers") 

clean_net <- clean_net |> 
  left_join(followers, by = c("actor_handle" = "follows_handle")) |> 
  arrange(followers)

# We have some on the left hand side that is not on the right hand side
clean_net |> count(is.na(followers))

small_net <- clean_net |> 
  filter(followers >= 30, 
         !is.na(followers),
         follows_handle %in% actor_handle)

small_net <- clean_net |> 
  filter(followers >= 30, !is.na(followers)) |> 
  filter(follows_handle %in% actor_handle) |> 
  filter(actor_handle %in% follows_handle)
  
# Do it again
small_net <- small_net |> 
  filter(follows_handle %in% actor_handle) |> 
  filter(actor_handle %in% follows_handle)

# We should end up having same set of actors to the left and to the right (follows)
n_distinct(small_net$actor_handle)
n_distinct(small_net$follows_handle)

setdiff(small_net$actor_handle, small_net$follows_handle)

trimmed_net <- trim_net(net, 30)
trimmed_oldnet <- trim_net(oldnet, 30)


