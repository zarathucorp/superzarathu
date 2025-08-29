# ============================================================================
# Modeling Functions (data.table & jstable/jsmodule compatible)
# ============================================================================

library(data.table)
library(magrittr)

#' Split data into training and test sets
#' @param data Data frame or data.table
#' @param train_prop Proportion for training set
#' @param seed Random seed
#' @return List with train and test sets
split_data <- function(data, train_prop = 0.8, seed = 123) {
  if (!is.data.table(data)) {
    data <- data.table(data)
  }
  
  set.seed(seed)
  n <- nrow(data)
  train_idx <- sample(1:n, size = floor(train_prop * n))
  
  list(
    train = data[train_idx],
    test = data[-train_idx]
  )
}

#' Build and evaluate a model
#' @param train_data Training data
#' @param test_data Test data
#' @param target Target variable name
#' @param features Feature variable names
#' @param model_type Type of model (lm, glm, etc.)
#' @return Model object with evaluation metrics
build_model <- function(train_data, test_data, target, features, model_type = "lm") {
  formula_str <- paste(target, "~", paste(features, collapse = " + "))
  formula_obj <- as.formula(formula_str)
  
  # Build model based on type
  if (model_type == "lm") {
    model <- lm(formula_obj, data = train_data)
  } else if (model_type == "glm") {
    model <- glm(formula_obj, data = train_data, family = binomial())
  } else {
    stop("Unsupported model type")
  }
  
  # Predictions
  train_pred <- predict(model, train_data)
  test_pred <- predict(model, test_data)
  
  # Evaluation metrics
  if (model_type == "lm") {
    train_rmse <- sqrt(mean((train_data[[target]] - train_pred)^2, na.rm = TRUE))
    test_rmse <- sqrt(mean((test_data[[target]] - test_pred)^2, na.rm = TRUE))
    
    metrics <- list(
      train_rmse = train_rmse,
      test_rmse = test_rmse,
      r_squared = summary(model)$r.squared
    )
  } else {
    # Add classification metrics here if needed
    metrics <- list()
  }
  
  return(list(
    model = model,
    metrics = metrics,
    predictions = list(train = train_pred, test = test_pred)
  ))
}

#' Perform cross-validation
#' @param data Data frame
#' @param target Target variable
#' @param features Feature variables
#' @param k Number of folds
#' @return Cross-validation results
cross_validate <- function(data, target, features, k = 5) {
  n <- nrow(data)
  fold_size <- floor(n / k)
  cv_results <- list()
  
  for (i in 1:k) {
    # Create fold indices
    test_idx <- ((i-1) * fold_size + 1):(min(i * fold_size, n))
    train_idx <- setdiff(1:n, test_idx)
    
    # Split data
    train_fold <- data[train_idx, ]
    test_fold <- data[test_idx, ]
    
    # Build model
    result <- build_model(train_fold, test_fold, target, features)
    cv_results[[i]] <- result$metrics
  }
  
  # Average metrics across folds
  avg_metrics <- lapply(names(cv_results[[1]]), function(metric) {
    mean(sapply(cv_results, function(x) x[[metric]]))
  })
  names(avg_metrics) <- names(cv_results[[1]])
  
  return(list(
    fold_results = cv_results,
    avg_metrics = avg_metrics
  ))
}