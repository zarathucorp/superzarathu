# roc Documentation

## Overview

`roc.R`은 jsmodule 패키지의 ROC(Receiver Operating Characteristic) 분석 시각화 모듈로, Shiny 애플리케이션에서 이진 분류 모델의 성능을 평가하는 인터랙티브한 ROC 곡선을 생성하는 기능을 제공합니다. 이 모듈은 AUC 계산, 최적 절단점 탐색, 모델 비교, 그리고 재분류 개선도(NRI, IDI) 분석 등의 고급 기능을 포함합니다.

## Module Components

### `rocUI(id)`

ROC 분석을 위한 Shiny 모듈 UI를 생성합니다.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `id` | character | - | 모듈의 네임스페이스 식별자 |

#### Returns

Shiny UI 객체 (ROC 분석 설정을 위한 UI 요소들)

#### UI Components

- 이벤트 변수 선택
- 독립변수 선택
- 절단값 입력
- 하위집단 분석 옵션
- 특이도 표시 토글

### `rocModule(input, output, session, data, data_label, data_varStruct = NULL, nfactor.limit = 10, design.survey = NULL, id.cluster = NULL)`

ROC 분석을 위한 서버 사이드 로직을 제공합니다.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `input` | - | - | Shiny 입력 객체 |
| `output` | - | - | Shiny 출력 객체 |
| `session` | - | - | Shiny 세션 객체 |
| `data` | reactive | - | 반응형 데이터 소스 |
| `data_label` | reactive | - | 반응형 데이터 레이블 |
| `data_varStruct` | list | NULL | 변수 구조 정보 |
| `nfactor.limit` | integer | 10 | 범주형 변수 레벨 최대 개수 |
| `design.survey` | survey.design | NULL | 설문조사 설계 데이터 |
| `id.cluster` | character | NULL | 마진 모델용 클러스터 변수 |

#### Returns

다음을 포함하는 반응형 리스트:
- ROC 플롯
- 절단점 통계
- ROC 분석 테이블

### `rocModule2()`

`rocModule()`과 유사하며, 라디오 버튼을 통한 모델 선택 방식이 다릅니다.

## Utility Functions

### `ROC_table()`

ROC 객체에서 AUC, NRI, IDI 정보를 추출합니다.

### `reclassificationJS()`

재분류 통계량을 계산합니다.

## Usage Examples

### 기본 사용법

```r
library(shiny)
library(jsmodule)
library(pROC)
library(DT)

# UI 정의
ui <- fluidPage(
  titlePanel("Interactive ROC Analysis"),
  sidebarLayout(
    sidebarPanel(
      rocUI("roc_analysis"),
      hr(),
      downloadButton("download_plot", "ROC 곡선 다운로드")
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("ROC Curve", 
                 plotOutput("plot_roc", height = "600px")),
        tabPanel("Cutoff Statistics", 
                 tableOutput("cut_roc")),
        tabPanel("ROC Analysis Table", 
                 DT::DTOutput("table_roc")),
        tabPanel("Model Comparison", 
                 DT::DTOutput("model_comparison"))
      )
    )
  )
)

server <- function(input, output, session) {
  # 예시 이진 분류 데이터
  data_input <- reactive({
    # 로지스틱 회귀에 적합한 데이터 생성
    set.seed(123)
    n <- 300
    
    x1 <- rnorm(n, 0, 1)
    x2 <- rnorm(n, 0, 1)
    x3 <- rnorm(n, 0, 1)
    
    # 로지스틱 모델: P(Y=1) = 1/(1 + exp(-(β0 + β1*x1 + β2*x2 + β3*x3)))
    linear_pred <- -0.5 + 1.2*x1 + 0.8*x2 + 0.3*x3
    prob <- 1 / (1 + exp(-linear_pred))
    
    y <- rbinom(n, 1, prob)
    
    # 예측 점수들 (서로 다른 모델을 시뮬레이션)
    score1 <- linear_pred + rnorm(n, 0, 0.1)  # 좋은 모델
    score2 <- 0.7 * linear_pred + rnorm(n, 0, 0.3)  # 중간 모델
    score3 <- 0.3 * linear_pred + rnorm(n, 0, 0.5)  # 나쁜 모델
    
    data.frame(
      outcome = as.factor(y),
      predictor1 = x1,
      predictor2 = x2,
      predictor3 = x3,
      model1_score = score1,
      model2_score = score2,
      model3_score = score3,
      group = factor(sample(c("A", "B"), n, replace = TRUE))
    )
  })
  
  data_label <- reactive({
    data.frame(
      variable = names(data_input()),
      label = c("Binary Outcome", "Predictor 1", "Predictor 2", 
               "Predictor 3", "Model 1 Score", "Model 2 Score", 
               "Model 3 Score", "Group Variable"),
      stringsAsFactors = FALSE
    )
  })
  
  # ROC 모듈 서버
  roc_result <- callModule(rocModule, "roc_analysis",
                          data = data_input,
                          data_label = data_label,
                          nfactor.limit = 15)
  
  # ROC 곡선 플롯 출력
  output$plot_roc <- renderPlot({
    req(roc_result())
    roc_result()$plot
  })
  
  # 절단점 통계 출력
  output$cut_roc <- renderTable({
    req(roc_result())
    roc_result()$cutoff_stats
  })
  
  # ROC 분석 테이블 출력
  output$table_roc <- DT::renderDT({
    req(roc_result())
    roc_result()$roc_table
  })
  
  # 모델 비교 분석
  output$model_comparison <- DT::renderDT({
    req(data_input())
    
    df <- data_input()
    
    if("outcome" %in% names(df)) {
      # 여러 모델의 AUC 비교
      score_vars <- names(df)[grepl("score", names(df))]
      
      comparison_results <- data.frame()
      
      for(score_var in score_vars) {
        tryCatch({
          roc_obj <- pROC::roc(df$outcome, df[[score_var]], quiet = TRUE)
          
          # AUC와 신뢰구간
          auc_ci <- pROC::ci.auc(roc_obj)
          
          comparison_results <- rbind(comparison_results, data.frame(
            Model = score_var,
            AUC = round(as.numeric(roc_obj$auc), 4),
            AUC_Lower_CI = round(auc_ci[1], 4),
            AUC_Upper_CI = round(auc_ci[3], 4),
            N_Positive = sum(df$outcome == 1),
            N_Negative = sum(df$outcome == 0)
          ))
        }, error = function(e) NULL)
      }
      
      comparison_results
    }
  })
}

shinyApp(ui = ui, server = server)
```

### 고급 사용법

```r
# 복잡한 ROC 분석 워크플로
server <- function(input, output, session) {
  # 데이터 입력 모듈 연동
  data_input <- callModule(csvFile, "datafile")
  
  # ROC 분석
  roc_analysis <- callModule(rocModule, "roc_viz",
                            data = reactive(data_input()$data),
                            data_label = reactive(data_input()$label))
  
  # 다중 ROC 곡선 비교
  multiple_roc_analysis <- reactive({
    req(data_input()$data)
    
    df <- data_input()$data
    
    # 이진 변수와 연속형 변수 식별
    binary_vars <- df %>% 
      select_if(function(x) is.factor(x) && length(levels(x)) == 2) %>%
      names()
    
    continuous_vars <- df %>% select_if(is.numeric) %>% names()
    
    if(length(binary_vars) >= 1 && length(continuous_vars) >= 2) {
      outcome_var <- binary_vars[1]
      predictor_vars <- continuous_vars[1:min(3, length(continuous_vars))]
      
      roc_results <- list()
      
      for(pred_var in predictor_vars) {
        tryCatch({
          roc_obj <- pROC::roc(df[[outcome_var]], df[[pred_var]], quiet = TRUE)
          
          roc_results[[pred_var]] <- list(
            roc_object = roc_obj,
            auc = as.numeric(roc_obj$auc),
            coords = pROC::coords(roc_obj, "all", ret = c("threshold", "sensitivity", "specificity"))
          )
        }, error = function(e) NULL)
      }
      
      return(roc_results)
    }
  })
  
  # ROC 곡선 비교 플롯
  comparison_roc_plot <- reactive({
    req(multiple_roc_analysis())
    
    roc_data <- multiple_roc_analysis()
    
    if(length(roc_data) >= 2) {
      # 여러 ROC 곡선을 하나의 플롯에 표시
      plot_data <- data.frame()
      
      for(var_name in names(roc_data)) {
        coords <- roc_data[[var_name]]$coords
        var_data <- data.frame(
          sensitivity = coords$sensitivity,
          specificity = coords$specificity,
          fpr = 1 - coords$specificity,
          model = var_name,
          auc = round(roc_data[[var_name]]$auc, 3)
        )
        
        plot_data <- rbind(plot_data, var_data)
      }
      
      # ROC 곡선 비교 플롯
      p <- ggplot(plot_data, aes(x = fpr, y = sensitivity, color = model)) +
        geom_line(size = 1.2) +
        geom_abline(intercept = 0, slope = 1, linetype = "dashed", 
                   color = "gray", alpha = 0.7) +
        scale_x_continuous(name = "1 - Specificity (False Positive Rate)",
                          limits = c(0, 1)) +
        scale_y_continuous(name = "Sensitivity (True Positive Rate)",
                          limits = c(0, 1)) +
        scale_color_brewer(type = "qual", palette = "Set2") +
        labs(title = "ROC Curve Comparison",
             color = "Model (AUC)") +
        theme_minimal() +
        theme(legend.position = "bottom")
      
      # 범례에 AUC 값 추가
      legend_labels <- paste0(names(roc_data), " (AUC: ", 
                             sapply(roc_data, function(x) round(x$auc, 3)), ")")
      names(legend_labels) <- names(roc_data)
      
      p <- p + scale_color_discrete(name = "Model", labels = legend_labels)
      
      return(p)
    }
  })
  
  # 최적 절단점 분석
  optimal_cutoffs <- reactive({
    req(multiple_roc_analysis())
    
    roc_data <- multiple_roc_analysis()
    cutoff_results <- data.frame()
    
    for(var_name in names(roc_data)) {
      roc_obj <- roc_data[[var_name]]$roc_object
      
      # Youden Index를 이용한 최적 절단점
      best_coords <- pROC::coords(roc_obj, "best", best.method = "youden", 
                                 ret = c("threshold", "sensitivity", "specificity", 
                                        "ppv", "npv", "accuracy"))
      
      cutoff_results <- rbind(cutoff_results, data.frame(
        Model = var_name,
        AUC = round(as.numeric(roc_obj$auc), 4),
        Optimal_Cutoff = round(best_coords$threshold, 4),
        Sensitivity = round(best_coords$sensitivity, 4),
        Specificity = round(best_coords$specificity, 4),
        PPV = round(best_coords$ppv, 4),
        NPV = round(best_coords$npv, 4),
        Accuracy = round(best_coords$accuracy, 4),
        Youden_Index = round(best_coords$sensitivity + best_coords$specificity - 1, 4)
      ))
    }
    
    return(cutoff_results)
  })
  
  # 통계적 비교 분석
  statistical_comparison <- reactive({
    req(multiple_roc_analysis())
    
    roc_data <- multiple_roc_analysis()
    model_names <- names(roc_data)
    
    if(length(model_names) >= 2) {
      comparison_results <- data.frame()
      
      # 모든 모델 쌍에 대한 비교
      for(i in 1:(length(model_names)-1)) {
        for(j in (i+1):length(model_names)) {
          model1 <- model_names[i]
          model2 <- model_names[j]
          
          roc1 <- roc_data[[model1]]$roc_object
          roc2 <- roc_data[[model2]]$roc_object
          
          # DeLong's test for comparing AUCs
          tryCatch({
            comparison <- pROC::roc.test(roc1, roc2, method = "delong")
            
            comparison_results <- rbind(comparison_results, data.frame(
              Model1 = model1,
              Model2 = model2,
              AUC1 = round(as.numeric(roc1$auc), 4),
              AUC2 = round(as.numeric(roc2$auc), 4),
              AUC_Difference = round(as.numeric(roc1$auc) - as.numeric(roc2$auc), 4),
              P_value = round(comparison$p.value, 4),
              Significant = ifelse(comparison$p.value < 0.05, "Yes", "No")
            ))
          }, error = function(e) NULL)
        }
      }
      
      return(comparison_results)
    }
  })
  
  # 비교 플롯 출력
  output$comparison_roc_plot <- renderPlot({
    req(comparison_roc_plot())
    comparison_roc_plot()
  })
  
  # 최적 절단점 테이블
  output$optimal_cutoffs <- DT::renderDT({
    req(optimal_cutoffs())
    optimal_cutoffs()
  }, options = list(scrollX = TRUE))
  
  # 통계적 비교 테이블
  output$statistical_comparison <- DT::renderDT({
    req(statistical_comparison())
    statistical_comparison()
  })
}
```

## ROC Analysis Features

### 지원하는 분석 유형

#### 기본 ROC 분석
```r
# 단일 모델 ROC 분석
single_roc_analysis <- function(outcome, predictor) {
  roc_obj <- pROC::roc(outcome, predictor, quiet = TRUE)
  
  return(list(
    auc = as.numeric(roc_obj$auc),
    ci_auc = pROC::ci.auc(roc_obj),
    roc_curve = roc_obj
  ))
}
```

#### 다중 모델 비교
```r
# 여러 모델의 ROC 곡선 비교
multi_model_roc <- function(outcome, predictors) {
  roc_list <- list()
  
  for(i in 1:length(predictors)) {
    predictor_name <- names(predictors)[i]
    roc_obj <- pROC::roc(outcome, predictors[[i]], quiet = TRUE)
    
    roc_list[[predictor_name]] <- list(
      roc_object = roc_obj,
      auc = as.numeric(roc_obj$auc),
      ci_auc = pROC::ci.auc(roc_obj)
    )
  }
  
  return(roc_list)
}
```

#### 층화 ROC 분석
```r
# 하위집단별 ROC 분석
stratified_roc <- function(outcome, predictor, strata) {
  unique_strata <- unique(strata)
  stratified_results <- list()
  
  for(stratum in unique_strata) {
    subset_idx <- which(strata == stratum)
    
    if(length(subset_idx) > 10) {  # 최소 표본 크기 확인
      roc_obj <- pROC::roc(outcome[subset_idx], predictor[subset_idx], 
                          quiet = TRUE)
      
      stratified_results[[as.character(stratum)]] <- list(
        roc_object = roc_obj,
        auc = as.numeric(roc_obj$auc),
        n = length(subset_idx)
      )
    }
  }
  
  return(stratified_results)
}
```

### 절단점 최적화

#### Youden Index
```r
# Youden Index를 이용한 최적 절단점
youden_cutoff <- function(roc_obj) {
  coords <- pROC::coords(roc_obj, "all", ret = c("threshold", "sensitivity", "specificity"))
  
  youden_index <- coords$sensitivity + coords$specificity - 1
  optimal_idx <- which.max(youden_index)
  
  return(list(
    cutoff = coords$threshold[optimal_idx],
    sensitivity = coords$sensitivity[optimal_idx],
    specificity = coords$specificity[optimal_idx],
    youden_index = youden_index[optimal_idx]
  ))
}
```

#### 비용 기반 최적화
```r
# 비용을 고려한 절단점 최적화
cost_based_cutoff <- function(roc_obj, cost_fp = 1, cost_fn = 1, prevalence = 0.5) {
  coords <- pROC::coords(roc_obj, "all", ret = c("threshold", "sensitivity", "specificity"))
  
  # 총 비용 계산
  total_cost <- prevalence * (1 - coords$sensitivity) * cost_fn + 
                (1 - prevalence) * (1 - coords$specificity) * cost_fp
  
  optimal_idx <- which.min(total_cost)
  
  return(list(
    cutoff = coords$threshold[optimal_idx],
    sensitivity = coords$sensitivity[optimal_idx],
    specificity = coords$specificity[optimal_idx],
    total_cost = total_cost[optimal_idx]
  ))
}
```

### 성능 지표 계산

#### 기본 성능 지표
```r
# ROC 곡선에서 성능 지표 계산
performance_metrics <- function(roc_obj, cutoff) {
  coords <- pROC::coords(roc_obj, cutoff, ret = c("threshold", "sensitivity", 
                                                 "specificity", "ppv", "npv", 
                                                 "accuracy", "precision", "recall"))
  
  return(list(
    cutoff = coords$threshold,
    sensitivity = coords$sensitivity,
    specificity = coords$specificity,
    ppv = coords$ppv,
    npv = coords$npv,
    accuracy = coords$accuracy,
    precision = coords$precision,
    recall = coords$recall,
    f1_score = 2 * coords$precision * coords$recall / (coords$precision + coords$recall)
  ))
}
```

#### Net Reclassification Improvement (NRI)
```r
# NRI 계산
calculate_nri <- function(outcome, old_model, new_model, cutoffs = c(0.1, 0.2)) {
  # 범주별 분류
  old_cat <- cut(old_model, breaks = c(-Inf, cutoffs, Inf), 
                labels = c("Low", "Medium", "High"))
  new_cat <- cut(new_model, breaks = c(-Inf, cutoffs, Inf), 
                labels = c("Low", "Medium", "High"))
  
  # 재분류 테이블
  reclassification_table <- table(old_cat, new_cat, outcome)
  
  # NRI 계산
  events <- which(outcome == 1)
  non_events <- which(outcome == 0)
  
  # 이벤트에서 향상된 재분류 비율
  events_up <- sum((new_model[events] > old_model[events]))
  events_down <- sum((new_model[events] < old_model[events]))
  nri_events <- (events_up - events_down) / length(events)
  
  # 비이벤트에서 향상된 재분류 비율
  non_events_up <- sum((new_model[non_events] > old_model[non_events]))
  non_events_down <- sum((new_model[non_events] < old_model[non_events]))
  nri_non_events <- (non_events_down - non_events_up) / length(non_events)
  
  total_nri <- nri_events + nri_non_events
  
  return(list(
    nri_events = nri_events,
    nri_non_events = nri_non_events,
    total_nri = total_nri,
    reclassification_table = reclassification_table
  ))
}
```

## Advanced Features

### 부트스트랩 신뢰구간

```r
# 부트스트랩을 이용한 AUC 신뢰구간
bootstrap_auc <- function(outcome, predictor, n_bootstrap = 1000) {
  n <- length(outcome)
  bootstrap_aucs <- numeric(n_bootstrap)
  
  for(i in 1:n_bootstrap) {
    boot_indices <- sample(n, n, replace = TRUE)
    boot_outcome <- outcome[boot_indices]
    boot_predictor <- predictor[boot_indices]
    
    tryCatch({
      boot_roc <- pROC::roc(boot_outcome, boot_predictor, quiet = TRUE)
      bootstrap_aucs[i] <- as.numeric(boot_roc$auc)
    }, error = function(e) {
      bootstrap_aucs[i] <- NA
    })
  }
  
  # 신뢰구간 계산
  ci_lower <- quantile(bootstrap_aucs, 0.025, na.rm = TRUE)
  ci_upper <- quantile(bootstrap_aucs, 0.975, na.rm = TRUE)
  
  return(list(
    mean_auc = mean(bootstrap_aucs, na.rm = TRUE),
    ci_lower = ci_lower,
    ci_upper = ci_upper,
    bootstrap_aucs = bootstrap_aucs
  ))
}
```

### 교차 검증

```r
# k-fold 교차 검증을 이용한 ROC 분석
cross_validation_roc <- function(data, outcome_var, predictor_var, k = 5) {
  n <- nrow(data)
  fold_size <- floor(n / k)
  
  cv_aucs <- numeric(k)
  
  for(i in 1:k) {
    # 테스트 세트 인덱스
    test_start <- (i - 1) * fold_size + 1
    test_end <- ifelse(i == k, n, i * fold_size)
    test_indices <- test_start:test_end
    
    # 훈련 및 테스트 세트
    train_data <- data[-test_indices, ]
    test_data <- data[test_indices, ]
    
    # 모델 훈련 (여기서는 단순히 예측자를 사용)
    train_outcome <- train_data[[outcome_var]]
    train_predictor <- train_data[[predictor_var]]
    
    # 테스트 세트에서 예측
    test_outcome <- test_data[[outcome_var]]
    test_predictor <- test_data[[predictor_var]]
    
    # ROC 분석
    tryCatch({
      test_roc <- pROC::roc(test_outcome, test_predictor, quiet = TRUE)
      cv_aucs[i] <- as.numeric(test_roc$auc)
    }, error = function(e) {
      cv_aucs[i] <- NA
    })
  }
  
  return(list(
    mean_cv_auc = mean(cv_aucs, na.rm = TRUE),
    sd_cv_auc = sd(cv_aucs, na.rm = TRUE),
    cv_aucs = cv_aucs
  ))
}
```

## Export and Download Features

### ROC 곡선 다운로드

```r
# 고품질 ROC 곡선 내보내기
publication_roc_plot <- reactive({
  req(roc_result())
  
  # 출판 품질 테마 적용
  roc_result()$plot +
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

### 분석 결과 보고서

```r
# ROC 분석 보고서 생성
roc_analysis_report <- reactive({
  req(multiple_roc_analysis(), optimal_cutoffs())
  
  roc_data <- multiple_roc_analysis()
  cutoff_data <- optimal_cutoffs()
  
  report_text <- paste0(
    "ROC Analysis Report\n",
    "==================\n\n",
    "Number of models analyzed: ", length(roc_data), "\n",
    "Sample size: ", length(roc_data[[1]]$roc_object$response), "\n\n"
  )
  
  for(i in 1:nrow(cutoff_data)) {
    model_name <- cutoff_data$Model[i]
    report_text <- paste0(report_text,
      "Model: ", model_name, "\n",
      "AUC: ", cutoff_data$AUC[i], "\n",
      "Optimal cutoff: ", cutoff_data$Optimal_Cutoff[i], "\n",
      "Sensitivity: ", cutoff_data$Sensitivity[i], "\n",
      "Specificity: ", cutoff_data$Specificity[i], "\n",
      "Accuracy: ", cutoff_data$Accuracy[i], "\n\n"
    )
  }
  
  return(report_text)
})

# 보고서 다운로드
output$download_report <- downloadHandler(
  filename = function() {
    paste("roc_analysis_report_", Sys.Date(), ".txt", sep = "")
  },
  content = function(file) {
    writeLines(roc_analysis_report(), file)
  }
)
```

## Performance Optimization

### 대용량 데이터 처리

```r
# 효율적인 ROC 분석
efficient_roc_analysis <- reactive({
  req(data_input()$data)
  
  df <- data_input()$data
  
  # 데이터가 너무 큰 경우 층화 샘플링
  if(nrow(df) > 10000) {
    # 클래스별로 균형 잡힌 샘플링
    outcome_var <- input$outcome_variable
    
    positive_indices <- which(df[[outcome_var]] == 1)
    negative_indices <- which(df[[outcome_var]] == 0)
    
    n_positive_sample <- min(2500, length(positive_indices))
    n_negative_sample <- min(2500, length(negative_indices))
    
    sampled_indices <- c(
      sample(positive_indices, n_positive_sample),
      sample(negative_indices, n_negative_sample)
    )
    
    df_sample <- df[sampled_indices, ]
    showNotification("Large dataset: Using stratified sample of 5,000 observations", 
                    type = "info")
  } else {
    df_sample <- df
  }
  
  return(df_sample)
})
```

## Dependencies

### 필수 패키지

- `shiny` - 기본 Shiny 기능
- `pROC` - ROC 곡선 분석
- `DT` - 결과 테이블 표시

### 선택적 패키지

- `plotROC` - 대안적 ROC 시각화
- `ROCR` - 추가 성능 지표
- `survivalROC` - 시간-의존적 ROC

## Troubleshooting

### 일반적인 오류

```r
# 1. 결과 변수가 이진이 아닌 경우
# 해결: 이진 변수 확인 및 변환

# 2. 예측 변수에 결측치가 많은 경우
# 해결: 결측치 처리 또는 완전 관측치만 사용

# 3. 모든 예측값이 동일한 경우
# 해결: 변수 분산 확인 및 다른 변수 선택

# 4. 표본 크기가 너무 작은 경우
# 해결: 최소 표본 크기 경고 및 신뢰구간 해석 주의
```

## See Also

- `pROC::roc()` - ROC 곡선 생성
- `pROC::coords()` - 절단점별 좌표
- `pROC::roc.test()` - ROC 곡선 비교
- `timeroc.R` - 시간-의존적 ROC 분석