source("clusters.R")

library(randomForest)
library(ggplot2)
library(glue)

if (!dir.exists("deliverable/figures")) dir.create("deliverable/figures")
purrr::walk2(clustering_algorithms$clustering, clustering_algorithms$algorithm, function(clust, algo) {

  y <- df[[clust]]
  levels(y) <- sprintf("%02.0f", as.numeric(levels(y)))
  if (clust %in% c("dpms_k4", "dpms_k6")) {
    x <- scale(wiki_features)
  } else {
    x <- wiki_features
  }
  rf_fit <- randomForest(x = x, y = y, importance = TRUE)

  variable_importance <- rf_fit$importance %>%
    apply(2, function(x) { return(abs(x) / sum(abs(x))) }) %>%
    {
      dplyr::mutate(dplyr::as_data_frame(.), feature = rownames(.))
    } %>%
    tidyr::gather(effect_on, importance, -feature) %>%
    dplyr::filter(effect_on != "MeanDecreaseGini") %>%
    dplyr::mutate(effect_on = dplyr::case_when(
      effect_on == "MeanDecreaseAccuracy" ~ "Cluster separation",
      TRUE ~ paste("Cluster No.", effect_on)
    ))

    p <- ggplot(variable_importance, aes(x = feature, y = importance, fill = importance)) +
    geom_col(show.legend = FALSE) +
    facet_wrap(~ effect_on, scales = "free_x") +
    scale_y_continuous(labels = scales::percent_format()) +
    scale_fill_continuous() +
    coord_flip() +
    labs(
      y = "Relative importance of feature", x = "Feature",
      title = "Feature importance in determining cluster assignments",
      subtitle = glue("With cluster assignment done via {algo}")
    ) +
    wmf::theme_facet(14, "Source Sans Pro")

  ggsave(glue("deliverable/figures/vi_{clust}.png"), p,
         width = 12, height = 10, dpi = 300, units = "in")

})






