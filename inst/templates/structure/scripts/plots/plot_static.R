# ============================================================================
# Static Plot Functions (data.table & jsmodule compatible)
# ============================================================================

library(data.table)
library(magrittr)
library(ggplot2)
library(scales)

#' Create publication-ready histogram
#' @param data Data frame
#' @param var Variable name
#' @param bins Number of bins
#' @param title Plot title
#' @return ggplot object
create_histogram <- function(data, var, bins = 30, title = NULL) {
  p <- ggplot(data, aes(x = .data[[var]])) +
    geom_histogram(bins = bins, fill = "steelblue", color = "black", alpha = 0.7) +
    theme_minimal() +
    labs(
      title = title %||% paste("Distribution of", var),
      x = var,
      y = "Frequency"
    ) +
    theme(
      plot.title = element_text(size = 14, face = "bold"),
      axis.title = element_text(size = 12)
    )
  
  return(p)
}

#' Create boxplot for group comparisons
#' @param data Data frame
#' @param x_var Grouping variable
#' @param y_var Numeric variable
#' @param title Plot title
#' @return ggplot object
create_boxplot <- function(data, x_var, y_var, title = NULL) {
  p <- ggplot(data, aes(x = .data[[x_var]], y = .data[[y_var]])) +
    geom_boxplot(fill = "lightblue", alpha = 0.7) +
    theme_minimal() +
    labs(
      title = title %||% paste(y_var, "by", x_var),
      x = x_var,
      y = y_var
    ) +
    theme(
      plot.title = element_text(size = 14, face = "bold"),
      axis.title = element_text(size = 12),
      axis.text.x = element_text(angle = 45, hjust = 1)
    )
  
  return(p)
}

#' Create scatter plot with regression line
#' @param data Data frame
#' @param x_var X variable
#' @param y_var Y variable
#' @param color_var Color grouping variable (optional)
#' @param title Plot title
#' @return ggplot object
create_scatterplot <- function(data, x_var, y_var, color_var = NULL, title = NULL) {
  p <- ggplot(data, aes(x = .data[[x_var]], y = .data[[y_var]]))
  
  if (!is.null(color_var)) {
    p <- p + aes(color = .data[[color_var]])
  }
  
  p <- p +
    geom_point(alpha = 0.6, size = 2) +
    geom_smooth(method = "lm", se = TRUE, alpha = 0.2) +
    theme_minimal() +
    labs(
      title = title %||% paste(y_var, "vs", x_var),
      x = x_var,
      y = y_var
    ) +
    theme(
      plot.title = element_text(size = 14, face = "bold"),
      axis.title = element_text(size = 12)
    )
  
  return(p)
}

#' Create bar plot
#' @param data Data frame
#' @param x_var Category variable
#' @param y_var Value variable (optional, for aggregated data)
#' @param title Plot title
#' @return ggplot object
create_barplot <- function(data, x_var, y_var = NULL, title = NULL) {
  if (is.null(y_var)) {
    # Count plot
    p <- ggplot(data, aes(x = .data[[x_var]])) +
      geom_bar(fill = "steelblue", alpha = 0.7)
  } else {
    # Value plot
    p <- ggplot(data, aes(x = .data[[x_var]], y = .data[[y_var]])) +
      geom_col(fill = "steelblue", alpha = 0.7)
  }
  
  p <- p +
    theme_minimal() +
    labs(
      title = title %||% paste("Distribution of", x_var),
      x = x_var,
      y = y_var %||% "Count"
    ) +
    theme(
      plot.title = element_text(size = 14, face = "bold"),
      axis.title = element_text(size = 12),
      axis.text.x = element_text(angle = 45, hjust = 1)
    )
  
  return(p)
}

#' Create all plots
#' @param data Data frame
#' @param output_dir Output directory
create_plots <- function(data, output_dir) {
  plot_dir <- file.path(output_dir, "plots")
  create_dir_if_needed(plot_dir)
  
  # Identify variable types
  numeric_vars <- names(data)[sapply(data, is.numeric)]
  categorical_vars <- names(data)[sapply(data, function(x) is.factor(x) || is.character(x))]
  
  # Create histograms for numeric variables
  for (var in numeric_vars) {
    p <- create_histogram(data, var)
    ggsave(
      filename = file.path(plot_dir, paste0("hist_", var, ".png")),
      plot = p,
      width = 8,
      height = 6,
      dpi = 300
    )
  }
  
  # Create bar plots for categorical variables
  for (var in categorical_vars) {
    if (length(unique(data[[var]])) <= 20) {  # Only for reasonable number of categories
      p <- create_barplot(data, var)
      ggsave(
        filename = file.path(plot_dir, paste0("bar_", var, ".png")),
        plot = p,
        width = 8,
        height = 6,
        dpi = 300
      )
    }
  }
  
  message("Plots saved to: ", plot_dir)
}