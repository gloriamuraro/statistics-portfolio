# Credit Risk Classification (in R)

Sample classification script demonstrating my experience with statistical
classification models in R, developed during my university studies.

This version is a cleaned-up and corrected extraction of the classification
component of a broader script I originally wrote for coursework. It fits 9
classification models on the same train/test split and compares them using
the same evaluation method as the original script: test-set
misclassification error rate, ranked to select the best-performing model.

# Data
The German Credit dataset (UCI Statlog, 1000 loan applicants, 20 predictors,
binary target: good/bad credit risk) is a public benchmark dataset for credit
risk classification. Sourced from a public GitHub mirror
(https://github.com/selva86/datasets).

# What the script does
1. Loads and inspects the dataset
2. Recodes the target variable and checks for missing values
3. Splits data into training (75%) and test (25%) sets
4. Fits nine classification models on the same split:
   - Logistic regression
   - Linear Discriminant Analysis (LDA)
   - Quadratic Discriminant Analysis (QDA)
   - Classification tree (rpart)
   - Random forest
   - Boosting / AdaBoost (ada)
   - Lasso-regularised logistic regression (glmnet) 
   - Generalised Additive Model (GAM, mgcv)
   - MARS (Multivariate Adaptive Regression Splines, via polspline)
5. Evaluates each model via confusion matrix and misclassification error
   rate on the test set, ranks them, and selects the best-performing model

# How to run
setwd("folder")  # folder containing this script and data
source("credit_risk.R")


# Packages
- Additional CRAN packages: `randomForest`, `ada`, `glmnet`,
  `polspline`, `mgcv` 

  install.packages(c("randomForest", "ada", "glmnet", "polspline"))
 

