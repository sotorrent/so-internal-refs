# Outlier detection
# (see http://stackoverflow.com/a/12867538 and https://en.wikipedia.org/wiki/Outlier#Tukey.27s_test)

# k=1.5 (outlier) or k=3 (far outlier) typical, see Tukey test

outlier_thresholds <- function(v, k) {
  q_1 = quantile(v, na.rm=TRUE)[2]
  q_3 = quantile(v, na.rm=TRUE)[4]
  #iqr = IQR(v)
  iqr = q_3-q_1
  lower = q_1 - k*iqr
  upper = q_3 + k*iqr
  thresholds <- data.frame(lower, upper)
  row.names(thresholds) <- NULL
  return(thresholds)
}

outlier_filter <- function(v, k) { 
  thresholds <- outlier_thresholds(v, k)
  return(v<thresholds$lower | v>thresholds$upper)
}

outlier <- function(v, k) {
  return(v[outlier_filter(v,k)])
}

outlier_pos <- function(v, k) {
  return(which(outlier_filter(v, k)))
}

outlier_count <- function(v, k) {
  return(length(outlier_pos(v, k)))
}

outlier_percent <- function(v, k) {
  return(length(outlier(v, k))/length(v)*100)
}
