# Create widget

library(tidygraph)
library(igraph)
library(DT)
library(tidyverse)
library(RColorBrewer)
library(threejs)
library(htmlwidgets)

file_name <- "data/research_graph_2024-06-18.rds"

profile_file_name <- file_name |> str_replace("_graph_", "_clean_profiles_") 

widget_file_name <- file_name |> 
  str_replace("_graph_", "_widget_") |> 
  str_replace(".rds", ".html")

# Get data from files 
graph <- readRDS(file_name)
profiles <- readRDS(profile_file_name)

# compute
edges <- graph |> activate(edges) |> as_tibble()
nodes <- graph |> activate(nodes) |> mutate(id = row_number()) |> as_tibble()

nodes <- nodes |>
  mutate(com_label = fct_infreq(as.character(community)),
         com_label = fct_lump(com_label, n = 10)) |>
  group_by(com_label) |>
  mutate(n = n(), com_id = cur_group_id()) |>
  ungroup() |>
  mutate(com_label = ifelse(com_id == max(com_id), "Other",
                            paste0(LETTERS[com_id], ", n=", n))) |>
  left_join(profiles, by = c("name" = "handle"))

# Make colors based on communities
community_cols <- 3 |> brewer.pal("Set1") |> colorRampPalette()
use_colors <- n_distinct(nodes$com_label) |> community_cols() |> sample()

nodes <- nodes |> mutate(color = use_colors[com_id], groupname = com_label)

# 3d plot with threejs
widget <- graphjs(graph, bg = "black",
                  vertex.size = 0.2,
                  edge.width = .3,
                  edge.alpha = .3,
                  vertex.color = nodes$color,
                  vertex.label = paste(nodes$displayName, nodes$description, sep = ": "))

rm(graph)  # Slows down Rstudio

widget |> saveWidget(widget_file_name)
widget |> write_rds(str_replace(widget_file_name, ".html", ".rds"))
