source("data.R")

library(glue)
library(ggplot2)

# Elbow method:

possible_ks <- 1:20

variance_explained <- function(k, x, reps = 100) {
  ve <- purrr::map_dbl(1:reps, function(rep) {
    set.seed(rep)
    k_means <- kmeans(x, centers = k, iter.max = 1000, nstart = 10)
    return(k_means$betweenss / k_means$totss)
  })
  return(data.frame(clusters = k, repetition = 1:reps, variance_explained = ve))
}
elbow_data <- purrr::map_dfr(possible_ks, variance_explained, x = wiki_features)
p <- elbow_data %>%
  dplyr::group_by(clusters) %>%
  dplyr::summarize(
    lower = quantile(variance_explained, 0.025),
    est = median(variance_explained),
    upper = quantile(variance_explained, 0.975)
  ) %>%
  ggplot(aes(x = clusters, y = est, ymin = lower, ymax = upper)) +
  geom_ribbon(alpha = 0.5) +
  geom_line() +
  scale_y_continuous(labels = scales::percent_format(), breaks = seq(0, 1, 0.1)) +
  scale_x_reverse(breaks = 1:20, minor_breaks = NULL) +
  coord_flip() +
  theme_bw() +
  labs(
    y = "Variance explained", x = "Clusters",
    title = "Variance explained by number of clusters in k-means",
    subtitle = "See https://en.wikipedia.org/wiki/Elbow_method_(clustering) for more info",
    caption = "One should choose a number of clusters so that adding another cluster doesn't give much better modeling of the data."
  )
ggsave("deliverable/figures/elbow_method_kmeans.png", p, width = 10, height = 6, units = "in")

k_means <- function(k, x, ...) {
  kmeans(x, centers = k, ...) %>%
  fitted(method = "classes") %>%
  as.list() %>%
  dplyr::as_data_frame() %>%
  tidyr::gather(wiki, cluster) %>%
  readr::write_csv(glue("cluster_assignments/k{k}_means.csv"))
}

purrr::walk(c(4, 5, 6, 8), k_means, x = wiki_features, iter.max = 100, nstart = 5)
