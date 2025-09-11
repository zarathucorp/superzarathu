# scatter Documentation

## Overview

`scatter.R`은 jsmodule 패키지의 산점도 시각화 모듈로, Shiny 애플리케이션에서 두 연속형 변수 간의 관계를 탐색하는 인터랙티브한 산점도를 생성하는 기능을 제공합니다. 이 모듈은 상관관계 분석, 회귀선 추가, 하위집단 분석 등의 고급 기능을 포함하며, 데이터의 선형 및 비선형 관계를 시각적으로 파악하는 데 도움을 줍니다.

## Module Components

### `scatterUI(id, label = "scatterplot")`

산점도 생성을 위한 Shiny 모듈 UI를 생성합니다.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `id` | character | - | 모듈의 네임스페이스 식별자 |
| `label` | character | "scatterplot" | 산점도 모듈 레이블 |

#### Returns

Shiny UI 객체 (산점도 설정을 위한 UI 요소들)

#### UI Components

- 변수 선택 드롭다운 (X축, Y축)
- 회귀선 타입 선택
- 상관계수 옵션
- 하위집단 분석 컨트롤

### `scatterServer(id, data, data_label, data_varStruct = NULL, nfactor.limit = 10)`

산점도 생성을 위한 서버 사이드 로직을 제공합니다.

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
- 동적 변수 처리
- 유연한 플롯 커스터마이징
- 하위집단 분석
- 플롯 내보내기 다운로드 옵션

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
  titlePanel("Interactive Scatterplot Analysis"),
  sidebarLayout(
    sidebarPanel(
      scatterUI("scatter_analysis", label = "산점도 분석"),
      hr(),
      downloadButton("download_plot", "플롯 다운로드")
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Scatterplot", 
                 plotOutput("scatter_plot", height = "600px")),
        tabPanel("Correlation Analysis", 
                 verbatimTextOutput("correlation_analysis")),
        tabPanel("Regression Summary", 
                 verbatimTextOutput("regression_summary"))
      )
    )
  )
)

server <- function(input, output, session) {
  # 예시 데이터
  data_input <- reactive({
    # 다양한 관계를 보여주는 데이터 생성
    set.seed(123)
    n <- 200
    
    data.frame(
      x1 = rnorm(n, 50, 10),
      y1 = 20 + 0.8 * rnorm(n, 50, 10) + rnorm(n, 0, 5),  # 양의 상관관계
      x2 = rnorm(n, 30, 8),
      y2 = 100 - 1.2 * rnorm(n, 30, 8) + rnorm(n, 0, 6),  # 음의 상관관계
      x3 = runif(n, 0, 10),
      y3 = (runif(n, 0, 10) - 5)^2 + rnorm(n, 0, 2),      # 비선형 관계
      group = factor(sample(c("A", "B", "C"), n, replace = TRUE)),
      treatment = factor(sample(c("Control", "Treatment"), n, replace = TRUE))
    )
  })
  
  data_label <- reactive({
    data.frame(
      variable = names(data_input()),
      label = c("X Variable 1", "Y Variable 1 (Positive Corr)", 
               "X Variable 2", "Y Variable 2 (Negative Corr)",
               "X Variable 3", "Y Variable 3 (Non-linear)",
               "Group Variable", "Treatment Variable"),
      stringsAsFactors = FALSE
    )
  })
  
  # 산점도 모듈 서버
  scatter_result <- scatterServer("scatter_analysis",
                                 data = data_input,
                                 data_label = data_label,
                                 nfactor.limit = 15)
  
  # 메인 산점도 출력
  output$scatter_plot <- renderPlot({
    req(scatter_result())
    print(scatter_result())
  })
  
  # 상관관계 분석
  output$correlation_analysis <- renderPrint({
    req(data_input())
    
    df <- data_input()
    numeric_vars <- df %>% select_if(is.numeric) %>% names()
    
    cat("Correlation Analysis Results:\n\n")
    
    # 모든 수치형 변수 간 상관관계
    if(length(numeric_vars) >= 2) {
      cor_matrix <- cor(df[numeric_vars], use = "complete.obs")
      
      cat("Correlation Matrix:\n")
      print(round(cor_matrix, 3))
      cat("\n")
      
      # 강한 상관관계 식별
      strong_corr <- which(abs(cor_matrix) > 0.7 & cor_matrix != 1, arr.ind = TRUE)
      
      if(nrow(strong_corr) > 0) {
        cat("Strong Correlations (|r| > 0.7):\n")
        for(i in 1:nrow(strong_corr)) {
          var1 <- rownames(cor_matrix)[strong_corr[i, 1]]
          var2 <- colnames(cor_matrix)[strong_corr[i, 2]]
          corr_val <- cor_matrix[strong_corr[i, 1], strong_corr[i, 2]]
          
          cat(sprintf("  %s vs %s: r = %.3f\n", var1, var2, corr_val))
        }
        cat("\n")
      }
      
      # 상관관계 검정
      for(i in 1:(length(numeric_vars)-1)) {
        for(j in (i+1):length(numeric_vars)) {
          var1 <- numeric_vars[i]
          var2 <- numeric_vars[j]
          
          cor_test <- cor.test(df[[var1]], df[[var2]])
          
          cat(sprintf("Correlation Test: %s vs %s\n", var1, var2))
          cat(sprintf("  Pearson's r: %.3f\n", cor_test$estimate))
          cat(sprintf("  P-value: %.4f\n", cor_test$p.value))
          cat(sprintf("  95%% CI: [%.3f, %.3f]\n\n", 
                     cor_test$conf.int[1], cor_test$conf.int[2]))
        }
      }
    }
  })
  
  # 회귀분석 요약
  output$regression_summary <- renderPrint({
    req(data_input())
    
    df <- data_input()
    numeric_vars <- df %>% select_if(is.numeric) %>% names()
    
    if(length(numeric_vars) >= 2) {
      cat("Regression Analysis Summary:\n\n")
      
      # 첫 번째 변수 쌍에 대한 회귀분석
      x_var <- numeric_vars[1]
      y_var <- numeric_vars[2]
      
      # 선형 회귀
      lm_result <- lm(df[[y_var]] ~ df[[x_var]])
      
      cat(sprintf("Linear Regression: %s ~ %s\n", y_var, x_var))
      cat("Coefficients:\n")
      print(summary(lm_result)$coefficients)
      cat(sprintf("\nR-squared: %.4f\n", summary(lm_result)$r.squared))
      cat(sprintf("Adjusted R-squared: %.4f\n", summary(lm_result)$adj.r.squared))
      cat(sprintf("F-statistic: %.3f (p-value: %.4f)\n\n", 
                 summary(lm_result)$fstatistic[1],
                 pf(summary(lm_result)$fstatistic[1], 
                    summary(lm_result)$fstatistic[2],
                    summary(lm_result)$fstatistic[3], 
                    lower.tail = FALSE)))
      
      # 잔차 분석
      residuals <- residuals(lm_result)
      cat("Residual Analysis:\n")
      cat(sprintf("  Mean residual: %.4f\n", mean(residuals)))
      cat(sprintf("  SD of residuals: %.4f\n", sd(residuals)))
      cat(sprintf("  Durbin-Watson statistic: %.3f\n", 
                 lmtest::dwtest(lm_result)$statistic))
    }
  })
}

shinyApp(ui = ui, server = server)
```

### 고급 사용법

```r
# 복잡한 산점도 분석 워크플로
server <- function(input, output, session) {
  # 데이터 입력 모듈 연동
  data_input <- callModule(csvFile, "datafile")
  
  # 산점도 분석
  scatter_analysis <- scatterServer("scatter_viz",
                                   data = reactive(data_input()$data),
                                   data_label = reactive(data_input()$label))
  
  # 다중 산점도 매트릭스
  scatter_matrix <- reactive({
    req(data_input()$data)
    
    df <- data_input()$data
    numeric_vars <- df %>% select_if(is.numeric) %>% names()
    
    if(length(numeric_vars) >= 3) {
      # 상위 5개 변수만 선택 (성능상의 이유)
      selected_vars <- numeric_vars[1:min(5, length(numeric_vars))]
      
      # GGally::ggpairs 사용
      if(requireNamespace("GGally", quietly = TRUE)) {
        p <- GGally::ggpairs(df[selected_vars],
                            upper = list(continuous = "cor"),
                            lower = list(continuous = "points"),
                            diag = list(continuous = "densityDiag")) +
          theme_minimal()
        
        return(p)
      }
    }
  })
  
  # 그룹별 산점도
  grouped_scatterplot <- reactive({
    req(data_input()$data)
    
    df <- data_input()$data
    numeric_vars <- df %>% select_if(is.numeric) %>% names()
    categorical_vars <- df %>% select_if(is.factor) %>% names()
    
    if(length(numeric_vars) >= 2 && length(categorical_vars) >= 1) {
      x_var <- numeric_vars[1]
      y_var <- numeric_vars[2]
      group_var <- categorical_vars[1]
      
      # 그룹별 색상 구분 산점도
      p1 <- ggplot(df, aes_string(x = x_var, y = y_var, color = group_var)) +
        geom_point(size = 2, alpha = 0.7) +
        geom_smooth(method = "lm", se = TRUE, alpha = 0.3) +
        scale_color_brewer(type = "qual", palette = "Set2") +
        labs(title = paste("Scatterplot:", y_var, "vs", x_var, "by", group_var),
             x = x_var, y = y_var, color = group_var) +
        theme_minimal() +
        theme(legend.position = "top")
      
      # 패싯별 산점도
      p2 <- ggplot(df, aes_string(x = x_var, y = y_var)) +
        geom_point(alpha = 0.6) +
        geom_smooth(method = "lm", se = TRUE, color = "red") +
        facet_wrap(as.formula(paste("~", group_var)), scales = "free") +
        labs(title = paste("Faceted Scatterplot:", y_var, "vs", x_var),
             x = x_var, y = y_var) +
        theme_minimal()
      
      return(list(grouped = p1, faceted = p2))
    }
  })
  
  # 이상치 탐지 분석
  outlier_detection <- reactive({
    req(data_input()$data)
    
    df <- data_input()$data
    numeric_vars <- df %>% select_if(is.numeric) %>% names()
    
    if(length(numeric_vars) >= 2) {
      outlier_results <- data.frame()
      
      for(i in 1:(length(numeric_vars)-1)) {
        for(j in (i+1):length(numeric_vars)) {
          var1 <- numeric_vars[i]
          var2 <- numeric_vars[j]
          
          # Mahalanobis distance를 이용한 이상치 탐지
          data_subset <- df[, c(var1, var2)]
          data_complete <- data_subset[complete.cases(data_subset), ]
          
          if(nrow(data_complete) > 2) {
            center <- colMeans(data_complete)
            cov_matrix <- cov(data_complete)
            
            # Mahalanobis distance 계산
            mahal_dist <- mahalanobis(data_complete, center, cov_matrix)
            
            # 이상치 임계값 (카이제곱 분포의 97.5% 분위수)
            threshold <- qchisq(0.975, df = 2)
            outliers <- which(mahal_dist > threshold)
            
            outlier_results <- rbind(outlier_results, data.frame(
              Variable_Pair = paste(var1, "vs", var2),
              Total_Observations = nrow(data_complete),
              Outliers_Count = length(outliers),
              Outlier_Percentage = round(length(outliers) / nrow(data_complete) * 100, 2),
              Threshold = round(threshold, 2)
            ))
          }
        }
      }
      
      return(outlier_results)
    }
  })
  
  # 비선형 관계 탐지
  nonlinear_analysis <- reactive({
    req(data_input()$data)
    
    df <- data_input()$data
    numeric_vars <- df %>% select_if(is.numeric) %>% names()
    
    if(length(numeric_vars) >= 2) {
      nonlinear_results <- data.frame()
      
      for(i in 1:(length(numeric_vars)-1)) {
        for(j in (i+1):length(numeric_vars)) {
          var1 <- numeric_vars[i]
          var2 <- numeric_vars[j]
          
          x <- df[[var1]]
          y <- df[[var2]]
          
          # 완전한 관측치만 사용
          complete_data <- complete.cases(x, y)
          x_clean <- x[complete_data]
          y_clean <- y[complete_data]
          
          if(length(x_clean) > 10) {
            # 선형 모델
            lm_model <- lm(y_clean ~ x_clean)
            linear_r2 <- summary(lm_model)$r.squared
            
            # 2차 다항식 모델
            poly_model <- lm(y_clean ~ poly(x_clean, 2))
            poly_r2 <- summary(poly_model)$r.squared
            
            # 비선형성 개선 정도
            improvement <- poly_r2 - linear_r2
            
            nonlinear_results <- rbind(nonlinear_results, data.frame(
              Variable_Pair = paste(var1, "vs", var2),
              Linear_R2 = round(linear_r2, 4),
              Polynomial_R2 = round(poly_r2, 4),
              Improvement = round(improvement, 4),
              Likely_Nonlinear = ifelse(improvement > 0.05, "Yes", "No")
            ))
          }
        }
      }
      
      return(nonlinear_results)
    }
  })
  
  # 산점도 매트릭스 출력
  output$scatter_matrix <- renderPlot({
    req(scatter_matrix())
    scatter_matrix()
  }, height = 600)
  
  # 그룹별 산점도 출력
  output$grouped_scatterplots <- renderUI({
    plots <- grouped_scatterplot()
    req(plots)
    
    tagList(
      h4("Grouped Scatterplot"),
      renderPlot({plots$grouped}, height = 400),
      h4("Faceted Scatterplot"),
      renderPlot({plots$faceted}, height = 400)
    )
  })
  
  # 이상치 탐지 결과
  output$outlier_detection <- DT::renderDT({
    req(outlier_detection())
    outlier_detection()
  })
  
  # 비선형 관계 분석 결과
  output$nonlinear_analysis <- DT::renderDT({
    req(nonlinear_analysis())
    nonlinear_analysis()
  })
}
```

## Visualization Features

### 지원하는 산점도 타입

#### 기본 산점도
```r
# 단순 산점도
ggplot(data, aes(x = x_var, y = y_var)) +
  geom_point()

# 투명도와 크기 조정
ggplot(data, aes(x = x_var, y = y_var)) +
  geom_point(alpha = 0.6, size = 2)
```

#### 그룹별 산점도
```r
# 색상으로 그룹 구분
ggplot(data, aes(x = x_var, y = y_var, color = group_var)) +
  geom_point(size = 2)

# 모양으로 그룹 구분
ggplot(data, aes(x = x_var, y = y_var, shape = group_var)) +
  geom_point(size = 3)

# 색상과 모양 모두 사용
ggplot(data, aes(x = x_var, y = y_var, color = group1, shape = group2)) +
  geom_point(size = 2)
```

#### 회귀선이 포함된 산점도
```r
# 선형 회귀선
ggplot(data, aes(x = x_var, y = y_var)) +
  geom_point() +
  geom_smooth(method = "lm", se = TRUE)

# 비선형 회귀선 (loess)
ggplot(data, aes(x = x_var, y = y_var)) +
  geom_point() +
  geom_smooth(method = "loess", se = TRUE)

# 다항식 회귀선
ggplot(data, aes(x = x_var, y = y_var)) +
  geom_point() +
  geom_smooth(method = "lm", formula = y ~ poly(x, 2), se = TRUE)
```

### 상관관계 분석 통합

#### 상관계수 표시
```r
# Pearson 상관계수
correlation_text <- function(data, x_var, y_var) {
  cor_result <- cor.test(data[[x_var]], data[[y_var]])
  
  text_label <- paste0(
    "r = ", round(cor_result$estimate, 3),
    "\np = ", round(cor_result$p.value, 4)
  )
  
  return(text_label)
}

# 산점도에 상관계수 추가
add_correlation <- function(plot, data, x_var, y_var) {
  plot + 
    annotate("text", 
             x = Inf, y = Inf, 
             label = correlation_text(data, x_var, y_var),
             hjust = 1.1, vjust = 1.1, 
             size = 4, color = "blue")
}
```

#### 다중 상관관계 분석
```r
# 편상관계수 계산
partial_correlation <- function(data, x_var, y_var, control_vars) {
  if(requireNamespace("ppcor", quietly = TRUE)) {
    vars_subset <- data[, c(x_var, y_var, control_vars)]
    complete_data <- vars_subset[complete.cases(vars_subset), ]
    
    if(nrow(complete_data) > length(control_vars) + 2) {
      pcor_result <- ppcor::pcor.test(
        complete_data[[x_var]], 
        complete_data[[y_var]], 
        complete_data[, control_vars, drop = FALSE]
      )
      
      return(list(
        estimate = pcor_result$estimate,
        p_value = pcor_result$p.value
      ))
    }
  }
}
```

### 고급 시각화 기법

#### 밀도 등고선 추가
```r
# 2D 밀도 등고선
ggplot(data, aes(x = x_var, y = y_var)) +
  geom_point(alpha = 0.5) +
  geom_density_2d() +
  theme_minimal()

# 색상으로 밀도 표시
ggplot(data, aes(x = x_var, y = y_var)) +
  stat_density_2d_filled(alpha = 0.7) +
  geom_point(color = "white", size = 0.5) +
  theme_minimal()
```

#### 마진 히스토그램
```r
# 마진에 히스토그램이 있는 산점도
if(requireNamespace("ggExtra", quietly = TRUE)) {
  base_plot <- ggplot(data, aes(x = x_var, y = y_var)) +
    geom_point() +
    theme_minimal()
  
  marginal_plot <- ggExtra::ggMarginal(base_plot, type = "histogram")
}
```

#### 버블 차트
```r
# 세 번째 변수로 점 크기 조정
ggplot(data, aes(x = x_var, y = y_var, size = size_var)) +
  geom_point(alpha = 0.6) +
  scale_size_continuous(range = c(1, 10)) +
  theme_minimal()

# 네 번째 변수로 색상 추가
ggplot(data, aes(x = x_var, y = y_var, size = size_var, color = color_var)) +
  geom_point(alpha = 0.7) +
  scale_size_continuous(range = c(1, 8)) +
  scale_color_viridis_c() +
  theme_minimal()
```

## Statistical Integration

### 회귀 진단

#### 잔차 분석
```r
# 회귀 진단 플롯
regression_diagnostics <- function(data, x_var, y_var) {
  lm_model <- lm(data[[y_var]] ~ data[[x_var]])
  
  # 잔차 vs 적합값
  p1 <- ggplot(data.frame(fitted = fitted(lm_model), 
                         residuals = residuals(lm_model)),
               aes(x = fitted, y = residuals)) +
    geom_point() +
    geom_hline(yintercept = 0, color = "red") +
    geom_smooth(se = FALSE) +
    labs(title = "Residuals vs Fitted", x = "Fitted values", y = "Residuals")
  
  # Q-Q 플롯
  p2 <- ggplot(data.frame(sample = residuals(lm_model)), aes(sample = sample)) +
    stat_qq() +
    stat_qq_line() +
    labs(title = "Normal Q-Q", x = "Theoretical Quantiles", y = "Sample Quantiles")
  
  return(list(residuals_fitted = p1, qq_plot = p2))
}
```

#### 영향력 분석
```r
# Cook's distance 계산
influence_analysis <- function(data, x_var, y_var) {
  lm_model <- lm(data[[y_var]] ~ data[[x_var]])
  
  cooks_d <- cooks.distance(lm_model)
  leverage <- hatvalues(lm_model)
  
  # 영향력이 큰 관측치 식별
  high_influence <- which(cooks_d > 4/length(cooks_d))
  
  return(list(
    cooks_distance = cooks_d,
    leverage = leverage,
    influential_points = high_influence
  ))
}
```

### 비선형성 탐지

#### 다항식 적합
```r
# 다양한 차수의 다항식 비교
polynomial_comparison <- function(data, x_var, y_var, max_degree = 4) {
  results <- data.frame()
  
  for(degree in 1:max_degree) {
    poly_model <- lm(data[[y_var]] ~ poly(data[[x_var]], degree))
    
    results <- rbind(results, data.frame(
      Degree = degree,
      R_squared = summary(poly_model)$r.squared,
      Adjusted_R_squared = summary(poly_model)$adj.r.squared,
      AIC = AIC(poly_model),
      BIC = BIC(poly_model)
    ))
  }
  
  return(results)
}
```

#### 스플라인 평활화
```r
# GAM (Generalized Additive Model)을 이용한 비선형 관계 탐지
if(requireNamespace("mgcv", quietly = TRUE)) {
  gam_smoothing <- function(data, x_var, y_var) {
    gam_model <- mgcv::gam(data[[y_var]] ~ s(data[[x_var]]))
    
    # 평활화된 곡선 예측
    x_seq <- seq(min(data[[x_var]], na.rm = TRUE), 
                 max(data[[x_var]], na.rm = TRUE), 
                 length.out = 100)
    
    predictions <- predict(gam_model, 
                          newdata = data.frame(x = x_seq), 
                          se.fit = TRUE)
    
    return(data.frame(
      x = x_seq,
      fitted = predictions$fit,
      se = predictions$se.fit
    ))
  }
}
```

## Advanced Features

### 동적 필터링

```r
# 브러싱을 통한 동적 선택
brushed_points <- reactive({
  req(input$plot_brush)
  
  brushedPoints(data_input()$data, input$plot_brush)
})

# 선택된 점들의 정보 표시
output$brushed_info <- renderTable({
  req(brushed_points())
  
  selected_data <- brushed_points()
  
  if(nrow(selected_data) > 0) {
    summary_stats <- selected_data %>%
      summarise_if(is.numeric, list(
        Mean = ~mean(., na.rm = TRUE),
        SD = ~sd(., na.rm = TRUE),
        Min = ~min(., na.rm = TRUE),
        Max = ~max(., na.rm = TRUE)
      ))
    
    return(summary_stats)
  }
})
```

### 인터랙티브 줌

```r
# 줌 기능이 있는 산점도
zoomable_scatter <- reactive({
  req(input$x_range, input$y_range)
  
  base_plot <- ggplot(data_input()$data, 
                     aes_string(x = input$x_var, y = input$y_var)) +
    geom_point(alpha = 0.6) +
    geom_smooth(method = "lm", se = TRUE)
  
  if(!is.null(input$x_range) && !is.null(input$y_range)) {
    base_plot <- base_plot + 
      coord_cartesian(xlim = input$x_range, ylim = input$y_range)
  }
  
  return(base_plot)
})
```

### 애니메이션 산점도

```r
# 시간에 따른 변화 애니메이션 (gganimate 사용)
if(requireNamespace("gganimate", quietly = TRUE)) {
  animated_scatter <- reactive({
    req(input$time_var, data_input()$data)
    
    df <- data_input()$data
    
    if(input$time_var %in% names(df)) {
      p <- ggplot(df, aes_string(x = input$x_var, y = input$y_var)) +
        geom_point(size = 3, alpha = 0.7) +
        theme_minimal() +
        labs(title = "Time: {closest_state}") +
        gganimate::transition_states(!!sym(input$time_var),
                                   transition_length = 1,
                                   state_length = 1)
      
      return(p)
    }
  })
}
```

## Export and Download Features

### 고해상도 산점도

```r
# 출판 품질 산점도
publication_scatter <- reactive({
  req(scatter_result())
  
  # 고품질 테마 적용
  scatter_result() +
    theme_classic() +
    theme(
      text = element_text(size = 12, family = "Arial"),
      axis.title = element_text(size = 14, face = "bold"),
      axis.text = element_text(size = 12),
      legend.title = element_text(size = 12, face = "bold"),
      legend.text = element_text(size = 11),
      plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
      panel.grid.major = element_line(color = "gray90", size = 0.5),
      panel.grid.minor = element_blank()
    )
})
```

### 분석 결과 내보내기

```r
# 상관관계 분석 결과 다운로드
output$download_correlation_results <- downloadHandler(
  filename = function() {
    paste("correlation_analysis_", Sys.Date(), ".csv", sep = "")
  },
  content = function(file) {
    numeric_data <- data_input()$data %>% select_if(is.numeric)
    cor_matrix <- cor(numeric_data, use = "complete.obs")
    
    # 상관계수 매트릭스를 long format으로 변환
    cor_df <- expand.grid(Var1 = rownames(cor_matrix), 
                         Var2 = colnames(cor_matrix))
    cor_df$Correlation <- as.vector(cor_matrix)
    
    write.csv(cor_df, file, row.names = FALSE)
  }
)
```

## Performance Optimization

### 대용량 데이터 처리

```r
# 효율적인 산점도 생성
efficient_scatter <- reactive({
  req(data_input()$data)
  
  df <- data_input()$data
  
  # 데이터 포인트가 너무 많은 경우 샘플링
  if(nrow(df) > 5000) {
    df_sample <- df[sample(nrow(df), 5000), ]
    showNotification("Large dataset: Using random sample of 5,000 points", 
                    type = "info")
  } else {
    df_sample <- df
  }
  
  # 최적화된 플롯 생성
  ggplot(df_sample, aes_string(x = input$x_var, y = input$y_var)) +
    geom_point(alpha = 0.6) +
    theme_minimal()
})
```

## Dependencies

### 필수 패키지

- `shiny` - 기본 Shiny 기능
- `ggplot2` - 그래픽 생성
- `ggpubr` - 향상된 플롯 기능

### 선택적 패키지

- `GGally` - 산점도 매트릭스
- `ggExtra` - 마진 플롯
- `mgcv` - GAM 모델링
- `ppcor` - 편상관계수
- `gganimate` - 애니메이션

## Troubleshooting

### 일반적인 오류

```r
# 1. 모든 점이 한 직선 위에 있는 경우
# 해결: 완벽한 상관관계 확인 및 적절한 메시지

# 2. 극단적인 이상치로 인한 스케일 문제
# 해결: 이상치 제거 또는 축 변환 옵션

# 3. 결측치로 인한 플롯 오류
# 해결: complete.cases() 사용

# 4. 너무 많은 점으로 인한 오버플로팅
# 해결: 투명도 조정, 샘플링, 또는 2D 밀도 플롯 사용
```

## See Also

- `ggplot2::geom_point()` - 산점도 생성
- `ggplot2::geom_smooth()` - 회귀선 추가
- `GGally::ggpairs()` - 산점도 매트릭스
- `line.R` - 선 그래프 모듈