library(ggplot2)

# Load shuffle counts for pool
shuffles <- read.table("clo/pool_100/shuffle_counts.txt", header = FALSE)
colnames(shuffles) <- c("count")

observed_val <- 1  # Observed MGE overlaps in pool
n_perm <- nrow(shuffles)
ge_count <- sum(shuffles$count >= observed_val)
p_val <- (ge_count + 1) / (n_perm + 1)

# Plot Null Distribution
ggplot(shuffles, aes(x = count)) +
  geom_histogram(binwidth = 1, fill = "#a6cee3", color = "#1f78b4", alpha = 0.7) +
  geom_vline(xintercept = observed_val, color = "red", linetype = "dashed", linewidth = 1.2) +
  annotate("text", x = observed_val, y = Inf, label = paste0(" Observed = ", observed_val, "\n p = ", round(p_val, 4)), 
           vjust = 2, hjust = -0.1, color = "red", fontface = "bold") +
  labs(
    title = "Permutation Null Distribution (MGE Overlaps)",
    subtitle = paste0("N = ", n_perm, " shuffles | p-value threshold resolution limit: p < 1/N (1/", n_perm, ")"),
    x = "Number of MGE Overlaps (Shuffled)",
    y = "Permutation Frequency"
  ) +
  theme_minimal(base_size = 14)

ggsave("clo_pool100_null_dist.png", width = 8, height = 5)