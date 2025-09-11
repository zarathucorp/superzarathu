# coxph Documentation

## Overview

`coxph.R`은 jsmodule 패키지의 Cox 비례위험모델 분석 모듈로, Shiny 애플리케이션에서 생존분석을 위한 Cox 회귀분석을 수행하는 기능을 제공합니다. 이 모듈은 시간-사건 데이터 분석, 경쟁위험 분석, 단계적 변수 선택, 그리고 가중 생존분석 등의 고급 기능을 포함하며, 다양한 생존분석 시나리오에 대응할 수 있는 종합적인 도구입니다.

## Module Components

### `coxUI(id)`

Cox 비례위험모델 분석을 위한 Shiny 모듈 UI를 생성합니다.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `id` | character | - | 모듈의 네임스페이스 식별자 |

#### Returns

Shiny UI 객체 (Cox 회귀분석 설정을 위한 다양한 입력 컨트롤들)

#### UI Components

- 이벤트 및 시간 변수 선택
- 시간 범위 옵션
- 경쟁위험 분석 체크박스
- 독립변수 선택
- 하위집단 분석 옵션
- 단계적 변수 선택

### `coxModule(input, output, session, data, data_label, data_varStruct = NULL, nfactor.limit = 10, design.survey = NULL)`

Cox 비례위험모델 분석을 위한 서버 사이드 로직을 제공합니다.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `input` | - | - | Shiny 입력 객체 |
| `output` | - | - | Shiny 출력 객체 |
| `session` | - | - | Shiny 세션 객체 |
| `data` | reactive | - | 반응형 데이터프레임 |
| `data_label` | reactive | - | 반응형 데이터 레이블 |
| `data_varStruct` | list | NULL | 변수 구조 정보 |
| `nfactor.limit` | integer | 10 | 범주형 변수 레벨 최대 개수 |
| `design.survey` | survey.design | NULL | 설문조사 설계 객체 |

#### Returns

다음을 포함하는 반응형 객체:
- 변수 선택 처리
- Cox 회귀분석 수행
- 시간 범위 필터링
- 경쟁위험 분석
- 하위집단 분석
- 단계적 변수 선택
- 가중 생존분석

## Usage Examples

### 기본 사용법

```r
library(shiny)
library(jsmodule)
library(survival)
library(DT)

# UI 정의
ui <- fluidPage(
  titlePanel("Cox Proportional Hazards Model Analysis"),
  sidebarLayout(
    sidebarPanel(
      coxUI("cox_analysis"),
      hr(),
      downloadButton("download_results", "결과 다운로드")
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Cox Regression", 
                 DT::DTOutput("cox_table")),
        tabPanel("Model Summary", 
                 verbatimTextOutput("model_summary")),
        tabPanel("Survival Curves", 
                 plotOutput("survival_curves", height = "600px")),
        tabPanel("Proportional Hazards Test", 
                 verbatimTextOutput("ph_test"))
      )
    )
  )
)

server <- function(input, output, session) {
  # 예시 생존분석 데이터
  data_input <- reactive({
    data(colon, package = "survival")
    
    # 데이터 전처리
    colon_clean <- colon %>%
      mutate(
        rx = factor(rx, labels = c("Obs", "Lev", "Lev+5FU")),
        sex = factor(sex, labels = c("Female", "Male")),
        obstruct = factor(obstruct, labels = c("No", "Yes")),
        perfor = factor(perfor, labels = c("No", "Yes")),
        adhere = factor(adhere, labels = c("No", "Yes")),
        differ = factor(differ, labels = c("Well", "Moderate", "Poor")),
        extent = factor(extent, labels = c("Submucosa", "Muscle", "Serosa", "Contiguous"))
      ) %>%
      filter(!is.na(time) & !is.na(status))
    
    colon_clean
  })
  
  data_label <- reactive({
    data.frame(
      variable = names(data_input()),
      label = c("ID", "Study", "Treatment", "Sex", "Age", "Obstruction",
               "Perforated", "Adherence", "Nodes", "Time", "Status", 
               "Differentiation", "Extent", "Surgery time", "Time to recurrence",
               "Recurrence status", "Time to death", "Death status"),
      stringsAsFactors = FALSE
    )
  })
  
  # Cox 회귀분석 모듈 서버
  cox_result <- callModule(coxModule, "cox_analysis",
                          data = data_input,
                          data_label = data_label,
                          nfactor.limit = 20)
  
  # Cox 회귀분석 테이블 출력
  output$cox_table <- DT::renderDT({
    req(cox_result()$table)
    
    DT::datatable(cox_result()$table, 
                  options = list(scrollX = TRUE, pageLength = 15),
                  rownames = FALSE) %>%
      DT::formatRound(columns = c("HR", "Lower", "Upper"), digits = 3) %>%
      DT::formatRound(columns = "P value", digits = 4)
  })
  
  # 모델 요약 출력
  output$model_summary <- renderPrint({
    req(cox_result()$model)
    
    model <- cox_result()$model
    cat("Cox Proportional Hazards Model Summary\n")
    cat("=====================================\n\n")
    
    # 모델 정보
    cat("Model Formula:", deparse(model$formula), "\n")
    cat("Number of observations:", model$n, "\n")
    cat("Number of events:", model$nevent, "\n\n")
    
    # 전체 모델 검정
    cat("Global Tests:\n")
    print(survival:::summary.coxph(model)$logtest)
    cat("\n")
    
    # 계수 요약
    cat("Coefficients:\n")
    print(summary(model)$coefficients)
    
    # 콘코던스 지수
    cat("\nConcordance Index:", round(model$concordance[1], 4), "\n")
  })
  
  # 생존곡선 플롯
  output$survival_curves <- renderPlot({
    req(cox_result()$model, data_input())
    
    model <- cox_result()$model
    df <- data_input()
    
    # 대표적인 범주형 변수로 생존곡선 그리기
    if("rx" %in% names(df)) {
      # 치료군별 생존곡선
      fit_strata <- survfit(Surv(time, status) ~ rx, data = df)
      
      # jskm으로 시각화
      jskm::jskm(fit_strata,
                table = TRUE,
                pval = TRUE,
                marks = FALSE,
                timeby = 500,
                xlims = c(0, max(df$time, na.rm = TRUE)),
                legend.labs = levels(df$rx))
    }
  })
  
  # 비례위험 가정 검정
  output$ph_test <- renderPrint({
    req(cox_result()$model)
    
    model <- cox_result()$model
    
    cat("Proportional Hazards Assumption Test\n")
    cat("===================================\n\n")
    
    # Schoenfeld residuals test
    tryCatch({
      ph_test <- survival::cox.zph(model)
      print(ph_test)
      
      cat("\nInterpretation:\n")
      cat("- p-value < 0.05 indicates violation of proportional hazards assumption\n")
      cat("- Global test p-value:", round(ph_test$table["GLOBAL", "p"], 4), "\n")
      
      if(ph_test$table["GLOBAL", "p"] < 0.05) {
        cat("- WARNING: Proportional hazards assumption may be violated\n")
      } else {
        cat("- Proportional hazards assumption appears to be satisfied\n")
      }
    }, error = function(e) {
      cat("Could not perform proportional hazards test\n")
      cat("Error:", e$message, "\n")
    })
  })
}

shinyApp(ui = ui, server = server)
```

### 고급 사용법

```r
# 복잡한 생존분석 워크플로
server <- function(input, output, session) {
  # 데이터 입력 모듈 연동
  data_input <- callModule(csvFile, "datafile")
  
  # Cox 회귀분석
  cox_analysis <- callModule(coxModule, "cox_viz",
                            data = reactive(data_input()$data),
                            data_label = reactive(data_input()$label))
  
  # 다중 모델 비교 분석
  model_comparison <- reactive({
    req(data_input()$data)
    
    df <- data_input()$data
    
    # 생존분석에 필요한 변수 확인
    if(all(c("time", "status") %in% names(df))) {
      models <- list()
      
      # 단변량 모델들
      continuous_vars <- df %>% select_if(is.numeric) %>% 
                        select(-time, -status) %>% names()
      categorical_vars <- df %>% select_if(is.factor) %>% names()
      
      univariate_results <- data.frame()
      
      # 연속형 변수 단변량 분석
      for(var in continuous_vars[1:min(5, length(continuous_vars))]) {
        tryCatch({
          formula_str <- paste("Surv(time, status) ~", var)
          model <- coxph(as.formula(formula_str), data = df)
          
          summary_model <- summary(model)
          
          univariate_results <- rbind(univariate_results, data.frame(
            Variable = var,
            Type = "Continuous",
            HR = round(summary_model$coefficients[1, "exp(coef)"], 3),
            Lower_CI = round(summary_model$conf.int[1, "lower .95"], 3),
            Upper_CI = round(summary_model$conf.int[1, "upper .95"], 3),
            P_value = round(summary_model$coefficients[1, "Pr(>|z|)"], 4),
            Concordance = round(model$concordance[1], 3)
          ))
        }, error = function(e) NULL)
      }
      
      # 범주형 변수 단변량 분석
      for(var in categorical_vars[1:min(3, length(categorical_vars))]) {
        tryCatch({
          formula_str <- paste("Surv(time, status) ~", var)
          model <- coxph(as.formula(formula_str), data = df)
          
          summary_model <- summary(model)
          
          # 첫 번째 계수만 사용 (참조 그룹 대비)
          if(nrow(summary_model$coefficients) >= 1) {
            univariate_results <- rbind(univariate_results, data.frame(
              Variable = var,
              Type = "Categorical",
              HR = round(summary_model$coefficients[1, "exp(coef)"], 3),
              Lower_CI = round(summary_model$conf.int[1, "lower .95"], 3),
              Upper_CI = round(summary_model$conf.int[1, "upper .95"], 3),
              P_value = round(summary_model$coefficients[1, "Pr(>|z|)"], 4),
              Concordance = round(model$concordance[1], 3)
            ))
          }
        }, error = function(e) NULL)
      }
      
      return(univariate_results)
    }
  })
  
  # 다변량 모델 구축
  multivariate_model <- reactive({
    req(model_comparison())
    
    # 유의한 변수들 선택 (p < 0.2)
    significant_vars <- model_comparison() %>%
      filter(P_value < 0.2) %>%
      pull(Variable)
    
    if(length(significant_vars) >= 2) {
      df <- data_input()$data
      
      # 다변량 모델 공식 생성
      formula_str <- paste("Surv(time, status) ~", 
                          paste(significant_vars, collapse = " + "))
      
      tryCatch({
        multivariate_cox <- coxph(as.formula(formula_str), data = df)
        
        return(list(
          model = multivariate_cox,
          formula = formula_str,
          summary = summary(multivariate_cox)
        ))
      }, error = function(e) {
        return(list(error = e$message))
      })
    }
  })
  
  # 생존곡선 예측
  survival_prediction <- reactive({
    req(multivariate_model()$model)
    
    model <- multivariate_model()$model
    df <- data_input()$data
    
    # 예측을 위한 대표적인 프로파일 생성
    # 연속형 변수는 중앙값, 범주형 변수는 최빈값 사용
    numeric_vars <- df %>% select_if(is.numeric) %>% 
                   select(-time, -status) %>% names()
    factor_vars <- df %>% select_if(is.factor) %>% names()
    
    new_data <- data.frame()
    
    # 연속형 변수 중앙값
    for(var in numeric_vars) {
      if(var %in% names(coef(model))) {
        new_data[[var]] <- median(df[[var]], na.rm = TRUE)
      }
    }
    
    # 범주형 변수 최빈값
    for(var in factor_vars) {
      if(any(grepl(var, names(coef(model))))) {
        mode_val <- names(sort(table(df[[var]]), decreasing = TRUE))[1]
        new_data[[var]] <- factor(mode_val, levels = levels(df[[var]]))
      }
    }
    
    if(nrow(new_data) > 0) {
      # 생존함수 예측
      survival_fit <- survfit(model, newdata = new_data)
      
      return(list(
        survival_fit = survival_fit,
        new_data = new_data,
        median_survival = median(survival_fit$time)
      ))
    }
  })
  
  # 잔차 분석
  residual_analysis <- reactive({
    req(multivariate_model()$model)
    
    model <- multivariate_model()$model
    
    # 다양한 잔차 계산
    residuals_list <- list(
      martingale = residuals(model, type = "martingale"),
      deviance = residuals(model, type = "deviance"),
      schoenfeld = residuals(model, type = "schoenfeld"),
      dfbeta = residuals(model, type = "dfbeta")
    )
    
    return(residuals_list)
  })
  
  # 단변량 분석 결과 출력
  output$univariate_analysis <- DT::renderDT({
    req(model_comparison())
    model_comparison()
  })
  
  # 다변량 모델 요약
  output$multivariate_summary <- renderPrint({
    req(multivariate_model())
    
    if(!is.null(multivariate_model()$error)) {
      cat("Error in multivariate model:\n")
      cat(multivariate_model()$error)
    } else {
      model_summary <- multivariate_model()$summary
      cat("Multivariate Cox Regression Results\n")
      cat("=================================\n\n")
      cat("Formula:", multivariate_model()$formula, "\n\n")
      
      print(model_summary$coefficients)
      
      cat("\nModel Statistics:\n")
      cat("Concordance:", round(multivariate_model()$model$concordance[1], 4), "\n")
      cat("Likelihood Ratio Test p-value:", 
          round(model_summary$logtest["pvalue"], 4), "\n")
    }
  })
  
  # 생존곡선 예측 플롯
  output$prediction_plot <- renderPlot({
    req(survival_prediction())
    
    survival_fit <- survival_prediction()$survival_fit
    
    # 생존곡선 플롯
    plot(survival_fit, 
         xlab = "Time", 
         ylab = "Survival Probability",
         main = "Predicted Survival Curve for Average Patient",
         conf.int = TRUE,
         col = "blue",
         lwd = 2)
    
    # 중앙생존시간 표시
    if(!is.na(survival_prediction()$median_survival)) {
      abline(v = survival_prediction()$median_survival, 
             col = "red", lty = 2, lwd = 2)
      text(survival_prediction()$median_survival, 0.8, 
           paste("Median:", round(survival_prediction()$median_survival, 1)),
           pos = 4, col = "red")
    }
  })
  
  # 잔차 플롯
  output$residual_plots <- renderPlot({
    req(residual_analysis())
    
    residuals_data <- residual_analysis()
    
    # 2x2 플롯 레이아웃
    par(mfrow = c(2, 2))
    
    # Martingale residuals
    plot(multivariate_model()$model$linear.predictors,
         residuals_data$martingale,
         xlab = "Linear Predictors", 
         ylab = "Martingale Residuals",
         main = "Martingale Residuals")
    abline(h = 0, col = "red", lty = 2)
    lines(lowess(multivariate_model()$model$linear.predictors, 
                residuals_data$martingale), col = "blue", lwd = 2)
    
    # Deviance residuals
    plot(multivariate_model()$model$linear.predictors,
         residuals_data$deviance,
         xlab = "Linear Predictors", 
         ylab = "Deviance Residuals",
         main = "Deviance Residuals")
    abline(h = 0, col = "red", lty = 2)
    
    # Q-Q plot for deviance residuals
    qqnorm(residuals_data$deviance, main = "Q-Q Plot of Deviance Residuals")
    qqline(residuals_data$deviance, col = "red")
    
    # Index plot
    plot(1:length(residuals_data$deviance),
         residuals_data$deviance,
         xlab = "Index", 
         ylab = "Deviance Residuals",
         main = "Index Plot")
    abline(h = c(-2, 2), col = "red", lty = 2)
    
    par(mfrow = c(1, 1))
  })
}
```

## Cox Regression Features

### 지원하는 분석 유형

#### 기본 Cox 회귀분석
```r
# 단변량 Cox 모델
univariate_cox <- coxph(Surv(time, status) ~ variable, data = data)

# 다변량 Cox 모델
multivariate_cox <- coxph(Surv(time, status) ~ var1 + var2 + var3, data = data)

# 층화 Cox 모델
stratified_cox <- coxph(Surv(time, status) ~ var1 + strata(strata_var), data = data)
```

#### 경쟁위험 분석
```r
# Fine-Gray 모델 (competing risks)
# 이벤트 타입별로 다른 위험함수 모델링
competing_risks_analysis <- function(data, time_var, event_var, covariates) {
  # 경쟁위험을 고려한 분석
  # 특정 이벤트에 대한 누적발생함수 모델링
}
```

#### 시간-의존적 공변량
```r
# 시간-의존적 공변량이 있는 Cox 모델
time_dependent_cox <- coxph(Surv(tstart, tstop, event) ~ covariate + 
                           time_dependent_covariate, 
                           data = long_format_data)
```

### 모델 진단

#### 비례위험 가정 검정
```r
# Schoenfeld residuals을 이용한 비례위험 가정 검정
ph_test <- function(cox_model) {
  ph_result <- cox.zph(cox_model)
  
  return(list(
    test_statistics = ph_result$table,
    global_p = ph_result$table["GLOBAL", "p"],
    violation = ph_result$table["GLOBAL", "p"] < 0.05
  ))
}
```

#### 영향력 진단
```r
# 영향력이 큰 관측치 식별
influence_diagnostics <- function(cox_model) {
  # dfbeta residuals
  dfbeta_res <- residuals(cox_model, type = "dfbeta")
  
  # 영향력이 큰 관측치 식별 (|dfbeta| > 2/sqrt(n))
  n <- nrow(dfbeta_res)
  threshold <- 2 / sqrt(n)
  
  influential_obs <- which(apply(abs(dfbeta_res) > threshold, 1, any))
  
  return(list(
    dfbeta = dfbeta_res,
    threshold = threshold,
    influential_observations = influential_obs
  ))
}
```

#### 모델 적합도 평가
```r
# 콘코던스 지수와 기타 적합도 지표
model_goodness_of_fit <- function(cox_model, data) {
  # 콘코던스 지수
  concordance <- cox_model$concordance[1]
  
  # AIC, BIC
  aic_value <- AIC(cox_model)
  bic_value <- BIC(cox_model)
  
  # 우도비 검정
  likelihood_test <- summary(cox_model)$logtest
  
  return(list(
    concordance = concordance,
    AIC = aic_value,
    BIC = bic_value,
    likelihood_ratio_test = likelihood_test
  ))
}
```

## Advanced Features

### 변수 선택 방법

#### 단계적 회귀
```r
# 전진 선택
forward_selection <- function(data, outcome_vars, candidate_vars, alpha_enter = 0.05) {
  selected_vars <- character()
  remaining_vars <- candidate_vars
  
  while(length(remaining_vars) > 0) {
    p_values <- numeric(length(remaining_vars))
    
    for(i in 1:length(remaining_vars)) {
      test_vars <- c(selected_vars, remaining_vars[i])
      formula_str <- paste("Surv(", outcome_vars[1], ",", outcome_vars[2], ") ~",
                          paste(test_vars, collapse = " + "))
      
      model <- coxph(as.formula(formula_str), data = data)
      p_values[i] <- summary(model)$coefficients[nrow(summary(model)$coefficients), "Pr(>|z|)"]
    }
    
    min_p_idx <- which.min(p_values)
    
    if(p_values[min_p_idx] < alpha_enter) {
      selected_vars <- c(selected_vars, remaining_vars[min_p_idx])
      remaining_vars <- remaining_vars[-min_p_idx]
    } else {
      break
    }
  }
  
  return(selected_vars)
}
```

#### 라소 정규화
```r
# 라소 Cox 회귀 (glmnet 패키지 사용)
if(requireNamespace("glmnet", quietly = TRUE)) {
  lasso_cox <- function(data, time_var, status_var, covariates) {
    # 데이터 준비
    x <- as.matrix(data[, covariates])
    y <- Surv(data[[time_var]], data[[status_var]])
    
    # 교차검증으로 최적 lambda 선택
    cv_fit <- glmnet::cv.glmnet(x, y, family = "cox")
    
    # 최적 모델
    optimal_fit <- glmnet::glmnet(x, y, family = "cox", lambda = cv_fit$lambda.min)
    
    return(list(
      model = optimal_fit,
      lambda = cv_fit$lambda.min,
      selected_variables = rownames(coef(optimal_fit))[coef(optimal_fit)[, 1] != 0]
    ))
  }
}
```

### 생존곡선 예측

#### 개별 예측
```r
# 새로운 관측치에 대한 생존확률 예측
individual_survival_prediction <- function(cox_model, new_data, time_points) {
  # 기저 생존함수
  baseline_survival <- survfit(cox_model)
  
  # 새로운 데이터에 대한 선형 예측자
  linear_predictors <- predict(cox_model, newdata = new_data, type = "lp")
  
  # 각 시점별 생존확률 계산
  survival_probs <- matrix(NA, nrow = nrow(new_data), ncol = length(time_points))
  
  for(i in 1:length(time_points)) {
    # 해당 시점의 기저 생존확률 찾기
    time_idx <- which.min(abs(baseline_survival$time - time_points[i]))
    baseline_surv_prob <- baseline_survival$surv[time_idx]
    
    # 개별 생존확률 = 기저생존확률^exp(linear_predictor)
    survival_probs[, i] <- baseline_surv_prob^exp(linear_predictors)
  }
  
  colnames(survival_probs) <- paste0("Time_", time_points)
  
  return(survival_probs)
}
```

#### 예후 지수
```r
# 예후 지수 계산 및 위험군 분류
prognostic_index <- function(cox_model, data, cutoff_quantiles = c(0.33, 0.67)) {
  # 선형 예측자 계산
  linear_predictors <- predict(cox_model, type = "lp")
  
  # 위험군 분류
  cutoffs <- quantile(linear_predictors, cutoff_quantiles)
  
  risk_groups <- cut(linear_predictors, 
                    breaks = c(-Inf, cutoffs, Inf),
                    labels = c("Low Risk", "Medium Risk", "High Risk"))
  
  # 위험군별 생존곡선
  surv_by_risk <- survfit(Surv(data$time, data$status) ~ risk_groups)
  
  return(list(
    linear_predictors = linear_predictors,
    risk_groups = risk_groups,
    cutoffs = cutoffs,
    survival_by_risk = surv_by_risk
  ))
}
```

## Export and Download Features

### 분석 결과 내보내기

```r
# Cox 회귀분석 결과 종합 보고서
cox_analysis_report <- reactive({
  req(cox_result()$model, cox_result()$table)
  
  model <- cox_result()$model
  results_table <- cox_result()$table
  
  # 보고서 텍스트 생성
  report_text <- paste0(
    "Cox Proportional Hazards Model Analysis Report\n",
    "===============================================\n\n",
    "Analysis Date: ", Sys.Date(), "\n",
    "Sample Size: ", model$n, " observations\n",
    "Number of Events: ", model$nevent, "\n",
    "Concordance Index: ", round(model$concordance[1], 4), "\n\n",
    
    "Model Formula:\n",
    deparse(model$formula), "\n\n",
    
    "Results Summary:\n",
    "Variables in Model: ", nrow(results_table), "\n"
  )
  
  # 유의한 변수 식별
  significant_vars <- results_table[results_table$`P value` < 0.05, ]
  
  if(nrow(significant_vars) > 0) {
    report_text <- paste0(report_text,
      "Significant Variables (p < 0.05): ", nrow(significant_vars), "\n\n",
      "Significant Results:\n"
    )
    
    for(i in 1:nrow(significant_vars)) {
      var_name <- rownames(significant_vars)[i]
      hr <- significant_vars[i, "HR"]
      ci_lower <- significant_vars[i, "Lower"]
      ci_upper <- significant_vars[i, "Upper"]
      p_val <- significant_vars[i, "P value"]
      
      report_text <- paste0(report_text,
        sprintf("- %s: HR = %.3f (95%% CI: %.3f-%.3f), p = %.4f\n",
                var_name, hr, ci_lower, ci_upper, p_val)
      )
    }
  }
  
  return(report_text)
})

# 보고서 다운로드
output$download_cox_report <- downloadHandler(
  filename = function() {
    paste("cox_analysis_report_", Sys.Date(), ".txt", sep = "")
  },
  content = function(file) {
    writeLines(cox_analysis_report(), file)
  }
)
```

## Performance Optimization

### 대용량 데이터 처리

```r
# 효율적인 Cox 회귀분석
efficient_cox_analysis <- reactive({
  req(data_input()$data)
  
  df <- data_input()$data
  
  # 결측치가 많은 변수 제외
  complete_ratio <- df %>%
    summarise_all(~mean(!is.na(.))) %>%
    gather(variable, complete_ratio)
  
  usable_vars <- complete_ratio %>%
    filter(complete_ratio >= 0.8) %>%
    pull(variable)
  
  df_clean <- df[, usable_vars]
  
  # 완전한 관측치만 사용
  df_complete <- df_clean[complete.cases(df_clean), ]
  
  # 표본 크기가 너무 큰 경우 층화 샘플링
  if(nrow(df_complete) > 5000) {
    showNotification("Large dataset: Consider using sampling for faster computation", 
                    type = "info")
  }
  
  return(df_complete)
})
```

## Dependencies

### 필수 패키지

- `shiny` - 기본 Shiny 기능
- `survival` - 생존분석 함수
- `survey` - 가중 생존분석
- `data.table` - 데이터 조작
- `jstable` - 결과 테이블 생성

### 선택적 패키지

- `glmnet` - 정규화 Cox 회귀
- `survminer` - 생존곡선 시각화
- `rms` - 회귀분석 모델링

## Troubleshooting

### 일반적인 오류

```r
# 1. 시간 변수에 음수 또는 0이 있는 경우
# 해결: 시간 변수 검증 및 변환

# 2. 이벤트가 발생하지 않은 경우 (모든 status = 0)
# 해결: 데이터 확인 및 적절한 추적기간 설정

# 3. 완전분리(complete separation) 문제
# 해결: 변수 제거 또는 정규화 방법 사용

# 4. 수렴하지 않는 모델
# 해결: 변수 스케일링 또는 모델 단순화
```

## See Also

- `survival::coxph()` - Cox 회귀분석
- `survival::cox.zph()` - 비례위험 가정 검정
- `survminer::ggsurvplot()` - 생존곡선 시각화
- `kaplan.R` - Kaplan-Meier 분석 모듈