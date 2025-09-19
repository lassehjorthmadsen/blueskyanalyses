# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Git Configuration

This is a personal side project. When making commits, use:
- Email: lassehjorthmadsen@gmail.com

## Project Overview

This is an R-based social network analysis project that studies scientist and researcher communities on Bluesky Social. The project generates a Quarto-based website at https://lassehjorthmadsen.github.io/blueskyanalyses/ showcasing network visualizations and centrality analysis.

## Architecture

### Core Dependencies
- **blueskynet package**: Custom R package located at `../blueskynet` - contains core network building and analysis functions. Must be loaded with `devtools::load_all("../blueskynet")`
- **Bluesky API Authentication**: Requires environment variables `BLUESKY_APP_PASS` and `BLUESKY_APP_USER`
- **Network Analysis Stack**: tidygraph, igraph for graph operations; threejs, htmlwidgets for 3D visualizations

### Data Pipeline Architecture

The project follows a multi-stage data pipeline:

1. **Network Building** (`build_research_network.R`)
   - Iterative algorithm starting from key actors
   - Expands network based on follow relationships and bio keyword matching
   - Uses threshold-based filtering (typically 30-40 connections minimum)
   - Supports both fresh builds and expansion of existing networks

2. **Data Processing Flow**:
   ```
   Raw Network → Trim/Clean → Fetch Fresh Profiles → Add Centrality Metrics → Create Visualizations
   ```

3. **File Naming Convention**:
   - Networks: `{type}_net_{date}.rds` (raw) → `{type}_clean_net_{date}.rds` (processed)
   - Profiles: `{type}_profiles_{date}.csv/rds`
   - Widgets: `{type}_widget_{date}.html/rds`
   - Graphs: `{type}_graph_{date}.rds`

### Key Script Functions

- **build_research_network.R**: Main network construction - can build new or expand existing networks
- **clean_net.R**: Applies threshold filtering using `trim_net(threshold = 30)`
- **fetch_profiles.R**: Downloads fresh profile data for network members
- **centrality_profiles.R**: Computes betweenness centrality, PageRank, community detection
- **create_widget.R**: Generates 3D network visualizations with threejs

### Keyword-Based Classification

Networks are built using keyword matching against user bio descriptions. Keywords are stored in `data/*_keywords.txt` files for different communities (research, journalist, artist, etc.). The `research_keywords.txt` contains 124 academic terms ranging from job titles to disciplines.

## Common Development Commands

### Building Networks
```r
# New research network from scratch
source("scripts/build_research_network.R")

# Expand existing network
# Edit the "RE-BUILD RESEARCH NETWORK" section in build_research_network.R
# Set appropriate threshold and existing net file path
```

### Processing Data
```r
# Clean and trim network
source("scripts/clean_net.R")

# Fetch updated profiles
source("scripts/fetch_profiles.R")

# Add centrality metrics
source("scripts/centrality_profiles.R")

# Generate 3D visualization
source("scripts/create_widget.R")
```

### Website Development
```r
# Render Quarto website
quarto render

# Preview locally
quarto preview

# Deploy to GitHub Pages (if configured)
quarto publish gh-pages
```

### Environment Setup
```r
# Load custom package
devtools::load_all("../blueskynet")

# Set authentication (in .Renviron)
BLUESKY_APP_USER=your.handle.bsky.social
BLUESKY_APP_PASS=your-app-password
```

## Data Structure

### Network Data Format
- Edge list with `actor_handle` → `follows_handle` relationships
- All handles must exist in both directions for inclusion after trimming
- Threshold filtering ensures minimum connectivity (typically 30+ connections)

### Profile Data Columns
Key fields: `handle`, `displayName`, `description`, `followersCount`, `followsCount`, `centrality`, `pageRank`, `community`, `insideFollowers`

### Centrality Metrics
- **Betweenness Centrality**: Measures bridging importance between network clusters
- **PageRank**: Measures influence based on connection quality
- **Community Detection**: Uses Walktrap algorithm to identify subgroups
- **Inside Followers**: Count of connections within the analyzed network (vs total followers)

## Project Structure Notes

- `scripts/`: All R analysis scripts (modular, can be run independently)
- `data/`: Network files, profiles, widgets, keyword lists (timestamped)
- `notes/`: Quarto notebooks for website content
- `pages/`: Static website pages (big-list.qmd, big-plot.qmd)
- `_site/`: Generated website output (auto-created by Quarto)

## Important Considerations

- **Rate Limiting**: Bluesky API calls are rate-limited; large network builds take time
- **Data Freshness**: Profile data becomes stale; use `fetch_profiles.R` to refresh
- **Memory Management**: Large igraph objects can slow RStudio; scripts include `rm(graph)` calls
- **Threshold Tuning**: Network size vs quality tradeoff controlled by connection thresholds
- **Authentication**: App passwords (not regular passwords) required for Bluesky API access