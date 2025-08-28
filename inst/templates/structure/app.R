# ============================================================================
# Shiny Application - Standalone Version
# ============================================================================

library(shiny)
library(shinydashboard)
library(DT)
library(plotly)
library(tidyverse)
library(data.table)

# Define UI
ui <- dashboardPage(
  dashboardHeader(title = "Data Analysis Dashboard"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard")),
      menuItem("Data", tabName = "data", icon = icon("table")),
      menuItem("Analysis", tabName = "analysis", icon = icon("chart-line")),
      menuItem("Visualization", tabName = "viz", icon = icon("chart-bar")),
      menuItem("Reports", tabName = "reports", icon = icon("file-alt"))
    )
  ),
  
  dashboardBody(
    tabItems(
      # Dashboard Tab
      tabItem(
        tabName = "dashboard",
        h2("Dashboard Overview"),
        fluidRow(
          valueBoxOutput("box_records"),
          valueBoxOutput("box_variables"),
          valueBoxOutput("box_missing")
        ),
        fluidRow(
          box(
            title = "Data Summary",
            width = 12,
            status = "primary",
            solidHeader = TRUE,
            DTOutput("summary_table")
          )
        )
      ),
      
      # Data Tab
      tabItem(
        tabName = "data",
        h2("Data Management"),
        fluidRow(
          box(
            title = "Upload Data",
            width = 4,
            status = "info",
            fileInput("file_upload", "Choose CSV/Excel/RDS File",
                     accept = c(".csv", ".xlsx", ".xls", ".rds")),
            hr(),
            h4("Current Data"),
            verbatimTextOutput("data_info")
          ),
          box(
            title = "Data Preview",
            width = 8,
            status = "primary",
            DTOutput("data_preview")
          )
        ),
        fluidRow(
          box(
            title = "Variable Types",
            width = 12,
            DTOutput("var_types")
          )
        )
      ),
      
      # Analysis Tab
      tabItem(
        tabName = "analysis",
        h2("Statistical Analysis"),
        fluidRow(
          box(
            title = "Analysis Settings",
            width = 4,
            selectInput("analysis_type", "Analysis Type",
                       choices = c("Descriptive Statistics" = "desc",
                                  "T-test" = "ttest",
                                  "ANOVA" = "anova",
                                  "Correlation" = "cor",
                                  "Linear Regression" = "lm")),
            conditionalPanel(
              condition = "input.analysis_type != 'desc'",
              selectInput("outcome_var", "Outcome Variable", choices = NULL),
              selectInput("predictor_var", "Predictor Variable(s)", 
                         choices = NULL, multiple = TRUE)
            ),
            actionButton("run_analysis", "Run Analysis", class = "btn-primary")
          ),
          box(
            title = "Analysis Results",
            width = 8,
            verbatimTextOutput("analysis_results")
          )
        ),
        fluidRow(
          box(
            title = "Statistical Plot",
            width = 12,
            plotlyOutput("analysis_plot")
          )
        )
      ),
      
      # Visualization Tab
      tabItem(
        tabName = "viz",
        h2("Data Visualization"),
        fluidRow(
          box(
            title = "Plot Settings",
            width = 4,
            selectInput("plot_type", "Plot Type",
                       choices = c("Histogram" = "hist",
                                  "Box Plot" = "box",
                                  "Scatter Plot" = "scatter",
                                  "Bar Chart" = "bar",
                                  "Line Chart" = "line")),
            selectInput("x_var", "X Variable", choices = NULL),
            conditionalPanel(
              condition = "input.plot_type %in% c('scatter', 'line')",
              selectInput("y_var", "Y Variable", choices = NULL)
            ),
            selectInput("color_var", "Color By (Optional)", 
                       choices = c("None" = ""), selected = ""),
            actionButton("create_plot", "Create Plot", class = "btn-success")
          ),
          box(
            title = "Visualization",
            width = 8,
            plotlyOutput("main_plot", height = "500px")
          )
        )
      ),
      
      # Reports Tab
      tabItem(
        tabName = "reports",
        h2("Report Generation"),
        fluidRow(
          box(
            title = "Report Settings",
            width = 4,
            textInput("report_title", "Report Title", 
                     value = "Data Analysis Report"),
            checkboxGroupInput("report_sections", "Include Sections",
                              choices = c("Data Summary" = "summary",
                                        "Descriptive Statistics" = "desc",
                                        "Analysis Results" = "analysis",
                                        "Visualizations" = "plots"),
                              selected = c("summary", "desc")),
            radioButtons("report_format", "Output Format",
                        choices = c("HTML" = "html", "Word" = "word"),
                        selected = "html"),
            br(),
            downloadButton("download_report", "Generate Report", 
                          class = "btn-warning")
          ),
          box(
            title = "Report Preview",
            width = 8,
            h4("Selected sections will be included in the report"),
            verbatimTextOutput("report_preview")
          )
        )
      )
    )
  )
)

# Define Server
server <- function(input, output, session) {
  
  # Reactive values
  values <- reactiveValues(
    data = NULL,
    analysis_result = NULL,
    current_plot = NULL
  )
  
  # Load initial data
  observe({
    if (is.null(values$data)) {
      # Try to load existing data
      if (file.exists("data/processed/data.rds")) {
        values$data <- readRDS("data/processed/data.rds")
      } else if (file.exists("data/raw/data.csv")) {
        values$data <- fread("data/raw/data.csv")
      } else {
        # Create sample data for demo
        values$data <- data.frame(
          id = 1:100,
          value = rnorm(100, mean = 50, sd = 10),
          group = sample(c("A", "B", "C"), 100, replace = TRUE),
          score = rpois(100, lambda = 5),
          date = seq(Sys.Date() - 99, Sys.Date(), by = "day")
        )
      }
    }
  })
  
  # File upload
  observeEvent(input$file_upload, {
    req(input$file_upload)
    
    ext <- tools::file_ext(input$file_upload$datapath)
    
    if (ext == "csv") {
      values$data <- fread(input$file_upload$datapath)
    } else if (ext %in% c("xlsx", "xls")) {
      values$data <- readxl::read_excel(input$file_upload$datapath)
    } else if (ext == "rds") {
      values$data <- readRDS(input$file_upload$datapath)
    }
    
    showNotification("Data loaded successfully!", type = "success")
  })
  
  # Update variable selections
  observe({
    req(values$data)
    
    numeric_vars <- names(values$data)[sapply(values$data, is.numeric)]
    all_vars <- names(values$data)
    
    updateSelectInput(session, "outcome_var", choices = numeric_vars)
    updateSelectInput(session, "predictor_var", choices = all_vars)
    updateSelectInput(session, "x_var", choices = all_vars)
    updateSelectInput(session, "y_var", choices = numeric_vars)
    updateSelectInput(session, "color_var", 
                     choices = c("None" = "", all_vars))
  })
  
  # Dashboard outputs
  output$box_records <- renderValueBox({
    valueBox(
      value = ifelse(is.null(values$data), 0, nrow(values$data)),
      subtitle = "Total Records",
      icon = icon("database"),
      color = "blue"
    )
  })
  
  output$box_variables <- renderValueBox({
    valueBox(
      value = ifelse(is.null(values$data), 0, ncol(values$data)),
      subtitle = "Variables",
      icon = icon("columns"),
      color = "green"
    )
  })
  
  output$box_missing <- renderValueBox({
    missing_pct <- if (is.null(values$data)) {
      0
    } else {
      round(sum(is.na(values$data)) / (nrow(values$data) * ncol(values$data)) * 100, 2)
    }
    valueBox(
      value = paste0(missing_pct, "%"),
      subtitle = "Missing Data",
      icon = icon("exclamation-triangle"),
      color = if (missing_pct > 10) "red" else if (missing_pct > 5) "yellow" else "green"
    )
  })
  
  # Data tab outputs
  output$data_info <- renderPrint({
    req(values$data)
    cat("Dimensions:", nrow(values$data), "rows x", ncol(values$data), "columns\n")
    cat("Memory:", format(object.size(values$data), units = "MB"), "\n")
  })
  
  output$data_preview <- renderDT({
    req(values$data)
    datatable(values$data, options = list(pageLength = 10, scrollX = TRUE))
  })
  
  output$var_types <- renderDT({
    req(values$data)
    var_info <- data.frame(
      Variable = names(values$data),
      Type = sapply(values$data, class),
      Missing = sapply(values$data, function(x) sum(is.na(x))),
      Unique = sapply(values$data, function(x) length(unique(x))),
      stringsAsFactors = FALSE
    )
    datatable(var_info, options = list(pageLength = 15))
  })
  
  output$summary_table <- renderDT({
    req(values$data)
    numeric_data <- values$data[sapply(values$data, is.numeric)]
    if (ncol(numeric_data) > 0) {
      summary_df <- data.frame(
        Variable = names(numeric_data),
        Mean = round(sapply(numeric_data, mean, na.rm = TRUE), 2),
        SD = round(sapply(numeric_data, sd, na.rm = TRUE), 2),
        Min = round(sapply(numeric_data, min, na.rm = TRUE), 2),
        Max = round(sapply(numeric_data, max, na.rm = TRUE), 2),
        stringsAsFactors = FALSE
      )
      datatable(summary_df, options = list(pageLength = 10))
    }
  })
  
  # Analysis
  observeEvent(input$run_analysis, {
    req(values$data)
    
    if (input$analysis_type == "desc") {
      values$analysis_result <- summary(values$data)
    } else if (input$analysis_type == "ttest" && !is.null(input$outcome_var)) {
      # Simple t-test example
      values$analysis_result <- t.test(values$data[[input$outcome_var]])
    } else if (input$analysis_type == "lm" && 
               !is.null(input$outcome_var) && 
               !is.null(input$predictor_var)) {
      formula_str <- paste(input$outcome_var, "~", 
                          paste(input$predictor_var, collapse = " + "))
      model <- lm(as.formula(formula_str), data = values$data)
      values$analysis_result <- summary(model)
    }
    
    showNotification("Analysis completed!", type = "success")
  })
  
  output$analysis_results <- renderPrint({
    if (!is.null(values$analysis_result)) {
      print(values$analysis_result)
    }
  })
  
  output$analysis_plot <- renderPlotly({
    req(values$data, input$outcome_var)
    
    if (input$analysis_type == "desc") {
      p <- plot_ly(y = values$data[[input$outcome_var]], type = "box",
                   name = input$outcome_var)
    } else {
      p <- plot_ly()
    }
    p
  })
  
  # Visualization
  observeEvent(input$create_plot, {
    req(values$data, input$x_var)
    
    if (input$plot_type == "hist") {
      p <- plot_ly(x = values$data[[input$x_var]], type = "histogram")
    } else if (input$plot_type == "box") {
      p <- plot_ly(y = values$data[[input$x_var]], type = "box")
    } else if (input$plot_type == "scatter" && !is.null(input$y_var)) {
      p <- plot_ly(data = values$data, x = ~get(input$x_var), 
                   y = ~get(input$y_var), type = "scatter", mode = "markers")
    } else if (input$plot_type == "bar") {
      bar_data <- table(values$data[[input$x_var]])
      p <- plot_ly(x = names(bar_data), y = as.numeric(bar_data), type = "bar")
    } else {
      p <- plot_ly()
    }
    
    if (input$color_var != "" && input$color_var %in% names(values$data)) {
      p <- p %>% add_trace(color = values$data[[input$color_var]])
    }
    
    values$current_plot <- p
  })
  
  output$main_plot <- renderPlotly({
    if (!is.null(values$current_plot)) {
      values$current_plot
    } else {
      plot_ly()
    }
  })
  
  # Reports
  output$report_preview <- renderPrint({
    cat("Report will include:\n")
    if ("summary" %in% input$report_sections) cat("- Data Summary\n")
    if ("desc" %in% input$report_sections) cat("- Descriptive Statistics\n")
    if ("analysis" %in% input$report_sections) cat("- Analysis Results\n")
    if ("plots" %in% input$report_sections) cat("- Visualizations\n")
  })
  
  output$download_report <- downloadHandler(
    filename = function() {
      paste0("report_", Sys.Date(), 
             ifelse(input$report_format == "html", ".html", ".docx"))
    },
    content = function(file) {
      # Simple report generation (would need rmarkdown for full functionality)
      if (input$report_format == "html") {
        html_content <- paste(
          "<html><head><title>", input$report_title, "</title></head>",
          "<body><h1>", input$report_title, "</h1>",
          "<p>Generated on: ", Sys.Date(), "</p>",
          if ("summary" %in% input$report_sections) 
            paste("<h2>Data Summary</h2><p>", nrow(values$data), 
                  " records, ", ncol(values$data), " variables</p>", sep = ""),
          "</body></html>"
        )
        writeLines(html_content, file)
      }
    }
  )
}

# Run the application
shinyApp(ui = ui, server = server)