# bar Documentation

## Overview

`bar.R`은 jsmodule 패키지의 막대그래프 시각화 모듈로, Shiny 애플리케이션에서 범주형 데이터의 분포와 비교를 위한 인터랙티브한 막대그래프를 생성하는 기능을 제공합니다. 이 모듈은 다양한 커스터마이징 옵션과 통계적 검정 기능을 포함하며, 동적 변수 선택과 다운로드 기능을 지원합니다.

## Module Components

### `barUI(id, label = "barplot")`

막대그래프 생성을 위한 Shiny 모듈 UI를 생성합니다.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `id` | character | - | 모듈의 고유 식별자 |
| `label` | character | "barplot" | 막대그래프 모듈 레이블 |

#### Returns

Shiny UI 객체 (막대그래프 설정을 위한 다양한 입력 컨트롤들)

#### UI Components

- X축 및 Y축 변수 선택 입력
- 색상 채우기(fill), 평균선(mean), 지터(jitter) 옵션 체크박스
- P-value 설정 옵션
- 층화변수 선택

### `barServer(id, data, data_label, data_varStruct = NULL, nfactor.limit = 10)`

막대그래프 생성을 위한 서버 사이드 로직을 제공합니다.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `id` | character | - | 모듈의 고유 식별자 |
| `data` | reactive | - | 반응형 데이터 소스 |
| `data_label` | reactive | - | 반응형 데이터 레이블 |
| `data_varStruct` | list | NULL | 변수 구조 정보 |
| `nfactor.limit` | integer | 10 | 범주형 변수 레벨 최대 개수 |

#### Returns

다음을 포함하는 반응형 함수:
- 설정 가능한 옵션이 적용된 ggplot 막대그래프
- 동적 변수 선택 기능
- 통계적 검정 통합
- 커스터마이징된 플롯 미학
- 플롯 내보내기 다운로드 옵션

## Usage Examples

### 기본 사용법

```r
library(shiny)
library(jsmodule)
library(ggplot2)
library(dplyr)

# UI 정의
ui <- fluidPage(
  titlePanel("Interactive Bar Plot Analysis"),
  sidebarLayout(
    sidebarPanel(
      barUI("bar_analysis", label = "막대그래프 분석"),
      hr(),
      downloadButton("download_plot", "플롯 다운로드")
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Bar Plot", 
                 plotOutput("bar_plot", height = "600px")),
        tabPanel("Data Summary", 
                 verbatimTextOutput("data_summary")),
        tabPanel("Statistical Tests", 
                 DT::DTOutput("stat_tests"))
      )
    )
  )
)

server <- function(input, output, session) {
  # 예시 데이터
  data_input <- reactive({
    mtcars %>%
      mutate(
        cyl = as.factor(cyl),
        vs = as.factor(vs),
        am = as.factor(am),
        gear = as.factor(gear),
        carb = as.factor(carb)
      )
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
  
  # 막대그래프 모듈 서버
  bar_result <- barServer("bar_analysis",
                         data = data_input,
                         data_label = data_label,
                         nfactor.limit = 15)
  
  # 메인 막대그래프 출력
  output$bar_plot <- renderPlot({
    req(bar_result())
    print(bar_result())
  })
  
  # 데이터 요약
  output$data_summary <- renderPrint({
    req(data_input())
    summary(data_input())
  })
  
  # 통계 검정 결과
  output$stat_tests <- DT::renderDT({
    req(data_input())
    
    # 범주형 변수들 간의 연관성 검정
    categorical_vars <- data_input() %>% 
      select_if(is.factor) %>% 
      names()
    
    if(length(categorical_vars) >= 2) {
      test_results <- data.frame(
        Variable1 = character(),
        Variable2 = character(),
        ChiSquare = numeric(),
        P_value = numeric(),
        stringsAsFactors = FALSE
      )
      
      for(i in 1:(length(categorical_vars)-1)) {
        for(j in (i+1):length(categorical_vars)) {
          var1 <- categorical_vars[i]
          var2 <- categorical_vars[j]
          
          tryCatch({
            chi_test <- chisq.test(data_input()[[var1]], data_input()[[var2]])
            test_results <- rbind(test_results, data.frame(
              Variable1 = var1,
              Variable2 = var2,
              ChiSquare = round(chi_test$statistic, 4),
              P_value = round(chi_test$p.value, 4)
            ))
          }, error = function(e) NULL)
        }
      }
      
      test_results
    }
  })
}

shinyApp(ui = ui, server = server)
```

### 고급 사용법

```r
# 복잡한 막대그래프 분석 워크플로
server <- function(input, output, session) {
  # 데이터 입력 모듈 연동
  data_input <- callModule(csvFile, "datafile")
  
  # 막대그래프 분석
  bar_analysis <- barServer("bar_viz",
                           data = reactive(data_input()$data),
                           data_label = reactive(data_input()$label))
  
  # 다중 막대그래프 생성
  multiple_bar_plots <- reactive({
    req(data_input()$data)
    
    df <- data_input()$data
    categorical_vars <- df %>% select_if(is.factor) %>% names()
    
    if(length(categorical_vars) >= 2) {
      plots <- list()
      
      # 주요 범주형 변수들에 대한 막대그래프 생성
      for(var in categorical_vars[1:min(4, length(categorical_vars))]) {
        p <- ggplot(df, aes_string(x = var)) +
          geom_bar(fill = "steelblue", alpha = 0.7) +
          theme_minimal() +
          labs(title = paste("Distribution of", var),
               x = var, y = "Count") +
          theme(axis.text.x = element_text(angle = 45, hjust = 1))
        
        plots[[var]] <- p
      }
      
      return(plots)
    }
  })
  
  # 비교 막대그래프 (층화변수 포함)
  comparative_bar_plot <- reactive({
    req(data_input()$data)
    
    df <- data_input()$data
    categorical_vars <- df %>% select_if(is.factor) %>% names()
    
    if(length(categorical_vars) >= 2) {
      var1 <- categorical_vars[1]
      var2 <- categorical_vars[2]
      
      ggplot(df, aes_string(x = var1, fill = var2)) +
        geom_bar(position = "dodge", alpha = 0.8) +
        scale_fill_brewer(type = "qual", palette = "Set2") +
        theme_minimal() +
        labs(title = paste("Comparison of", var1, "by", var2),
             x = var1, y = "Count", fill = var2) +
        theme(axis.text.x = element_text(angle = 45, hjust = 1),
              legend.position = "top")
    }
  })
  
  # 다중 플롯 출력
  output$multiple_plots <- renderUI({
    plots <- multiple_bar_plots()
    req(plots)
    
    plot_outputs <- lapply(names(plots), function(name) {
      div(
        h4(paste("Distribution of", name)),
        renderPlot({
          plots[[name]]
        }, height = 300)
      )
    })
    
    do.call(tagList, plot_outputs)
  })
  
  # 비교 플롯 출력
  output$comparative_plot <- renderPlot({
    req(comparative_bar_plot())
    comparative_bar_plot()
  }, height = 400)
}
```

## Visualization Features

### 지원하는 막대그래프 타입

#### 기본 막대그래프
```r
# 단순 빈도 막대그래프
ggplot(data, aes(x = categorical_var)) +
  geom_bar()

# 그룹별 막대그래프
ggplot(data, aes(x = categorical_var, fill = group_var)) +
  geom_bar(position = "dodge")
```

#### 누적 막대그래프
```r
# 누적 막대그래프
ggplot(data, aes(x = categorical_var, fill = group_var)) +
  geom_bar(position = "stack")

# 비율 누적 막대그래프
ggplot(data, aes(x = categorical_var, fill = group_var)) +
  geom_bar(position = "fill")
```

#### 평균값 막대그래프
```r
# 연속형 변수의 평균값 막대그래프
ggplot(data, aes(x = categorical_var, y = continuous_var)) +
  stat_summary(fun = mean, geom = "bar")
```

### 커스터마이징 옵션

#### 색상 및 테마
```r
# 색상 팔레트 옵션
color_options <- list(
  single_color = "steelblue",
  qualitative = "Set2",
  sequential = "Blues",
  diverging = "RdBu"
)

# 테마 옵션
theme_options <- list(
  minimal = theme_minimal(),
  classic = theme_classic(),
  bw = theme_bw(),
  void = theme_void()
)
```

#### 축 설정
```r
# 축 레이블 및 제목
axis_customization <- list(
  x_label = "Custom X Label",
  y_label = "Custom Y Label",
  title = "Custom Plot Title",
  axis_text_angle = 45,
  axis_text_size = 12
)
```

## Statistical Integration

### 지원하는 통계 검정

#### 카이제곱 검정
```r
# 두 범주형 변수 간의 독립성 검정
chi_square_test <- function(var1, var2, data) {
  result <- chisq.test(data[[var1]], data[[var2]])
  return(list(
    statistic = result$statistic,
    p_value = result$p.value,
    df = result$parameter
  ))
}
```

#### Fisher의 정확검정
```r
# 작은 표본에서의 정확검정
fisher_test <- function(var1, var2, data) {
  contingency_table <- table(data[[var1]], data[[var2]])
  result <- fisher.test(contingency_table)
  return(list(
    p_value = result$p.value,
    odds_ratio = result$estimate
  ))
}
```

### P-value 표시

```r
# 막대그래프에 통계적 유의성 표시
add_significance <- function(plot, p_value) {
  if(p_value < 0.001) {
    significance <- "***"
  } else if(p_value < 0.01) {
    significance <- "**"
  } else if(p_value < 0.05) {
    significance <- "*"
  } else {
    significance <- "ns"
  }
  
  plot + 
    annotate("text", x = Inf, y = Inf, 
             label = paste("p =", round(p_value, 4), significance),
             hjust = 1.1, vjust = 1.1, size = 4)
}
```

## Advanced Features

### 동적 변수 선택

```r
# 데이터 타입에 따른 동적 변수 필터링
dynamic_variable_selection <- reactive({
  req(data_input()$data)
  
  df <- data_input()$data
  
  list(
    categorical_vars = df %>% select_if(is.factor) %>% names(),
    numeric_vars = df %>% select_if(is.numeric) %>% names(),
    binary_vars = df %>% 
      select_if(function(x) is.factor(x) && length(levels(x)) == 2) %>% 
      names()
  )
})
```

### 조건부 시각화

```r
# 조건에 따른 플롯 생성
conditional_plotting <- reactive({
  req(input$plot_type, data_input()$data)
  
  df <- data_input()$data
  
  if(input$plot_type == "frequency") {
    # 빈도 막대그래프
    ggplot(df, aes_string(x = input$x_var)) +
      geom_bar()
  } else if(input$plot_type == "grouped") {
    # 그룹별 막대그래프
    ggplot(df, aes_string(x = input$x_var, fill = input$group_var)) +
      geom_bar(position = "dodge")
  } else if(input$plot_type == "mean") {
    # 평균값 막대그래프
    ggplot(df, aes_string(x = input$x_var, y = input$y_var)) +
      stat_summary(fun = mean, geom = "bar", alpha = 0.7) +
      stat_summary(fun.data = mean_se, geom = "errorbar", width = 0.2)
  }
})
```

## Export and Download Features

### 플롯 다운로드

```r
# 다양한 형식으로 플롯 저장
output$download_bar_plot <- downloadHandler(
  filename = function() {
    paste("bar_plot_", Sys.Date(), ".", input$file_format, sep = "")
  },
  content = function(file) {
    # 플롯 크기 및 해상도 설정
    width <- as.numeric(input$plot_width)
    height <- as.numeric(input$plot_height)
    dpi <- as.numeric(input$plot_dpi)
    
    ggsave(file, plot = bar_result(),
           width = width, height = height, dpi = dpi,
           device = input$file_format)
  }
)
```

## Performance Optimization

### 대용량 데이터 처리

```r
# 큰 데이터셋을 위한 최적화
optimized_bar_plot <- reactive({
  req(data_input()$data)
  
  df <- data_input()$data
  
  # 범주 수가 너무 많은 경우 상위 카테고리만 선택
  if(length(unique(df[[input$x_var]])) > 20) {
    top_categories <- df %>%
      count(!!sym(input$x_var)) %>%
      top_n(15, n) %>%
      pull(!!sym(input$x_var))
    
    df_filtered <- df %>%
      filter(!!sym(input$x_var) %in% top_categories)
    
    showNotification("Showing top 15 categories due to large number of levels", 
                    type = "info")
  } else {
    df_filtered <- df
  }
  
  # 최적화된 플롯 생성
  ggplot(df_filtered, aes_string(x = input$x_var)) +
    geom_bar(alpha = 0.8) +
    theme_minimal()
})
```

## Dependencies

### 필수 패키지

- `shiny` - 기본 Shiny 기능
- `ggplot2` - 그래픽 생성
- `dplyr` - 데이터 조작

### 선택적 패키지

- `RColorBrewer` - 색상 팔레트
- `scales` - 축 포매팅
- `DT` - 결과 테이블 표시

## Troubleshooting

### 일반적인 오류

```r
# 1. 범주가 너무 많은 변수
# 해결: nfactor.limit 조정 또는 상위 카테고리 선택

# 2. 모든 변수가 연속형인 경우
# 해결: 연속형 변수의 구간화 또는 다른 시각화 방법 제안

# 3. 결측치로 인한 플롯 오류
# 해결: 결측치 처리 옵션 제공

# 4. 메모리 부족 (대용량 데이터)
# 해결: 표본 추출 또는 집계 후 시각화
```

## See Also

- `ggplot2::geom_bar()` - 막대그래프 생성
- `dplyr::count()` - 빈도 계산
- `box.R` - 박스플롯 모듈
- `histogram.R` - 히스토그램 모듈