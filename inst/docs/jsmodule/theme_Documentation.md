# theme Documentation

## Overview
`theme.R`은 jsmodule 패키지의 CSS 스타일링 유틸리티입니다. Shiny 애플리케이션에 일관된 시각적 스타일을 적용하기 위한 간단하고 효율적인 방법을 제공합니다. 패키지에 내장된 CSS 파일을 자동으로 로드하여 모든 jsmodule 기반 앱에서 통일된 디자인을 구현할 수 있습니다.

## Main Function

### `use_jsmodule_style()`
jsmodule 패키지의 기본 CSS 스타일을 Shiny UI에 적용하는 함수입니다.

**Parameters:**
- 매개변수 없음

**Returns:**
- CSS 파일을 참조하는 HTML `<link>` 태그 (htmltools::tags$link 객체)

**Purpose:**
- jsmodule 패키지의 일관된 스타일 적용
- 모든 통계 분석 모듈에서 통일된 UI 디자인
- 사용자 정의 스타일링의 기본 베이스 제공

## Usage Examples

### Basic Shiny Application Styling
```r
library(shiny)
library(jsmodule)

# UI에 jsmodule 스타일 적용
ui <- fluidPage(
  use_jsmodule_style(),  # CSS 스타일 로드
  
  titlePanel("Statistical Analysis with jsmodule"),
  
  sidebarLayout(
    sidebarPanel(
      h3("Analysis Options"),
      # 분석 옵션들...
    ),
    
    mainPanel(
      tabsetPanel(
        tabPanel("Data", DTOutput("data_table")),
        tabPanel("Analysis", DTOutput("analysis_results")),
        tabPanel("Plots", plotOutput("plots"))
      )
    )
  )
)

server <- function(input, output, session) {
  # 서버 로직...
}

shinyApp(ui = ui, server = server)
```

### Integration with jsmodule Gadgets
```r
library(jsmodule)

# 가젯에서 스타일 적용
create_styled_gadget <- function(data) {
  ui <- miniPage(
    use_jsmodule_style(),  # 가젯에 스타일 적용
    
    gadgetTitleBar("Data Analysis Gadget"),
    
    miniContentPanel(
      fillRow(
        fillCol(
          # 입력 컨트롤들
          selectInput("variable", "Select Variable:", names(data))
        ),
        fillCol(
          # 결과 표시
          DTOutput("results_table")
        )
      )
    )
  )
  
  server <- function(input, output, session) {
    # 가젯 서버 로직...
    observeEvent(input$done, stopApp())
    observeEvent(input$cancel, stopApp())
  }
  
  runGadget(ui, server)
}
```

### Dashboard Application
```r
library(shiny)
library(shinydashboard)
library(jsmodule)

# 대시보드에서 jsmodule 스타일 사용
ui <- dashboardPage(
  dashboardHeader(title = "Medical Statistics Dashboard"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Data Upload", tabName = "data"),
      menuItem("Descriptive Analysis", tabName = "descriptive"),
      menuItem("Regression", tabName = "regression"),
      menuItem("Survival Analysis", tabName = "survival")
    )
  ),
  
  dashboardBody(
    use_jsmodule_style(),  # jsmodule 스타일 적용
    
    tabItems(
      tabItem("data", 
        fluidRow(
          box(csvFileInput("file"), width = 12)
        )
      ),
      tabItem("descriptive",
        fluidRow(
          box(tb1moduleUI("table1"), width = 12)
        )
      )
      # 추가 탭들...
    )
  )
)
```

## CSS Style Components

### Default Styling Features
```css
/* jsmodule 기본 스타일 특징들 */

/* 테이블 스타일링 */
.dataTables_wrapper {
  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
  font-size: 14px;
}

/* 버튼 스타일링 */
.btn-primary {
  background-color: #337ab7;
  border-color: #2e6da4;
}

/* 패널 및 박스 스타일링 */
.well {
  background-color: #f5f5f5;
  border: 1px solid #e3e3e3;
  border-radius: 4px;
}

/* 통계 결과 테이블 */
.statistical-table {
  margin-top: 15px;
  margin-bottom: 15px;
}

/* 그래프 컨테이너 */
.plot-container {
  border: 1px solid #ddd;
  border-radius: 4px;
  padding: 10px;
  margin: 10px 0;
}
```

### Module-Specific Styling
```css
/* 모듈별 특화 스타일링 */

/* 회귀분석 결과 테이블 */
.regression-results {
  font-family: monospace;
  font-size: 13px;
}

/* ROC 곡선 영역 */
.roc-plot-area {
  background-color: #fafafa;
  border: 2px solid #e6e6e6;
}

/* 생존분석 플롯 */
.kaplan-meier-plot {
  border: 1px solid #cccccc;
  background-color: white;
}

/* 기술통계 테이블 */
.descriptive-stats {
  border-collapse: collapse;
  width: 100%;
}

.descriptive-stats th,
.descriptive-stats td {
  border: 1px solid #ddd;
  padding: 8px;
  text-align: left;
}
```

## Advanced Customization

### Extending Default Styles
```r
# 기본 스타일에 추가 CSS 적용
create_extended_ui <- function() {
  ui <- fluidPage(
    # 기본 jsmodule 스타일 로드
    use_jsmodule_style(),
    
    # 추가 커스텀 CSS
    tags$head(
      tags$style(HTML("
        /* 커스텀 스타일 추가 */
        .custom-header {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white;
          padding: 20px;
          border-radius: 5px;
          margin-bottom: 20px;
        }
        
        .highlight-table .dataTables_wrapper {
          border: 2px solid #007bff;
          border-radius: 5px;
        }
        
        .analysis-panel {
          box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
          border-radius: 8px;
          padding: 15px;
          margin: 10px 0;
        }
      "))
    ),
    
    div(class = "custom-header",
        h1("Advanced Statistical Analysis Platform")
    ),
    
    # UI 구성요소들...
  )
  
  return(ui)
}
```

### Theme Customization Function
```r
# 테마 사용자화 함수
apply_custom_theme <- function(primary_color = "#337ab7", 
                              secondary_color = "#5bc0de",
                              font_family = "'Segoe UI', sans-serif") {
  
  custom_css <- sprintf("
    :root {
      --primary-color: %s;
      --secondary-color: %s;
      --font-family: %s;
    }
    
    .btn-primary {
      background-color: var(--primary-color);
      border-color: var(--primary-color);
    }
    
    .nav-tabs > li.active > a {
      color: var(--primary-color);
      border-bottom-color: var(--primary-color);
    }
    
    body {
      font-family: var(--font-family);
    }
    
    .dataTables_wrapper .dataTables_paginate .paginate_button.current {
      background-color: var(--primary-color) !important;
      border-color: var(--primary-color) !important;
    }
  ", primary_color, secondary_color, font_family)
  
  return(tags$style(HTML(custom_css)))
}

# 사용 예시
ui <- fluidPage(
  use_jsmodule_style(),
  apply_custom_theme(
    primary_color = "#e74c3c",
    secondary_color = "#3498db", 
    font_family = "'Roboto', sans-serif"
  ),
  
  # UI 내용...
)
```

### Responsive Design Support
```r
# 반응형 디자인 지원
add_responsive_styles <- function() {
  tags$head(
    tags$meta(name = "viewport", content = "width=device-width, initial-scale=1"),
    tags$style(HTML("
      /* 반응형 스타일 */
      @media (max-width: 768px) {
        .sidebar {
          width: 100%;
          margin-bottom: 20px;
        }
        
        .main-panel {
          width: 100%;
        }
        
        .dataTables_wrapper {
          overflow-x: auto;
        }
        
        .plot-container {
          width: 100%;
          height: auto;
        }
      }
      
      @media (max-width: 480px) {
        .btn {
          width: 100%;
          margin: 5px 0;
        }
        
        .form-group {
          margin-bottom: 10px;
        }
      }
    "))
  )
}
```

## Integration with Popular UI Frameworks

### Bootstrap Integration
```r
# Bootstrap과 함께 사용
library(bslib)

create_bootstrap_themed_app <- function() {
  # Bootstrap 테마 정의
  my_theme <- bs_theme(
    bootswatch = "flatly",
    primary = "#007bff",
    secondary = "#6c757d"
  )
  
  ui <- fluidPage(
    theme = my_theme,
    use_jsmodule_style(),  # jsmodule 스타일 추가
    
    # UI 구성...
  )
  
  return(ui)
}
```

### Shinydashboard Integration
```r
# shinydashboard와 통합
create_dashboard_with_jsmodule_style <- function() {
  ui <- dashboardPage(
    dashboardHeader(),
    dashboardSidebar(),
    dashboardBody(
      use_jsmodule_style(),
      
      # CSS 오버라이드로 대시보드 스타일 조정
      tags$style(HTML("
        .content-wrapper, .right-side {
          background-color: #f7f7f7;
        }
        
        .box {
          border-radius: 5px;
          box-shadow: 0 1px 3px rgba(0,0,0,0.12);
        }
      ")),
      
      # 대시보드 내용...
    )
  )
  
  return(ui)
}
```

### Semantic UI Integration
```r
# Semantic UI와 함께 사용
library(semantic.dashboard)

semantic_ui_with_jsmodule <- function() {
  ui <- dashboardPage(
    dashboardHeader(),
    dashboardSidebar(),
    dashboardBody(
      use_jsmodule_style(),
      
      # Semantic UI와 jsmodule 스타일 조화
      tags$style(HTML("
        .ui.table {
          font-family: inherit;
        }
        
        .ui.button.primary {
          background-color: #337ab7;
        }
      ")),
      
      # UI 내용...
    ),
    theme = "slate"
  )
  
  return(ui)
}
```

## Technical Implementation

### File Structure
```r
# 패키지 내 CSS 파일 구조
package_structure <- list(
  "inst/assets/style.css" = "메인 CSS 파일",
  "inst/assets/modules/" = "모듈별 CSS 파일들",
  "inst/assets/themes/" = "테마 변형들",
  "inst/assets/responsive/" = "반응형 스타일"
)
```

### CSS Loading Mechanism
```r
# CSS 로딩 메커니즘 (내부 구현)
use_jsmodule_style <- function() {
  # 패키지 내 CSS 파일 경로 찾기
  css_file <- system.file("assets", "style.css", package = "jsmodule")
  
  # 파일 존재 확인
  if (css_file == "") {
    warning("jsmodule CSS file not found")
    return(NULL)
  }
  
  # CSS 파일을 HTML head에 포함
  htmltools::includeCSS(css_file)
}
```

### Dynamic Style Loading
```r
# 동적 스타일 로딩
load_conditional_styles <- function(modules_used = c()) {
  base_style <- use_jsmodule_style()
  additional_styles <- list()
  
  # 사용된 모듈에 따라 추가 CSS 로드
  if ("regression" %in% modules_used) {
    additional_styles$regression <- tags$link(
      rel = "stylesheet", 
      type = "text/css", 
      href = "regression-styles.css"
    )
  }
  
  if ("survival" %in% modules_used) {
    additional_styles$survival <- tags$link(
      rel = "stylesheet",
      type = "text/css", 
      href = "survival-styles.css"
    )
  }
  
  return(tagList(base_style, additional_styles))
}
```

## Performance Considerations

### CSS Optimization
- **최소화**: CSS 파일 크기 최적화
- **캐싱**: 브라우저 캐싱 활용
- **선택적 로딩**: 필요한 스타일만 로드
- **CDN 활용**: 외부 폰트 및 리소스 최적화

### Loading Performance
```r
# 비동기 CSS 로딩 (고급 사용)
async_load_styles <- function() {
  tags$head(
    # 중요한 스타일은 즉시 로드
    use_jsmodule_style(),
    
    # 비중요한 스타일은 비동기 로드
    tags$script(HTML("
      // 페이지 로드 완료 후 추가 스타일 로드
      window.addEventListener('load', function() {
        const link = document.createElement('link');
        link.rel = 'stylesheet';
        link.href = 'additional-styles.css';
        document.head.appendChild(link);
      });
    "))
  )
}
```

## Best Practices

### CSS 조직화
- **모듈화**: 기능별 CSS 분리
- **네이밍**: BEM 방법론 적용
- **재사용성**: 공통 클래스 활용
- **유지보수성**: 주석 및 문서화

### 호환성 고려사항
- **브라우저 호환성**: 주요 브라우저 지원
- **반응형 디자인**: 다양한 화면 크기 대응
- **접근성**: WCAG 가이드라인 준수
- **성능**: 로딩 시간 최적화

## Dependencies

### Required Packages
```r
# 필수 패키지
library(htmltools)      # HTML 태그 및 CSS 포함

# 권장 패키지  
library(bslib)          # Bootstrap 테마
library(shinythemes)    # Shiny 테마 모음
library(fresh)          # 테마 사용자화
```

### Browser Compatibility
- Chrome/Chromium (최신 2개 버전)
- Firefox (최신 2개 버전) 
- Safari (최신 2개 버전)
- Edge (최신 2개 버전)
- Internet Explorer 11 (제한적 지원)

## Version Notes
이 문서는 jsmodule 패키지의 CSS 테마 유틸리티를 기반으로 작성되었습니다. 스타일 정의는 패키지 업데이트에 따라 개선될 수 있으며, 사용자 정의 스타일과의 호환성을 위해 CSS 특이성을 고려해야 합니다.