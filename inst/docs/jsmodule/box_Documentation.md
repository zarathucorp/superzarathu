# box Documentation

## Overview

`box.R`은 jsmodule 패키지의 박스플롯 시각화 모듈로, Shiny 애플리케이션에서 연속형 데이터의 분포를 범주별로 비교하는 인터랙티브한 박스플롯을 생성하는 기능을 제공합니다. 이 모듈은 오차막대, 개별 데이터 포인트 표시, 통계적 검정 등의 고급 기능을 포함하며, 동적 변수 선택과 커스터마이징 옵션을 지원합니다.

## Module Components

### `boxUI(id, label = "boxplot")`

박스플롯 생성을 위한 Shiny 모듈 UI를 생성합니다.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `id` | character | - | 모듈의 네임스페이스 식별자 |
| `label` | character | "boxplot" | 박스플롯 모듈 레이블 |

#### Returns

Shiny UI 객체 (박스플롯 설정을 위한 다양한 입력 컨트롤들)

#### UI Components

- 변수 선택 드롭다운 (X축, Y축)
- 오차막대, 포인트, 색상 채우기 옵션 체크박스
- P-value 및 층화 옵션

### `optionUI(id)`

추가적인 플롯 옵션을 위한 드롭다운 버튼 UI를 생성합니다.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `id` | character | - | 모듈의 네임스페이스 식별자 |

#### Returns

Shiny UI 객체 (플롯 설정 옵션이 포함된 드롭다운 버튼)

### `boxServer(id, data, data_label, data_varStruct = NULL, nfactor.limit = 10)`

박스플롯 생성을 위한 서버 사이드 로직을 제공합니다.

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
- 설정 가능한 옵션이 적용된 ggplot 박스플롯
- 동적 변수 선택 기능
- 통계적 검정 통합
- 커스터마이징된 플롯 미학

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
  titlePanel("Interactive Boxplot Analysis"),
  sidebarLayout(
    sidebarPanel(
      boxUI("box_analysis", label = "박스플롯 분석"),
      hr(),
      optionUI("box_analysis"),
      hr(),
      downloadButton("download_plot", "플롯 다운로드")
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Boxplot", 
                 plotOutput("box_plot", height = "600px")),
        tabPanel("Summary Statistics", 
                 DT::DTOutput("summary_stats")),
        tabPanel("Statistical Tests", 
                 verbatimTextOutput("stat_tests"))
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
        vs = as.factor(ifelse(vs == 0, "V-shaped", "Straight")),
        am = as.factor(ifelse(am == 0, "Automatic", "Manual")),
        gear = as.factor(gear)
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
  
  # 박스플롯 모듈 서버
  box_result <- boxServer("box_analysis",
                         data = data_input,
                         data_label = data_label,
                         nfactor.limit = 15)
  
  # 메인 박스플롯 출력
  output$box_plot <- renderPlot({
    req(box_result())
    print(box_result())
  })
  
  # 요약 통계
  output$summary_stats <- DT::renderDT({
    req(data_input())
    
    # 연속형 변수들에 대한 요약 통계
    numeric_vars <- data_input() %>% select_if(is.numeric) %>% names()
    categorical_vars <- data_input() %>% select_if(is.factor) %>% names()
    
    if(length(numeric_vars) > 0 && length(categorical_vars) > 0) {
      summary_results <- data.frame()
      
      for(num_var in numeric_vars[1:min(3, length(numeric_vars))]) {
        for(cat_var in categorical_vars[1:min(2, length(categorical_vars))]) {
          group_summary <- data_input() %>%
            group_by(!!sym(cat_var)) %>%
            summarise(
              Variable = num_var,
              Group = cat_var,
              Mean = round(mean(!!sym(num_var), na.rm = TRUE), 2),
              Median = round(median(!!sym(num_var), na.rm = TRUE), 2),
              SD = round(sd(!!sym(num_var), na.rm = TRUE), 2),
              Min = round(min(!!sym(num_var), na.rm = TRUE), 2),
              Max = round(max(!!sym(num_var), na.rm = TRUE), 2),
              .groups = "drop"
            )
          
          summary_results <- rbind(summary_results, group_summary)
        }
      }
      
      summary_results
    }
  }, options = list(scrollX = TRUE))
  
  # 통계 검정
  output$stat_tests <- renderPrint({
    req(data_input())
    
    df <- data_input()
    numeric_vars <- df %>% select_if(is.numeric) %>% names()
    categorical_vars <- df %>% select_if(is.factor) %>% names()
    
    if(length(numeric_vars) > 0 && length(categorical_vars) > 0) {
      cat("Statistical Tests Results:\n\n")
      
      for(num_var in numeric_vars[1:2]) {
        for(cat_var in categorical_vars[1:2]) {
          cat(paste("Testing", num_var, "by", cat_var, ":\n"))
          
          # 그룹 수에 따른 검정 선택
          groups <- unique(df[[cat_var]])
          
          if(length(groups) == 2) {
            # t-test for two groups
            tryCatch({
              test_result <- t.test(df[[num_var]] ~ df[[cat_var]])
              cat(paste("  Two-sample t-test: p-value =", 
                       round(test_result$p.value, 4), "\n"))
            }, error = function(e) {
              cat("  t-test failed\n")
            })
          } else if(length(groups) > 2) {
            # ANOVA for multiple groups
            tryCatch({
              anova_result <- aov(df[[num_var]] ~ df[[cat_var]])
              anova_summary <- summary(anova_result)
              cat(paste("  ANOVA: p-value =", 
                       round(anova_summary[[1]][1,5], 4), "\n"))
            }, error = function(e) {
              cat("  ANOVA failed\n")
            })
          }
          cat("\n")
        }
      }
    }
  })
}

shinyApp(ui = ui, server = server)
```

### 고급 사용법

```r
# 복잡한 박스플롯 분석 워크플로
server <- function(input, output, session) {
  # 데이터 입력 모듈 연동
  data_input <- callModule(csvFile, "datafile")
  
  # 박스플롯 분석
  box_analysis <- boxServer("box_viz",
                           data = reactive(data_input()$data),
                           data_label = reactive(data_input()$label))
  
  # 다중 박스플롯 생성
  multiple_box_plots <- reactive({
    req(data_input()$data)
    
    df <- data_input()$data
    numeric_vars <- df %>% select_if(is.numeric) %>% names()
    categorical_vars <- df %>% select_if(is.factor) %>% names()
    
    if(length(numeric_vars) >= 1 && length(categorical_vars) >= 1) {
      plots <- list()
      
      # 주요 연속형 변수들에 대한 박스플롯 생성
      for(num_var in numeric_vars[1:min(3, length(numeric_vars))]) {
        for(cat_var in categorical_vars[1:min(2, length(categorical_vars))]) {
          plot_name <- paste(num_var, "by", cat_var)
          
          p <- ggplot(df, aes_string(x = cat_var, y = num_var, fill = cat_var)) +
            geom_boxplot(alpha = 0.7, outlier.colour = "red") +
            geom_jitter(width = 0.2, alpha = 0.5) +
            stat_compare_means() +  # ggpubr 패키지의 통계 비교
            theme_minimal() +
            labs(title = paste("Distribution of", num_var, "by", cat_var),
                 x = cat_var, y = num_var) +
            theme(axis.text.x = element_text(angle = 45, hjust = 1),
                  legend.position = "none")
          
          plots[[plot_name]] <- p
        }
      }
      
      return(plots)
    }
  })
  
  # 이상치 분석
  outlier_analysis <- reactive({
    req(data_input()$data)
    
    df <- data_input()$data
    numeric_vars <- df %>% select_if(is.numeric) %>% names()
    
    outlier_summary <- data.frame()
    
    for(var in numeric_vars) {
      Q1 <- quantile(df[[var]], 0.25, na.rm = TRUE)
      Q3 <- quantile(df[[var]], 0.75, na.rm = TRUE)
      IQR <- Q3 - Q1
      
      lower_bound <- Q1 - 1.5 * IQR
      upper_bound <- Q3 + 1.5 * IQR
      
      outliers <- df[[var]][df[[var]] < lower_bound | df[[var]] > upper_bound]
      outliers <- outliers[!is.na(outliers)]
      
      outlier_summary <- rbind(outlier_summary, data.frame(
        Variable = var,
        Outlier_Count = length(outliers),
        Outlier_Percentage = round(length(outliers) / nrow(df) * 100, 2),
        Lower_Bound = round(lower_bound, 2),
        Upper_Bound = round(upper_bound, 2)
      ))
    }
    
    return(outlier_summary)
  })
  
  # 다중 플롯 출력
  output$multiple_plots <- renderUI({
    plots <- multiple_box_plots()
    req(plots)
    
    plot_outputs <- lapply(names(plots), function(name) {
      div(
        h4(name),
        renderPlot({
          plots[[name]]
        }, height = 350)
      )
    })
    
    do.call(tagList, plot_outputs)
  })
  
  # 이상치 분석 결과
  output$outlier_analysis <- DT::renderDT({
    req(outlier_analysis())
    outlier_analysis()
  })
}
```

## Visualization Features

### 지원하는 박스플롯 타입

#### 기본 박스플롯
```r
# 단순 박스플롯
ggplot(data, aes(x = categorical_var, y = continuous_var)) +
  geom_boxplot()

# 색상 구분 박스플롯
ggplot(data, aes(x = categorical_var, y = continuous_var, fill = categorical_var)) +
  geom_boxplot(alpha = 0.7)
```

#### 바이올린 플롯과 결합
```r
# 바이올린 플롯 + 박스플롯
ggplot(data, aes(x = categorical_var, y = continuous_var)) +
  geom_violin(alpha = 0.5) +
  geom_boxplot(width = 0.2, alpha = 0.8)
```

#### 개별 데이터 포인트 추가
```r
# 박스플롯 + 지터 포인트
ggplot(data, aes(x = categorical_var, y = continuous_var)) +
  geom_boxplot(alpha = 0.7) +
  geom_jitter(width = 0.2, alpha = 0.6, color = "red")

# 박스플롯 + 비스웜 플롯
ggplot(data, aes(x = categorical_var, y = continuous_var)) +
  geom_boxplot(alpha = 0.7) +
  ggbeeswarm::geom_beeswarm(alpha = 0.6)
```

### 통계적 검정 통합

#### 두 그룹 비교
```r
# t-test with ggpubr
ggplot(data, aes(x = binary_var, y = continuous_var)) +
  geom_boxplot() +
  stat_compare_means(method = "t.test")
```

#### 다중 그룹 비교
```r
# ANOVA with post-hoc tests
ggplot(data, aes(x = categorical_var, y = continuous_var)) +
  geom_boxplot() +
  stat_compare_means() +  # Overall ANOVA
  stat_compare_means(comparisons = list(c("group1", "group2")))  # Pairwise
```

#### 비모수 검정
```r
# Wilcoxon test
ggplot(data, aes(x = categorical_var, y = continuous_var)) +
  geom_boxplot() +
  stat_compare_means(method = "wilcox.test")

# Kruskal-Wallis test
ggplot(data, aes(x = categorical_var, y = continuous_var)) +
  geom_boxplot() +
  stat_compare_means(method = "kruskal.test")
```

### 커스터마이징 옵션

#### 색상 및 스타일
```r
# 색상 팔레트 옵션
color_schemes <- list(
  default = scale_fill_grey(),
  colorbrewer = scale_fill_brewer(type = "qual", palette = "Set2"),
  viridis = scale_fill_viridis_d(),
  manual = scale_fill_manual(values = c("#E69F00", "#56B4E9", "#009E73"))
)
```

#### 축 및 레이블 설정
```r
# 축 변환 및 포매팅
axis_transformations <- list(
  log_scale = scale_y_log10(),
  sqrt_scale = scale_y_sqrt(),
  reverse_scale = scale_y_reverse()
)

# 레이블 커스터마이징
label_options <- list(
  title = labs(title = "Custom Title", subtitle = "Subtitle"),
  axes = labs(x = "Custom X Label", y = "Custom Y Label"),
  caption = labs(caption = "Data source: Custom dataset")
)
```

## Advanced Features

### 이상치 탐지 및 처리

```r
# 이상치 식별 함수
identify_outliers <- function(data, variable, method = "IQR") {
  if(method == "IQR") {
    Q1 <- quantile(data[[variable]], 0.25, na.rm = TRUE)
    Q3 <- quantile(data[[variable]], 0.75, na.rm = TRUE)
    IQR <- Q3 - Q1
    
    lower_bound <- Q1 - 1.5 * IQR
    upper_bound <- Q3 + 1.5 * IQR
    
    outliers <- which(data[[variable]] < lower_bound | data[[variable]] > upper_bound)
  } else if(method == "z_score") {
    z_scores <- abs(scale(data[[variable]]))
    outliers <- which(z_scores > 3)
  }
  
  return(outliers)
}

# 이상치 시각화
plot_with_outliers <- function(data, x_var, y_var) {
  outlier_indices <- identify_outliers(data, y_var)
  
  ggplot(data, aes_string(x = x_var, y = y_var)) +
    geom_boxplot(alpha = 0.7) +
    geom_point(data = data[outlier_indices, ], 
               aes_string(x = x_var, y = y_var),
               color = "red", size = 3, alpha = 0.8) +
    labs(title = paste("Boxplot with outliers highlighted"))
}
```

### 동적 그룹 비교

```r
# 동적 페어와이즈 비교
dynamic_comparisons <- reactive({
  req(input$group_var, data_input()$data)
  
  groups <- unique(data_input()$data[[input$group_var]])
  
  if(length(groups) > 2) {
    # 모든 가능한 페어와이즈 비교 생성
    combinations <- combn(groups, 2, simplify = FALSE)
    return(combinations)
  } else {
    return(list(groups))
  }
})

# 통계 결과 테이블
statistical_summary <- reactive({
  req(dynamic_comparisons(), input$y_var)
  
  comparisons <- dynamic_comparisons()
  results <- data.frame()
  
  for(comp in comparisons) {
    if(length(comp) == 2) {
      group1_data <- data_input()$data[data_input()$data[[input$group_var]] == comp[1], input$y_var]
      group2_data <- data_input()$data[data_input()$data[[input$group_var]] == comp[2], input$y_var]
      
      # t-test
      t_result <- t.test(group1_data, group2_data)
      
      results <- rbind(results, data.frame(
        Comparison = paste(comp[1], "vs", comp[2]),
        Mean_Diff = round(mean(group1_data, na.rm = TRUE) - mean(group2_data, na.rm = TRUE), 3),
        P_value = round(t_result$p.value, 4),
        CI_Lower = round(t_result$conf.int[1], 3),
        CI_Upper = round(t_result$conf.int[2], 3)
      ))
    }
  }
  
  return(results)
})
```

## Export and Download Features

### 고품질 플롯 내보내기

```r
# 출판 품질 플롯 생성
publication_quality_plot <- reactive({
  req(box_result())
  
  base_plot <- box_result()
  
  # 고품질 테마 적용
  publication_plot <- base_plot +
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
  
  return(publication_plot)
})

# 다운로드 핸들러
output$download_publication_plot <- downloadHandler(
  filename = function() {
    paste("boxplot_publication_", Sys.Date(), ".pdf", sep = "")
  },
  content = function(file) {
    ggsave(file, plot = publication_quality_plot(),
           width = 8, height = 6, dpi = 300, device = "pdf")
  }
)
```

## Performance Optimization

### 대용량 데이터 처리

```r
# 효율적인 박스플롯 생성
efficient_boxplot <- reactive({
  req(data_input()$data)
  
  df <- data_input()$data
  
  # 표본 추출 (필요한 경우)
  if(nrow(df) > 10000) {
    df_sample <- df %>% 
      group_by(!!sym(input$group_var)) %>%
      slice_sample(n = min(1000, n())) %>%
      ungroup()
    
    showNotification("Large dataset: Using stratified sampling", type = "info")
  } else {
    df_sample <- df
  }
  
  # 최적화된 플롯 생성
  ggplot(df_sample, aes_string(x = input$group_var, y = input$y_var)) +
    geom_boxplot(alpha = 0.7) +
    theme_minimal()
})
```

## Dependencies

### 필수 패키지

- `shiny` - 기본 Shiny 기능
- `ggplot2` - 그래픽 생성
- `ggpubr` - 통계적 비교 및 p-value 표시

### 선택적 패키지

- `dplyr` - 데이터 조작
- `ggbeeswarm` - 비스웜 플롯
- `RColorBrewer` - 색상 팔레트

## Troubleshooting

### 일반적인 오류

```r
# 1. 그룹별 관측치 수가 너무 적은 경우
# 해결: 최소 관측치 수 확인 및 경고 메시지

# 2. 모든 값이 동일한 경우 (분산이 0)
# 해결: 분산 확인 및 다른 시각화 방법 제안

# 3. 극단적인 이상치로 인한 스케일 문제
# 해결: 축 변환 옵션 또는 이상치 제거 옵션 제공

# 4. 범주가 너무 많은 경우
# 해결: 상위 카테고리 선택 또는 다른 시각화 방법 제안
```

## See Also

- `ggplot2::geom_boxplot()` - 박스플롯 생성
- `ggpubr::stat_compare_means()` - 통계적 비교
- `bar.R` - 막대그래프 모듈
- `histogram.R` - 히스토그램 모듈