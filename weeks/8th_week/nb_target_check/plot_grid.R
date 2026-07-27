#!/usr/bin/env Rscript
# plot_grid.R
#
# Reads cons_div_fur.csv / cons_div_seqwin.csv for each dataset/pool, and
# plots them in a 2 (row) x 6 (column) grid:
#   rows:    seqwin (top), fur (bottom)
#   columns: clo_100, mtb_100, sen_100 | clo_1000, mtb_1000, sen_1000
# x = fraction_nontarget_hit, y = divergence
#
# Run from the nb_target_check directory:
#   Rscript plot_grid.R

library(ggplot2)
library(dplyr)

datasets <- c(clo = "C. difficile", mtb = "M. tuberculosis", sen = "S. enterica")
pools <- c("100", "1000")
tools <- c(seqwin = "cons_div_seqwin.csv", fur = "cons_div_fur.csv")

all_data <- list()

for (ds in names(datasets)) {
  for (pool in pools) {
    for (tool in names(tools)) {
      path <- file.path(ds, paste0("pool_", pool), tools[[tool]])
      if (!file.exists(path)) {
        message("missing: ", path)
        next
      }
      df <- read.csv(path)
      if (nrow(df) == 0) next
      df$taxon <- datasets[[ds]]
      df$pool <- pool
      df$tool <- tool
      all_data[[length(all_data) + 1]] <- df
    }
  }
}

combined <- bind_rows(all_data)

# order factors so panels come out in the requested layout
combined$tool <- factor(combined$tool, levels = c("seqwin", "fur"))
combined$pool <- factor(combined$pool, levels = c("100", "1000"))
combined$taxon <- factor(combined$taxon, levels = datasets)

p <- ggplot(combined, aes(x = fraction_nontarget_hit, y = divergence)) +
  geom_point(alpha = 0.5, size = 1) +
  facet_grid(tool ~ pool + taxon) +
  labs(x = "Fraction of neighbors hit", y = "Divergence") +
  theme_bw(base_size = 10)

ggsave("cons_div_grid.png", p, width = 16, height = 6, dpi = 300)
message("wrote cons_div_grid.png")