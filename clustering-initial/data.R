library(magrittr)

df <- readr::read_csv("data/refined.csv") %>%
  dplyr::select(-`overall size rank`) %>%
  dplyr::mutate(wiki = stringi::stri_trans_general(wiki, "latin-ascii"))

wiki_labels <- df$wiki
wiki_features <- as.matrix(df[, -1]) %>%
  set_rownames(wiki_labels)

if (exists("for_pca")) {
  if (for_pca) {
    # Remove 3 superfluous features:
    highly_correlated <- c(
      "monthly editors",
      "monthly active editors",
      "monthly new active editors",
      "monthly nonbot edits"
    )
    remove <- setdiff(highly_correlated, highly_correlated[1])
    df <- df[, -which(colnames(df) %in% remove)]
    rm(remove, highly_correlated)
    wiki_features <- as.matrix(df[, -1]) %>%
      set_rownames(wiki_labels)
  }
}

