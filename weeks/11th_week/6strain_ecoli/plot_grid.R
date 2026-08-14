#!/usr/bin/env Rscript
# plot_grid.R
#
# Reads cons_div_fur.csv / cons_div_seqwin.csv for each E. coli clade (a, b1, b2, d, e, f),
# and plots them in a 2 (row) x 6 (column) grid:
#    rows:    seqwin (top), fur (bottom)
#    columns: Clade A, Clade B1, Clade B2, Clade D, Clade E, Clade F
#
# x = fraction_nontarget_hit, y = divergence
#
# Run from 6strain_ecoli directory:
#    Rscript plot_grid.R

library(ggplot2)
library(dplyr)

# Map directory names to clade labels
datasets <- c(
  a  = "Clade A",
  b1 = "Clade B1",
  b2 = "Clade B2",
  d  = "Clade D",
  e  = "Clade E",
  f  = "Clade F"
)

tools <- c(seqwin = "cons_div_seqwin.csv", fur = "cons_div_fur.csv")

all_data <- list()

for (ds in names(datasets)) {
  for (tool in names(tools)) {
    # Direct path to the clade folder (e.g., a/cons_div_fur.csv)
    path <- file.path(ds, tools[[tool]])
    
    if (!file.exists(path)) {
      message("missing: ", path)
      next
    }
    
    df <- read.csv(path)
    if (nrow(df) == 0) next
    
    df$taxon <- datasets[[ds]]
    df$tool <- tool
    all_data[[length(all_data) + 1]] <- df
  }
}

combined <- bind_rows(all_data)

# Order factors so panels display in exact specified sequence
combined$tool <- factor(combined$tool, levels = c("seqwin", "fur"))
combined$taxon <- factor(combined$taxon, levels = datasets)

p <- ggplot(combined, aes(x = fraction_nontarget_hit, y = divergence)) +
  geom_point(alpha = 0.5, size = 1, color = "darkblue") +
  facet_grid(tool ~ taxon) +
  labs(
    x = "Fraction of neighbors hit", 
    y = "Divergence",
    title = "Sequence Divergence vs Neighbor Off-Target Rate (E. coli Clades)"
  ) +
  theme_bw(base_size = 10) +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"))

ggsave("cons_div_grid.png", p, width = 16, height = 6, dpi = 300)
message("wrote cons_div_grid.png")