source("data.R")

wiki_colnames <- colnames(wiki_features)
colnames(wiki_features) <- paste0("v", 1:length(wiki_colnames))

library(corrplot) # install.packages("corrplot")
M <- cor(wiki_features)

corrplot.mixed(M, upper = "ellipse", order = "hclust")
# v10, v12, v6, v7 highly correlated
plot(df[, wiki_colnames[c(6, 7, 10, 12)]], pch = 16, col = rgb(0, 0, 0, 0.5))
