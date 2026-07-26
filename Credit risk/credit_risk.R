# credit_risk_classification.R
#
# Credit risk classification example using the German Credit dataset
# (1000 loan applicants, 20 predictors, binary target: good/bad credit risk).
# 
#
# This script is adapted and cleaned up from classification work I did
# during my university studies, covering several models. Each model is
# fitted on the same train/test split and compared using the same
# evaluation method: confusion matrix and misclassification error rate,
# with the lowest test error rate selected as the best model.
#
# Data source: German Credit dataset (UCI Statlog), a widely used public
# benchmark dataset for credit risk classification.
# https://github.com/selva86/datasets/blob/master/GermanCredit.csv

set.seed(123)

# ---------------------------------------------------------------
# 1. Load and inspect data
# ---------------------------------------------------------------
dati <- read.csv("german_credit.csv", header = TRUE, stringsAsFactors = TRUE)
str(dati)
summary(dati$credit_risk)

# Target variable: credit_risk (1 = good, 0 = bad) -> convert to factor
dati$credit_risk <- factor(dati$credit_risk, levels = c(0, 1), labels = c("bad", "good"))
table(dati$credit_risk)

# ---------------------------------------------------------------
# 2. Basic data quality checks
# ---------------------------------------------------------------
cat("\nMissing values per column:\n")
print(colSums(is.na(dati)))

dati <- na.omit(dati)  # drop rows with missing values, if any

# ---------------------------------------------------------------
# 3. Train / test split (75% / 25%)
# ---------------------------------------------------------------
n <- nrow(dati)
train_idx <- sample(seq_len(n), size = round(0.75 * n))
test_idx  <- setdiff(seq_len(n), train_idx)

train <- dati[train_idx, ]
test  <- dati[test_idx, ]

cat("\nTrain size:", nrow(train), " Test size:", nrow(test), "\n")

# ---------------------------------------------------------------
# 4. Logistic regression
# ---------------------------------------------------------------
log_model <- glm(credit_risk ~ ., family = binomial, data = train)

log_prob <- predict(log_model, newdata = test, type = "response")
log_pred <- ifelse(log_prob > 0.5, "good", "bad")

conf_matrix_log <- table(predicted = log_pred, actual = test$credit_risk)
cat("\n--- Logistic Regression: Confusion Matrix ---\n")
print(conf_matrix_log)

error_log <- 1 - sum(diag(conf_matrix_log)) / sum(conf_matrix_log)
cat("Logistic regression error rate:", round(error_log, 3), "\n")

# ---------------------------------------------------------------
# 5. Linear Discriminant Analysis (LDA)
# ---------------------------------------------------------------
library(MASS)

lda_model <- lda(credit_risk ~ ., data = train)
lda_pred  <- predict(lda_model, newdata = test)

conf_matrix_lda <- table(predicted = lda_pred$class, actual = test$credit_risk)
cat("\n--- LDA: Confusion Matrix ---\n")
print(conf_matrix_lda)

error_lda <- 1 - sum(diag(conf_matrix_lda)) / sum(conf_matrix_lda)
cat("LDA error rate:", round(error_lda, 3), "\n")

# ---------------------------------------------------------------
# 6. Quadratic Discriminant Analysis (QDA)
# ---------------------------------------------------------------
# QDA needs each predictor group to have enough observations per level;
# collapse rare factor levels beforehand if this ever fails on new data.
qda_model <- qda(credit_risk ~ ., data = train)
qda_pred  <- predict(qda_model, newdata = test)

conf_matrix_qda <- table(predicted = qda_pred$class, actual = test$credit_risk)
cat("\n--- QDA: Confusion Matrix ---\n")
print(conf_matrix_qda)

error_qda <- 1 - sum(diag(conf_matrix_qda)) / sum(conf_matrix_qda)
cat("QDA error rate:", round(error_qda, 3), "\n")

# ---------------------------------------------------------------
# 7. Classification tree
# ---------------------------------------------------------------
library(rpart)

tree_model <- rpart(credit_risk ~ ., data = train, method = "class")
tree_pred  <- predict(tree_model, newdata = test, type = "class")

conf_matrix_tree <- table(predicted = tree_pred, actual = test$credit_risk)
cat("\n--- Classification Tree: Confusion Matrix ---\n")
print(conf_matrix_tree)

error_tree <- 1 - sum(diag(conf_matrix_tree)) / sum(conf_matrix_tree)
cat("Classification tree error rate:", round(error_tree, 3), "\n")


# ---------------------------------------------------------------
# 8. Random forest
# ---------------------------------------------------------------
library(randomForest)

rf_model <- randomForest(credit_risk ~ ., data = train, ntree = 500, importance = TRUE)
rf_pred  <- predict(rf_model, newdata = test)

conf_matrix_rf <- table(predicted = rf_pred, actual = test$credit_risk)
cat("\n--- Random Forest: Confusion Matrix ---\n")
print(conf_matrix_rf)

error_rf <- 1 - sum(diag(conf_matrix_rf)) / sum(conf_matrix_rf)
cat("Random forest error rate:", round(error_rf, 3), "\n")


# ---------------------------------------------------------------
# 9. Boosting (AdaBoost)
# ---------------------------------------------------------------
library(ada)

boost_model <- ada(credit_risk ~ ., data = train, iter = 50)
boost_pred  <- predict(boost_model, newdata = test)

conf_matrix_boost <- table(predicted = boost_pred, actual = test$credit_risk)
cat("\n--- Boosting (AdaBoost): Confusion Matrix ---\n")
print(conf_matrix_boost)

error_boost <- 1 - sum(diag(conf_matrix_boost)) / sum(conf_matrix_boost)
cat("Boosting error rate:", round(error_boost, 3), "\n")

# ---------------------------------------------------------------
# 10. Regularised logistic regression (glmnet, replacing LARS)
# ---------------------------------------------------------------

library(glmnet)

# glmnet needs a numeric design matrix (dummy-coded factors), and no intercept column
x_train <- model.matrix(credit_risk ~ . - 1, data = train)
x_test  <- model.matrix(credit_risk ~ . - 1, data = test)
y_train <- train$credit_risk

set.seed(123)
cv_lasso <- cv.glmnet(x_train, y_train, family = "binomial", alpha = 1)
lasso_prob <- predict(cv_lasso, newx = x_test, s = "lambda.min", type = "response")
lasso_pred <- ifelse(lasso_prob > 0.5, "good", "bad")

conf_matrix_lasso <- table(predicted = lasso_pred, actual = test$credit_risk)
cat("\n--- Lasso Logistic Regression (glmnet): Confusion Matrix ---\n")
print(conf_matrix_lasso)

error_lasso <- 1 - sum(diag(conf_matrix_lasso)) / sum(conf_matrix_lasso)
cat("Lasso logistic regression error rate:", round(error_lasso, 3), "\n")

# ---------------------------------------------------------------
# 11. Generalised Additive Model (GAM)
# ---------------------------------------------------------------

library(mgcv)

gam_model <- gam(
  credit_risk ~ s(duration) + s(amount) + s(age) + status + credit_history +
    purpose + savings + employment_duration + personal_status_sex +
    other_debtors + property + other_installment_plans + housing + job +
    telephone + foreign_worker,
  family = binomial, data = train
)
gam_prob <- predict(gam_model, newdata = test, type = "response")
gam_pred <- ifelse(gam_prob > 0.5, "good", "bad")

conf_matrix_gam <- table(predicted = gam_pred, actual = test$credit_risk)
cat("\n--- GAM: Confusion Matrix ---\n")
print(conf_matrix_gam)

error_gam <- 1 - sum(diag(conf_matrix_gam)) / sum(conf_matrix_gam)
cat("GAM error rate:", round(error_gam, 3), "\n")

# ---------------------------------------------------------------
# 12. MARS (Multivariate Adaptive Regression Splines)
# ---------------------------------------------------------------
library(polspline)

# polyclass expects a numeric 0/1 response and a predictor matrix
y_train_num <- as.numeric(train$credit_risk) - 1  # 0 = bad, 1 = good
x_train_num <- model.matrix(credit_risk ~ . - 1, data = train)
x_test_num  <- model.matrix(credit_risk ~ . - 1, data = test)

mars_model <- polyclass(y_train_num, x_train_num)
mars_prob  <- ppolyclass(x_test_num, mars_model)[, 2]  # P(class = 1 = "good")
mars_pred  <- ifelse(mars_prob > 0.5, "good", "bad")

conf_matrix_mars <- table(predicted = mars_pred, actual = test$credit_risk)
cat("\n--- MARS (polyclass): Confusion Matrix ---\n")
print(conf_matrix_mars)

error_mars <- 1 - sum(diag(conf_matrix_mars)) / sum(conf_matrix_mars)
cat("MARS error rate:", round(error_mars, 3), "\n")

# ---------------------------------------------------------------
# 13. Compare all models and select the best one
# ---------------------------------------------------------------

# pick the model with the lowest error rate.
results <- data.frame(
  model = c("Logistic regression", "LDA", "QDA", "Classification tree",
            "Random forest", "Boosting (AdaBoost)",
            "Lasso logistic regression", "GAM", "MARS"),
  error_rate = c(error_log, error_lda, error_qda, error_tree,
                 error_rf, error_boost,
                 error_lasso, error_gam, error_mars)
)
results <- results[order(results$error_rate), ]

cat("\n--- Model comparison (ranked by test error rate) ---\n")
print(results, row.names = FALSE)

best_model <- results$model[1]
cat("\nBest performing model on the test set:", best_model,
    "(error rate =", round(results$error_rate[1], 3), ")\n")

