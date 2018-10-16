source("data.R")

library(mclust)

mclust_fit <- Mclust(scale(wiki_features), G = c(4, 5, 6, 8, 10))

summary(mclust_fit)
# VEV model with 4 components

mclust_fit$classification %>%
  as.list() %>%
  dplyr::as_data_frame() %>%
  tidyr::gather(wiki, cluster) %>%
  readr::write_csv("cluster_assignments/model_based.csv")
