source("data.R")

library(glue)
library(ggplot2)
# library(ggdendro) # install.packages("ggdendro")
library(dendextend) # install.packages("dendextend")

d <- dist(scale(wiki_features))

library(cluster) # agnes()

clust_methods <- c("complete", "single", "average", "ward") %>%
  set_names(., .)

# Agglomerative coefficients (closer to 1 suggests strong clustering structure)
ac <- purrr::map_dbl(clust_methods, ~ agnes(d, method = .x)$ac)

hc <- agnes(d, method = names(ac[which.max(ac)]))
dc <- as.dendrogram(hc)

hierarchical_clusterings <- function(clusters) {
  return(tidyr::gather(dplyr::as_data_frame(as.list(cutree(dc, k = clusters))), wiki, cluster))
}

purrr::walk(
  c(4, 5, 10),
  ~ readr::write_csv(hierarchical_clusterings(.x), glue("cluster_assignments/hclust_k{.x}.csv"))
)

dendrogram_ordering <- dplyr::data_frame(index = 0:(length(wiki_labels) - 1), wiki = labels(dc))

highlighted_wikis <- hierarchical_clusterings(5) %>%
  dplyr::left_join(dendrogram_ordering, by = "wiki") %>%
  dplyr::group_by(cluster) %>%
  dplyr::arrange(cluster, index) %>%
  dplyr::filter(index %% 5 == 0) %>%
  dplyr::ungroup() %>%
  dplyr::select(wiki) %>%
  dplyr::pull()
# highlighted_wikis <- union(highlighted_wikis, c("English Wikipedia", "Wikidata", "Wikimedia Commons"))

library(circlize) # install.packages("circlize")

if (!dir.exists("deliverable/hierarchical_dendrograms")) dir.create("deliverable/hierarchical_dendrograms")

purrr::walk(c(4, 5, 10), function(n_clusters) {

  custom_cex <- set_names(rep(0.15, length(wiki_labels)), labels(dc))
  custom_cex[highlighted_wikis] <- 0.25
  custom_pch <- set_names(rep(as.numeric(NA), length(wiki_labels)), labels(dc))
  custom_pch[highlighted_wikis] <- 20
  if (n_clusters == 10) {
    custom_colors <- RColorBrewer::brewer.pal(n_clusters / 2, "Dark2")
  } else if (n_clusters == 5) {
    custom_colors <- RColorBrewer::brewer.pal(n_clusters, "Set1")
  } else if (n_clusters == 4) {
    custom_colors <- wmf::colors_discrete(8)[c("Red30", "Green30", "Accent10", "Yellow30")]
  }

  dc %<>%
    color_branches(k = n_clusters, col = custom_colors) %>%
    color_labels(k = n_clusters, col = custom_colors) %>%
    set("labels_cex", custom_cex) %>%
    set("leaves_pch", custom_pch) %>%
    set("leaves_cex", 0.3) %>%
    set("branches_lwd", 0.1) %>%
    identity()

  # par(mar = c(0, 1, 0, 1), mgp = c(0, 0, 0), oma = c(1, 1, 1, 1))
  pdf(glue("deliverable/hierarchical_dendrograms/radial_dendrogram_k{n_clusters}.pdf"), width = 11, height = 8.5)
  circlize_dendrogram(dc, labels_track_height = 0.2, dend_track_height = 0.5)
  dev.off()

})
