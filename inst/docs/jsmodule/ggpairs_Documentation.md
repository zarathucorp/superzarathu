# ggpairs Documentation

## Overview

`ggpairs.R`은 jsmodule 패키지의 시각화 모듈로, Shiny 애플리케이션에서 다변량 데이터의 상관관계와 분포를 한눈에 파악할 수 있는 pairs plot을 생성하는 기능을 제공합니다. 이 모듈은 `GGally` 패키지의 `ggpairs()` 함수를 기반으로 하여 인터랙티브한 변수 선택, 테마 커스터마이징, 그리고 다운로드 기능을 포함합니다.

## Module Components

### `ggpairsModuleUI1(id)`

ggpairs 플롯을 위한 변수 선택 UI를 생성합니다.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `id` | character | - | 모듈의 네임스페이스 식별자 |

#### Returns

Shiny UI 객체 (변수 선택 및 테마 옵션)

#### UI Components

- 변수 선택 드롭다운
- 층화변수 선택 드롭다운
- 테마 선택 드롭다운

### `ggpairsModuleUI2(id)`

ggpairs 플롯을 위한 그래프 옵션 및 다운로드 컨트롤 UI를 생성합니다.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `id` | character | - | 모듈의 네임스페이스 식별자 |

#### Returns

Shiny UI 객체 (그래프 커스터마이징 및 다운로드 옵션)

#### UI Components

- 그래프 타입 선택 패널
- 다운로드 옵션 (파일 형식, 차원 설정)
- 플롯 디스플레이 옵션

### `ggpairsModule(input, output, session, data, data_label, data_varStruct = NULL, nfactor.limit = 20)`

ggpairs 플롯 생성을 위한 서버 사이드 로직을 제공합니다.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `input` | - | - | Shiny 입력 객체 |
| `output` | - | - | Shiny 출력 객체 |
| `session` | - | - | Shiny 세션 객체 |
| `data` | data.frame | - | 분석할 데이터셋 |
| `data_label` | data.frame | - | 변수 레이블 정보 |
| `data_varStruct` | list | NULL | 변수 구조 정보 |
| `nfactor.limit` | integer | 20 | 범주형 변수 레벨 제한 |

#### Returns

다음을 포함하는 반응형 객체:
- 인터랙티브 ggpairs 플롯
- 변수별 상관계수 매트릭스
- 커스터마이징된 테마 적용

### `ggpairsModule2(input, output, session, data, data_label, data_varStruct = NULL, nfactor.limit = 20)`

반응형 데이터 입력을 위한 ggpairs 플롯 모듈입니다.

#### Parameters

동일한 매개변수를 사용하되, `data`와 `data_label`이 반응형 객체로 처리됩니다.

## Usage Examples

### 기본 사용법

```r
library(shiny)
library(jsmodule)
library(GGally)
library(ggplot2)

# UI 정의
ui <- fluidPage(
  titlePanel("Multivariate Data Exploration with ggpairs"),
  sidebarLayout(
    sidebarPanel(
      ggpairsModuleUI1("ggpairs_viz"),
      hr(),
      h4("Plot Options"),
      ggpairsModuleUI2("ggpairs_viz")
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Pairs Plot", 
                 plotOutput("pairs_plot", height = "600px")),
        tabPanel("Summary", 
                 verbatimTextOutput("plot_summary")),
        tabPanel("Correlation Matrix", 
                 DT::DTOutput("correlation_matrix"))
      )
    )
  )
)

server <- function(input, output, session) {
  # 예시 데이터 로드
  data_input <- reactive({
    mtcars
  })
  
  data_label <- reactive({
    data.frame(
      variable = names(mtcars),
      label = c("Miles per gallon", "Cylinders", "Displacement", 
               "Horsepower", "Rear axle ratio", "Weight", 
               "Quarter mile time", "Engine shape", "Transmission", 
               "Forward gears", "Carburetors"),
      stringsAsFactors = FALSE
    )
  })
  
  # ggpairs 모듈 서버
  ggpairs_result <- callModule(ggpairsModule, "ggpairs_viz",
                              data = data_input,
                              data_label = data_label,
                              nfactor.limit = 25)
  
  # 메인 플롯 출력
  output$pairs_plot <- renderPlot({
    req(ggpairs_result())
    ggpairs_result()
  })
  
  # 플롯 요약 정보
  output$plot_summary <- renderPrint({
    req(data_input())
    cat("Dataset Summary:\n")
    cat("Variables:", ncol(data_input()), "\n")
    cat("Observations:", nrow(data_input()), "\n")
    cat("Numeric variables:", sum(sapply(data_input(), is.numeric)), "\n")
    cat("Factor variables:", sum(sapply(data_input(), is.factor)), "\n")
  })
  
  # 상관계수 매트릭스
  output$correlation_matrix <- DT::renderDT({
    req(data_input())
    
    numeric_data <- data_input() %>% select_if(is.numeric)
    if(ncol(numeric_data) >= 2) {
      cor_matrix <- cor(numeric_data, use = "complete.obs")
      cor_df <- as.data.frame(round(cor_matrix, 3))
      cor_df$Variable <- rownames(cor_df)
      cor_df <- cor_df[, c("Variable", names(cor_df)[-ncol(cor_df)])]
      cor_df
    }
  }, options = list(scrollX = TRUE))
}

shinyApp(ui = ui, server = server)
```

### 고급 사용법

```r
# 복잡한 데이터 탐색 워크플로
server <- function(input, output, session) {
  # 데이터 입력 모듈 연동
  data_input <- callModule(csvFile, "datafile")
  
  # ggpairs 시각화
  ggpairs_result <- callModule(ggpairsModule2, "pairs_analysis",
                              data = reactive(data_input()$data),
                              data_label = reactive(data_input()$label))
  
  # 동적 변수 선택 기반 분석
  selected_pairs <- reactive({
    req(data_input()$data)
    
    # 수치형 변수만 선택
    numeric_vars <- data_input()$data %>%
      select_if(is.numeric) %>%
      names()
    
    # 상관계수가 높은 변수 쌍 식별
    if(length(numeric_vars) >= 2) {
      cor_matrix <- cor(data_input()$data[numeric_vars], use = "complete.obs")
      high_cor_pairs <- which(abs(cor_matrix) > 0.7 & cor_matrix != 1, arr.ind = TRUE)
      
      if(nrow(high_cor_pairs) > 0) {
        data.frame(
          var1 = rownames(cor_matrix)[high_cor_pairs[,1]],
          var2 = colnames(cor_matrix)[high_cor_pairs[,2]],
          correlation = cor_matrix[high_cor_pairs],
          stringsAsFactors = FALSE
        )
      }
    }
  })
  
  # 커스텀 ggpairs 플롯
  custom_pairs_plot <- reactive({
    req(data_input()$data)
    
    df <- data_input()$data
    numeric_vars <- df %>% select_if(is.numeric) %>% names()
    
    if(length(numeric_vars) >= 3) {
      # 선택된 변수들로 pairs plot 생성
      selected_vars <- numeric_vars[1:min(5, length(numeric_vars))]
      
      ggpairs(df[selected_vars], 
              title = "Custom Pairs Plot",
              upper = list(continuous = wrap("cor", size = 3)),
              lower = list(continuous = wrap("points", alpha = 0.6)),
              diag = list(continuous = wrap("densityDiag", alpha = 0.7))) +
        theme_minimal()
    }
  })
  
  # 고상관 변수 쌍 출력
  output$high_correlation_pairs <- DT::renderDT({
    req(selected_pairs())
    selected_pairs()
  })
  
  # 커스텀 플롯 출력
  output$custom_pairs <- renderPlot({
    req(custom_pairs_plot())
    custom_pairs_plot()
  }, height = 500)
}
```

## Visualization Features

### 지원하는 플롯 타입

#### 연속형 변수 간 관계
```r
# 상관계수 표시
upper = list(continuous = wrap("cor", size = 4))

# 산점도
lower = list(continuous = wrap("points", alpha = 0.7))

# 밀도 플롯
diag = list(continuous = wrap("densityDiag"))

# 회귀선 추가
lower = list(continuous = wrap("smooth", alpha = 0.8))
```

#### 범주형 변수 처리
```r
# 박스플롯
lower = list(combo = wrap("box", alpha = 0.7))

# 바이올린 플롯
lower = list(combo = wrap("dot", alpha = 0.8))

# 패싯 히스토그램
lower = list(combo = wrap("facethist"))
```

### 테마 커스터마이징

```r
# 사용 가능한 테마 옵션:
themes <- c(
  "theme_minimal()",
  "theme_classic()",
  "theme_bw()",
  "theme_gray()",
  "theme_void()"
)

# 커스텀 테마 적용
custom_theme <- theme_minimal() +
  theme(
    plot.title = element_text(size = 16, hjust = 0.5),
    axis.text = element_text(size = 10),
    strip.text = element_text(size = 12),
    legend.position = "bottom"
  )
```

## Advanced Customization

### 조건부 시각화

```r
# 층화변수를 이용한 조건부 플롯
stratified_pairs <- reactive({
  req(data_input()$data, input$strata_var)
  
  if(input$strata_var != "None") {
    # 층화변수별로 색상 구분
    ggpairs(data_input()$data, 
            columns = selected_numeric_vars(),
            mapping = aes_string(color = input$strata_var),
            title = paste("Pairs Plot by", input$strata_var)) +
      theme_minimal()
  }
})
```

### 상관계수 매트릭스 커스터마이징

```r
# 상관계수 시각화 옵션
correlation_visual <- reactive({
  req(data_input()$data)
  
  numeric_data <- data_input()$data %>% select_if(is.numeric)
  
  if(ncol(numeric_data) >= 2) {
    # 상관계수 히트맵
    cor_matrix <- cor(numeric_data, use = "complete.obs")
    
    # 커스텀 상관계수 플롯
    ggpairs(numeric_data,
            upper = list(continuous = wrap("cor", 
                                         method = input$correlation_method,
                                         stars = input$show_significance)),
            lower = list(continuous = wrap("points", 
                                         alpha = input$point_alpha,
                                         size = input$point_size)))
  }
})
```

## Performance Optimization

### 대용량 데이터 처리

```r
# 큰 데이터셋을 위한 최적화
optimized_pairs <- reactive({
  req(data_input()$data)
  
  df <- data_input()$data
  
  # 표본 추출 (10,000개 이상인 경우)
  if(nrow(df) > 10000) {
    df_sample <- df[sample(nrow(df), 5000), ]
    showNotification("Large dataset detected. Using random sample of 5,000 observations.", 
                    type = "warning")
  } else {
    df_sample <- df
  }
  
  # 수치형 변수 제한 (너무 많은 경우)
  numeric_vars <- df_sample %>% select_if(is.numeric) %>% names()
  if(length(numeric_vars) > 8) {
    numeric_vars <- numeric_vars[1:8]
    showNotification("Too many numeric variables. Showing first 8 variables.", 
                    type = "info")
  }
  
  # 최적화된 ggpairs 생성
  ggpairs(df_sample[numeric_vars],
          progress = FALSE)  # 진행률 표시 제거
})
```

### 메모리 효율성

```r
# 메모리 사용량 최소화
efficient_pairs <- reactive({
  req(data_input()$data)
  
  # 필요한 변수만 선택
  selected_data <- data_input()$data %>%
    select(all_of(input$selected_variables))
  
  # 결측치 처리
  complete_data <- selected_data %>%
    na.omit()
  
  # 간단한 ggpairs 생성
  ggpairs(complete_data,
          upper = list(continuous = "cor"),
          lower = list(continuous = "points"),
          diag = list(continuous = "barDiag"))
})
```

## Export and Download Features

### 다양한 형식 지원

```r
# 다운로드 핸들러
output$download_pairs <- downloadHandler(
  filename = function() {
    paste("pairs_plot_", Sys.Date(), ".", input$file_format, sep = "")
  },
  content = function(file) {
    # 플롯 크기 설정
    width <- as.numeric(input$plot_width)
    height <- as.numeric(input$plot_height)
    dpi <- as.numeric(input$plot_dpi)
    
    # 파일 형식에 따른 저장
    if(input$file_format == "png") {
      ggsave(file, plot = ggpairs_result(), 
             width = width, height = height, dpi = dpi, device = "png")
    } else if(input$file_format == "pdf") {
      ggsave(file, plot = ggpairs_result(), 
             width = width, height = height, device = "pdf")
    } else if(input$file_format == "svg") {
      ggsave(file, plot = ggpairs_result(), 
             width = width, height = height, device = "svg")
    }
  }
)
```

## Dependencies

### 필수 패키지

- `shiny` - 기본 Shiny 기능
- `GGally` - ggpairs 플롯 생성
- `ggplot2` - 기본 그래픽 시스템
- `dplyr` - 데이터 조작

### 선택적 패키지

- `DT` - 상관계수 매트릭스 표시
- `plotly` - 인터랙티브 플롯
- `corrplot` - 상관계수 시각화

## Troubleshooting

### 일반적인 오류

```r
# 1. 너무 많은 변수로 인한 메모리 부족
# 해결: 변수 수 제한 또는 표본 추출

# 2. 범주형 변수의 레벨이 너무 많음
# 해결: nfactor.limit 조정 또는 변수 제외

# 3. 모든 변수가 범주형인 경우
# 해결: 수치형 변수 확인 또는 다른 시각화 방법 선택

# 4. 상관계수 계산 실패 (상수 변수 등)
# 해결: 변수 분산 확인 및 상수 변수 제거
```

## See Also

- `ggplot2::ggplot()` - 기본 그래픽 문법
- `GGally::ggpairs()` - Pairs plot 생성
- `corrplot::corrplot()` - 상관계수 시각화
- `plotly::ggplotly()` - 인터랙티브 플롯 변환