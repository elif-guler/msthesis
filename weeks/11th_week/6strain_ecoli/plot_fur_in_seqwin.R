#!/usr/bin/env Rscript
# plot_fur_in_seqwin.R
#
# Reads fur_in_seqwin.csv for each E. coli clade (a, b1, b2, d, e, f),
# keeps only the markers that were found in seqwin's marker set (found == 1),
# and plots identity vs coverage in a 1 x 6 grid.
#
# Run from the 6strain_ecoli directory:
#   Rscript plot_fur_in_seqwin.R

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

all_data <- list()

for (ds in names(datasets)) {
  path <- file.path(ds, "fur_in_seqwin.csv")
  
  if (!file.exists(path)) {
    message("missing: ", path)
    next
  }
  
  df <- read.csv(path)
  df <- df[df$found == 1, ]
  if (nrow(df) == 0) next
  
  df$clade <- datasets[[ds]]
  all_data[[length(all_data) + 1]] <- df
}

combined <- bind_rows(all_data)
combined$clade <- factor(combined$clade, levels = datasets)

p <- ggplot(combined, aes(x = coverage, y = identity)) +
  geom_point(alpha = 0.6, size = 1.5, color = "darkgreen") +
  facet_wrap(~ clade, ncol = 6) +
  labs(
    x = "Coverage (%)", 
    y = "Identity (%)",
    title = "FUR Markers Found in SeqWin (Coverage vs Identity)"
  ) +
  theme_bw(base_size = 11) +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"))

ggsave("fur_in_seqwin_grid.png", p, width = 16, height = 4, dpi = 300)
message("wrote fur_in_seqwin_grid.png")