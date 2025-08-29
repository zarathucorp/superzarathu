# ============================================================================
# Kaplan-Meier Plots using jskm package
# ============================================================================

library(data.table)
library(magrittr)
library(survival)
library(jskm)
library(survminer)

#' Create Kaplan-Meier plot using jskm
#' @param data Data.table or data frame with survival data
#' @param time_var Time variable name
#' @param event_var Event variable name
#' @param group_var Grouping variable (optional)
#' @param pval Show p-value
#' @param table Show risk table
#' @param style Plot style ("jama" or "nejm")
#' @return jskm plot object
create_km_plot <- function(data, time_var, event_var, group_var = NULL, 
                          pval = TRUE, table = TRUE, style = "jama") {
  if (!is.data.table(data)) {
    data <- data.table(data)
  }
  
  # Create survival formula
  if (is.null(group_var)) {
    surv_formula <- as.formula(paste0("Surv(", time_var, ", ", event_var, ") ~ 1"))
  } else {
    surv_formula <- as.formula(paste0("Surv(", time_var, ", ", event_var, ") ~ ", group_var))
  }
  
  # Fit survival model
  fit <- survfit(surv_formula, data = data)
  
  # Create jskm plot
  p <- jskm(
    fit,
    pval = pval,
    table = table,
    marks = TRUE,
    xlims = c(0, max(data[[time_var]], na.rm = TRUE)),
    ylims = c(0, 1),
    ystratalabs = if (!is.null(group_var)) levels(factor(data[[group_var]])) else NULL,
    ystrataname = group_var,
    theme = style
  )
  
  return(p)
}

#' Create survey-weighted Kaplan-Meier plot
#' @param svy_design Survey design object
#' @param time_var Time variable name
#' @param event_var Event variable name
#' @param group_var Grouping variable (optional)
#' @return svyjskm plot object
create_survey_km_plot <- function(svy_design, time_var, event_var, group_var = NULL) {
  # Create survival formula
  if (is.null(group_var)) {
    surv_formula <- as.formula(paste0("Surv(", time_var, ", ", event_var, ") ~ 1"))
  } else {
    surv_formula <- as.formula(paste0("Surv(", time_var, ", ", event_var, ") ~ ", group_var))
  }
  
  # Create svyjskm plot
  p <- svyjskm(
    surv_formula,
    design = svy_design,
    pval = TRUE,
    table = TRUE,
    marks = TRUE
  )
  
  return(p)
}

#' Create competing risk plot
#' @param data Data with competing events
#' @param time_var Time variable
#' @param event_var Event variable (multi-state)
#' @param group_var Grouping variable
#' @return Competing risk plot
create_competing_risk_plot <- function(data, time_var, event_var, group_var = NULL) {
  if (!is.data.table(data)) {
    data <- data.table(data)
  }
  
  # Prepare for competing risk analysis
  # This would use cmprsk package functions with jskm styling
  
  message("Competing risk analysis requires cmprsk package integration")
  # Implementation would go here
}

#' Create time-dependent ROC curve
#' @param data Data with survival data
#' @param time_var Time variable
#' @param event_var Event variable
#' @param marker_var Biomarker variable
#' @param predict_time Time point for prediction
#' @return Time-dependent ROC plot
create_timeroc_plot <- function(data, time_var, event_var, marker_var, predict_time) {
  if (!is.data.table(data)) {
    data <- data.table(data)
  }
  
  # This would integrate with timeROC package
  message("Time-dependent ROC requires timeROC package integration")
  # Implementation would go here
}