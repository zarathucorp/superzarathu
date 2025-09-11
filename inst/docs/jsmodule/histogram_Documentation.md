# histogram Documentation

## Overview

`histogram.R`은 jsmodule 패키지의 히스토그램 시각화 모듈로, Shiny 애플리케이션에서 연속형 데이터의 분포를 탐색하는 인터랙티브한 히스토그램을 생성하는 기능을 제공합니다. 이 모듈은 동적 변수 선택, 층화 분석, 그리고 통계적 정보 표시 기능을 포함하며, 데이터의 분포 특성을 시각적으로 파악하는 데 도움을 줍니다.

## Module Components

### `histogramUI(id, label = "histogram")`

히스토그램 생성을 위한 Shiny 모듈 UI를 생성합니다.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `id` | character | - | 모듈의 네임스페이스 식별자 |
| `label` | character | "histogram" | 히스토그램 모듈 레이블 |

#### Returns

Shiny UI 객체 (히스토그램 선택을 위한 UI 요소들)

#### UI Components

- 변수 선택 UI 입력
- 층화변수 선택 UI 입력

### `histogramServer(id, data, data_label, data_varStruct = NULL, nfactor.limit = 10)`

히스토그램 생성을 위한 서버 사이드 로직을 제공합니다.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `id` | character | - | 모듈의 네임스페이스 식별자 |
| `data` | reactive | - | 반응형 데이터 소스 |
| `data_label` | reactive | - | 반응형 데이터 레이블 |
| `data_varStruct` | list | NULL | 변수 구조 정보 |
| `nfactor.limit` | integer | 10 | 범주형 변수 레벨 최대 개수 |

#### Returns

다음을 포함하는 반응형 함수:
- 동적 변수 선택 기능
- 층화 지원
- ggpubr을 사용한 히스토그램 생성
- 플롯 다운로드 기능

## Usage Examples

### 기본 사용법

```r
library(shiny)
library(jsmodule)
library(ggplot2)
library(ggpubr)
library(dplyr)

# UI 정의
ui <- fluidPage(
  titlePanel("Interactive Histogram Analysis"),
  sidebarLayout(
    sidebarPanel(
      histogramUI("hist_analysis", label = "히스토그램 분석"),
      hr(),
      downloadButton("download_plot", "플롯 다운로드")
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Histogram", 
                 plotOutput("histogram_plot", height = "600px")),
        tabPanel("Distribution Summary", 
                 verbatimTextOutput("dist_summary")),
        tabPanel("Normality Tests", 
                 DT::DTOutput("normality_tests"))
      )
    )
  )
)

server <- function(input, output, session) {
  # 예시 데이터
  data_input <- reactive({
    # 다양한 분포를 가진 데이터 생성
    set.seed(123)
    data.frame(
      normal_var = rnorm(1000, mean = 50, sd = 10),
      skewed_var = rexp(1000, rate = 0.1),
      uniform_var = runif(1000, min = 0, max = 100),
      bimodal_var = c(rnorm(500, 30, 5), rnorm(500, 70, 8)),
      group = factor(sample(c("A", "B", "C"), 1000, replace = TRUE)),
      treatment = factor(sample(c("Control", "Treatment"), 1000, replace = TRUE))
    )
  })
  
  data_label <- reactive({
    data.frame(
      variable = names(data_input()),
      label = c("Normal Distribution", "Skewed Distribution", 
               "Uniform Distribution", "Bimodal Distribution",
               "Group Variable", "Treatment Variable"),
      stringsAsFactors = FALSE
    )
  })
  
  # 히스토그램 모듈 서버
  histogram_result <- histogramServer("hist_analysis",
                                     data = data_input,
                                     data_label = data_label,
                                     nfactor.limit = 15)
  
  # 메인 히스토그램 출력
  output$histogram_plot <- renderPlot({
    req(histogram_result())
    print(histogram_result())
  })
  
  # 분포 요약 통계
  output$dist_summary <- renderPrint({
    req(data_input())
    
    df <- data_input()
    numeric_vars <- df %>% select_if(is.numeric) %>% names()
    
    cat("Distribution Summary:\n\n")
    
    for(var in numeric_vars) {
      cat(paste("Variable:", var, "\n"))
      cat(paste("  Mean:", round(mean(df[[var]], na.rm = TRUE), 3), "\n"))
      cat(paste("  Median:", round(median(df[[var]], na.rm = TRUE), 3), "\n"))
      cat(paste("  SD:", round(sd(df[[var]], na.rm = TRUE), 3), "\n"))
      cat(paste("  Skewness:", round(moments::skewness(df[[var]], na.rm = TRUE), 3), "\n"))
      cat(paste("  Kurtosis:", round(moments::kurtosis(df[[var]], na.rm = TRUE), 3), "\n"))
      cat("\n")
    }
  })
  
  # 정규성 검정
  output$normality_tests <- DT::renderDT({
    req(data_input())
    
    df <- data_input()
    numeric_vars <- df %>% select_if(is.numeric) %>% names()
    
    test_results <- data.frame()
    
    for(var in numeric_vars) {
      # Shapiro-Wilk 검정 (표본 크기가 5000 이하인 경우)
      if(length(df[[var]]) <= 5000) {
        sw_test <- shapiro.test(df[[var]])
        sw_p <- sw_test$p.value
      } else {
        sw_p <- NA
      }
      
      # Kolmogorov-Smirnov 검정
      ks_test <- ks.test(df[[var]], "pnorm", 
                        mean = mean(df[[var]], na.rm = TRUE),
                        sd = sd(df[[var]], na.rm = TRUE))
      
      test_results <- rbind(test_results, data.frame(
        Variable = var,
        Shapiro_Wilk_p = ifelse(is.na(sw_p), "N/A (large sample)", 
                               round(sw_p, 4)),
        KS_test_p = round(ks_test$p.value, 4),
        Normal_Distribution = ifelse(!is.na(sw_p) && sw_p > 0.05, "Yes", "No"),
        stringsAsFactors = FALSE
      ))
    }
    
    test_results
  })
}

shinyApp(ui = ui, server = server)
```

### 고급 사용법

```r
# 복잡한 히스토그램 분석 워크플로
server <- function(input, output, session) {
  # 데이터 입력 모듈 연동
  data_input <- callModule(csvFile, "datafile")
  
  # 히스토그램 분석
  histogram_analysis <- histogramServer("hist_viz",
                                       data = reactive(data_input()$data),
                                       data_label = reactive(data_input()$label))
  
  # 다중 히스토그램 생성
  multiple_histograms <- reactive({
    req(data_input()$data)
    
    df <- data_input()$data
    numeric_vars <- df %>% select_if(is.numeric) %>% names()
    
    if(length(numeric_vars) >= 1) {
      plots <- list()
      
      # 주요 수치형 변수들에 대한 히스토그램 생성
      for(var in numeric_vars[1:min(4, length(numeric_vars))]) {
        # 기본 히스토그램
        p1 <- ggplot(df, aes_string(x = var)) +
          geom_histogram(aes(y = ..density..), bins = 30, 
                        fill = "skyblue", alpha = 0.7, color = "black") +
          geom_density(color = "red", size = 1) +
          labs(title = paste("Distribution of", var),
               x = var, y = "Density") +
          theme_minimal()
        
        # Q-Q 플롯
        p2 <- ggplot(df, aes_string(sample = var)) +
          stat_qq() +
          stat_qq_line(color = "red") +
          labs(title = paste("Q-Q Plot:", var)) +
          theme_minimal()
        
        # 박스플롯 (이상치 확인용)
        p3 <- ggplot(df, aes_string(y = var)) +
          geom_boxplot(fill = "lightgreen", alpha = 0.7) +
          coord_flip() +
          labs(title = paste("Boxplot:", var), x = "", y = var) +
          theme_minimal()
        
        plots[[var]] <- list(histogram = p1, qqplot = p2, boxplot = p3)
      }
      
      return(plots)
    }
  })
  
  # 층화 히스토그램
  stratified_histogram <- reactive({
    req(data_input()$data)
    
    df <- data_input()$data
    numeric_vars <- df %>% select_if(is.numeric) %>% names()
    categorical_vars <- df %>% select_if(is.factor) %>% names()
    
    if(length(numeric_vars) >= 1 && length(categorical_vars) >= 1) {
      num_var <- numeric_vars[1]
      cat_var <- categorical_vars[1]
      
      # 층화별 히스토그램
      p <- ggplot(df, aes_string(x = num_var, fill = cat_var)) +
        geom_histogram(alpha = 0.7, position = "identity", bins = 25) +
        facet_wrap(as.formula(paste("~", cat_var)), scales = "free_y") +
        scale_fill_brewer(type = "qual", palette = "Set2") +
        labs(title = paste("Distribution of", num_var, "by", cat_var),
             x = num_var, y = "Frequency") +
        theme_minimal() +
        theme(legend.position = "none")
      
      return(p)
    }
  })
  
  # 분포 비교 분석
  distribution_comparison <- reactive({
    req(data_input()$data)
    
    df <- data_input()$data
    numeric_vars <- df %>% select_if(is.numeric) %>% names()
    categorical_vars <- df %>% select_if(is.factor) %>% names()
    
    if(length(numeric_vars) >= 1 && length(categorical_vars) >= 1) {
      comparison_results <- data.frame()
      
      for(num_var in numeric_vars[1:min(3, length(numeric_vars))]) {
        for(cat_var in categorical_vars[1:min(2, length(categorical_vars))]) {
          groups <- unique(df[[cat_var]])
          
          if(length(groups) == 2) {
            # 두 그룹 간 분포 비교
            group1_data <- df[df[[cat_var]] == groups[1], num_var]
            group2_data <- df[df[[cat_var]] == groups[2], num_var]
            
            # Kolmogorov-Smirnov 검정
            ks_result <- ks.test(group1_data, group2_data)
            
            comparison_results <- rbind(comparison_results, data.frame(
              Numeric_Variable = num_var,
              Grouping_Variable = cat_var,
              Group1 = groups[1],
              Group2 = groups[2],
              KS_statistic = round(ks_result$statistic, 4),
              P_value = round(ks_result$p.value, 4),
              Different_Distributions = ifelse(ks_result$p.value < 0.05, "Yes", "No")
            ))
          }
        }
      }
      
      return(comparison_results)
    }
  })
  
  # 다중 플롯 출력
  output$multiple_histograms <- renderUI({
    plots <- multiple_histograms()
    req(plots)
    
    plot_outputs <- lapply(names(plots), function(var_name) {
      div(
        h3(paste("Analysis for", var_name)),
        fluidRow(
          column(4, renderPlot({plots[[var_name]]$histogram}, height = 300)),
          column(4, renderPlot({plots[[var_name]]$qqplot}, height = 300)),
          column(4, renderPlot({plots[[var_name]]$boxplot}, height = 300))
        ),
        hr()
      )
    })
    
    do.call(tagList, plot_outputs)
  })
  
  # 층화 히스토그램 출력
  output$stratified_histogram <- renderPlot({
    req(stratified_histogram())
    stratified_histogram()
  }, height = 400)
  
  # 분포 비교 결과
  output$distribution_comparison <- DT::renderDT({
    req(distribution_comparison())
    distribution_comparison()
  })
}
```

## Visualization Features

### 지원하는 히스토그램 타입

#### 기본 히스토그램
```r
# 빈도 히스토그램
ggplot(data, aes(x = numeric_var)) +
  geom_histogram(bins = 30)

# 밀도 히스토그램
ggplot(data, aes(x = numeric_var)) +
  geom_histogram(aes(y = ..density..), bins = 30)
```

#### 밀도 곡선과 결합
```r
# 히스토그램 + 밀도 곡선
ggplot(data, aes(x = numeric_var)) +
  geom_histogram(aes(y = ..density..), alpha = 0.7) +
  geom_density(color = "red", size = 1)

# 정규분포 곡선 오버레이
ggplot(data, aes(x = numeric_var)) +
  geom_histogram(aes(y = ..density..), alpha = 0.7) +
  stat_function(fun = dnorm, 
                args = list(mean = mean(data$numeric_var), 
                           sd = sd(data$numeric_var)),
                color = "blue", size = 1)
```

#### 층화 히스토그램
```r
# 그룹별 히스토그램 (중첩)
ggplot(data, aes(x = numeric_var, fill = group_var)) +
  geom_histogram(alpha = 0.6, position = "identity")

# 그룹별 히스토그램 (패싯)
ggplot(data, aes(x = numeric_var)) +
  geom_histogram() +
  facet_wrap(~group_var)
```

### 빈(Bin) 설정 옵션

#### 빈 개수 최적화
```r
# 다양한 빈 개수 설정 방법
bin_methods <- list(
  fixed = 30,                                    # 고정 개수
  sturges = nclass.Sturges(data$numeric_var),   # Sturges 공식
  scott = nclass.scott(data$numeric_var),       # Scott 공식
  fd = nclass.FD(data$numeric_var)              # Freedman-Diaconis 공식
)

# 최적 빈 개수 선택
optimal_bins <- function(x) {
  methods <- c(
    sturges = nclass.Sturges(x),
    scott = nclass.scott(x),
    fd = nclass.FD(x)
  )
  return(round(median(methods)))
}
```

#### 빈 너비 설정
```r
# 빈 너비 기반 설정
bin_width <- diff(range(data$numeric_var)) / 30

ggplot(data, aes(x = numeric_var)) +
  geom_histogram(binwidth = bin_width)
```

### 분포 진단

#### 정규성 평가
```r
# 시각적 정규성 평가
normality_check <- function(data, variable) {
  p1 <- ggplot(data, aes_string(x = variable)) +
    geom_histogram(aes(y = ..density..), alpha = 0.7) +
    stat_function(fun = dnorm, 
                  args = list(mean = mean(data[[variable]]),
                             sd = sd(data[[variable]])),
                  color = "red") +
    labs(title = "Histogram with Normal Overlay")
  
  p2 <- ggplot(data, aes_string(sample = variable)) +
    stat_qq() +
    stat_qq_line() +
    labs(title = "Q-Q Plot")
  
  return(list(histogram = p1, qqplot = p2))
}
```

#### 분포 모양 특성
```r
# 왜도와 첨도 계산
distribution_characteristics <- function(x) {
  list(
    mean = mean(x, na.rm = TRUE),
    median = median(x, na.rm = TRUE),
    mode = as.numeric(names(sort(table(round(x)), decreasing = TRUE)[1])),
    skewness = moments::skewness(x, na.rm = TRUE),
    kurtosis = moments::kurtosis(x, na.rm = TRUE),
    range = range(x, na.rm = TRUE),
    iqr = IQR(x, na.rm = TRUE)
  )
}
```

## Statistical Integration

### 분포 적합도 검정

#### 정규성 검정
```r
# 다양한 정규성 검정
normality_tests <- function(x) {
  results <- list()
  
  # Shapiro-Wilk 검정 (n <= 5000)
  if(length(x) <= 5000) {
    results$shapiro <- shapiro.test(x)
  }
  
  # Anderson-Darling 검정
  results$anderson <- nortest::ad.test(x)
  
  # Kolmogorov-Smirnov 검정
  results$ks <- ks.test(x, "pnorm", mean = mean(x), sd = sd(x))
  
  return(results)
}
```

#### 다른 분포와의 비교
```r
# 여러 분포와의 적합도 비교
distribution_fitting <- function(x) {
  distributions <- list(
    normal = list(fun = "pnorm", params = list(mean = mean(x), sd = sd(x))),
    exponential = list(fun = "pexp", params = list(rate = 1/mean(x))),
    uniform = list(fun = "punif", params = list(min = min(x), max = max(x)))
  )
  
  results <- data.frame()
  
  for(dist_name in names(distributions)) {
    dist_info <- distributions[[dist_name]]
    ks_result <- do.call(ks.test, c(list(x, dist_info$fun), dist_info$params))
    
    results <- rbind(results, data.frame(
      Distribution = dist_name,
      KS_statistic = ks_result$statistic,
      P_value = ks_result$p.value
    ))
  }
  
  return(results)
}
```

## Advanced Features

### 동적 빈 조정

```r
# 사용자 인터랙션을 통한 빈 조정
dynamic_bins <- reactive({
  req(input$bins_method, data_input()$data)
  
  x <- data_input()$data[[input$selected_variable]]
  
  if(input$bins_method == "fixed") {
    return(input$bins_number)
  } else if(input$bins_method == "sturges") {
    return(nclass.Sturges(x))
  } else if(input$bins_method == "scott") {
    return(nclass.scott(x))
  } else if(input$bins_method == "fd") {
    return(nclass.FD(x))
  }
})

# 동적 히스토그램
dynamic_histogram <- reactive({
  req(dynamic_bins(), input$selected_variable)
  
  ggplot(data_input()$data, aes_string(x = input$selected_variable)) +
    geom_histogram(bins = dynamic_bins(), alpha = 0.7, 
                  fill = input$fill_color, color = "black") +
    theme_minimal() +
    labs(title = paste("Histogram of", input$selected_variable),
         subtitle = paste("Bins:", dynamic_bins()))
})
```

### 분포 변환

```r
# 데이터 변환 옵션
transformation_options <- reactive({
  req(input$transformation, data_input()$data)
  
  x <- data_input()$data[[input$selected_variable]]
  
  transformed_data <- switch(input$transformation,
    "none" = x,
    "log" = log(x + 1),  # +1을 추가하여 0 처리
    "sqrt" = sqrt(x),
    "reciprocal" = 1 / (x + 1),
    "square" = x^2,
    "standardize" = scale(x)[,1]
  )
  
  return(transformed_data)
})

# 변환된 데이터의 히스토그램
transformed_histogram <- reactive({
  req(transformation_options())
  
  df_transformed <- data.frame(
    original = data_input()$data[[input$selected_variable]],
    transformed = transformation_options()
  )
  
  p1 <- ggplot(df_transformed, aes(x = original)) +
    geom_histogram(bins = 30, alpha = 0.7) +
    labs(title = "Original Distribution") +
    theme_minimal()
  
  p2 <- ggplot(df_transformed, aes(x = transformed)) +
    geom_histogram(bins = 30, alpha = 0.7) +
    labs(title = paste("Transformed Distribution:", input$transformation)) +
    theme_minimal()
  
  return(list(original = p1, transformed = p2))
})
```

## Export and Download Features

### 고품질 히스토그램 내보내기

```r
# 출판용 히스토그램
publication_histogram <- reactive({
  req(histogram_result())
  
  # 고품질 테마 적용
  histogram_result() +
    theme_classic() +
    theme(
      text = element_text(size = 12, family = "Arial"),
      axis.title = element_text(size = 14, face = "bold"),
      axis.text = element_text(size = 12),
      plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
      panel.grid.major = element_line(color = "gray90", size = 0.5),
      panel.grid.minor = element_blank()
    )
})
```

## Dependencies

### 필수 패키지

- `shiny` - 기본 Shiny 기능
- `ggplot2` - 그래픽 생성
- `ggpubr` - 향상된 플롯 기능

### 선택적 패키지

- `moments` - 왜도 및 첨도 계산
- `nortest` - 정규성 검정
- `fitdistrplus` - 분포 적합

## Troubleshooting

### 일반적인 오류

```r
# 1. 모든 값이 동일한 경우
# 해결: 분산 확인 및 적절한 메시지 표시

# 2. 극단적인 이상치로 인한 스케일 문제
# 해결: 이상치 제거 또는 축 변환 옵션

# 3. 결측치가 많은 경우
# 해결: 결측치 처리 및 경고 메시지

# 4. 빈 개수가 너무 많거나 적은 경우
# 해결: 적응적 빈 개수 조정
```

## See Also

- `ggplot2::geom_histogram()` - 히스토그램 생성
- `ggplot2::geom_density()` - 밀도 곡선
- `moments::skewness()` - 왜도 계산
- `box.R` - 박스플롯 모듈