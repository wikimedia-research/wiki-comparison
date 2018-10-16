source("data.R")

# load cluster assignments:
cluster_assignments <- list(
  dpm_k4 = readr::read_csv("cluster_assignments/dp_means_k4.csv"),
  dpm_k5 = readr::read_csv("cluster_assignments/dp_means_k5.csv"),
  dpms_k4 = readr::read_csv("cluster_assignments/dp_means_scaled_k4.csv"),
  dpms_k5 = readr::read_csv("cluster_assignments/dp_means_scaled_k5.csv"),
  k4_means = readr::read_csv("cluster_assignments/k4_means.csv"),
  k5_means = readr::read_csv("cluster_assignments/k5_means.csv"),
  k6_means = readr::read_csv("cluster_assignments/k8_means.csv"),
  k8_means = readr::read_csv("cluster_assignments/k8_means.csv"),
  model_based = readr::read_csv("cluster_assignments/model_based.csv"),
  hclust_k4 = readr::read_csv("cluster_assignments/hclust_k4.csv"),
  hclust_k5 = readr::read_csv("cluster_assignments/hclust_k5.csv"),
  hclust_k10 = readr::read_csv("cluster_assignments/hclust_k10.csv")
) %>%
  dplyr::bind_rows(.id = "algorithm") %>%
  dplyr::mutate(cluster = as.character(cluster)) %>%
  tidyr::spread(algorithm, cluster) %>%
  dplyr::mutate_at(dplyr::vars(-wiki), factor)
df %<>%
  dplyr::left_join(cluster_assignments, by = "wiki")

clustering_algorithms <- dplyr::data_frame(
  clustering = c("dpm_k4", "dpm_k5", "dpms_k4", "dpms_k5", "hclust_k10",
                 "hclust_k4", "hclust_k5", "k4_means", "k5_means", "k6_means",
                 "k8_means", "model_based"),
  algorithm = c(rep("DP-means", 2), rep("DP-means (scaled features)", 2),
                rep("hierarchical agglomerative", 3), rep("k-means", 4),
                "model-based"),
  label = c("DP-means (4 clusters)",
            "DP-means (5 clusters)",
            "DP-means (4 clusters, scaled features)",
            "DP-means (5 clusters, scaled features)",
            "Hierarchical (10 clusters)",
            "Hierarchical (4 clusters)",
            "Hierarchical (5 clusters)",
            "k-means (4 clusters)",
            "k-means (5 clusters)",
            "k-means (6 clusters)",
            "k-means (8 clusters)",
            "Model-based (4 clusters)")
)

# deliverable <- df[, c("wiki", clustering_algorithms$clustering)]
# names(deliverable) <- c("Wiki", clustering_algorithms$label)
# readr::write_csv(deliverable, "deliverable/wiki_segments.csv")
# rm(deliverable)
