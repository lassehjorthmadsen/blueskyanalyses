# Gather posts data
library(tidyverse)
devtools::load_all("../blueskynet")

# Authentication
password       <- Sys.getenv("BLUESKY_APP_PASS")
identifier     <- Sys.getenv("BLUESKY_APP_USER")
auth_object    <- get_token(identifier, password)
token          <- auth_object$accessJwt
refresh_tok    <- auth_object$refreshJwt

# Get most recent profiles data
profiles <- list.files("data", pattern = "research_profiles_.*\\.csv", full.names = TRUE) |>
  sort(decreasing = TRUE) |>
  head(1) |>
  read.csv()

# File paths and parameters
posts_file <- paste0("data/stratified_posts_", Sys.Date(), ".csv")
log_file <- paste0("data/error_log_", Sys.Date(), ".txt")
post_limit <- 100

# Get users from three ranges: top 200, bottom 200, middle 200
total_users <- nrow(profiles)
middle_start <- floor((total_users - 200) / 2)
middle_end <- middle_start + 199

users_to_sample <- bind_rows(
  profiles |>
    slice_max(order_by = centrality, n = 200) |>
    mutate(range = "top"),

  profiles |>
    arrange(centrality) |>
    slice(middle_start:middle_end) |>
    mutate(range = "middle"),

  profiles |>
    slice_min(order_by = centrality, n = 200) |>
    mutate(range = "bottom")
) |>
  select(did, handle, range)

# Check for existing data
if(file.exists(posts_file)) {
  processed_users <- read_csv(posts_file, show_col_types = FALSE) |>
    distinct(actor) |>
    pull(actor)
} else {
  processed_users <- character(0)
}

users_to_process <- users_to_sample |>
  filter(!did %in% processed_users)

message(sprintf("\nFound %d processed users. Processing remaining %d users.\n",
                length(processed_users),
                nrow(users_to_process)))

# Process remaining users
for(i in seq_len(nrow(users_to_process))) {
  current_user <- users_to_process$did[i]
  current_range <- users_to_process$range[i]
  
  message(sprintf("\n[User %d/%d] Processing %s range: %s",
                  i,
                  nrow(users_to_process),
                  current_range,
                  current_user))
  
  tryCatch({
    # Get and process posts
    user_posts <- get_user_posts(current_user,
                                 token = token,
                                 filter = "posts_no_replies",
                                 limit = post_limit,
                                 return_df = TRUE)
    
    if(!is.null(user_posts) && nrow(user_posts) > 0) {
      # Write to CSV
      write_csv(user_posts, 
                posts_file, 
                append = (i != 1 || length(processed_users) > 0))
      
      message(sprintf("✓ Processed %d posts", nrow(user_posts)))
    } else {
      message("✗ No posts found")
    }
    
    # Verify token
    if(!verify_token(token)) {
      message("! Token expired, refreshing...")
      auth_object <- refresh_token(refresh_tok)
      token <- auth_object$accessJwt
    }
    
    Sys.sleep(0.5)  # Small delay between users
    
  }, error = function(e) {
    message(sprintf("\n✗ Error processing user %d: %s", i, e$message))
    write(sprintf("%s: Error processing user %d (%s): %s", 
                  Sys.time(), i, current_user, e$message),
          log_file,
          append = TRUE)
  })
}

message("\nProcessing completed!")