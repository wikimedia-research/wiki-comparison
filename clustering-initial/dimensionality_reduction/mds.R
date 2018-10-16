source("clusters.R")

library(ggplot2)
library(ggrepel)
library(patchwork)

d <- dist(wiki_features)

classical_mds <- cmdscale(d)

plot(classical_mds)

library(MASS)

nonmetric_mds <- isoMDS(d)

df$mds1 <- nonmetric_mds$points[, 1]
df$mds2 <- nonmetric_mds$points[, 2]

highlighted_wikis <- unique(c(
  # these are put into clusters '1' and '5':
  "Hindi Wikipedia", "Japanese Wikipedia", "Korean Wikipedia", "Italian Wikipedia",
  "Wikidata", "Wikimedia Commons", "German Wikivoyage",
  grep("^English W.*", wiki_labels, value = TRUE)
))

ggplot(df, aes(x = mds1, y = mds2, color = hclust_k5)) +
  geom_point() +
  scale_color_brewer(palette = "Set1") +
  geom_label_repel(
    data = dplyr::filter(df, wiki %in% highlighted_wikis),
    aes(label = wiki), segment.color = "gray70",
    show.legend = FALSE, fontface = "bold", seed = 42
  ) +
  labs(
    x = "MDS Coordinate 1",
    y = "MDS Coordinate 2",
    color = "Cluster assignment", shape = "Cluster assignment",
    title = "Segmentation and projection of Wikimedia projects",
    subtitle = "Projection into 2D space via multidimensional scaling (MDS)"
  ) +
  wmf::theme_min(14, base_family = "Source Sans Pro")
