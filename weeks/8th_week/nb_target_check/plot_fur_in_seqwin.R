#!/usr/bin/env Rscript
# plot_fur_in_seqwin.R
#
# Reads fur_in_seqwin.csv for each dataset/pool, keeps only the markers
# that were found in seqwin's marker set (found == 1), and plots identity
# vs coverage in a 2 (pool) x 3 (taxon) grid.
#
# Run from the nb_target_check directory:
#   Rscript plot_fur_in_seqwin.R

library(ggplot2)
library(dplyr)

datasets <- c(clo = "C. difficile", mtb = "M. tuberculosis", sen = "S. enterica")
pools <- c("100", "1000")

all_data <- list()

for (ds in names(datasets)) {
  for (pool in pools) {
    path <- file.path(ds, paste0("pool_", pool), "fur_in_seqwin.csv")
    if (!file.exists(path)) {
      message("missing: ", path)
      next
    }
    df <- read.csv(path)
    df <- df[df$found == 1, ]
    if (nrow(df) == 0) next
    df$taxon <- datasets[[ds]]
    df$pool <- pool
    all_data[[length(all_data) + 1]] <- df
  }
}

combined <- bind_rows(all_data)
combined$taxon <- factor(combined$taxon, levels = datasets)
combined$pool <- factor(combined$pool, levels = c("100", "1000"))

p <- ggplot(combined, aes(x = coverage, y = identity)) +
  geom_point(alpha = 0.5, size = 1.5) +
  facet_grid(pool ~ taxon) +
  labs(x = "Coverage (%)", y = "Identity (%)") +
  theme_bw(base_size = 11)

ggsave("fur_in_seqwin_grid.png", p, width = 10, height = 6, dpi = 300)
message("wrote fur_in_seqwin_grid.png")