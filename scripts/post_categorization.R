# Script to label posts from Bluesky using an LLM

library(ellmer)
library(tidyverse)

# Parameters
posts_date <- as.Date("2025-09-30")
posts_file <- paste0("data/stratified_posts_", posts_date, ".csv")
pcats_file <- posts_file |>
  str_replace("stratified_posts_", "stratified_posts_cat_")

sample_size <- 3000 # Use Inf to not sample
chunk_size <- 500
model <- "gemini-2.5-flash"

system_prompt <- paste(
  "You are a post categorization expert.",
  "Your task is to assign short, descriptive categories to social media posts.",
  "Categories should be 1-3 words, clear and consistent.",
  "You will recieve a text in csv format, each line with a id number and a text containing the post.",
  "The text will be a chunk of a larger file.",
  "Follow those rules:",
  "1. Respond with a similar csv containg the id number and corresponding category, like this: 1,category",
  "2. Do not include any text formatting in the data, so no backticks and no 'csv'.",
  "3. Respond only with a clean csv that can be read by readr::read_csv()",
  "4. Always use those exact column names: 'id', 'category'",
  "5. Be mindful of the full conversation history i.e. earlier chunks, so that labels are consistent",
  "6. Use at the most 10 different categories",
  "7. Use Miscellaneous for any posts that don't fit into existing categories",
  "8. Don't miss any posts, return the same ids that you recieved, and the same number of lines, plus a header",
  sep = "\n"
)

# Get data
posts <- read_csv(posts_file, show_col_types = FALSE)

# Prepare data
unique_posts <- posts |>
  filter(!is_repost) |> # Skip reposts; can be hard to interpret (e.g. "This!")
  distinct(text) |> # We don't want to categorize the same content multiple times
  slice_sample(n = sample_size) |> # We might run out of tokens if we do everything
  mutate(id = row_number()) # Join later, don't send the full post back in the response

# Chunk the data
posts_chunked <- split(
  unique_posts,
  ceiling(seq_len(nrow(unique_posts)) / chunk_size)
)

# Convert chunks to csv strings
post_strings <- posts_chunked |>
  map(\(x) {
    unite(x, text, id, text, sep = ",") |>
      pull(text) |>
      paste(collapse = "\n")
  })

# Set-up chat
chat <- chat_google_gemini(
  system_prompt = system_prompt,
  model = "gemini-2.5-flash"
)

# Ask for categories
safe_chat <- safely(\(x) chat$chat(x, echo = FALSE))
cats <- map(post_strings, safe_chat, .progress = TRUE)

# cats <- post_strings |> map(\(x) chat$chat(x, echo = FALSE), .progress = TRUE)

# Convert responses to df and join original post back on
cats_df <- cats |>
  map(pluck, "result") |>
  keep(~ !is.null(.)) |>  # Remove NULL results after plucking
  map_dfr(read_csv, show_col_types = FALSE, .id = "chunk_id") |>
  left_join(unique_posts, by = "id")

### Checks ###

# Structure of what we sent
posts_chunked |>
  bind_rows(.id = "chunk_id") |>
  group_by(chunk_id) |>
  summarise(
    rows = n(),
    unique_ids = length(unique(id)),
    min_id = min(id),
    max_id = max(id)
  )

# Structure of what we got
cats_df |>
  group_by(chunk_id) |>
  summarise(
    rows = n(),
    unique_ids = length(unique(id)),
    min_id = min(id),
    max_id = max(id)
  )

# Did we get unique ids back?
nrow(cats_df)
n_distinct(cats_df)

# Did we get all ids back?
nrow(unique_posts)

# What categories did we get?
cats_df |> count(category, sort = TRUE)

# Save
cats_df |> write_csv(pcats_file)

# Check token usage
token_usage()
