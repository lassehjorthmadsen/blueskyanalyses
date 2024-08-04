# Compute centrality metrics and add to profiles

file_name <- "data/research_clean_net_2024-06-18.rds"
profile_file_name <- file_name |> str_replace("_net_", "_profiles_") 
graph_file_name <- file_name |> str_replace("clean_net", "graph") 

# Get data from files 
net_clean <- readRDS(file_name)
profiles_clean <- readRDS(profile_file_name)

# Compute centrality metrics
# 1. graph object
graph <- net_clean |>
  as_tbl_graph() |>
  activate(nodes)

# 2. compute centrality
centrality <- centr_betw(graph)
V(graph)$centrality <- centrality$res

# 3. Identify high density subgraphs, "communities"
community <- cluster_walktrap(graph)
V(graph)$community <- community$membership

# 4. compute page rank
prank <- page.rank(graph)
V(graph)$pageRank <- prank$vector

# 5. Join profiles with metrics
followers <- net_clean |> count(follows_handle, name = "insideFollowers")
metrics <- graph |> as_tibble() |> rename(handle = name) 

profiles_clean <- profiles_clean |> 
  left_join(metrics, by = "handle") |>
  left_join(followers, by = c("handle" = "follows_handle")) 

# Save
graph |>  saveRDS(graph_file_name)
profiles_clean |> write_rds(profile_file_name)
profiles_clean |> write_csv(str_replace(profile_file_name, ".rds", ".csv"))

# There's an issue with Rstudio slowing down when list of large 
# igraph objects is created. https://github.com/rstudio/rstudio/issues/13489
rm(graph) 












