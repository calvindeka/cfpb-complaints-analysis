# Which CFPB complaints end in monetary relief?
# Run from the project root (after `python -m src.export_model_data`):
#   Rscript r/test_helpers.R && Rscript r/model.R
suppressPackageStartupMessages({ library(readr); library(dplyr); library(ggplot2); library(rpart) })
source("r/helpers.R")
set.seed(1)
dir.create("outputs", showWarnings = FALSE)

d <- read_csv("data/model_data.csv", show_col_types = FALSE)

# ---- 1. Time-based split: train on 2024, test on 2025 -------------------------------------
# A random split would let the model "peek" at the same weeks it is tested on. Real use is
# "learn from the past, predict the future", so we mimic that: 2024 -> 2025.
train <- filter(d, year == 2024)
test  <- filter(d, year == 2025)
base_train <- mean(train$relief); base_test <- mean(test$relief)
cat(sprintf("train n=%d (relief %.2f%%), test n=%d (relief %.2f%%)\n",
            nrow(train), 100 * base_train, nrow(test), 100 * base_test))

# ---- 2. Features: levels are decided from TRAIN only ---------------------------------------
# Rare categories (< 200 train rows) and categories never seen in train become "Other".
# The most common level goes first so it acts as the reference level in the regression.
make_factor <- function(col, min_n = 200) {
  f_train <- lump_levels(train[[col]], train[[col]], min_n)
  ord <- names(sort(table(f_train), decreasing = TRUE))
  ord <- c(setdiff(ord, "Other"), "Other")
  ord <- ord[ord %in% levels(f_train)]
  fold_unused_other(factor(as.character(f_train), levels = ord),
                    as.character(lump_levels(train[[col]], test[[col]], min_n)))
}
cols <- c("product", "sub_product", "issue", "state", "submitted_via", "tags")
facs <- lapply(setNames(cols, cols), make_factor)
mk <- function(part, part_name) {
  out <- data.frame(relief = part$relief)
  for (cn in cols) out[[cn]] <- facs[[cn]][[part_name]]
  out$month <- factor(part$month, levels = 1:12)
  out$log_company_volume <- log1p(part$company_volume_2024)
  out
}
tr <- mk(train, "train"); te <- mk(test, "test")
cat("levels kept: ", paste(sapply(cols, function(c) paste0(c, "=", nlevels(tr[[c]]))), collapse = ", "), "\n")

# ---- 3. Models ------------------------------------------------------------------------------
# `product` is deliberately NOT a predictor: every sub_product and issue belongs to exactly one product,
# so `product` is redundant given them. Including it made the regression unstable (odds ratios of 0
# with absurd confidence intervals), which is called collinearity. sub_product carries the product info.
form <- relief ~ sub_product + issue + state + submitted_via + tags + month + log_company_volume
logit <- glm(form, data = tr, family = binomial)
tree  <- rpart(factor(relief) ~ sub_product + issue + state + submitted_via + tags + month + log_company_volume,
               data = tr, method = "class", control = rpart.control(cp = 0.0005, minbucket = 200))

p_tr_logit <- predict(logit, tr, type = "response");  p_te_logit <- predict(logit, te, type = "response")
p_tr_tree  <- predict(tree, tr, type = "prob")[, "1"]; p_te_tree  <- predict(tree, te, type = "prob")[, "1"]

# Threshold chosen on TRAIN (best F1), then applied unchanged to the untouched test set.
th_logit <- best_f1_threshold(tr$relief, p_tr_logit)
th_tree  <- best_f1_threshold(tr$relief, p_tr_tree)

row <- function(name, y, p, th) {
  m <- confusion_metrics(y, p, th)
  data.frame(model = name, threshold = th, accuracy = m$accuracy, precision = m$precision,
             recall = m$recall, f1 = m$f1, auc = if (length(unique(p)) == 1) 0.5 else auc(y, p),
             tp = m$tp, fp = m$fp, fn = m$fn, tn = m$tn)
}
metrics <- bind_rows(
  row("baseline: always 'no relief'", te$relief, rep(0, nrow(te)), 0.5),
  row("logistic regression",          te$relief, p_te_logit, th_logit),
  row("decision tree (rpart)",        te$relief, p_te_tree,  th_tree)
)
write_csv(metrics, "outputs/model_metrics.csv")
print(as.data.frame(metrics), digits = 4)

cat(sprintf("\nTrain AUC (logit) = %.4f | Test AUC (logit) = %.4f\n", auc(tr$relief, p_tr_logit), auc(te$relief, p_te_logit)))

# Robustness: does the January-2025 surge (Navy Federal / Capital One) distort the result?
no_jan <- te$month != "1"
cat(sprintf("Test AUC excluding January 2025: logit = %.4f (n=%d)\n",
            auc(te$relief[no_jan], p_te_logit[no_jan]), sum(no_jan)))
# Simple non-model comparison: predict by product base rate alone.
prod_rate <- tapply(tr$relief, tr$product, mean)
cat(sprintf("Test AUC, product-only rule: %.4f\n", auc(te$relief, prod_rate[as.character(te$product)])))

# ---- 4. Odds ratios with 95% confidence intervals (Wald) -------------------------------------
co <- summary(logit)$coefficients
or <- data.frame(term = rownames(co), estimate = co[, 1], se = co[, 2], p_value = co[, 4], row.names = NULL) %>%
  filter(term != "(Intercept)") %>%
  mutate(odds_ratio = exp(estimate), ci_low = exp(estimate - 1.96 * se), ci_high = exp(estimate + 1.96 * se)) %>%
  arrange(desc(abs(estimate)))
write_csv(or, "outputs/model_odds_ratios.csv")
cat("\nTop drivers (|log odds| among terms with p < 0.001):\n")
print(as.data.frame(head(filter(or, p_value < 0.001), 12) %>% select(term, odds_ratio, ci_low, ci_high)), digits = 3)

top <- head(filter(or, p_value < 0.001, se < 1), 15) %>% mutate(term = factor(term, levels = rev(term)))
ggplot(top, aes(odds_ratio, term)) +
  geom_vline(xintercept = 1, linetype = "dashed") +
  geom_pointrange(aes(xmin = ci_low, xmax = ci_high)) + scale_x_log10() +
  labs(title = "Odds of monetary relief: 15 largest effects (logistic regression, trained on 2024)",
       subtitle = "Odds ratio vs. the most common category; bars = 95% CI; >1 = more relief", x = "Odds ratio (log scale)", y = NULL) +
  theme_minimal(base_size = 10)
ggsave("outputs/model_odds_ratios.png", width = 10, height = 5.5, dpi = 130)

# ---- 5. Calibration on the held-out test set: predicted vs observed by decile ---------------
cal <- te %>% mutate(pred = p_te_logit, decile = ntile(pred, 10)) %>%
  group_by(decile) %>% summarise(n = n(), mean_predicted = mean(pred), observed_rate = mean(relief), .groups = "drop")
write_csv(cal, "outputs/model_calibration.csv")
print(as.data.frame(cal), digits = 3)
ggplot(cal, aes(mean_predicted, observed_rate)) +
  geom_abline(linetype = "dashed") + geom_line() + geom_point(size = 2.5) +
  geom_text(aes(label = decile), vjust = -0.9, size = 3) +
  scale_x_continuous(labels = scales::percent) + scale_y_continuous(labels = scales::percent) +
  labs(title = "Held-out 2025 test set: predicted vs. observed monetary-relief rate, by decile of predicted risk",
       subtitle = "Dashed line = perfect calibration. Numbers = risk decile (10 = highest predicted risk).",
       x = "Mean predicted probability", y = "Observed relief rate") +
  theme_minimal(base_size = 10)
ggsave("outputs/model_calibration.png", width = 8, height = 5, dpi = 130)

writeLines(capture.output(sessionInfo()), "outputs/r_session_info.txt")
cat("\ndone\n")
