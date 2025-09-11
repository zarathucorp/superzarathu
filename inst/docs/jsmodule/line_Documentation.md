# line Documentation

## Overview

`line.R`은 jsmodule 패키지의 선 그래프 시각화 모듈로, Shiny 애플리케이션에서 시간에 따른 변화나 연속적인 관계를 나타내는 인터랙티브한 선 그래프를 생성하는 기능을 제공합니다. 이 모듈은 추세 분석, 시계열 데이터 시각화, 그리고 그룹 간 변화 패턴 비교에 특화되어 있으며, 동적 변수 선택과 통계적 검정 기능을 포함합니다.

## Module Components

### `lineUI(id, label = "lineplot")`

선 그래프 생성을 위한 Shiny 모듈 UI를 생성합니다.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `id` | character | - | 모듈의 네임스페이스 식별자 |
| `label` | character | "lineplot" | 선 그래프 모듈 레이블 |

#### Returns

Shiny UI 객체 (선 그래프 설정을 위한 UI 요소들)

#### UI Components

- 변수 선택 드롭다운 (X축, Y축)
- 층화변수 선택
- 플롯 옵션 체크박스
- P-value 설정

### `lineServer(id, data, data_label, data_varStruct = NULL, nfactor.limit = 10)`

선 그래프 생성을 위한 서버 사이드 로직을 제공합니다.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `id` | character | - | 모듈의 네임스페이스 식별자 |
| `data` | reactive | - | 반응형 데이터프레임 |
| `data_label` | reactive | - | 반응형 데이터 레이블 |
| `data_varStruct` | list | NULL | 변수 구조 정보 |
| `nfactor.limit` | integer | 10 | 범주형 변수 레벨 최대 개수 |

#### Returns

다음을 포함하는 반응형 함수:
- 동적 변수 선택 기능
- 유연한 플롯 커스터마이징
- 통계적 검정 통합
- 하위집단 분석 지원

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
  titlePanel("Interactive Line Plot Analysis"),
  sidebarLayout(
    sidebarPanel(
      lineUI("line_analysis", label = "선 그래프 분석"),
      hr(),
      downloadButton("download_plot", "플롯 다운로드")
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Line Plot", 
                 plotOutput("line_plot", height = "600px")),
        tabPanel("Trend Analysis", 
                 verbatimTextOutput("trend_analysis")),
        tabPanel("Correlation Matrix", 
                 DT::DTOutput("correlation_table"))
      )
    )
  )
)

server <- function(input, output, session) {
  # 예시 시계열 데이터
  data_input <- reactive({
    # 시간 변수가 포함된 예시 데이터 생성
    set.seed(123)
    time_points <- 1:50
    
    data.frame(
      time = time_points,
      trend1 = 10 + 0.5 * time_points + rnorm(50, 0, 2),
      trend2 = 20 - 0.3 * time_points + rnorm(50, 0, 1.5),
      seasonal = 15 + 5 * sin(2 * pi * time_points / 12) + rnorm(50, 0, 1),
      group = factor(rep(c("A", "B"), each = 25)),
      treatment = factor(rep(c("Control", "Treatment", "Control", "Treatment"), 
                           length.out = 50))
    )
  })
  
  data_label <- reactive({
    data.frame(
      variable = names(data_input()),
      label = c("Time Points", "Linear Trend 1", "Linear Trend 2", 
               "Seasonal Pattern", "Group Variable", "Treatment"),
      stringsAsFactors = FALSE
    )
  })
  
  # 선 그래프 모듈 서버
  line_result <- lineServer("line_analysis",
                           data = data_input,
                           data_label = data_label,
                           nfactor.limit = 15)
  
  # 메인 선 그래프 출력
  output$line_plot <- renderPlot({
    req(line_result())
    print(line_result())
  })
  
  # 추세 분석
  output$trend_analysis <- renderPrint({
    req(data_input())
    
    df <- data_input()
    numeric_vars <- df %>% select_if(is.numeric) %>% names()
    
    cat("Trend Analysis Results:\n\n")
    
    for(var in numeric_vars[-1]) {  # time 변수 제외
      if("time" %in% numeric_vars) {
        # 선형 회귀 적합
        lm_result <- lm(df[[var]] ~ df$time)
        
        cat(paste("Variable:", var, "\n"))
        cat(paste("  Slope:", round(coef(lm_result)[2], 4), "\n"))
        cat(paste("  R-squared:", round(summary(lm_result)$r.squared, 4), "\n"))
        cat(paste("  P-value:", round(summary(lm_result)$coefficients[2,4], 4), "\n"))
        
        # 추세 해석
        slope <- coef(lm_result)[2]
        if(abs(slope) < 0.01) {
          trend <- "No significant trend"
        } else if(slope > 0) {
          trend <- "Increasing trend"
        } else {
          trend <- "Decreasing trend"
        }
        cat(paste("  Interpretation:", trend, "\n\n"))
      }
    }
  })
  
  # 상관관계 매트릭스
  output$correlation_table <- DT::renderDT({
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
# 복잡한 시계열 분석 워크플로
server <- function(input, output, session) {
  # 데이터 입력 모듈 연동
  data_input <- callModule(csvFile, "datafile")
  
  # 선 그래프 분석
  line_analysis <- lineServer("line_viz",
                             data = reactive(data_input()$data),
                             data_label = reactive(data_input()$label))
  
  # 다중 시계열 플롯
  multiple_time_series <- reactive({
    req(data_input()$data)
    
    df <- data_input()$data
    numeric_vars <- df %>% select_if(is.numeric) %>% names()
    
    # 시간 변수 감지
    time_candidates <- numeric_vars[grepl("time|date|year|month", 
                                         tolower(numeric_vars))]
    
    if(length(time_candidates) >= 1 && length(numeric_vars) >= 2) {
      time_var <- time_candidates[1]
      value_vars <- setdiff(numeric_vars, time_var)[1:min(3, length(numeric_vars)-1)]
      
      plots <- list()
      
      for(var in value_vars) {
        p <- ggplot(df, aes_string(x = time_var, y = var)) +
          geom_line(color = "steelblue", size = 1) +
          geom_point(color = "darkblue", size = 2, alpha = 0.7) +
          geom_smooth(method = "lm", se = TRUE, color = "red", alpha = 0.3) +
          labs(title = paste("Time Series:", var),
               x = time_var, y = var) +
          theme_minimal() +
          theme(plot.title = element_text(hjust = 0.5))
        
        plots[[var]] <- p
      }
      
      return(plots)
    }
  })
  
  # 그룹별 비교 선 그래프
  grouped_line_plots <- reactive({
    req(data_input()$data)
    
    df <- data_input()$data
    numeric_vars <- df %>% select_if(is.numeric) %>% names()
    categorical_vars <- df %>% select_if(is.factor) %>% names()
    
    if(length(numeric_vars) >= 2 && length(categorical_vars) >= 1) {
      x_var <- numeric_vars[1]
      y_var <- numeric_vars[2]
      group_var <- categorical_vars[1]
      
      # 그룹별 선 그래프
      p1 <- ggplot(df, aes_string(x = x_var, y = y_var, color = group_var)) +
        geom_line(size = 1) +
        geom_point(size = 2, alpha = 0.7) +
        scale_color_brewer(type = "qual", palette = "Set2") +
        labs(title = paste("Line Plot:", y_var, "by", x_var, "grouped by", group_var),
             x = x_var, y = y_var, color = group_var) +
        theme_minimal() +
        theme(legend.position = "top")
      
      # 패싯별 선 그래프
      p2 <- ggplot(df, aes_string(x = x_var, y = y_var)) +
        geom_line(color = "steelblue", size = 1) +
        geom_point(color = "darkblue", size = 2, alpha = 0.7) +
        geom_smooth(method = "lm", se = TRUE, alpha = 0.3) +
        facet_wrap(as.formula(paste("~", group_var)), scales = "free") +
        labs(title = paste("Faceted Line Plot:", y_var, "by", x_var),
             x = x_var, y = y_var) +
        theme_minimal()
      
      return(list(grouped = p1, faceted = p2))
    }
  })
  
  # 변화율 분석
  change_rate_analysis <- reactive({
    req(data_input()$data)
    
    df <- data_input()$data
    numeric_vars <- df %>% select_if(is.numeric) %>% names()
    
    if(length(numeric_vars) >= 2) {
      # 시간 변수 가정 (첫 번째 수치형 변수)
      time_var <- numeric_vars[1]
      value_vars <- numeric_vars[-1]
      
      change_results <- data.frame()
      
      for(var in value_vars[1:min(3, length(value_vars))]) {
        # 정렬된 데이터에서 변화율 계산
        df_sorted <- df[order(df[[time_var]]), ]
        values <- df_sorted[[var]]
        
        # 백분율 변화율
        pct_change <- c(NA, diff(values) / lag(values)[-1] * 100)
        
        # 평균 변화율
        avg_change <- mean(pct_change, na.rm = TRUE)
        
        # 최대/최소 변화율
        max_change <- max(pct_change, na.rm = TRUE)
        min_change <- min(pct_change, na.rm = TRUE)
        
        change_results <- rbind(change_results, data.frame(
          Variable = var,
          Avg_Change_Pct = round(avg_change, 2),
          Max_Change_Pct = round(max_change, 2),
          Min_Change_Pct = round(min_change, 2),
          Volatility = round(sd(pct_change, na.rm = TRUE), 2)
        ))
      }
      
      return(change_results)
    }
  })
  
  # 다중 플롯 출력
  output$multiple_time_series <- renderUI({
    plots <- multiple_time_series()
    req(plots)
    
    plot_outputs <- lapply(names(plots), function(var_name) {
      div(
        h4(paste("Time Series Analysis:", var_name)),
        renderPlot({
          plots[[var_name]]
        }, height = 350)
      )
    })
    
    do.call(tagList, plot_outputs)
  })
  
  # 그룹 비교 플롯 출력
  output$grouped_line_plots <- renderUI({
    plots <- grouped_line_plots()
    req(plots)
    
    tagList(
      h4("Grouped Line Plot"),
      renderPlot({plots$grouped}, height = 400),
      h4("Faceted Line Plot"),
      renderPlot({plots$faceted}, height = 400)
    )
  })
  
  # 변화율 분석 결과
  output$change_rate_analysis <- DT::renderDT({
    req(change_rate_analysis())
    change_rate_analysis()
  })
}
```

## Visualization Features

### 지원하는 선 그래프 타입

#### 기본 선 그래프
```r
# 단순 선 그래프
ggplot(data, aes(x = x_var, y = y_var)) +
  geom_line()

# 포인트가 포함된 선 그래프
ggplot(data, aes(x = x_var, y = y_var)) +
  geom_line() +
  geom_point()
```

#### 다중 선 그래프
```r
# 그룹별 선 그래프
ggplot(data, aes(x = x_var, y = y_var, color = group_var)) +
  geom_line(size = 1) +
  geom_point()

# 다중 Y축 선 그래프 (서로 다른 스케일)
p1 <- ggplot(data, aes(x = time)) +
  geom_line(aes(y = var1), color = "blue") +
  scale_y_continuous("Variable 1", sec.axis = sec_axis(~ . * scale_factor, 
                                                      name = "Variable 2"))
```

#### 추세선이 포함된 선 그래프
```r
# 회귀 추세선
ggplot(data, aes(x = x_var, y = y_var)) +
  geom_line() +
  geom_smooth(method = "lm", se = TRUE)

# 비선형 추세선
ggplot(data, aes(x = x_var, y = y_var)) +
  geom_line() +
  geom_smooth(method = "loess", se = TRUE)
```

### 시계열 특화 기능

#### 시간 축 포매팅
```r
# 날짜 축 포매팅
time_formatting <- list(
  daily = scale_x_date(date_labels = "%Y-%m-%d", date_breaks = "1 day"),
  monthly = scale_x_date(date_labels = "%Y-%m", date_breaks = "1 month"),
  yearly = scale_x_date(date_labels = "%Y", date_breaks = "1 year")
)

# 연속형 시간 축
continuous_time <- scale_x_continuous(
  breaks = scales::pretty_breaks(n = 10),
  labels = scales::number_format(accuracy = 1)
)
```

#### 계절성 분석
```r
# 계절성 분해 (additive)
seasonal_decomposition <- function(ts_data, frequency = 12) {
  if(length(ts_data) >= 2 * frequency) {
    ts_obj <- ts(ts_data, frequency = frequency)
    decomp <- decompose(ts_obj, type = "additive")
    
    return(list(
      trend = as.numeric(decomp$trend),
      seasonal = as.numeric(decomp$seasonal),
      residual = as.numeric(decomp$random)
    ))
  }
}

# 계절성 플롯
seasonal_plot <- function(data, time_var, value_var, period = 12) {
  data$period_group <- rep(1:period, length.out = nrow(data))
  
  ggplot(data, aes_string(x = "period_group", y = value_var)) +
    geom_line(aes(group = 1), alpha = 0.7) +
    geom_point() +
    scale_x_continuous(breaks = 1:period) +
    labs(title = "Seasonal Pattern", x = "Period", y = value_var) +
    theme_minimal()
}
```

### 통계적 분석 통합

#### 추세 검정
```r
# Mann-Kendall 추세 검정
trend_test <- function(x, y) {
  # 단순 선형 회귀
  lm_result <- lm(y ~ x)
  
  # Spearman 상관계수 (비모수)
  spearman_cor <- cor.test(x, y, method = "spearman")
  
  return(list(
    linear_model = summary(lm_result),
    spearman_test = spearman_cor,
    slope = coef(lm_result)[2],
    r_squared = summary(lm_result)$r.squared
  ))
}
```

#### 변화점 탐지
```r
# 변화점 탐지 (단순한 방법)
change_point_detection <- function(data, time_var, value_var) {
  x <- data[[time_var]]
  y <- data[[value_var]]
  
  # 이동평균 계산
  window_size <- min(10, length(y) %/% 5)
  moving_avg <- zoo::rollmean(y, k = window_size, fill = NA)
  
  # 큰 변화 지점 식별
  changes <- abs(diff(moving_avg, na.rm = TRUE))
  threshold <- quantile(changes, 0.9, na.rm = TRUE)
  
  change_points <- which(changes > threshold) + window_size %/% 2
  
  return(list(
    change_points = change_points,
    change_times = x[change_points],
    change_values = y[change_points]
  ))
}
```

## Advanced Features

### 인터랙티브 줌 및 패닝

```r
# 줌 가능한 선 그래프
zoomable_line_plot <- reactive({
  req(input$x_range, input$y_range)
  
  base_plot <- ggplot(data_input()$data, 
                     aes_string(x = input$x_var, y = input$y_var)) +
    geom_line() +
    geom_point()
  
  if(!is.null(input$x_range)) {
    base_plot <- base_plot + 
      coord_cartesian(xlim = input$x_range, ylim = input$y_range)
  }
  
  return(base_plot)
})
```

### 동적 평활화

```r
# 사용자 설정 가능한 평활화
smoothing_options <- reactive({
  req(input$smooth_method, input$smooth_span)
  
  base_plot <- ggplot(data_input()$data, 
                     aes_string(x = input$x_var, y = input$y_var)) +
    geom_line(alpha = 0.6) +
    geom_point(alpha = 0.6)
  
  if(input$smooth_method == "loess") {
    base_plot <- base_plot + 
      geom_smooth(method = "loess", span = input$smooth_span, se = input$show_se)
  } else if(input$smooth_method == "lm") {
    base_plot <- base_plot + 
      geom_smooth(method = "lm", se = input$show_se)
  } else if(input$smooth_method == "gam") {
    base_plot <- base_plot + 
      geom_smooth(method = "gam", se = input$show_se)
  }
  
  return(base_plot)
})
```

### 예측 및 외삽

```r
# 선형 예측
linear_prediction <- reactive({
  req(data_input()$data, input$prediction_periods)
  
  df <- data_input()$data
  x <- df[[input$x_var]]
  y <- df[[input$y_var]]
  
  # 선형 모델 적합
  lm_model <- lm(y ~ x)
  
  # 예측 구간 생성
  future_x <- seq(max(x), max(x) + input$prediction_periods, length.out = 10)
  predictions <- predict(lm_model, newdata = data.frame(x = future_x), 
                        interval = "prediction")
  
  # 예측 데이터프레임
  pred_df <- data.frame(
    x = future_x,
    y = predictions[, "fit"],
    lower = predictions[, "lwr"],
    upper = predictions[, "upr"]
  )
  
  # 원본 데이터와 예측 결합 플롯
  p <- ggplot() +
    geom_line(data = df, aes_string(x = input$x_var, y = input$y_var), 
              color = "blue", size = 1) +
    geom_point(data = df, aes_string(x = input$x_var, y = input$y_var), 
               color = "blue") +
    geom_line(data = pred_df, aes(x = x, y = y), 
              color = "red", linetype = "dashed", size = 1) +
    geom_ribbon(data = pred_df, aes(x = x, ymin = lower, ymax = upper), 
                alpha = 0.3, fill = "red") +
    labs(title = "Time Series with Linear Prediction",
         subtitle = paste("Prediction for next", input$prediction_periods, "periods")) +
    theme_minimal()
  
  return(p)
})
```

## Export and Download Features

### 고해상도 시계열 플롯

```r
# 출판 품질 선 그래프
publication_line_plot <- reactive({
  req(line_result())
  
  # 고품질 테마 적용
  line_result() +
    theme_classic() +
    theme(
      text = element_text(size = 12, family = "Arial"),
      axis.title = element_text(size = 14, face = "bold"),
      axis.text = element_text(size = 12),
      legend.title = element_text(size = 12, face = "bold"),
      legend.text = element_text(size = 11),
      plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
      panel.grid.major = element_line(color = "gray90", size = 0.5),
      panel.grid.minor = element_line(color = "gray95", size = 0.3)
    )
})

# 시계열 데이터 내보내기
output$download_timeseries_data <- downloadHandler(
  filename = function() {
    paste("timeseries_data_", Sys.Date(), ".csv", sep = "")
  },
  content = function(file) {
    processed_data <- data_input()$data
    write.csv(processed_data, file, row.names = FALSE)
  }
)
```

## Performance Optimization

### 대용량 시계열 데이터

```r
# 효율적인 시계열 플롯
efficient_line_plot <- reactive({
  req(data_input()$data)
  
  df <- data_input()$data
  
  # 데이터 포인트가 너무 많은 경우 간소화
  if(nrow(df) > 1000) {
    # 균등 간격 샘플링
    sample_indices <- seq(1, nrow(df), length.out = 1000)
    df_sample <- df[sample_indices, ]
    
    showNotification("Large dataset: Using 1000 evenly spaced points", 
                    type = "info")
  } else {
    df_sample <- df
  }
  
  # 최적화된 플롯 생성
  ggplot(df_sample, aes_string(x = input$x_var, y = input$y_var)) +
    geom_line(alpha = 0.8) +
    theme_minimal()
})
```

## Dependencies

### 필수 패키지

- `shiny` - 기본 Shiny 기능
- `ggplot2` - 그래픽 생성
- `ggpubr` - 향상된 플롯 기능
- `data.table` - 데이터 조작

### 선택적 패키지

- `zoo` - 시계열 데이터 조작
- `forecast` - 시계열 예측
- `changepoint` - 변화점 탐지
- `plotly` - 인터랙티브 플롯

## Troubleshooting

### 일반적인 오류

```r
# 1. 시간 순서가 맞지 않는 경우
# 해결: 시간 변수로 정렬 후 플롯 생성

# 2. 결측치로 인한 선 연결 문제
# 해결: na.rm = TRUE 옵션 또는 결측치 보간

# 3. 스케일 차이로 인한 시각화 문제
# 해결: 정규화 또는 로그 변환

# 4. 너무 많은 그룹으로 인한 가독성 저하
# 해결: 주요 그룹 선택 또는 패싯 사용
```

## See Also

- `ggplot2::geom_line()` - 선 그래프 생성
- `ggplot2::geom_smooth()` - 추세선 추가
- `zoo::rollmean()` - 이동평균
- `scatter.R` - 산점도 모듈