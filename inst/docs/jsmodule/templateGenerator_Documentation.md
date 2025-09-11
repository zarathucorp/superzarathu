# templateGenerator Documentation

## Overview
`templateGenerator.R`은 jsmodule 패키지의 Shiny 애플리케이션 템플릿 생성 유틸리티입니다. 대화형 인터페이스를 통해 사용자가 원하는 분석 모듈들을 선택하고, 완전한 Shiny 앱 구조를 자동으로 생성해주는 코드 생성기입니다.

## Main Function

### `templateGenerator(author = "LHJ", folder_name = "my_app", save_path = getwd())`
Shiny 애플리케이션 템플릿을 대화형으로 생성하는 가젯을 실행합니다.

**Parameters:**
- `author`: 앱 제작자 이름 (기본값: "LHJ")
- `folder_name`: 생성될 앱 폴더명 (기본값: "my_app")
- `save_path`: 앱이 저장될 경로 (기본값: 현재 작업 디렉토리)

**Returns:**
- 완성된 Shiny 앱 프로젝트 폴더 (파일 시스템에 생성)
- `global.R`: 전역 설정 및 라이브러리
- `app.R`: 메인 앱 파일 (UI 및 Server)
- 선택적 추가 파일들

## Usage Examples

### Basic Template Generation
```r
library(jsmodule)

# 기본 템플릿 생성기 실행
if (interactive()) {
  templateGenerator()
}
```

### Custom Template with Specific Options
```r
library(jsmodule)

# 사용자 정의 설정으로 템플릿 생성
if (interactive()) {
  templateGenerator(
    author = "김연구자",
    folder_name = "clinical_analysis_app",
    save_path = "~/R_projects/"
  )
}
```

### Programmatic Template Creation
```r
# 스크립트에서 자동 실행을 위한 예시
# (실제로는 대화형 환경에서만 작동)

create_custom_app <- function() {
  if (interactive()) {
    # 의료 연구용 앱 템플릿
    templateGenerator(
      author = "Medical Research Team",
      folder_name = "medical_stats_app",
      save_path = "~/medical_projects/"
    )
  } else {
    message("Template generator requires interactive R session")
  }
}
```

## Available Modules

### Regression Analysis Panels
```r
# 선택 가능한 회귀분석 모듈들
regression_modules <- list(
  linear = list(
    name = "Linear Regression",
    description = "연속형 종속변수에 대한 선형회귀분석",
    functions = c("regressModuleUI", "regressModule2")
  ),
  logistic = list(
    name = "Logistic Regression", 
    description = "이진형 종속변수에 대한 로지스틱회귀분석",
    functions = c("logisticModuleUI", "logisticModule2")
  ),
  cox = list(
    name = "Cox Proportional Hazards",
    description = "생존분석을 위한 Cox 비례위험모델",
    functions = c("coxModuleUI", "coxModule2")
  )
)
```

### Visualization Panels
```r
# 선택 가능한 시각화 모듈들
plot_modules <- list(
  basic_plot = list(
    name = "Basic Plot (ggpairs)",
    description = "변수 간 관계 탐색을 위한 기본 그래프",
    functions = c("ggpairsModuleUI", "ggpairsModule2")
  ),
  histogram = list(
    name = "Histogram",
    description = "연속형 변수의 분포 시각화",
    functions = c("histogramUI", "histogramModule")
  ),
  scatter = list(
    name = "Scatterplot",
    description = "두 연속형 변수 간의 관계",
    functions = c("scatterUI", "scatterModule")  
  ),
  box = list(
    name = "Boxplot",
    description = "그룹별 분포 비교",
    functions = c("boxUI", "boxModule")
  ),
  bar = list(
    name = "Barplot", 
    description = "범주형 변수의 빈도 시각화",
    functions = c("barUI", "barModule")
  ),
  line = list(
    name = "Lineplot",
    description = "시계열 또는 연속 데이터의 추세",
    functions = c("lineUI", "lineModule")
  ),
  kaplan = list(
    name = "Kaplan-Meier Plot",
    description = "생존곡선 시각화",
    functions = c("kaplanUI", "kaplanModule")
  )
)
```

### Analysis Result Panels
```r
# 분석 결과 모듈들
result_modules <- list(
  roc = list(
    name = "ROC Analysis",
    description = "ROC 곡선 분석 및 AUC 계산",
    functions = c("rocUI", "rocModule")
  ),
  timeroc = list(
    name = "Time-dependent ROC",
    description = "시간의존적 ROC 분석",
    functions = c("timerocUI", "timerocModule2")
  )
)
```

## Generated App Structure

### File Organization
```r
# 생성되는 앱 구조
app_structure <- list(
  "global.R" = "전역 라이브러리 및 설정",
  "app.R" = "메인 Shiny 애플리케이션",
  "www/" = "CSS, JS, 이미지 등 웹 리소스 (선택적)",
  "data/" = "예제 데이터 파일 (선택적)",
  "R/" = "추가 R 스크립트 (선택적)",
  "README.md" = "앱 설명서 (선택적)"
)
```

### Generated global.R
```r
# 자동 생성되는 global.R 내용 예시
## Created by: [Author Name]
## Date: [Current Date]

# Load required libraries
library(shiny)
library(DT)
library(data.table)
library(ggplot2)
library(jstable)
library(jsmodule)

# Additional libraries based on selected modules
if (linear_regression_selected) {
  library(broom)
}

if (survival_analysis_selected) {
  library(survival)
}

# Global settings
options(shiny.maxRequestSize = 2048*1024^2)  # 2GB file upload limit
```

### Generated app.R Structure
```r
# 자동 생성되는 app.R 구조 예시
source("global.R")

# UI
ui <- fluidPage(
  titlePanel("Statistical Analysis Application"),
  
  sidebarLayout(
    sidebarPanel(
      # 데이터 입력 모듈
      csvFileInput("data"),
      width = 3
    ),
    
    mainPanel(
      tabsetPanel(
        # 선택된 모듈들에 따라 동적 생성
        tabPanel("Data", DTOutput("data_table")),
        
        # 회귀분석 탭 (선택시)
        if("linear" %in% selected_modules) {
          tabPanel("Linear Regression", 
                   regressModuleUI("linear"),
                   DTOutput("linear_results"))
        },
        
        # 시각화 탭 (선택시)  
        if("histogram" %in% selected_modules) {
          tabPanel("Histogram",
                   histogramUI("hist"),
                   plotOutput("hist_plot"))
        }
        
        # ... 기타 선택된 모듈들
      ),
      width = 9
    )
  )
)

# Server
server <- function(input, output, session) {
  # 데이터 입력 처리
  data_input <- callModule(csvFileInput, "data")
  
  # 각 모듈별 서버 로직
  if("linear" %in% selected_modules) {
    linear_results <- callModule(regressModule2, "linear", 
                                data = data_input$data,
                                data_label = data_input$data_label)
  }
  
  # ... 기타 모듈들의 서버 로직
}

# Run the application
shinyApp(ui = ui, server = server)
```

## Interface Components

### Module Selection Interface
- **체크박스 그룹**: 포함할 분석 모듈 선택
- **미리보기 패널**: 선택된 모듈들의 구조 확인
- **설정 옵션**: 앱 이름, 저장 위치 등
- **생성 버튼**: 최종 템플릿 생성 실행

### Configuration Options
```r
# 설정 가능한 옵션들
config_options <- list(
  app_title = "앱 제목 설정",
  theme = c("default", "bootstrap", "cerulean", "darkly"),
  layout = c("sidebar", "navbar", "dashboard"),
  data_input = c("csv", "excel", "multiple"),
  export_options = c("table", "plot", "report")
)
```

## Advanced Features

### Custom Module Integration
```r
# 사용자 정의 모듈 추가 방법
add_custom_module <- function(module_info) {
  # 모듈 정보 구조
  custom_module <- list(
    name = module_info$name,
    ui_function = module_info$ui_function,
    server_function = module_info$server_function,
    dependencies = module_info$required_packages,
    description = module_info$description
  )
  
  # 템플릿에 모듈 추가
  return(custom_module)
}

# 예시: 사용자 정의 분석 모듈
custom_analysis <- add_custom_module(list(
  name = "Custom Analysis",
  ui_function = "customAnalysisUI",
  server_function = "customAnalysisServer", 
  required_packages = c("custom_package"),
  description = "사용자 정의 통계 분석"
))
```

### Template Customization
```r
# 템플릿 사용자화 옵션
customize_template <- function(base_template, customizations) {
  # CSS 스타일 추가
  if("custom_css" %in% customizations) {
    add_css_file(base_template)
  }
  
  # JavaScript 기능 추가
  if("custom_js" %in% customizations) {
    add_js_functions(base_template)
  }
  
  # 추가 데이터 처리 함수
  if("data_processing" %in% customizations) {
    add_data_utilities(base_template)
  }
  
  return(base_template)
}
```

### Multi-language Support
```r
# 다국어 지원 템플릿 생성
generate_multilang_template <- function(languages = c("en", "ko")) {
  # 언어별 UI 텍스트
  ui_text <- list(
    en = list(
      title = "Statistical Analysis Application",
      data_tab = "Data",
      analysis_tab = "Analysis"
    ),
    ko = list(
      title = "통계 분석 애플리케이션",
      data_tab = "데이터",
      analysis_tab = "분석"
    )
  )
  
  # 언어 선택 UI 추가
  lang_selector <- selectInput("language", "Language/언어",
                              choices = languages, selected = "en")
  
  return(ui_text)
}
```

## Code Generation Process

### Template Processing Pipeline
```r
# 템플릿 생성 파이프라인
generation_pipeline <- function(user_selections) {
  
  # 1단계: 모듈 검증
  validate_modules(user_selections$modules)
  
  # 2단계: 의존성 분석  
  dependencies <- analyze_dependencies(user_selections$modules)
  
  # 3단계: UI 코드 생성
  ui_code <- generate_ui_code(user_selections)
  
  # 4단계: Server 코드 생성
  server_code <- generate_server_code(user_selections)
  
  # 5단계: Global 설정 생성
  global_code <- generate_global_code(dependencies)
  
  # 6단계: 파일 작성
  write_template_files(ui_code, server_code, global_code, user_selections)
  
  return("Template generated successfully!")
}
```

### Dependency Management
```r
# 의존성 자동 관리
manage_dependencies <- function(selected_modules) {
  # 필수 패키지 목록
  base_packages <- c("shiny", "DT", "data.table")
  
  # 모듈별 추가 패키지
  module_packages <- list(
    linear_regression = c("broom", "car"),
    survival_analysis = c("survival", "survminer"),
    plotting = c("ggplot2", "plotly"),
    roc_analysis = c("pROC", "timeROC")
  )
  
  # 선택된 모듈에 필요한 패키지들 수집
  required_packages <- unique(c(
    base_packages,
    unlist(module_packages[selected_modules])
  ))
  
  return(required_packages)
}
```

## Quality Control

### Code Validation
```r
# 생성된 코드 검증
validate_generated_code <- function(code_files) {
  validation_results <- list()
  
  # 구문 검사
  for(file in code_files) {
    tryCatch({
      parse(file = file)
      validation_results[[file]] <- "Valid syntax"
    }, error = function(e) {
      validation_results[[file]] <- paste("Syntax error:", e$message)
    })
  }
  
  return(validation_results)
}
```

### Testing Framework
```r
# 생성된 앱 테스트
test_generated_app <- function(app_path) {
  # 기본 실행 테스트
  app_test <- tryCatch({
    shiny::runApp(app_path, launch.browser = FALSE, test.mode = TRUE)
    "App launches successfully"
  }, error = function(e) {
    paste("Launch error:", e$message)
  })
  
  # 모듈 로딩 테스트
  module_tests <- test_module_loading(app_path)
  
  return(list(app = app_test, modules = module_tests))
}
```

## Export and Documentation

### Documentation Generation
```r
# 자동 문서 생성
generate_app_documentation <- function(app_config) {
  docs <- list(
    readme = generate_readme(app_config),
    user_guide = generate_user_guide(app_config),
    developer_notes = generate_dev_notes(app_config)
  )
  
  return(docs)
}

generate_readme <- function(config) {
  readme_content <- paste0(
    "# ", config$app_title, "\n\n",
    "Created by: ", config$author, "\n",
    "Date: ", Sys.Date(), "\n\n",
    "## Features\n",
    paste("-", config$selected_modules, collapse = "\n"), "\n\n",
    "## Usage\n",
    "```r\n",
    "shiny::runApp()\n",
    "```\n"
  )
  
  return(readme_content)
}
```

## Dependencies

### Required Packages
```r
# templateGenerator 실행에 필요한 패키지
required_for_generator <- c(
  "shiny",           # 가젯 인터페이스
  "bslib",           # Bootstrap 테마
  "DT",              # 테이블 표시
  "shinycssloaders", # 로딩 애니메이션
  "shinyWidgets"     # 고급 UI 위젯
)
```

### Generated App Dependencies
```r
# 생성되는 앱의 기본 의존성
base_app_dependencies <- c(
  "shiny",           # 핵심 프레임워크
  "DT",              # 데이터 테이블
  "data.table",      # 데이터 처리
  "jsmodule",        # 분석 모듈들
  "jstable"          # 통계 테이블 생성
)
```

## Best Practices

### Template Design Principles
- **모듈화**: 각 분석을 독립적 모듈로 구성
- **재사용성**: 다른 데이터에서도 쉽게 사용 가능
- **확장성**: 새로운 모듈 추가가 용이한 구조
- **사용자 친화성**: 직관적인 인터페이스

### Code Quality Standards
- **일관성**: 일관된 코딩 스타일 적용
- **문서화**: 충분한 주석 및 설명
- **오류 처리**: 견고한 예외 처리
- **성능**: 효율적인 데이터 처리

## Version Notes
이 문서는 jsmodule 패키지의 Shiny 앱 템플릿 생성기를 기반으로 작성되었습니다. 생성되는 앱의 구조와 기능은 선택하는 모듈에 따라 달라집니다.