# Minimal improvement to post categorization script
# Fixes main issues without over-engineering
# MAY BE BUGGY?

library(httr2)
library(jsonlite)
library(purrr)
library(tidyverse)

# Parameters
posts_date <- as.Date("2025-09-30")
posts_file <- paste0("data/stratified_posts_", posts_date, ".csv")
pcats_file <- posts_file |>
  str_replace("stratified_posts_", "stratified_posts_cat_")

sample_size <- 10000
chunk_size <- 500
model <- "gemini_2_5_flash"
api_key <- Sys.getenv("MARKETPLACE_API_KEY")

# API configuration
base_url <- "https://api.marketplace.novo-genai.com/v1"
cert_path <- "C:/Users/LMDN/OneDrive - Novo Nordisk/.certs/zscaler_root_ca.crt"

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

# Simple validation
if (api_key == "") {
  stop("MARKETPLACE_API_KEY environment variable not set")
}
if (!file.exists(cert_path)) {
  stop("Certificate file not found")
}

# Chat function using closure to avoid global variables
create_chat_session <- function(system_prompt) {
  conversation <- list(list(role = "system", content = system_prompt))

  function(user_message) {
    # Add user message to local conversation
    conversation <<- append(
      conversation,
      list(list(role = "user", content = user_message))
    )

    # Make API request
    body <- list(model = model, messages = conversation, temperature = 0)

    response <- request(paste0(base_url, "/chat/completions")) |>
      req_headers(
        "Authorization" = paste("Bearer", api_key),
        "Content-Type" = "application/json"
      ) |>
      req_body_json(body) |>
      req_options(cainfo = cert_path) |>
      req_timeout(120) |>
      req_retry(max_tries = 3) |>
      req_perform()

    result <- response |>
      resp_body_json() |>
      pluck("choices", 1, "message", "content")

    # Add assistant response to local conversation
    conversation <<- append(
      conversation,
      list(list(role = "assistant", content = result))
    )

    result
  }
}

# Load and prepare data
posts <- read_csv(posts_file, show_col_types = FALSE)

unique_posts <- posts |>
  filter(!is_repost) |>
  distinct(text) |>
  slice_sample(n = sample_size) |>
  mutate(id = row_number())

# Create chunks
posts_chunked <- split(
  unique_posts,
  ceiling(seq_len(nrow(unique_posts)) / chunk_size)
)

post_strings <- posts_chunked |>
  map(\(x) {
    unite(x, text, id, text, sep = ",") |>
      pull(text) |>
      paste(collapse = "\n")
  })

# Create chat session (conversation state encapsulated in closure)
chat_session <- create_chat_session(system_prompt)

# Process chunks with error handling
safe_chat <- safely(\(x) chat_session(x))
cats <- map(post_strings, safe_chat, .progress = TRUE)

# Process results
cats_df <- cats |>
  map(pluck, "result") |>
  discard(is.null) |>
  map_dfr(read_csv, show_col_types = FALSE, .id = "chunk_id") |>
  left_join(unique_posts, by = "id")

# Quick validation
cat("Processed:", nrow(cats_df), "of", nrow(unique_posts), "posts\n")
cat("Categories found:\n")
print(cats_df |> count(category, sort = TRUE))

# Save results
write_csv(cats_df, pcats_file)
cat("Results saved to:", pcats_file, "\n")
