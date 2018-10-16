source("clusters.R")

library(glmnet)
library(ggplot2)
library(glue)
if (!dir.exists("deliverable/figures")) dir.create("deliverable/figures")

rescale <- function(x, new_min = -1, new_max = 1) {
  return((new_max - new_min) / (max(x) - min(x)) * (x - max(x)) + new_max)
}

purrr::walk2(clustering_algorithms$clustering, clustering_algorithms$algorithm, function(clust, algo) {

  y <- df[[clust]]
  clusters <- max(as.numeric(levels(y)))
  if (clust %in% c("dpms_k4", "dpms_k6")) {
    x <- as.matrix(scale(wiki_features))
  } else {
    x <- as.matrix(wiki_features)
  }

  coefs <- matrix(0, nrow = clusters, ncol = ncol(x))
  colnames(coefs) <- colnames(x)
  for (cluster in 1:clusters) {
    yy <- factor(as.numeric(y == cluster), 0:1)
    lr_fit <- glmnet(x, yy, family = "binomial", alpha = 1)
    coefs[cluster, ] <- coef(lr_fit, s = 0.01)[-1, 1]
  }

  coefs <- as.data.frame(coefs)
  coefs$cluster <- sprintf("Cluster %02.0f", 1:clusters)
  coefs <- tidyr::gather(coefs, feature, effect, -cluster)

  p <- coefs %>%
    dplyr::group_by(cluster) %>%
    dplyr::mutate(effect = (effect != 0) * rescale(effect)) %>%
    dplyr::ungroup() %>%
    ggplot(aes(x = feature, y = effect, fill = effect)) +
    geom_col(color = "black", show.legend = FALSE) +
    facet_wrap(~ cluster, scales = "free_x") +
    scale_fill_gradient2(high = "#3366cc", low = "#dd3333", mid = "white") +
    scale_y_continuous(breaks = c(-0.5, 0.5), labels = c("decreases", "increases")) +
    coord_flip() +
    wmf::theme_facet(14, "Source Sans Pro") +
    labs(
      y = "Effect of feature on assignment probability", x = "Feature",
      title = "Effect of features on clustering outcome",
      subtitle = glue("Effects estimated via logistic lasso regression, with cluster assignment done via {algo}")
    )

  ggsave(glue("deliverable/figures/coef_{clust}.png"), p,
         width = 18, height = 10, dpi = 300, units = "in")

})
