#!/usr/bin/env Rscript
# plot_marker_bp.R
#
# Reads marker_bp_summary.csv (from calc_marker_bp.sh) and plots total
# basepairs of markers per pool, grouped by tool, faceted by taxon.
#
# Run from the nb_target_check directory:
#   Rscript plot_marker_bp.R

library(ggplot2)
library(scales)

df <- read.csv("marker_bp_summary.csv")

taxon_names <- c(clo = "C. difficile", mtb = "M. tuberculosis", sen = "S. enterica")
df$taxon <- taxon_names[df$dataset]
df$taxon <- factor(df$taxon, levels = taxon_names)
df$pool <- factor(df$pool, levels = c("100", "1000"))
df$tool <- factor(df$tool, levels = c("seqwin", "fur"))

p <- ggplot(df, aes(x = tool, y = total_bp, fill = tool)) +
  geom_col(width = 0.6) +
  facet_grid(pool ~ taxon, scales = "free_y") +
  scale_y_continuous(labels = label_comma()) +
  labs(x = NULL, y = "Total marker basepairs", fill = "Tool") +
  theme_bw(base_size = 11)

ggsave("marker_bp_histogram.png", p, width = 10, height = 6, dpi = 300)
message("wrote marker_bp_histogram.png")