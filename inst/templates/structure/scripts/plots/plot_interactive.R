# ============================================================================
# Interactive Plot Functions (jsmodule/jskm style for Shiny)
# ============================================================================

library(data.table)
library(magrittr)
library(ggplot2)
library(plotly)
library(jskm)
library(jsmodule)

#' Create interactive scatter plot (jsmodule compatible)
#' @param data Data.table or data frame
#' @param x_var X variable name
#' @param y_var Y variable name
#' @param color_var Color variable (optional)
#' @param title Plot title
#' @return Plotly object for jsmodule
create_interactive_scatter <- function(data, x_var, y_var, color_var = NULL, title = "") {
  if (!is.data.table(data)) {
    data <- data.table(data)
  }
  
  p <- plot_ly(data, x = ~get(x_var), y = ~get(y_var), 
               type = 'scatter', mode = 'markers')
  
  if (!is.null(color_var)) {
    p <- p %>% add_trace(color = ~get(color_var))
  }
  
  p <- p %>% layout(
    title = title,
    xaxis = list(title = x_var),
    yaxis = list(title = y_var),
    hovermode = 'closest'
  )
  
  return(p)
}

#' Create interactive bar chart
#' @param data Data frame
#' @param x_var X variable name
#' @param y_var Y variable name
#' @param orientation "v" for vertical, "h" for horizontal
#' @return Plotly object
create_interactive_bar <- function(data, x_var, y_var, orientation = "v") {
  if (orientation == "v") {
    p <- plot_ly(data, x = ~get(x_var), y = ~get(y_var), type = 'bar')
  } else {
    p <- plot_ly(data, y = ~get(x_var), x = ~get(y_var), type = 'bar', orientation = 'h')
  }
  
  p <- p %>% layout(
    xaxis = list(title = if(orientation == "v") x_var else y_var),
    yaxis = list(title = if(orientation == "v") y_var else x_var)
  )
  
  return(p)
}

#' Create interactive line chart
#' @param data Data frame
#' @param x_var X variable name
#' @param y_var Y variable name
#' @param group_var Grouping variable (optional)
#' @return Plotly object
create_interactive_line <- function(data, x_var, y_var, group_var = NULL) {
  if (is.null(group_var)) {
    p <- plot_ly(data, x = ~get(x_var), y = ~get(y_var), 
                type = 'scatter', mode = 'lines+markers')
  } else {
    p <- plot_ly(data, x = ~get(x_var), y = ~get(y_var), 
                color = ~get(group_var),
                type = 'scatter', mode = 'lines+markers')
  }
  
  p <- p %>% layout(
    xaxis = list(title = x_var),
    yaxis = list(title = y_var)
  )
  
  return(p)
}

#' Create interactive heatmap
#' @param matrix_data Matrix or data frame
#' @param x_labels X axis labels
#' @param y_labels Y axis labels
#' @return Plotly heatmap
create_interactive_heatmap <- function(matrix_data, x_labels = NULL, y_labels = NULL) {
  p <- plot_ly(
    z = as.matrix(matrix_data),
    x = x_labels,
    y = y_labels,
    type = "heatmap",
    colorscale = "Viridis"
  )
  
  return(p)
}

#' Convert ggplot to interactive plotly
#' @param ggplot_obj ggplot object
#' @return Plotly object
ggplot_to_interactive <- function(ggplot_obj) {
  ggplotly(ggplot_obj)
}