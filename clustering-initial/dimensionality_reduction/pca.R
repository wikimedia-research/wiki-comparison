for_pca <- TRUE
source("clusters.R")

library(ggplot2)
library(ggrepel)
library(ggfortify)

pcs <- prcomp(wiki_features, center = TRUE, scale = TRUE)

magnitude <- function(x, y) { return(sqrt((x ^ 2) + (y ^ 2))) }
# Scores (projection to space spanned by principal components):
tidy_pcs_map <- broom::tidy(pcs, matrix = "samples") %>%
  tidyr::spread(PC, value) %>%
  dplyr::left_join(cluster_assignments, by = c("row" = "wiki")) %>%
  dplyr::mutate(norm12 = purrr::map2_dbl(`1`, `2`, magnitude))
# Loadings (weights of the dimensions in the principal components):
tidy_pcs_contributions <- broom::tidy(pcs, matrix = "variables")
tidy_pcs_contributions_wide <- tidy_pcs_contributions %>%
  tidyr::spread(PC, value) %>%
  dplyr::mutate(norm12 = purrr::map2_dbl(`1`, `2`, magnitude))
# How much of variance is explained by each principal component:
tidy_pcs_explanations <- broom::tidy(pcs, matrix = "pcs")

autoplot(pcs, data = df,
         colour = "k5_means", alpha = 0.3,
         label = TRUE, label.index = highlighted_wikis,
         label.fontface = "bold",
         label.repel = TRUE,
         loadings = TRUE, loadings.label = TRUE,
         loadings.top.n = 5,
         loadings.colour = "black",
         loadings.label.colour = "black",
         loadings.label.size = 4,
         label.show.legend = FALSE) +
  scale_color_brewer(palette = "Set1") +
  labs(
    color = "Cluster assignment",
    title = "Segmentation and projection of Wikimedia projects",
    subtitle = "Showing scores & dimension weights from first two principal components"
  ) +
  wmf::theme_min()

if (!dir.exists("deliverable/figures")) dir.create("deliverable/figures")

p1 <- tidy_pcs_contributions %>%
  dplyr::left_join(tidy_pcs_explanations, by = "PC") %>%
  dplyr::filter(PC %in% 1:4) %>%
  dplyr::mutate(PC = sprintf("PC%i (%.2f%%)", PC, 100 * percent), value = abs(value)) %>%
  ggplot(aes(x = column, y = value, fill = value)) +
  geom_col(show.legend = FALSE, alpha = 0.8, color = "black") +
  geom_hline(yintercept = 0) +
  facet_wrap(~ PC, ncol = 4) +
  labs(
    x = NULL, y = "Relative importance in principle component",
    title = "Principal component loadings (absolute value)",
    caption = "Each principal component is a weighted sum of features and explains a certain % of total variability in data"
  ) +
  coord_flip() +
  wmf::theme_facet(14, "Source Sans Pro", clean_xaxis = TRUE)
ggsave("deliverable/figures/pca_loadings.png", p1, width = 10, height = 6, dpi = 300, units = "in")

scaler <- min(max(abs(tidy_pcs_map$`1`)) / max(abs(tidy_pcs_contributions_wide$`1`)),
              max(abs(tidy_pcs_map$`2`)) / max(abs(tidy_pcs_contributions_wide$`2`)))

purrr::walk2(clustering_algorithms$clustering, clustering_algorithms$algorithm, function(clust, algo) {

  set.seed(0)
  temp_tidy_pcs_map <- tidy_pcs_map
  temp_tidy_pcs_map$cluster <- temp_tidy_pcs_map[[clust]]

  set.seed(0)
  highlighted_wikis <- unique(c(
    "Hindi Wikipedia", "Japanese Wikipedia", "Korean Wikipedia", "Italian Wikipedia",
    "Wikidata", "Wikimedia Commons", "German Wikivoyage",
    grep("^English W.*", wiki_labels, value = TRUE)
  ))
  # so let's grab some random wikis from the clusters:
  highlighted_wikis <- union(highlighted_wikis, unlist(purrr::map(levels(df[[clust]]), function(cluster) {
    wikis_in_this_cluster <- df$wiki[df[[clust]] == cluster]
    if (any(highlighted_wikis %in% wikis_in_this_cluster)) {
      return(sample(wikis_in_this_cluster, 2))
    } else {
      return(sample(wikis_in_this_cluster, min(6, length(wikis_in_this_cluster))))
    }
  })))
  # and highlight a few additional ones:
  highlighted_wikis <- unique(c(
    highlighted_wikis,
    tidy_pcs_map$row[order(tidy_pcs_map$`2`, decreasing = TRUE)[1:2]],
    tidy_pcs_map$row[order(tidy_pcs_map$norm12, decreasing = TRUE)[1:5]]
  ))

  p2 <- ggplot(temp_tidy_pcs_map, aes(x = `1`, y = `2`)) +
    geom_segment(
      aes(x = 0, y = 0, xend = scaler * `1` * 0.8, yend = scaler * `2` * 0.8),
      data = dplyr::top_n(tidy_pcs_contributions_wide, 5, norm12),
      arrow = arrow(length = unit(0.02, "npc"), type = "closed")
    ) +
    geom_label(
      aes(x = scaler * `1` * 0.65, y = scaler * `2` * 0.65, label = column),
      data = dplyr::top_n(tidy_pcs_contributions_wide, 5, norm12),
    )
  if (max(as.numeric(levels(temp_tidy_pcs_map$cluster))) <= 6) {
    p2 <- p2 + geom_point(aes(color = cluster, shape = cluster), alpha = 0.85) +
      scale_color_brewer(palette = "Set1")
  } else {
    p2 <- p2 + geom_point(aes(color = cluster), alpha = 0.85)
  }
  p2 <- p2 + geom_label_repel(
    data = dplyr::filter(temp_tidy_pcs_map, row %in% highlighted_wikis),
    aes(label = row, color = cluster), segment.color = "gray70",
    show.legend = FALSE, fontface = "bold", seed = 42
  ) +
    labs(
      x = sprintf("First principal component (%.2f%%)", 100 * tidy_pcs_explanations$percent[tidy_pcs_explanations$PC == 1]),
      y = sprintf("Second principal component (%.2f%%)", 100 * tidy_pcs_explanations$percent[tidy_pcs_explanations$PC == 2]),
      color = glue("Cluster assignment via {algo}"), shape = glue("Cluster assignment via {algo}"),
      title = "Segmentation and projection of Wikimedia projects",
      subtitle = "Showing scores & dimension weights from first two principal components"
    ) +
    wmf::theme_min(14, base_family = "Source Sans Pro")
  ggsave(glue("deliverable/figures/pca_biplot_{clust}.png"), p2,
         width = 16, height = 10, dpi = 300, units = "in")

})
#
# library(rgl) # install.packages("rgl")
# library(car) # install.packages("car")
#
# scatter3d(
#   x = tidy_pcs_map$`1`,
#   y = tidy_pcs_map$`2`,
#   z = tidy_pcs_map$`3`,
#   groups = factor(tidy_pcs_map$k5_means),
#   surface = FALSE, grid = FALSE, ellipsoid = TRUE
# )
