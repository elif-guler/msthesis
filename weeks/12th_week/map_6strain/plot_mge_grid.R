#!/usr/bin/env Rscript

# plot_map_mge_grid.R
#
# Builds a grid of null-distribution histograms - one panel per
# strain x marker_type - from the shuffle_counts.txt files produced
# by map_mge_test.sh, with the observed overlap count marked as a
# vertical line and the empirical p-value annotated.
#
# Usage:
#   Rscript plot_map_mge_grid.R
#   Rscript plot_map_mge_grid.R --summary map_mge_summary.csv --out map_mge_null_grid.png
#
# Requires:
#   ggplot2
#   dplyr
#   readr
#   patchwork
#
# Install if needed:
#   install.packages(c("ggplot2", "dplyr", "readr", "patchwork"))


# ============================================================
# Load packages
# ============================================================

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(readr)
  library(patchwork)
})


# ============================================================
# Parse command-line arguments
# ============================================================

args <- commandArgs(trailingOnly = TRUE)

summary_path <- "map_mge_summary.csv"
out_path <- "map_mge_null_grid.png"

i <- 1

while (i <= length(args)) {

  if (args[i] == "--summary") {
    if (i == length(args)) {
      stop("--summary requires a file path")
    }
    summary_path <- args[i + 1]
    i <- i + 2

  } else if (args[i] == "--out") {
    if (i == length(args)) {
      stop("--out requires a file path")
    }
    out_path <- args[i + 1]
    i <- i + 2

  } else {
    stop("Unknown argument: ", args[i])
  }
}


# ============================================================
# Load summary
# ============================================================

if (!file.exists(summary_path)) {
  stop("Summary file does not exist: ", summary_path)
}

summary <- read_csv(
  summary_path,
  show_col_types = FALSE
)

summary <- summary %>%
  mutate(
    observed = as.integer(observed),
    permutations = as.integer(permutations),
    pvalue = as.numeric(pvalue)
  )


# ============================================================
# Load shuffle counts
# ============================================================

load_shuffle_counts <- function(strain, marker_type) {

  path <- file.path(
    strain,
    paste0("mge_test_", marker_type),
    "shuffle_counts.txt"
  )

  if (!file.exists(path)) {
    return(NULL)
  }

  counts <- readLines(path, warn = FALSE)

  counts <- counts[nzchar(trimws(counts))]

  if (length(counts) == 0) {
    return(integer(0))
  }

  as.integer(counts)
}


# ============================================================
# Determine strains and marker types
# ============================================================

# Keep the desired row order
marker_types <- c("fur", "seqwin")

# Keep strains in alphabetical order
strains <- sort(unique(summary$strain))

n_rows <- length(marker_types)   # 2
n_cols <- length(strains)        # 6


# ============================================================
# Create lookup table
# ============================================================

by_key <- summary %>%
  mutate(key = paste(strain, marker_type, sep = "\t"))


# ============================================================
# Create individual panels
# ============================================================

plots <- list()

plot_index <- 1

# IMPORTANT:
# Loop over marker_type FIRST so that:
#   row 1 = fur
#   row 2 = seqwin
#
# Within each row, loop over strains so that:
#   col 1 ... col 6 = the six strains

for (marker_type in marker_types) {

  for (strain in strains) {

    key <- paste(strain, marker_type, sep = "\t")

    row <- by_key %>%
      filter(key == !!key)

    # --------------------------------------------------------
    # No summary data
    # --------------------------------------------------------

    if (nrow(row) == 0) {

      p <- ggplot() +
        annotate(
          "text",
          x = 0.5,
          y = 0.5,
          label = "no data",
          hjust = 0.5,
          vjust = 0.5
        ) +
        labs(
          title = paste(strain, "/", marker_type)
        ) +
        theme_void()

      plots[[plot_index]] <- p
      plot_index <- plot_index + 1

      next
    }


    # --------------------------------------------------------
    # Extract values
    # --------------------------------------------------------

    observed <- row$observed[1]
    pvalue <- row$pvalue[1]
    n_perm <- row$permutations[1]

    counts <- load_shuffle_counts(
      strain,
      marker_type
    )


    # --------------------------------------------------------
    # No permutations
    # --------------------------------------------------------

    if (
      is.null(counts) ||
      length(counts) == 0 ||
      n_perm == 0
    ) {

      label <- paste0(
        "no permutations run\n",
        "(0 markers placed on reference)\n",
        "observed=", observed
      )

      p <- ggplot() +
        annotate(
          "text",
          x = 0.5,
          y = 0.5,
          label = label,
          hjust = 0.5,
          vjust = 0.5,
          size = 3
        ) +
        labs(
          title = paste(strain, "/", marker_type)
        ) +
        theme_void()

      plots[[plot_index]] <- p
      plot_index <- plot_index + 1

      next
    }


    # --------------------------------------------------------
    # Build histogram data
    # --------------------------------------------------------

    hist_data <- data.frame(
      count = counts
    )


    # --------------------------------------------------------
    # Histogram
    # --------------------------------------------------------

    p <- ggplot(
      hist_data,
      aes(x = count)
    ) +

      geom_histogram(
        binwidth = 1,
        boundary = -0.5,
        fill = "steelblue",
        alpha = 0.75,
        color = "white"
      ) +

      # Observed overlap
      geom_vline(
        xintercept = observed,
        color = "red",
        linetype = "dashed",
        linewidth = 0.7
      ) +

      labs(
        title = paste(strain, "/", marker_type),
        x = "permuted MGE overlap count",
        y = "frequency"
      ) +

      # Annotation
      annotate(
        "label",
        x = Inf,
        y = Inf,
        label = paste0(
          "obs=", observed,
          "\np=", sprintf("%.3f", pvalue)
        ),
        hjust = 1.05,
        vjust = 1.1,
        size = 3,
        fill = "white",
        alpha = 0.7
      ) +

      theme_minimal(base_size = 10) +

      theme(
        plot.title = element_text(
          size = 11,
          face = "plain"
        ),
        panel.grid.minor = element_blank()
      )


    plots[[plot_index]] <- p
    plot_index <- plot_index + 1
  }
}


# ============================================================
# Combine panels into 2 x 6 grid
# ============================================================

combined_plot <- wrap_plots(
  plots,
  nrow = 2,
  ncol = 6
) +

  plot_annotation(
    title = paste(
      "Null distributions: permuted MGE overlaps vs.",
      "observed (fur vs. seqwin)"
    ),
    theme = theme(
      plot.title = element_text(
        size = 13,
        face = "plain"
      )
    )
  )


# ============================================================
# Save figure
# ============================================================

width <- 5 * 6
height <- 3 * 2

ggsave(
  filename = out_path,
  plot = combined_plot,
  width = width,
  height = height,
  units = "in",
  dpi = 150
)

cat("wrote", out_path, "\n")