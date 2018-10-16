# Initial wiki segmentation

We utilized multiple unsupervised learning techniques (sometimes with different number of clusters per technique) on the publicly available [wiki dimensions data](https://docs.google.com/spreadsheets/d/1a-UBqsYtJl6gpauJyanx0nyxuPqRvhzJRN817XpkuS8/edit?usp=sharing) to yield a set of segmentations, which can be found in [wiki_segments.csv](wiki_segments.csv).

Once we decide which clustering method yields the most satisfactory results and which number of clusters makes the most sense to us, we can come up with profiles/"wiki personas" by qualitatively considering the wikis in the cluster as well as quantitatively by computing cluster centers (e.g. per-dimension averages of wikis in each cluster). However, this is just an initial work so the segments are far from perfect, and we should iterate.

## Methods

### Dimensionality Reduction

In [principal component analysis (PCA)](https://en.wikipedia.org/wiki/Principal_component_analysis), the key idea is that you can reduce the number of dimensions of your data by finding these principal components (which are linear combinations of the original dimensions) that explain as much of the variability in the data as possible. The first two principal components (PCs) are orthogonal to each other (and to all the other PCs) and together explain *the most* variability, which makes them ideal for 2D visualization. For each observation -- wiki -- we can compute its *score* in each PC, which allows us to project the wikis from a bunch-of-dimensional space into a two-dimensional space.

### Cluster Analysis

- The **[k-means](https://en.wikipedia.org/wiki/K-means_clustering)** algorithm works by figuring out cluster centers (given the number of desired clusters) and then assigning each observation the cluster label of the cluster whose center the observation is most closest to (as measured by Euclidean distance).
- The **DP-means** algorithm, introduced in [Revisiting k-means: New Algorithms via Bayesian Nonparametrics](https://arxiv.org/abs/1111.0352) (Kulis & Jordan, 2011) is similar to k-means but uses a distance threshold to create clusters as needed.
- **[Hierarchical clustering](https://en.wikipedia.org/wiki/Hierarchical_clustering)** works on (Euclidean) distances between observations. In the agglomerative version (which we used), each observation starts in its own cluster and clusters are then merged together by relaxing distance constraints until all observations are in a single cluster.
- In **model-based clustering** (Guassian [mixture modeling](https://en.wikipedia.org/wiki/Mixture_model)), the clusters are assumed to be multivariate Gaussian distributions (clusters) and each observation comes from a distribution that is a weighted mixture of them. The assignment is determined by whichever component has the largest weight in the mixture.

## Results

During correlation analysis, we saw that several features (dimensions) were very highly correlated with each other (correlation > 0.9):

- monthly editors
- monthly active editors
- monthly new active editors
- monthly nonbot edits

We removed the latter three variables from PCA and retained monthly editors as a feature.

Since each PC is a weighted combination of the original dimensions, we know how much each dimension contributes to the overall value and can visualize & interpret these *loadings* too:

![Feature loadings in the first 4 principal components](figures/pca_loadings.png)

It appears that the first principal component (PC1, explaining 32% of variability) is driven in large part by dimensions associated with editing activity, content volume, and traffic. The second principal component (PC2, explaining 11% of variability) is driven primarily by dimensions associated with mobile device usage and editing by users on mobile devices. Therefore one possible interpretation is that PC1 is the size & popularity of a wiki while PC2 is the mobile-ness of its users.

However, interpretation of principal components is not an exact science. We can try to prescribe some meaning but it would not be the definitive one, so proceed with caution. **Warning**: don't pay too much attention to the *sign* (-/+), which should be regarded relatively rather than absolutely. For example, English Wikipedia can have a large negative score along PC1 but a wiki with much less traffic, content, and editing volume would have a large positive score along PC1, so it's less about absolute values and more about directionality. Unfortunately these two PCs don't capture as much variability of the data as we would have liked them to, so further work on data dimensions is needed.

Using the aforementioned PCA, we visualize the results of cluster analysis in 2D as [biplots](https://en.wikipedia.org/wiki/Biplot), which display each wiki using their principal component *scores* and display features as vectors. Because including all features as vectors would be a lot of clutter, we only show the top 5 features chosen by their [magnitude](https://en.wikipedia.org/wiki/Euclidean_vector#Length) in the space spanned by the first two principal components. This helps us interpret the clusters, for example clusters in the bottom left of each biplot contain wikis with a lot of traffic/volume/activity but without a lot of contributions from contributors on mobile devices, while clusters in the top right of each biplot contain low traffic/volume/activity wikis with greater "mobile-ness" (mobile traffic, editors using mobile devices).

Furthermore, to understand the individual clusters -- created with [unsupervised learning](https://en.wikipedia.org/wiki/Unsupervised_learning) -- we can use [supervised learning](https://en.wikipedia.org/wiki/Supervised_learning). By treating each cluster assignment as a class label, we can train certain classification models that have very useful properties:

- [Random forest](https://en.wikipedia.org/wiki/Random_forest) allows us to assess [variable importance](https://en.wikipedia.org/wiki/Random_forest#Variable_importance) -- how importance is each feature relative to other features in determining assignment to a specific cluster.
- [Logistic regression](https://en.wikipedia.org/wiki/Logistic_regression) allows us to assess the directional effect of each feature on the probability of a wiki being assigned to a specific cluster, with positive values indicating that increasing the value of the feature increases the probability and negative values indicating that increasing the value of the feature decreases that probability.

The figures are presented as follows:

| Row | What's visualized | Explanation |
|----:|:------------------|:------------|
|1|Biplot|2D projection of observations|
|2|Variable importance|(Direction-less) Importance of each feature in determining the cluster assignment|
|3|Logistic regression coefficients|(Directional) Effect of each feature on probability of being assigned to the cluster|

### k-means

[Elbow method](https://en.wikipedia.org/wiki/Elbow_method_%28clustering%29) is often used to determine the number of clusters, especially when using k-means:

![Variance explained by number of clusters in k-means](figures/elbow_method_kmeans.png)

This tells us that 4-6 clusters yield pretty good results (~60%-70% of variance explained) with 8 yielding slightly better results (75%) but beyond that the marginal improvements are not worth the extra clusters. Therefore the results presented below are for k-means with 4, 5, 6, and 8 clusters, which are all reasonable segmentations and will require review.

|4 clusters|5 clusters|6 clusters|8 clusters|
|:--------:|:--------:|:--------:|:--------:|
|[![Biplot with 4 clusters via k-means](figures/pca_biplot_k4_means.png)](figures/pca_biplot_k4_means.png)|[![Biplot with 5 clusters via k-means](figures/pca_biplot_k5_means.png)](figures/pca_biplot_k5_means.png)|[![Biplot with 6 clusters via k-means](figures/pca_biplot_k6_means.png)](figures/pca_biplot_k6_means.png)|[![Biplot with 8 clusters via k-means](figures/pca_biplot_k8_means.png)](figures/pca_biplot_k8_means.png)|
|[![Variable importance in 4 cluster assignment via k-means](figures/vi_k4_means.png)](figures/vi_k4_means.png)|[![Variable importance in 5 cluster assignment via k-means](figures/vi_k5_means.png)](figures/vi_k5_means.png)|[![Variable importance in 6 cluster assignment via k-means](figures/vi_k6_means.png)](figures/vi_k6_means.png)|[![Variable importance in 8 cluster assignment via k-means](figures/vi_k8_means.png)](figures/vi_k8_means.png)|
|[![Logistic regression coefficients in 4 cluster assignment via k-means](figures/coef_k4_means.png)](figures/coef_k4_means.png)|[![Logistic regression coefficients in 5 cluster assignment via k-means](figures/coef_k5_means.png)](figures/coef_k5_means.png)|[![Logistic regression coefficients in 6 cluster assignment via k-means](figures/coef_k6_means.png)](figures/coef_k6_means.png)|[![Logistic regression coefficients in 8 cluster assignment via k-means](figures/coef_k8_means.png)](figures/coef_k8_means.png)|

### DP-means

We tried multiple distance thresholds and retained the most reasonable clusterings (4 and 5 clusters).

|4 clusters|5 clusters|
|:--------:|:--------:|
|[![Biplot with 4 clusters via DP-means](figures/pca_biplot_dpm_k4.png)](figures/pca_biplot_dpm_k4.png)|[![Biplot with 5 clusters via DP-means](figures/pca_biplot_dpm_k5.png)](figures/pca_biplot_dpm_k5.png)|
|[![Variable importance in 4 cluster assignment via DP-means](figures/vi_dpm_k4.png)](figures/vi_dpm_k4.png)|[![Variable importance in 5 cluster assignment via DP-means](figures/vi_dpm_k5.png)](figures/vi_dpm_k5.png)|
|[![Logistic regression coefficients in 4 cluster assignment via DP-means](figures/coef_dpm_k4.png)](figures/coef_dpm_k4.png)|[![Logistic regression coefficients in 5 cluster assignment via DP-means](figures/coef_dpm_k5.png)](figures/coef_dpm_k5.png)|

### Hierarchical agglomerative

There are 3 different clusterings: 4, 5, and 10 clusters. In addition to biplots, these are also visualized as radial [dendrograms](https://en.wikipedia.org/wiki/Dendrogram) showing the hierarchy of the cluster assignments -- which are saved as PDF files:

|4 clusters|5 clusters|10 clusters|
|:--------:|:--------:|:---------:|
|[![radial_dendrogram_k4.pdf](figures/radial_dendrogram_k4.png)](hierarchical_dendrograms/radial_dendrogram_k4.pdf)|[![radial_dendrogram_k5.pdf](figures/radial_dendrogram_k5.png)](hierarchical_dendrograms/radial_dendrogram_k5.pdf)|[![radial_dendrogram_k10.pdf](figures/radial_dendrogram_k10.png)](hierarchical_dendrograms/radial_dendrogram_k10.pdf)|

These should be reviewed to determine if the cluster assignments make sense and which clustering should be used (4 vs 5 vs 10).

|4 clusters|5 clusters|10 clusters|
|:--------:|:--------:|:---------:|
|[![Biplot with 4 clusters via hierarchical clustering](figures/pca_biplot_hclust_k4.png)](figures/pca_biplot_hclust_k4.png)|[![Biplot with 5 clusters via hierarchical clustering](figures/pca_biplot_hclust_k5.png)](figures/pca_biplot_hclust_k5.png)|[![Biplot with 10 clusters via hierarchical clustering](figures/pca_biplot_hclust_k10.png)](figures/pca_biplot_hclust_k10.png)|
|[![Variable importance in 4 cluster assignment via hierarchical clustering](figures/vi_hclust_k4.png)](figures/vi_hclust_k4.png)|[![Variable importance in 5 cluster assignment via hierarchical clustering](figures/vi_hclust_k5.png)](figures/vi_hclust_k5.png)|[![Variable importance in 10 cluster assignment via hierarchical clustering](figures/vi_hclust_k10.png)](figures/vi_hclust_k10.png)|
|[![Logistic regression coefficients in 4 cluster assignment via hierarchical clustering](figures/coef_hclust_k4.png)](figures/coef_hclust_k4.png)|[![Logistic regression coefficients in 5 cluster assignment via hierarchical clustering](figures/coef_hclust_k5.png)](figures/coef_hclust_k5.png)|[![Logistic regression coefficients in 10 cluster assignment via hierarchical clustering](figures/coef_hclust_k10.png)](figures/coef_hclust_k10.png)|

### Model-based

This method considered different numbers of clusters and selected 4 clusters using [BIC](https://en.wikipedia.org/wiki/Bayesian_information_criterion).

|Biplot|VI Plot|LR Coefs|
|:----:|:-----:|:------:|
|[![Biplot with model-based clusters](figures/pca_biplot_model_based.png)](figures/pca_biplot_model_based.png)|[![Importance of features on assignment to clusters determined by model-based clustering](figures/vi_model_based.png)](figures/vi_model_based.png)|[![Effect of features on assignment to clusters determined by model-based clustering](figures/coef_model_based.png)](figures/coef_model_based.png)|

## Discussion

Unlike supervised learning where there is a clear objective, a truth to compare against and optimize for, unsupervised learning is a lot more open to interpretation and multiple conflicting results can all be true or meaningful in their own certain way at the same time. There are two major action items:

- **_More work is needed on the dimensions by which we break down the wikis._**
  - Intuitively, the more content a wiki has, the more there is for users to consume, which drives traffic. As content pulls readers, some of them become editors who contribute to the volume of content. Which leads to more traffic, which leads to more contributors, which leads to more content, which leads... Therefore metrics around traffic, volume, and editing activity become highly-correlated and together do not contribute a whole lot of unique information about the wikis, so we should decide what is more important for us.
  - Additionally, we should strive to develop metrics which describe the communities of the wikis or the quality of the content (not just quantity). After seeing these initial results, hopefully that can help guide conversations around which of the currently proposed new dimensions should be prioritized and added for the next iteration of clustering.
- **_Perhaps not all wikis should be included in the segmentation process._** Some of the wikis may be too small with too little activity for the metrics to be reliable.
