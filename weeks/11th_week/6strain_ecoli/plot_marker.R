#!/usr/bin/env Rscript
# plot_marker_bp.R
#
# Reads marker_bp_summary.csv (from calc_marker_bp.sh) and plots total
# basepairs of markers per clade, grouped by tool.
#
# Run from the 6strain_ecoli directory:
#   Rscript plot_marker_bp.R

library(ggplot2)
library(scales)

df <- read.csv("marker_bp_summary.csv")

# Map dataset directory names to readable clade titles
clade_names <- c(
  a  = "Clade A",
  b1 = "Clade B1",
  b2 = "Clade B2",
  d  = "Clade D",
  e  = "Clade E",
  f  = "Clade F"
)

df$clade <- clade_names[df$dataset]
df$clade <- factor(df$clade, levels = clade_names)
df$tool  <- factor(df$tool, levels = c("seqwin", "fur"))

p <- ggplot(df, aes(x = tool, y = total_bp, fill = tool)) +
  geom_col(width = 0.6) +
  facet_wrap(~ clade, ncol = 6, scales = "free_y") +
  scale_y_continuous(labels = label_comma()) +
  labs(
    x = NULL, 
    y = "Total marker basepairs", 
    fill = "Tool",
    title = "Total Marker Basepairs across E. coli Clades"
  ) +
  theme_bw(base_size = 11) +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold"),
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

ggsave("marker_bp_histogram.png", p, width = 12, height = 5, dpi = 300)
message("wrote marker_bp_histogram.png")