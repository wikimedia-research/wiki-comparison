source("data.R")

library(glue)
library(dpmclust) # devtools::install_github("bearloga/dpmclust")

lambdas <- 6:11

dpm <- function(lambda, scaled, x) {
  if (scaled) x <- scale(x)
  dpm_fit <- dp_means(x, lambda)
  k <- length(dpm_fit$size)
  if (k < 2) {
    warning("Don't bother with lambda=", lambda)
  } else {
    file_name <- paste0("dp_means", ifelse(scaled, "_scaled_", "_"), glue("k{k}"))
    fitted(dpm_fit, method = "classes") %>%
      set_names(wiki_labels) %>%
      as.list() %>%
      dplyr::as_data_frame() %>%
      tidyr::gather(wiki, cluster) %>%
      readr::write_csv(glue("cluster_assignments/{file_name}.csv"))
  }
}

library(furrr)
plan(multiprocess)
future_walk2(
  rep(lambdas, 2),
  c(rep(TRUE, length(lambdas)), rep(FALSE, length(lambdas))),
  dpm, x = wiki_features
)
