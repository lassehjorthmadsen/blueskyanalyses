# Build a network of researchers from University of Padua
library(tidyverse)
library(httr2)
devtools::load_all("../blueskynet")

# Key actors from the provided lists
files <- c(
  "ad-hoc/Padua/Bluesky 'Padova' academics.txt",
  "ad-hoc/Padua/Bluesky 'unipd' academics.txt",
  "ad-hoc/Padua/Bluesky 'Padua' academics.txt"
)

actors <- files |>
  map(read_csv, col_names = "id", show_col_types = FALSE) |>
  bind_rows() |>
  pull(id) |>
  iconv(to = "ASCII", sub = "") |>
  unique()

# Authorization
auth_object <- get_token(
  Sys.getenv("BLUESKY_APP_USER"),
  Sys.getenv("BLUESKY_APP_PASS")
)
token       <- auth_object$accessJwt
refresh_tok <- auth_object$refreshJwt

# Parameters: no keyword filter, one expansion iteration, no trimming threshold
keywords       <- c(".*")
threshold      <- 0
max_iterations <- 1
sample_size    <- Inf

# File locations
stamp        <- Sys.Date()
bundle_file  <- paste0("ad-hoc/Padua/padua_bundle_",   stamp, ".rds")
profile_file <- paste0("ad-hoc/Padua/padua_profiles_", stamp, ".csv")

# Build the full expanded network
padua_bundle <- build_network(
  key_actor      = actors,
  keywords       = keywords,
  token          = token,
  refresh_tok    = refresh_tok,
  threshold      = threshold,
  save_net       = FALSE,
  max_iterations = max_iterations,
  sample_size    = sample_size,
  prop           = 1
)

# Flag profiles that belong to the original Padua list
padua_bundle$profiles <- padua_bundle$profiles |>
  mutate(core_network = handle %in% actors)

# Reduced network: only edges where BOTH endpoints are on the original list
core_net <- padua_bundle$net |>
  filter(actor_handle %in% actors, follows_handle %in% actors)

core_profiles <- padua_bundle$profiles |>
  filter(handle %in% unique(c(core_net$actor_handle, core_net$follows_handle)))

padua_bundle$core_widget <- create_widget(core_net, core_profiles, prop = 1)

# Save the full bundle plus a CSV of profiles for easy consumption
saveRDS(padua_bundle, bundle_file)
write.csv(padua_bundle$profiles, profile_file, row.names = FALSE)

# ---- Fetch most recent posts for the expanded network ---------------------
posts_file <- paste0("ad-hoc/Padua/padua_posts_", stamp, ".csv")
log_file   <- paste0("ad-hoc/Padua/padua_posts_errors_", stamp, ".txt")
post_limit <- 100

users_to_process <- padua_bundle$profiles |>
  select(did, handle)

# Resume support: skip users already in the output file
if (file.exists(posts_file)) {
  done <- read_csv(posts_file, show_col_types = FALSE) |> distinct(actor) |> pull(actor)
  users_to_process <- filter(users_to_process, !did %in% done)
  message(sprintf("Resuming: %d users already processed, %d remaining",
                  length(done), nrow(users_to_process)))
}

for (i in seq_len(nrow(users_to_process))) {
  did <- users_to_process$did[i]
  message(sprintf("[%d/%d] %s", i, nrow(users_to_process), users_to_process$handle[i]))

  if (!verify_token(token)) {
    auth_object <- refresh_token(refresh_tok)
    token       <- auth_object$accessJwt
    refresh_tok <- auth_object$refreshJwt
  }

  tryCatch({
    posts <- get_user_posts(did, token = token, filter = "posts_no_replies",
                            limit = post_limit, return_df = TRUE)
    if (!is.null(posts) && nrow(posts) > 0) {
      write_csv(posts, posts_file, append = file.exists(posts_file))
    }
    Sys.sleep(0.5)
  }, error = function(e) {
    message(sprintf("  ! error: %s", e$message))
    write(sprintf("%s: %s (%s): %s", Sys.time(), users_to_process$handle[i], did, e$message),
          log_file, append = TRUE)
  })
}

message("Posts collection complete.")

# ---- Categorize posts via LLM ---------------------------------------------
stamp       <- Sys.Date()
pcats_file  <- paste0("ad-hoc/Padua/padua_posts_cat_", stamp, ".csv")
sample_size <- 10000
chunk_size  <- 500
model       <- "gemini_2_5_flash"
api_key     <- Sys.getenv("MARKETPLACE_API_KEY")
base_url    <- Sys.getenv("MARKETPLACE_BASE_URL")
cert_path   <- Sys.getenv("MARKETPLACE_CERT_PATH")

posts_file <- "ad-hoc/Padua/padua_posts_2026-04-06.csv"

if (api_key == "")   stop("MARKETPLACE_API_KEY environment variable not set")
if (base_url == "")  stop("MARKETPLACE_BASE_URL environment variable not set")
if (cert_path == "") stop("MARKETPLACE_CERT_PATH environment variable not set")
if (!file.exists(cert_path)) stop("Certificate file not found: ", cert_path)

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

create_chat_session <- function(system_prompt) {
  conversation <- list(list(role = "system", content = system_prompt))
  function(user_message) {
    conversation <<- append(conversation,
                            list(list(role = "user", content = user_message)))
    body <- list(model = model, messages = conversation, temperature = 0)
    result <- request(paste0(base_url, "/chat/completions")) |>
      req_headers("Authorization" = paste("Bearer", api_key),
                  "Content-Type" = "application/json") |>
      req_body_json(body) |>
      req_options(cainfo = cert_path) |>
      req_timeout(120) |>
      req_retry(max_tries = 3) |>
      req_perform() |>
      resp_body_json() |>
      pluck("choices", 1, "message", "content")
    conversation <<- append(conversation,
                            list(list(role = "assistant", content = result)))
    result
  }
}

# Prepare unique posts (dedupe, exclude reposts, sample, assign ids)
posts <- read_csv(posts_file, show_col_types = FALSE)

unique_posts <- posts |>
  filter(!is_repost) |>
  distinct(text) |>
  slice_sample(n =sample_size) |>
  mutate(id = row_number())

# Chunk into csv strings
post_strings <- split(unique_posts, ceiling(seq_len(nrow(unique_posts)) / chunk_size)) |>
  map(\(x) unite(x, text, id, text, sep = ",") |> pull(text) |> paste(collapse = "\n"))

# Categorize
chat_session <- create_chat_session(system_prompt)
safe_chat    <- safely(\(x) chat_session(x))
cats         <- map(post_strings[[1]], safe_chat, .progress = TRUE)

cats_df <- cats |>
  map(pluck, "result") |>
  discard(is.null) |>
  map_dfr(read_csv, show_col_types = FALSE, .id = "chunk_id") |>
  left_join(unique_posts, by = "id")

cat("Processed:", nrow(cats_df), "of", nrow(unique_posts), "posts\n")
cats_df |> count(category, sort = TRUE)

write_csv(cats_df, pcats_file)
message("Categorized posts saved to: ", pcats_file)
