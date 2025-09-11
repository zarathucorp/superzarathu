# forestglm Documentation

## Overview

`forestglm.R`은 jsmodule 패키지의 일반화선형모델(GLM) 결과를 시각화하는 Forest Plot 모듈로, Shiny 애플리케이션에서 다양한 통계적 분포(가우시안, 이항, 포아송 등)를 따르는 결과변수에 대한 하위집단 분석 결과를 forest plot으로 표현하는 기능을 제공합니다. 이 모듈은 오즈비(Odds Ratio), 위험비(Risk Ratio), 회귀계수 등을 시각적으로 비교할 수 있게 하며, 설문조사 가중치와 반복측정 데이터도 지원합니다.

## Module Components

### `forestglmUI(id, label = "forestplot")`

GLM Forest plot 생성을 위한 Shiny 모듈 UI를 생성합니다.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `id` | character | - | 모듈의 고유 식별자 |
| `label` | character | "forestplot" | Forest plot 모듈 레이블 |

#### Returns

Shiny UI 객체 (forest plot 설정을 위한 다양한 입력 컨트롤들)

#### UI Components

- 그룹 선택 드롭다운
- 종속변수 선택
- 하위집단 및 공변량 선택
- Forest plot 커스터마이징 체크박스:
  - 커스텀 X축 눈금
  - 전체 모양 토글
  - 테두리 모양 변경

### `forestglmServer(id, data, data_label, family, data_varStruct = NULL, nfactor.limit = 10, design.survey = NULL, repeated_id = NULL)`

GLM Forest plot 생성을 위한 서버 사이드 로직을 제공합니다.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `id` | character | - | 모듈의 고유 식별자 |
| `data` | reactive | - | 반응형 데이터 소스 |
| `data_label` | reactive | - | 반응형 데이터 레이블 |
| `family` | character | - | 통계적 분포 ("gaussian", "binomial", "poisson") |
| `data_varStruct` | list | NULL | 변수 구조 정보 |
| `nfactor.limit` | integer | 10 | 범주형 변수 레벨 최대 개수 |
| `design.survey` | reactive | NULL | 반응형 설문조사 설계 |
| `repeated_id` | character | NULL | 반복측정 식별자 |

#### Returns

다음을 포함하는 반응형 리스트:
1. 하위집단 분석 데이터 테이블
2. Forest plot 그림

#### Key Functionality

- 하위집단 분석 테이블 생성
- 커스터마이징 가능한 forest plot 생성
- 다양한 통계적 분포 지원
- 설문조사 설계 및 반복측정 처리

## Usage Examples

### 기본 사용법

```r
library(shiny)
library(jsmodule)
library(DT)

# UI 정의
ui <- fluidPage(
  titlePanel("GLM Forest Plot Analysis"),
  sidebarLayout(
    sidebarPanel(
      forestglmUI("forest_analysis", label = "GLM Forest Plot"),
      hr(),
      radioButtons("family_choice", "Statistical Family:",
                  choices = list(
                    "Linear Regression" = "gaussian",
                    "Logistic Regression" = "binomial", 
                    "Poisson Regression" = "poisson"
                  ),
                  selected = "binomial"),
      hr(),
      downloadButton("download_plot", "Forest Plot 다운로드")
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Forest Plot", 
                 plotOutput("forest_plot", height = "800px")),
        tabPanel("Subgroup Table", 
                 DT::DTOutput("subgroup_table")),
        tabPanel("Model Summary", 
                 verbatimTextOutput("model_summary")),
        tabPanel("Effect Sizes", 
                 DT::DTOutput("effect_sizes"))
      )
    )
  )
)

server <- function(input, output, session) {
  # 예시 데이터
  data_input <- reactive({
    # 다양한 분포에 적합한 데이터 생성
    set.seed(123)
    n <- 500
    
    data.frame(
      # 예측 변수들
      age = rnorm(n, 50, 15),
      age_group = factor(ifelse(rnorm(n, 50, 15) > 50, "Older", "Younger")),
      sex = factor(sample(c("Male", "Female"), n, replace = TRUE)),
      treatment = factor(sample(c("Control", "Treatment"), n, replace = TRUE)),
      smoking = factor(sample(c("Never", "Former", "Current"), n, replace = TRUE, prob = c(0.5, 0.3, 0.2))),
      
      # 연속형 결과변수 (gaussian)
      continuous_outcome = rnorm(n, 10 + 0.1 * rnorm(n, 50, 15) + 
                                ifelse(sample(c("Male", "Female"), n, replace = TRUE) == "Male", 2, 0), 3),
      
      # 이항 결과변수 (binomial)
      binary_outcome = rbinom(n, 1, 
                             plogis(-1 + 0.5 * scale(rnorm(n, 50, 15))[,1] + 
                                   ifelse(sample(c("Treatment", "Control"), n, replace = TRUE) == "Treatment", 1, 0))),
      
      # 카운트 결과변수 (poisson)
      count_outcome = rpois(n, exp(1 + 0.3 * scale(rnorm(n, 50, 15))[,1] + 
                                  ifelse(sample(c("Treatment", "Control"), n, replace = TRUE) == "Treatment", 0.5, 0)))
    )
  })
  
  data_label <- reactive({
    data.frame(
      variable = names(data_input()),
      label = c("Age", "Age Group", "Sex", "Treatment", "Smoking Status",
               "Continuous Outcome", "Binary Outcome", "Count Outcome"),
      stringsAsFactors = FALSE
    )
  })
  
  # GLM Forest plot 모듈 서버
  forest_result <- callModule(forestglmServer, "forest_analysis",
                             data = data_input,
                             data_label = data_label,
                             family = reactive(input$family_choice),
                             nfactor.limit = 20)
  
  # Forest plot 출력
  output$forest_plot <- renderPlot({
    req(forest_result())
    if(!is.null(forest_result()$plot)) {
      forest_result()$plot
    }
  })
  
  # 하위집단 분석 테이블 출력
  output$subgroup_table <- DT::renderDT({
    req(forest_result())
    if(!is.null(forest_result()$table)) {
      DT::datatable(forest_result()$table,
                    options = list(scrollX = TRUE, pageLength = 15),
                    rownames = FALSE) %>%
        DT::formatRound(columns = c("Estimate", "Lower", "Upper"), digits = 3) %>%
        DT::formatRound(columns = "P value", digits = 4)
    }
  })
  
  # 모델 요약
  output$model_summary <- renderPrint({
    req(data_input(), input$family_choice)
    
    df <- data_input()
    
    cat("GLM Model Summary\n")
    cat("=================\n\n")
    cat("Family:", input$family_choice, "\n")
    cat("Sample size:", nrow(df), "\n\n")
    
    # 분포에 따른 적절한 결과변수 선택
    outcome_var <- switch(input$family_choice,
      "gaussian" = "continuous_outcome",
      "binomial" = "binary_outcome", 
      "poisson" = "count_outcome"
    )
    
    if(outcome_var %in% names(df)) {
      # 전체 모델 적합
      formula_str <- paste(outcome_var, "~ treatment + sex + age_group")
      
      tryCatch({
        overall_model <- glm(as.formula(formula_str), 
                           data = df, 
                           family = input$family_choice)
        
        print(summary(overall_model))
        
        cat("\nModel Diagnostics:\n")
        cat("AIC:", round(AIC(overall_model), 2), "\n")
        cat("Deviance:", round(overall_model$deviance, 2), "\n")
        cat("Null deviance:", round(overall_model$null.deviance, 2), "\n")
        
        # 분산설명력
        if(input$family_choice == "gaussian") {
          rsq <- 1 - (overall_model$deviance / overall_model$null.deviance)
          cat("R-squared:", round(rsq, 4), "\n")
        }
        
        # 의사 R-squared (for non-gaussian)
        if(input$family_choice != "gaussian") {
          pseudo_rsq <- 1 - (overall_model$deviance / overall_model$null.deviance)
          cat("Pseudo R-squared:", round(pseudo_rsq, 4), "\n")
        }
        
      }, error = function(e) {
        cat("Error fitting model:", e$message, "\n")
      })
    }
  })
  
  # 효과 크기 분석
  output$effect_sizes <- DT::renderDT({
    req(data_input(), input$family_choice)
    
    df <- data_input()
    
    outcome_var <- switch(input$family_choice,
      "gaussian" = "continuous_outcome",
      "binomial" = "binary_outcome", 
      "poisson" = "count_outcome"
    )
    
    if(outcome_var %in% names(df)) {
      # 단변량 분석
      predictors <- c("treatment", "sex", "age_group", "smoking")
      effect_results <- data.frame()
      
      for(predictor in predictors) {
        if(predictor %in% names(df)) {
          tryCatch({
            formula_str <- paste(outcome_var, "~", predictor)
            model <- glm(as.formula(formula_str), 
                        data = df, 
                        family = input$family_choice)
            
            summary_model <- summary(model)
            
            # 첫 번째 계수 (참조그룹 제외)
            if(nrow(summary_model$coefficients) >= 2) {
              coef_row <- 2  # 첫 번째 예측변수 계수
              
              estimate <- summary_model$coefficients[coef_row, "Estimate"]
              se <- summary_model$coefficients[coef_row, "Std. Error"]
              p_value <- summary_model$coefficients[coef_row, "Pr(>|t|)"]
              
              # 효과크기 변환
              if(input$family_choice == "binomial") {
                # 오즈비
                effect_measure <- "Odds Ratio"
                transformed_estimate <- exp(estimate)
                lower_ci <- exp(estimate - 1.96 * se)
                upper_ci <- exp(estimate + 1.96 * se)
              } else if(input$family_choice == "poisson") {
                # 발생률비
                effect_measure <- "Rate Ratio"
                transformed_estimate <- exp(estimate)
                lower_ci <- exp(estimate - 1.96 * se)
                upper_ci <- exp(estimate + 1.96 * se)
              } else {
                # 회귀계수
                effect_measure <- "Coefficient"
                transformed_estimate <- estimate
                lower_ci <- estimate - 1.96 * se
                upper_ci <- estimate + 1.96 * se
              }
              
              effect_results <- rbind(effect_results, data.frame(
                Predictor = predictor,
                Effect_Measure = effect_measure,
                Estimate = round(transformed_estimate, 3),
                Lower_CI = round(lower_ci, 3),
                Upper_CI = round(upper_ci, 3),
                P_value = round(p_value, 4),
                AIC = round(AIC(model), 1)
              ))
            }
          }, error = function(e) NULL)
        }
      }
      
      effect_results
    }
  })
}

shinyApp(ui = ui, server = server)
```

### 고급 사용법

```r
# 복잡한 GLM 하위집단 분석 워크플로
server <- function(input, output, session) {
  # 데이터 입력 모듈 연동
  data_input <- callModule(csvFile, "datafile")
  
  # GLM Forest plot 분석
  forest_analysis <- callModule(forestglmServer, "forest_viz",
                               data = reactive(data_input()$data),
                               data_label = reactive(data_input()$label),
                               family = reactive(input$selected_family))
  
  # 다중 분포별 모델 비교
  multi_family_analysis <- reactive({
    req(data_input()$data)
    
    df <- data_input()$data
    
    # 연속형, 이항, 카운트 결과변수 식별
    continuous_vars <- df %>% select_if(is.numeric) %>% names()
    binary_vars <- df %>% 
      select_if(function(x) is.numeric(x) && all(x %in% c(0,1,NA))) %>% 
      names()
    
    families_to_test <- c("gaussian", "binomial", "poisson")
    comparison_results <- list()
    
    for(family in families_to_test) {
      # 적절한 결과변수 선택
      if(family == "gaussian" && length(continuous_vars) > 0) {
        outcome_var <- continuous_vars[1]
      } else if(family == "binomial" && length(binary_vars) > 0) {
        outcome_var <- binary_vars[1]
      } else if(family == "poisson") {
        # 카운트 변수가 있는지 확인 (음이 아닌 정수)
        count_candidates <- df %>%
          select_if(function(x) is.numeric(x) && all(x >= 0, na.rm = TRUE) && all(x == round(x), na.rm = TRUE)) %>%
          names()
        
        if(length(count_candidates) > 0) {
          outcome_var <- count_candidates[1]
        } else {
          next
        }
      } else {
        next
      }
      
      # 예측변수들
      predictors <- df %>% 
        select_if(is.factor) %>% 
        select(-all_of(outcome_var)) %>% 
        names()
      
      if(length(predictors) >= 1) {
        family_results <- data.frame()
        
        for(predictor in predictors[1:min(3, length(predictors))]) {
          tryCatch({
            formula_str <- paste(outcome_var, "~", predictor)
            model <- glm(as.formula(formula_str), data = df, family = family)
            
            summary_model <- summary(model)
            
            if(nrow(summary_model$coefficients) >= 2) {
              coef_idx <- 2
              
              estimate <- summary_model$coefficients[coef_idx, "Estimate"]
              se <- summary_model$coefficients[coef_idx, "Std. Error"]
              p_value <- summary_model$coefficients[coef_idx, "Pr(>|t|)"]
              
              # 효과 크기 변환
              if(family == "binomial" || family == "poisson") {
                effect_size <- exp(estimate)
                effect_name <- ifelse(family == "binomial", "OR", "RR")
              } else {
                effect_size <- estimate
                effect_name <- "Coef"
              }
              
              family_results <- rbind(family_results, data.frame(
                Family = family,
                Outcome = outcome_var,
                Predictor = predictor,
                Effect_Type = effect_name,
                Effect_Size = round(effect_size, 3),
                P_value = round(p_value, 4),
                AIC = round(AIC(model), 1)
              ))
            }
          }, error = function(e) NULL)
        }
        
        if(nrow(family_results) > 0) {
          comparison_results[[family]] <- family_results
        }
      }
    }
    
    if(length(comparison_results) > 0) {
      return(do.call(rbind, comparison_results))
    }
  })
  
  # 상호작용 분석
  interaction_analysis <- reactive({
    req(data_input()$data, input$selected_family)
    
    df <- data_input()$data
    family_choice <- input$selected_family
    
    # 적절한 결과변수 선택
    outcome_var <- switch(family_choice,
      "gaussian" = names(df %>% select_if(is.numeric))[1],
      "binomial" = names(df %>% select_if(function(x) is.numeric(x) && all(x %in% c(0,1,NA))))[1],
      "poisson" = names(df %>% select_if(function(x) is.numeric(x) && all(x >= 0, na.rm = TRUE) && all(x == round(x), na.rm = TRUE)))[1]
    )
    
    if(!is.null(outcome_var) && outcome_var %in% names(df)) {
      factor_vars <- df %>% select_if(is.factor) %>% names()
      
      if(length(factor_vars) >= 2) {
        interaction_results <- data.frame()
        
        # 모든 2차 상호작용 테스트
        for(i in 1:(length(factor_vars)-1)) {
          for(j in (i+1):length(factor_vars)) {
            var1 <- factor_vars[i]
            var2 <- factor_vars[j]
            
            tryCatch({
              # 상호작용 모델
              formula_main <- paste(outcome_var, "~", var1, "+", var2)
              formula_interaction <- paste(outcome_var, "~", var1, "*", var2)
              
              model_main <- glm(as.formula(formula_main), data = df, family = family_choice)
              model_interaction <- glm(as.formula(formula_interaction), data = df, family = family_choice)
              
              # 상호작용 검정
              anova_result <- anova(model_main, model_interaction, test = "Chisq")
              interaction_p <- anova_result$`Pr(>Chi)`[2]
              
              interaction_results <- rbind(interaction_results, data.frame(
                Variable1 = var1,
                Variable2 = var2,
                Outcome = outcome_var,
                Family = family_choice,
                Interaction_P = round(interaction_p, 4),
                Main_AIC = round(AIC(model_main), 1),
                Interaction_AIC = round(AIC(model_interaction), 1),
                Significant = ifelse(interaction_p < 0.05, "Yes", "No")
              ))
            }, error = function(e) NULL)
          }
        }
        
        return(interaction_results)
      }
    }
  })
  
  # 모델 진단 플롯
  model_diagnostics <- reactive({
    req(data_input()$data, input$selected_family)
    
    df <- data_input()$data
    family_choice <- input$selected_family
    
    # 적절한 결과변수와 예측변수 선택
    outcome_var <- switch(family_choice,
      "gaussian" = names(df %>% select_if(is.numeric))[1],
      "binomial" = names(df %>% select_if(function(x) is.numeric(x) && all(x %in% c(0,1,NA))))[1],
      "poisson" = names(df %>% select_if(function(x) is.numeric(x) && all(x >= 0, na.rm = TRUE) && all(x == round(x), na.rm = TRUE)))[1]
    )
    
    predictors <- df %>% select_if(is.factor) %>% names()
    
    if(!is.null(outcome_var) && length(predictors) >= 1) {
      formula_str <- paste(outcome_var, "~", paste(predictors[1:min(3, length(predictors))], collapse = " + "))
      
      tryCatch({
        model <- glm(as.formula(formula_str), data = df, family = family_choice)
        
        # 잔차 계산
        residuals_pearson <- residuals(model, type = "pearson")
        residuals_deviance <- residuals(model, type = "deviance")
        fitted_values <- fitted(model)
        
        return(list(
          model = model,
          fitted = fitted_values,
          residuals_pearson = residuals_pearson,
          residuals_deviance = residuals_deviance
        ))
      }, error = function(e) {
        return(list(error = e$message))
      })
    }
  })
  
  # 다중 분포 비교 결과
  output$multi_family_comparison <- DT::renderDT({
    req(multi_family_analysis())
    multi_family_analysis()
  })
  
  # 상호작용 분석 결과
  output$interaction_results <- DT::renderDT({
    req(interaction_analysis())
    interaction_analysis()
  })
  
  # 모델 진단 플롯
  output$diagnostic_plots <- renderPlot({
    req(model_diagnostics())
    
    diagnostics <- model_diagnostics()
    
    if(!is.null(diagnostics$error)) {
      plot.new()
      text(0.5, 0.5, paste("Model fitting error:", diagnostics$error), cex = 1.2)
    } else {
      # 2x2 진단 플롯
      par(mfrow = c(2, 2))
      
      # 잔차 vs 적합값
      plot(diagnostics$fitted, diagnostics$residuals_pearson,
           xlab = "Fitted Values", ylab = "Pearson Residuals",
           main = "Residuals vs Fitted")
      abline(h = 0, col = "red", lty = 2)
      lines(lowess(diagnostics$fitted, diagnostics$residuals_pearson), col = "blue", lwd = 2)
      
      # Q-Q plot
      qqnorm(diagnostics$residuals_deviance, main = "Q-Q Plot of Deviance Residuals")
      qqline(diagnostics$residuals_deviance, col = "red")
      
      # Scale-Location plot
      sqrt_abs_resid <- sqrt(abs(diagnostics$residuals_deviance))
      plot(diagnostics$fitted, sqrt_abs_resid,
           xlab = "Fitted Values", ylab = "sqrt(|Deviance Residuals|)",
           main = "Scale-Location")
      lines(lowess(diagnostics$fitted, sqrt_abs_resid), col = "red", lwd = 2)
      
      # Cook's distance
      cooks_d <- cooks.distance(diagnostics$model)
      plot(cooks_d, type = "h",
           xlab = "Observation Index", ylab = "Cook's Distance",
           main = "Cook's Distance")
      abline(h = 4/length(cooks_d), col = "red", lty = 2)
      
      par(mfrow = c(1, 1))
    }
  }, height = 600)
}
```

## GLM Forest Plot Features

### 지원하는 통계적 분포

#### 가우시안 분포 (Linear Regression)
```r
# 연속형 결과변수에 대한 선형 회귀
gaussian_forest <- function(data, outcome, predictors) {
  results <- data.frame()
  
  for(predictor in predictors) {
    formula_str <- paste(outcome, "~", predictor)
    model <- glm(as.formula(formula_str), data = data, family = "gaussian")
    
    # 회귀계수와 신뢰구간
    summary_model <- summary(model)
    coef_estimate <- summary_model$coefficients[2, "Estimate"]
    se <- summary_model$coefficients[2, "Std. Error"]
    
    results <- rbind(results, data.frame(
      Predictor = predictor,
      Coefficient = coef_estimate,
      Lower_CI = coef_estimate - 1.96 * se,
      Upper_CI = coef_estimate + 1.96 * se,
      P_value = summary_model$coefficients[2, "Pr(>|t|)"]
    ))
  }
  
  return(results)
}
```

#### 이항 분포 (Logistic Regression)
```r
# 이항 결과변수에 대한 로지스틱 회귀
binomial_forest <- function(data, outcome, predictors) {
  results <- data.frame()
  
  for(predictor in predictors) {
    formula_str <- paste(outcome, "~", predictor)
    model <- glm(as.formula(formula_str), data = data, family = "binomial")
    
    # 오즈비와 신뢰구간
    summary_model <- summary(model)
    log_or <- summary_model$coefficients[2, "Estimate"]
    se <- summary_model$coefficients[2, "Std. Error"]
    
    results <- rbind(results, data.frame(
      Predictor = predictor,
      Odds_Ratio = exp(log_or),
      Lower_CI = exp(log_or - 1.96 * se),
      Upper_CI = exp(log_or + 1.96 * se),
      P_value = summary_model$coefficients[2, "Pr(>|z|)"]
    ))
  }
  
  return(results)
}
```

#### 포아송 분포 (Poisson Regression)
```r
# 카운트 결과변수에 대한 포아송 회귀
poisson_forest <- function(data, outcome, predictors) {
  results <- data.frame()
  
  for(predictor in predictors) {
    formula_str <- paste(outcome, "~", predictor)
    model <- glm(as.formula(formula_str), data = data, family = "poisson")
    
    # 발생률비와 신뢰구간
    summary_model <- summary(model)
    log_rr <- summary_model$coefficients[2, "Estimate"]
    se <- summary_model$coefficients[2, "Std. Error"]
    
    results <- rbind(results, data.frame(
      Predictor = predictor,
      Rate_Ratio = exp(log_rr),
      Lower_CI = exp(log_rr - 1.96 * se),
      Upper_CI = exp(log_rr + 1.96 * se),
      P_value = summary_model$coefficients[2, "Pr(>|z|)"]
    ))
  }
  
  return(results)
}
```

### 모델 선택 및 비교

#### AIC 기반 모델 선택
```r
# AIC를 이용한 최적 모델 선택
aic_model_selection <- function(data, outcome, candidates, family) {
  aic_results <- data.frame()
  
  # 단변량 모델들
  for(var in candidates) {
    formula_str <- paste(outcome, "~", var)
    model <- glm(as.formula(formula_str), data = data, family = family)
    
    aic_results <- rbind(aic_results, data.frame(
      Model = var,
      AIC = AIC(model),
      Variables = 1
    ))
  }
  
  # 다변량 모델들 (전진 선택)
  selected_vars <- character()
  remaining_vars <- candidates
  
  while(length(remaining_vars) > 0) {
    best_aic <- Inf
    best_var <- NULL
    
    for(var in remaining_vars) {
      test_vars <- c(selected_vars, var)
      formula_str <- paste(outcome, "~", paste(test_vars, collapse = " + "))
      
      tryCatch({
        model <- glm(as.formula(formula_str), data = data, family = family)
        current_aic <- AIC(model)
        
        if(current_aic < best_aic) {
          best_aic <- current_aic
          best_var <- var
        }
      }, error = function(e) NULL)
    }
    
    if(!is.null(best_var)) {
      # 개선이 있는지 확인
      if(length(selected_vars) == 0 || best_aic < min(aic_results$AIC[aic_results$Variables == length(selected_vars)])) {
        selected_vars <- c(selected_vars, best_var)
        remaining_vars <- setdiff(remaining_vars, best_var)
        
        aic_results <- rbind(aic_results, data.frame(
          Model = paste(selected_vars, collapse = " + "),
          AIC = best_aic,
          Variables = length(selected_vars)
        ))
      } else {
        break
      }
    } else {
      break
    }
  }
  
  return(aic_results[order(aic_results$AIC), ])
}
```

#### 교차검증을 통한 모델 평가
```r
# k-fold 교차검증
cross_validation_glm <- function(data, formula, family, k = 5) {
  n <- nrow(data)
  fold_size <- floor(n / k)
  cv_errors <- numeric(k)
  
  for(i in 1:k) {
    # 테스트 세트 인덱스
    test_start <- (i - 1) * fold_size + 1
    test_end <- ifelse(i == k, n, i * fold_size)
    test_indices <- test_start:test_end
    
    # 훈련 및 테스트 세트
    train_data <- data[-test_indices, ]
    test_data <- data[test_indices, ]
    
    # 모델 적합
    model <- glm(formula, data = train_data, family = family)
    
    # 예측
    predictions <- predict(model, newdata = test_data, type = "response")
    
    # 오차 계산 (분포에 따라 다름)
    if(family == "gaussian") {
      cv_errors[i] <- mean((test_data[[all.vars(formula)[1]]] - predictions)^2)
    } else if(family == "binomial") {
      # 로그 우도
      y_true <- test_data[[all.vars(formula)[1]]]
      cv_errors[i] <- -mean(y_true * log(predictions) + (1 - y_true) * log(1 - predictions))
    } else if(family == "poisson") {
      # 포아송 편차
      y_true <- test_data[[all.vars(formula)[1]]]
      cv_errors[i] <- mean(2 * (y_true * log(y_true/predictions) - (y_true - predictions)))
    }
  }
  
  return(list(
    mean_cv_error = mean(cv_errors),
    se_cv_error = sd(cv_errors) / sqrt(k),
    cv_errors = cv_errors
  ))
}
```

## Advanced Features

### 정규화 GLM (Elastic Net)

```r
# glmnet을 이용한 정규화 GLM
if(requireNamespace("glmnet", quietly = TRUE)) {
  regularized_glm_analysis <- function(data, outcome, predictors, family, alpha = 0.5) {
    # 데이터 준비
    x <- model.matrix(~ . - 1, data = data[, predictors])
    y <- data[[outcome]]
    
    # 교차검증으로 최적 lambda 선택
    cv_fit <- glmnet::cv.glmnet(x, y, family = family, alpha = alpha)
    
    # 최적 모델
    optimal_fit <- glmnet::glmnet(x, y, family = family, alpha = alpha, lambda = cv_fit$lambda.min)
    
    # 선택된 변수들
    selected_vars <- rownames(coef(optimal_fit))[coef(optimal_fit)[, 1] != 0][-1]  # intercept 제외
    
    return(list(
      model = optimal_fit,
      lambda = cv_fit$lambda.min,
      selected_variables = selected_vars,
      cv_error = min(cv_fit$cvm)
    ))
  }
}
```

### 베이지안 GLM

```r
# rstanarm을 이용한 베이지안 GLM (선택적)
if(requireNamespace("rstanarm", quietly = TRUE)) {
  bayesian_glm_analysis <- function(data, formula, family) {
    # 베이지안 GLM 적합
    bayes_model <- rstanarm::stan_glm(formula, data = data, family = family,
                                     prior = rstanarm::normal(0, 2.5),
                                     chains = 4, iter = 2000)
    
    # 사후분포 요약
    posterior_summary <- summary(bayes_model)
    
    # 신뢰구간 (credible intervals)
    credible_intervals <- rstanarm::posterior_interval(bayes_model, prob = 0.95)
    
    return(list(
      model = bayes_model,
      summary = posterior_summary,
      credible_intervals = credible_intervals
    ))
  }
}
```

## Export and Download Features

### 결과 보고서 생성

```r
# GLM Forest plot 분석 보고서
glm_analysis_report <- reactive({
  req(forest_result()$table, input$family_choice)
  
  results_table <- forest_result()$table
  family_name <- switch(input$family_choice,
    "gaussian" = "Linear Regression",
    "binomial" = "Logistic Regression", 
    "poisson" = "Poisson Regression"
  )
  
  report_text <- paste0(
    "GLM Forest Plot Analysis Report\n",
    "===============================\n\n",
    "Analysis Type: ", family_name, "\n",
    "Analysis Date: ", Sys.Date(), "\n",
    "Number of Subgroups: ", nrow(results_table), "\n\n",
    
    "Results Summary:\n"
  )
  
  # 유의한 결과 식별
  significant_results <- results_table[results_table$`P value` < 0.05, ]
  
  if(nrow(significant_results) > 0) {
    effect_name <- switch(input$family_choice,
      "gaussian" = "Coefficient",
      "binomial" = "Odds Ratio",
      "poisson" = "Rate Ratio"
    )
    
    report_text <- paste0(report_text,
      "Significant Results (p < 0.05):\n"
    )
    
    for(i in 1:nrow(significant_results)) {
      subgroup_name <- rownames(significant_results)[i]
      estimate <- significant_results[i, "Estimate"]
      lower_ci <- significant_results[i, "Lower"]
      upper_ci <- significant_results[i, "Upper"]
      p_val <- significant_results[i, "P value"]
      
      report_text <- paste0(report_text,
        sprintf("- %s: %s = %.3f (95%% CI: %.3f-%.3f), p = %.4f\n",
                subgroup_name, effect_name, estimate, lower_ci, upper_ci, p_val)
      )
    }
  }
  
  return(report_text)
})
```

## Dependencies

### 필수 패키지

- `shiny` - 기본 Shiny 기능
- `stats` - GLM 함수들
- `forestplot` - Forest plot 생성
- `ggplot2` - 그래픽 시각화

### 선택적 패키지

- `glmnet` - 정규화 GLM
- `rstanarm` - 베이지안 GLM
- `survey` - 가중 GLM
- `lme4` - 혼합효과 모델

## Troubleshooting

### 일반적인 오류

```r
# 1. 수렴하지 않는 모델
# 해결: 변수 스케일링, 시작값 조정, 정규화

# 2. 완전분리 문제 (로지스틱 회귀)
# 해결: 페널라이즈드 우도, 변수 제거

# 3. 과분산 (포아송 회귀)
# 해결: 음이항 회귀, 준포아송 회귀 사용

# 4. 너무 많은 하위집단
# 해결: 주요 하위집단 선택, 계층적 표시
```

## See Also

- `stats::glm()` - 일반화선형모델
- `forestplot::forestplot()` - Forest plot 생성
- `glmnet::cv.glmnet()` - 정규화 GLM
- `forestcox.R` - Cox 회귀 Forest plot