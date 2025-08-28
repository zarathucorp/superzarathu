# LLM 지시어: R Shiny 웹 애플리케이션 생성 (jsmodule 통합)

## 사용자 요청
`{{USER_ARGUMENTS}}`

## AI Assistant Helper
웹검색이 가능한 경우, jsmodule 패키지의 최신 함수 사용법을 확인하세요:
- GitHub 소스코드: https://github.com/jinseob2kim/jsmodule/tree/master/R
- 패키지 문서: https://jinseob2kim.github.io/jsmodule/
- CRAN: https://cran.r-project.org/package=jsmodule
- 예제 앱: https://github.com/jinseob2kim/jsmodule/tree/master/inst/example
- 데모 앱: https://jinseob2kim.shinyapps.io/jsmodule/

## 프로젝트 구조
- 데이터: `data/processed/` 폴더의 최신 RDS 자동 로드
- 앱 위치: 프로젝트 루트에 app.R 생성
- 모듈: `scripts/` 폴더의 기존 스크립트 활용
- 배포: shinyapps.io 자동 준비

## 주요 기능
- 대시보드 자동 생성
- 데이터 탐색 인터페이스
- 통계 분석 모듈 (jsmodule 통합)
- 실시간 시각화
- 보고서 생성 기능
- 반응형 UI/UX

## 앱 타입 자동 선택
```r
detect_app_type <- function(request, data) {
  request_lower <- tolower(request)
  
  if (grepl("dashboard|대시보드", request_lower)) {
    return("dashboard")
  } else if (grepl("jsmodule|통계|분석", request_lower)) {
    return("jsmodule")
  } else if (grepl("explorer|탐색", request_lower)) {
    return("explorer")
  } else if (grepl("report|보고서", request_lower)) {
    return("report")
  } else if (grepl("survey|설문", request_lower)) {
    return("survey")
  } else {
    return("standard")
  }
}
```

## 패키지 정보
- **jsmodule**: Shiny 의학통계 모듈 패키지
  - GitHub: https://github.com/jinseob2kim/jsmodule
  - 주요 모듈: jsBasicGadget, jsRegressGadget, jsSurvivalModule, jsROCModule
  - 문서: https://jinseob2kim.github.io/jsmodule/
  - 예제 앱: https://github.com/jinseob2kim/jsmodule/tree/master/inst/example

## 구현 지침

### 📍 스크립트 위치
- **메인 앱**: `app.R` (프로젝트 루트)
- **보조 함수**: `global.R`에 추가
- **테이블 모듈**: `scripts/tables/table_dt.R` 활용
- **플롯 모듈**: `scripts/plots/plot_interactive.R` 활용

### 1. 기본 앱 구조
```r
library(shiny)
library(shinydashboard)
library(DT)
library(plotly)

# UI 생성
create_ui <- function(app_type = "standard") {
  dashboardPage(
    dashboardHeader(title = "Data Analysis Dashboard"),
    
    dashboardSidebar(
      sidebarMenu(
        menuItem("Data", tabName = "data", icon = icon("database")),
        menuItem("Analysis", tabName = "analysis", icon = icon("chart-line")),
        menuItem("Visualization", tabName = "viz", icon = icon("chart-bar")),
        menuItem("Report", tabName = "report", icon = icon("file-pdf"))
      )
    ),
    
    dashboardBody(
      tags$head(
        tags$style(HTML(custom_css()))
      ),
      tabItems(
        create_data_tab(),
        create_analysis_tab(),
        create_viz_tab(),
        create_report_tab()
      )
    )
  )
}
```

### 2. jsmodule 통합 (의학통계 모듈)
```r
library(jsmodule)
# 최신 모듈 사용법은 https://github.com/jinseob2kim/jsmodule/tree/master/R 참고

create_jsmodule_app <- function(data) {
  ui <- navbarPage(
    "Statistical Analysis Platform",
    
    # 기초통계 탭
    tabPanel("Table 1",
      jsBasicGadgetUI("tb1")
    ),
    
    # 회귀분석 탭
    tabPanel("Regression",
      jsRegressGadgetUI("reg")
    ),
    
    # 생존분석 탭
    tabPanel("Survival",
      jsSurvivalUI("surv")
    ),
    
    # ROC 분석 탭
    tabPanel("ROC",
      jsROCUI("roc")
    )
  )
  
  server <- function(input, output, session) {
    # 데이터 reactive
    data_r <- reactive(data)
    
    # 모듈 서버
    callModule(jsBasicGadget, "tb1", data = data_r)
    callModule(jsRegressGadget, "reg", data = data_r)
    callModule(jsSurvival, "surv", data = data_r)
    callModule(jsROC, "roc", data = data_r)
  }
  
  shinyApp(ui, server)
}
```

### 3. 데이터 탐색 모듈
```r
create_data_tab <- function() {
  tabItem(
    tabName = "data",
    fluidRow(
      # 데이터 업로드
      box(
        title = "Data Upload",
        width = 12,
        fileInput("file", "Choose File",
                 accept = c(".csv", ".xlsx", ".rds")),
        
        # 데이터 미리보기
        DTOutput("data_preview")
      )
    ),
    
    fluidRow(
      # 데이터 요약
      box(
        title = "Data Summary",
        width = 6,
        verbatimTextOutput("data_summary")
      ),
      
      # 결측치 분석
      box(
        title = "Missing Values",
        width = 6,
        plotlyOutput("missing_plot")
      )
    )
  )
}
```

### 4. 분석 모듈
```r
create_analysis_tab <- function() {
  tabItem(
    tabName = "analysis",
    
    # 분석 선택
    fluidRow(
      box(
        title = "Analysis Settings",
        width = 4,
        selectInput("analysis_type", "Analysis Type",
                   choices = c("Descriptive", "T-test", "ANOVA", 
                             "Correlation", "Regression", "Survival")),
        
        uiOutput("analysis_controls"),
        
        actionButton("run_analysis", "Run Analysis", 
                    class = "btn-primary")
      ),
      
      # 분석 결과
      box(
        title = "Results",
        width = 8,
        DTOutput("analysis_results"),
        plotlyOutput("analysis_plot")
      )
    )
  )
}
```

### 5. 시각화 모듈
```r
create_viz_tab <- function() {
  tabItem(
    tabName = "viz",
    
    fluidRow(
      # 플롯 설정
      box(
        title = "Plot Settings",
        width = 3,
        selectInput("plot_type", "Plot Type",
                   choices = c("Histogram", "Boxplot", "Scatter", 
                             "Line", "Heatmap", "3D Scatter")),
        
        uiOutput("plot_controls"),
        
        # 인터랙티브 옵션
        checkboxInput("interactive", "Interactive Plot", TRUE),
        
        actionButton("create_plot", "Create Plot", 
                    class = "btn-success")
      ),
      
      # 플롯 출력
      box(
        title = "Visualization",
        width = 9,
        plotlyOutput("main_plot", height = "600px"),
        
        # 다운로드 버튼
        downloadButton("download_plot", "Download Plot")
      )
    )
  )
}
```

### 6. 보고서 생성 모듈
```r
create_report_tab <- function() {
  tabItem(
    tabName = "report",
    
    fluidRow(
      box(
        title = "Report Settings",
        width = 12,
        
        # 보고서 템플릿 선택
        selectInput("report_template", "Template",
                   choices = c("Basic", "Academic", "Clinical", "Custom")),
        
        # 섹션 선택
        checkboxGroupInput("report_sections", "Include Sections",
                          choices = c("Summary", "Methods", "Results", 
                                    "Tables", "Figures", "Conclusions"),
                          selected = c("Summary", "Results", "Tables", "Figures")),
        
        # 출력 형식
        radioButtons("report_format", "Output Format",
                    choices = c("HTML", "PDF", "Word", "PowerPoint"),
                    inline = TRUE),
        
        # 생성 버튼
        actionButton("generate_report", "Generate Report", 
                    class = "btn-warning", icon = icon("file-pdf")),
        
        # 다운로드
        downloadButton("download_report", "Download Report")
      )
    ),
    
    # 보고서 미리보기
    fluidRow(
      box(
        title = "Report Preview",
        width = 12,
        htmlOutput("report_preview")
      )
    )
  )
}
```

### 7. 서버 로직
```r
create_server <- function() {
  function(input, output, session) {
    # 데이터 관리
    values <- reactiveValues(
      data = NULL,
      results = list()
    )
    
    # 파일 업로드
    observeEvent(input$file, {
      ext <- tools::file_ext(input$file$datapath)
      
      if (ext == "csv") {
        values$data <- read.csv(input$file$datapath)
      } else if (ext %in% c("xlsx", "xls")) {
        values$data <- openxlsx::read.xlsx(input$file$datapath)
      } else if (ext == "rds") {
        values$data <- readRDS(input$file$datapath)
      }
    })
    
    # 데이터 미리보기
    output$data_preview <- renderDT({
      req(values$data)
      datatable(values$data, options = list(pageLength = 10))
    })
    
    # 분석 실행
    observeEvent(input$run_analysis, {
      req(values$data)
      
      result <- perform_analysis(
        values$data,
        type = input$analysis_type,
        vars = input$selected_vars
      )
      
      values$results[[input$analysis_type]] <- result
      
      # 결과 표시
      output$analysis_results <- renderDT({
        datatable(result$table)
      })
      
      output$analysis_plot <- renderPlotly({
        ggplotly(result$plot)
      })
    })
    
    # 보고서 생성
    observeEvent(input$generate_report, {
      report <- generate_report(
        data = values$data,
        results = values$results,
        sections = input$report_sections,
        template = input$report_template
      )
      
      output$report_preview <- renderUI({
        HTML(report)
      })
    })
  }
}
```

### 8. 반응형 UI 요소
```r
# 동적 UI 생성
output$analysis_controls <- renderUI({
  req(input$analysis_type)
  
  vars <- names(values$data)
  
  switch(input$analysis_type,
    "T-test" = tagList(
      selectInput("outcome_var", "Outcome Variable", 
                 choices = vars[sapply(values$data, is.numeric)]),
      selectInput("group_var", "Group Variable", 
                 choices = vars[sapply(values$data, function(x) length(unique(x)) == 2)])
    ),
    "Regression" = tagList(
      selectInput("dependent_var", "Dependent Variable", choices = vars),
      selectizeInput("independent_vars", "Independent Variables", 
                    choices = vars, multiple = TRUE)
    ),
    "Survival" = tagList(
      selectInput("time_var", "Time Variable", choices = vars),
      selectInput("event_var", "Event Variable", choices = vars),
      selectInput("strata_var", "Stratification Variable (optional)", 
                 choices = c("None", vars))
    )
  )
})
```

### 9. 앱 실행 및 배포
```r
# 앱 실행
run_app <- function(data_path = NULL, port = NULL) {
  if (!is.null(data_path)) {
    data <- load_data(data_path)
  } else {
    data <- NULL
  }
  
  app <- shinyApp(
    ui = create_ui(),
    server = create_server()
  )
  
  runApp(app, port = port, launch.browser = TRUE)
}

# 배포 준비
prepare_deployment <- function(app_dir) {
  # app.R 생성
  app_content <- '
  source("global.R")
  shinyApp(ui = create_ui(), server = create_server())
  '
  writeLines(app_content, file.path(app_dir, "app.R"))
  
  # rsconnect 배포
  # rsconnect::deployApp(app_dir)
}
```

## 사용 예시
```r
# 기본: 데이터 탐색 대시보드
"데이터 분석 앱 만들어줘"

# jsmodule 통계 앱
"의학통계 분석 앱 만들어줘"
"Table 1이랑 회귀분석 할 수 있는 앱"

# 대시보드
"실시간 모니터링 대시보드 만들어줘"
"데이터 시각화 대시보드"

# 특정 기능 앱
"생존분석 전용 앱 만들어줘"
"데이터 업로드하고 분석하는 앱"

# 보고서 생성
"결과 리포트 생성하는 앱 만들어줘"
```

## 스마트 기능
- 데이터 구조 분석 후 최적 UI 자동 생성
- jsmodule 자동 통합
- 반응형 디자인 자동 적용
- 배포 준비 자동화
- 기존 분석 스크립트 자동 연결