#!/usr/bin/env Rscript
# plot_venn_bp.R
#
# Reads venn_bp_summary.csv and draws one Venn diagram png per row,
# sized by total marker basepairs instead of marker counts.
# Run from the directory containing venn_bp_summary.csv:
#   Rscript plot_venn_bp.R

library(VennDiagram)

df <- read.csv("venn_bp_summary.csv")

for (i in 1:nrow(df)) {
  row <- df[i, ]
  filename <- paste0("venn_bp_", row$dataset, "_", row$pool, ".png")

  png(filename, width = 6, height = 6, units = "in", res = 300)
  draw.pairwise.venn(
    area1 = row$bp_fur_only + row$bp_intersection,
    area2 = row$bp_seqwin_only + row$bp_intersection,
    cross.area = row$bp_intersection,
    category = c("fur (bp)", "seqwin (bp)"),
    fill = c("skyblue", "lightpink")
  )
  dev.off()

  print(paste("wrote", filename))
}