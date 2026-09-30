# Tests for r/helpers.R. Run: Rscript r/test_helpers.R   (fails loudly if any check is wrong)
source("r/helpers.R")

# --- auc: probability that a random positive outranks a random negative ---
stopifnot(auc(c(0, 0, 1, 1), c(0.1, 0.2, 0.8, 0.9)) == 1)          # perfect ranking
stopifnot(auc(c(0, 0, 1, 1), c(0.9, 0.8, 0.2, 0.1)) == 0)          # perfectly wrong
stopifnot(auc(c(0, 1, 0, 1), c(0.5, 0.5, 0.5, 0.5)) == 0.5)        # all tied = coin flip
stopifnot(abs(auc(c(0, 0, 1, 1), c(0.1, 0.4, 0.35, 0.8)) - 0.75) < 1e-12)  # hand-checked: 3 of 4 (pos, neg) pairs ranked right

# --- confusion_metrics ---
m <- confusion_metrics(y = c(1, 1, 0, 0, 0, 0), p = c(0.9, 0.2, 0.8, 0.1, 0.1, 0.1), threshold = 0.5)
stopifnot(m$tp == 1, m$fn == 1, m$fp == 1, m$tn == 3)
stopifnot(m$accuracy == 4/6, m$precision == 0.5, m$recall == 0.5)
none <- confusion_metrics(y = c(1, 0), p = c(0.1, 0.2), threshold = 0.5)   # predicts no positives at all
stopifnot(none$tp == 0, none$fp == 0, is.na(none$precision), none$recall == 0)

# --- lump_levels: levels come from TRAIN only; rare / unseen values become "Other" ---
train <- c(rep("a", 5), rep("b", 3), "c")
f <- lump_levels(train_values = train, x = c("a", "b", "c", "zzz"), min_n = 3)
stopifnot(identical(as.character(f), c("a", "b", "Other", "Other")))
stopifnot(identical(levels(f), c("a", "b", "Other")))

# --- best_f1_threshold picks the cut-off that maximises F1 on the data it is given ---
y <- c(0, 0, 0, 0, 1, 1)
p <- c(0.05, 0.1, 0.2, 0.3, 0.6, 0.7)
th <- best_f1_threshold(y, p)
stopifnot(th > 0.3 && th <= 0.6)

cat("all R helper tests passed\n")

# --- regression test: n_pos * n_neg used to overflow R's 32-bit integers (NA) on big data ---
big_y <- c(rep(0L, 100000), rep(1L, 30000))          # 30,000 x 100,000 = 3e9 pairs > 2^31
big_p <- c(seq(0, 1, length.out = 100000), seq(0.5, 1.5, length.out = 30000))
a <- auc(big_y, big_p)
stopifnot(!is.na(a), a > 0.5, a <= 1)

# --- drop_unused_other: "Other" must vanish if train never used it; test values fold to reference ---
r <- fold_unused_other(train_f = factor(c("a", "a", "b"), levels = c("a", "b", "Other")),
                       test_x = c("a", "Other", "b"))
stopifnot(identical(levels(r$train), c("a", "b")))
stopifnot(identical(as.character(r$test), c("a", "a", "b")))   # unseen "Other" -> most common level "a"
r2 <- fold_unused_other(train_f = factor(c("a", "Other", "b", "a"), levels = c("a", "b", "Other")),
                        test_x = c("Other", "b"))
stopifnot(identical(levels(r2$train), c("a", "b", "Other")), identical(as.character(r2$test), c("Other", "b")))
cat("all extra R helper tests passed\n")
