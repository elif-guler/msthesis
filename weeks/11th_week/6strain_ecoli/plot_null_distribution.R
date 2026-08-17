library(ggplot2)

clades <- c("b2", "d", "e", "f")
summary_df <- read.csv("gin_mge_summary.csv")

all_shuffles <- data.frame()

for (c in clades) {
  file_path <- file.path(c, "pool_fur_markers", "shuffle_counts.txt")
  if (file.exists(file_path)) {
    df <- read.table(file_path, header = FALSE)
    colnames(df) <- c("count")
    df$clade <- toupper(c)
    all_shuffles <- rbind(all_shuffles, df)
  }
}

# Summary labels for annotations
summary_df$clade <- toupper(summary_df$dataset)
summary_df$label <- paste0("Obs = ", summary_df$observed, "\np = ", round(summary_df$pvalue, 3))

p <- ggplot(all_shuffles, aes(x = count)) +
  geom_histogram(binwidth = 1, fill = "#a6cee3", color = "#1f78b4", alpha = 0.7) +
  geom_vline(data = summary_df, aes(xintercept = observed), color = "red", linetype = "dashed", linewidth = 1) +
  geom_text(data = summary_df, aes(x = observed, y = Inf, label = label), 
            vjust = 1.5, hjust = -0.1, color = "red", fontface = "bold", size = 3.5) +
  facet_wrap(~clade, scales = "free_y") +
  labs(
    title = "Permutation Null Distributions Across E. coli Clades",
    x = "Number of MGE Overlaps (Shuffled)",
    y = "Permutation Frequency"
  ) +
  theme_minimal(base_size = 12)

ggsave("ecoli_mge_null_grid.png", plot = p, width = 9, height = 7)
cat("Saved grid plot to ecoli_mge_null_grid.png\n")
