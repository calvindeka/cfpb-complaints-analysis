# Small, tested helper functions for the monetary-relief model (base R only).

# AUC = probability that a randomly chosen positive case gets a higher score than a randomly
# chosen negative case (0.5 = coin flip, 1 = perfect ranking). Computed from ranks
# (Mann-Whitney); tied scores share their average rank.
auc <- function(y, p) {
  r <- rank(p)
  n_pos <- as.numeric(sum(y == 1))   # as.numeric: integer * integer overflows past ~2.1 billion
  n_neg <- as.numeric(sum(y == 0))
  (sum(r[y == 1]) - n_pos * (n_pos + 1) / 2) / (n_pos * n_neg)
}

# Confusion matrix + rates at a probability threshold (predict "relief" when p >= threshold).
# precision is NA when the model predicts no positives at all (0/0).
confusion_metrics <- function(y, p, threshold) {
  pred <- as.integer(p >= threshold)
  tp <- sum(pred == 1 & y == 1)
  fp <- sum(pred == 1 & y == 0)
  fn <- sum(pred == 0 & y == 1)
  tn <- sum(pred == 0 & y == 0)
  precision <- if (tp + fp == 0) NA_real_ else tp / (tp + fp)
  recall <- tp / (tp + fn)
  f1 <- if (is.na(precision) || precision + recall == 0) 0 else 2 * precision * recall / (precision + recall)
  list(tp = tp, fp = fp, fn = fn, tn = tn, threshold = threshold,
       accuracy = (tp + tn) / length(y), precision = precision, recall = recall, f1 = f1)
}

# Turn a text column into a factor whose levels are decided by TRAIN data only:
# values seen at least `min_n` times in train keep their name; everything else
# (rare in train, or never seen in train) becomes "Other". This stops the test set from
# influencing the model and stops unseen categories from crashing predict().
lump_levels <- function(train_values, x, min_n = 200, other = "Other") {
  counts <- table(train_values)
  keep <- sort(names(counts)[counts >= min_n])
  factor(ifelse(x %in% keep, x, other), levels = c(keep, other))
}

# The probability cut-off that maximises F1 (balance of precision and recall) on the data given.
# We will choose it on TRAIN data and then apply it, unchanged, to the held-out test set.
best_f1_threshold <- function(y, p, grid = seq(0.02, 0.98, by = 0.01)) {
  f1s <- vapply(grid, function(t) confusion_metrics(y, p, t)$f1, numeric(1))
  grid[which.max(f1s)]
}

# If the train data never used the "Other" level, drop it (an unused factor level gives the
# regression an NA coefficient) and fold any test value that would have been "Other" into the
# most common train level instead. If train did use "Other", keep everything as is.
fold_unused_other <- function(train_f, test_x, other = "Other") {
  if (sum(train_f == other) > 0) {
    return(list(train = droplevels(train_f), test = factor(as.character(test_x), levels = levels(train_f))))
  }
  ref <- names(which.max(table(train_f)))
  lv <- setdiff(levels(train_f), other)
  test_chr <- ifelse(as.character(test_x) == other, ref, as.character(test_x))
  list(train = factor(as.character(train_f), levels = lv), test = factor(test_chr, levels = lv))
}
