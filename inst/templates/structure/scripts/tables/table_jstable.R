# ============================================================================
# jstable-based Table Functions
# ============================================================================

library(data.table)
library(magrittr)
library(jstable)
library(openxlsx)

#' Create Table 1 using jstable
#' @param data Data.table or data frame
#' @param vars Variables to include (if NULL, all variables)
#' @param strata Stratification variable (optional)
#' @param labels Label data frame from mk.lev()
#' @return Table 1 object
create_table1_js <- function(data, vars = NULL, strata = NULL, labels = NULL) {
  if (!is.data.table(data)) {
    data <- data.table(data)
  }
  
  # If no vars specified, use all except strata
  if (is.null(vars)) {
    vars <- setdiff(names(data), strata)
  }
  
  # Create Table 1
  tb1 <- CreateTableOneJS(
    vars = vars,
    strata = strata,
    data = data,
    includeNA = FALSE,
    test = !is.null(strata),  # Only test if stratified
    smd = !is.null(strata)     # Only SMD if stratified
  )
  
  # Apply labels if provided
  if (!is.null(labels)) {
    tb1 <- LabeljsTable(tb1, ref = labels)
  }
  
  return(tb1)
}

#' Create regression table using jstable
#' @param model Regression model (lm, glm, coxph)
#' @param labels Label data frame from mk.lev()
#' @return Formatted regression table
create_regression_table <- function(model, labels = NULL) {
  model_class <- class(model)[1]
  
  # Select appropriate display function
  if (model_class == "lm") {
    tb <- glmshow.display(model)
  } else if (model_class == "glm") {
    tb <- glmshow.display(model)
    if (!is.null(labels)) {
      tb <- LabeljsTable(tb, ref = labels)
    }
  } else if (model_class %in% c("coxph", "coxph.penal")) {
    tb <- cox2.display(model)
    if (!is.null(labels)) {
      tb <- LabeljsCox(tb, ref = labels)
    }
  } else if (model_class == "geeglm") {
    tb <- geeglm.display(model)
    if (!is.null(labels)) {
      tb <- LabeljsGeeglm(tb, ref = labels)
    }
  } else if (model_class %in% c("lmerMod", "glmerMod")) {
    tb <- lmer.display(model)
    if (!is.null(labels)) {
      tb <- LabeljsMixed(tb, ref = labels)
    }
  } else {
    stop("Unsupported model type")
  }
  
  return(tb)
}

#' Create subgroup analysis table
#' @param data Data.table or data frame
#' @param time_var Time variable for survival
#' @param event_var Event variable for survival
#' @param indep_vars Independent variables
#' @param subgroup_vars Subgroup variables
#' @param model_type "cox" or "glm"
#' @param labels Label data frame
#' @return Subgroup analysis table
create_subgroup_table <- function(data, time_var = NULL, event_var = NULL, 
                                 indep_vars, subgroup_vars, 
                                 model_type = "cox", labels = NULL) {
  if (!is.data.table(data)) {
    data <- data.table(data)
  }
  
  if (model_type == "cox") {
    tb <- TableSubgroupMultiCox(
      formula = as.formula(paste0("Surv(", time_var, ", ", event_var, ") ~ ", 
                                 paste(indep_vars, collapse = " + "))),
      data = data,
      var_subgroups = subgroup_vars
    )
  } else {
    tb <- TableSubgroupMultiGLM(
      formula = as.formula(paste0(event_var, " ~ ", 
                                 paste(indep_vars, collapse = " + "))),
      data = data,
      var_subgroups = subgroup_vars,
      family = "binomial"
    )
  }
  
  if (!is.null(labels)) {
    # Apply labels to subgroup table
    tb <- LabeljsTable(tb, ref = labels)
  }
  
  return(tb)
}

#' Create survey-weighted regression table
#' @param design Survey design object
#' @param formula Model formula
#' @param family GLM family
#' @param labels Label data frame
#' @return Survey regression table
create_survey_table <- function(design, formula, family = "gaussian", labels = NULL) {
  tb <- svyregress.display(
    formula = formula,
    design = design,
    family = family
  )
  
  if (!is.null(labels)) {
    tb <- LabeljsTable(tb, ref = labels)
  }
  
  return(tb)
}

#' Prepare data with labels (사용자 스타일)
#' @param data Raw data
#' @param varlist List of variables to use
#' @param factor_vars Character vector of factor variable names
#' @return List with out and out.label
prepare_data_with_labels <- function(data, varlist, factor_vars = NULL) {
  if (!is.data.table(data)) {
    data <- data.table(data)
  }
  
  # Extract variables from varlist
  all_vars <- unique(unlist(varlist))
  out <- data[, .SD, .SDcols = all_vars]
  
  # Auto-detect factor variables if not provided
  if (is.null(factor_vars)) {
    factor_vars <- names(out)[sapply(out, function(x) length(unique(x)) <= 6)]
  }
  
  # Set factor and numeric types
  out[, (factor_vars) := lapply(.SD, factor), .SDcols = factor_vars]
  conti_vars <- setdiff(names(out), factor_vars)
  out[, (conti_vars) := lapply(.SD, as.numeric), .SDcols = conti_vars]
  
  # Create label data frame
  out.label <- mk.lev(out)
  
  # Auto-label binary variables
  vars01 <- sapply(factor_vars, function(v) {
    identical(levels(out[[v]]), c("0", "1"))
  })
  
  for (v in names(vars01)[vars01 == TRUE]) {
    out.label[variable == v, val_label := c("No", "Yes")]
  }
  
  return(list(
    data = out,
    label = out.label,
    varlist = varlist
  ))
}