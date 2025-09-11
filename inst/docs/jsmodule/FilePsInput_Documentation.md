# FilePsInput Documentation

## Overview

`FilePsInput.R`은 jsmodule 패키지의 성향점수 분석(Propensity Score Analysis) 전용 데이터 입력 모듈입니다. 이 모듈은 성향점수 매칭, 역확률 가중치(IPTW), 층화 분석 등을 위한 데이터를 업로드하고 전처리하는 기능을 제공합니다.

## Module Components

### `FilePsInput(id, label)`

성향점수 분석을 위한 Shiny 모듈 UI를 생성합니다.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `id` | character | - | 모듈의 고유 식별자 |
| `label` | character | "Upload data (csv/xlsx/sav/sas7bdat/dta)" | 파일 입력 레이블 |

#### Returns

성향점수 분석용 UI 요소들을 포함하는 Shiny UI 객체

#### Example

```r
library(shiny)
library(jsmodule)

ui <- fluidPage(
  titlePanel("Propensity Score Analysis"),
  sidebarLayout(
    sidebarPanel(
      FilePsInput("ps_data", 
                  label = "Upload data for PS analysis")
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Data", DT::DTOutput("data_table")),
        tabPanel("PS Scores", DT::DTOutput("ps_table")),
        tabPanel("Matching", DT::DTOutput("matched_data"))
      )
    )
  )
)
```

### `FilePs(input, output, session, nfactor.limit = 20)`

성향점수 분석을 위한 서버 사이드 로직을 제공합니다.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `input` | - | - | Shiny 입력 객체 |
| `output` | - | - | Shiny 출력 객체 |
| `session` | - | - | Shiny 세션 객체 |
| `nfactor.limit` | integer | 20 | 범주형 변수로 제안할 고유값 임계치 |

#### Returns

다음을 포함하는 반응형 리스트:
- `data`: 원본 데이터
- `data_ps`: 성향점수가 계산된 데이터
- `data_match`: 매칭된 데이터 (해당하는 경우)
- `label`: 변수 레이블 정보
- `ps_model`: 성향점수 모델
- `match_object`: 매칭 객체 (MatchIt)

## Propensity Score Analysis Features

### 지원하는 분석 방법

#### 1. 성향점수 매칭 (Propensity Score Matching)

```r
# 1:1 매칭
ps_data <- callModule(FilePs, "ps_input")

observe({
  if (!is.null(ps_data()$data_match)) {
    matched_data <- ps_data()$data_match
    
    # 매칭 후 균형 확인
    balance_check <- MatchIt::summary(ps_data()$match_object)
    print(balance_check)
  }
})
```

#### 2. 역확률 가중치 (Inverse Probability Treatment Weighting)

```r
# IPTW 분석
server <- function(input, output, session) {
  ps_data <- callModule(FilePs, "ps_input")
  
  # IPTW 가중치 계산
  iptw_data <- reactive({
    req(ps_data()$data_ps)
    
    data_with_ps <- ps_data()$data_ps
    treatment_var <- input$treatment_variable
    
    # 가중치 계산
    data_with_ps$iptw_weight <- ifelse(
      data_with_ps[[treatment_var]] == 1,
      1 / data_with_ps$propensity_score,
      1 / (1 - data_with_ps$propensity_score)
    )
    
    return(data_with_ps)
  })
  
  output$iptw_summary <- renderPrint({
    req(iptw_data())
    summary(iptw_data()$iptw_weight)
  })
}
```

#### 3. 층화 분석 (Stratification)

```r
# 성향점수 기반 층화
stratified_analysis <- reactive({
  req(ps_data()$data_ps)
  
  data_with_ps <- ps_data()$data_ps
  
  # 5분위수 기반 층화
  data_with_ps$ps_stratum <- cut(
    data_with_ps$propensity_score,
    breaks = quantile(data_with_ps$propensity_score, 
                     probs = seq(0, 1, 0.2)),
    include.lowest = TRUE,
    labels = paste("Stratum", 1:5)
  )
  
  return(data_with_ps)
})
```

## Usage Notes

### 기본 사용 패턴

```r
library(shiny)
library(jsmodule)
library(MatchIt)
library(DT)

# 완전한 성향점수 분석 앱
ui <- fluidPage(
  titlePanel("Propensity Score Analysis"),
  sidebarLayout(
    sidebarPanel(
      FilePsInput("ps_analysis"),
      hr(),
      h4("Analysis Options"),
      radioButtons("ps_method", "PS Method:",
                  choices = list(
                    "Matching" = "matching",
                    "IPTW" = "iptw",
                    "Stratification" = "stratification"
                  )),
      conditionalPanel(
        condition = "input.ps_method == 'matching'",
        selectInput("match_method", "Matching Method:",
                   choices = list(
                     "1:1 Nearest" = "nearest",
                     "Optimal" = "optimal",
                     "Genetic" = "genetic"
                   ))
      )
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Original Data", 
                 DT::DTOutput("original_data")),
        tabPanel("PS Model", 
                 verbatimTextOutput("ps_model_summary")),
        tabPanel("PS Distribution", 
                 plotOutput("ps_distribution")),
        tabPanel("Processed Data", 
                 DT::DTOutput("processed_data")),
        tabPanel("Balance Check", 
                 verbatimTextOutput("balance_summary"))
      )
    )
  )
)

server <- function(input, output, session) {
  # 성향점수 분석 모듈
  ps_data <- callModule(FilePs, "ps_analysis")
  
  # 원본 데이터 표시
  output$original_data <- DT::renderDT({
    req(ps_data()$data)
    ps_data()$data
  }, options = list(scrollX = TRUE))
  
  # 성향점수 모델 요약
  output$ps_model_summary <- renderPrint({
    req(ps_data()$ps_model)
    summary(ps_data()$ps_model)
  })
  
  # 성향점수 분포 시각화
  output$ps_distribution <- renderPlot({
    req(ps_data()$data_ps)
    
    data_ps <- ps_data()$data_ps
    treatment_var <- names(data_ps)[2]  # 예시
    
    ggplot(data_ps, aes(x = propensity_score, 
                       fill = factor(!!sym(treatment_var)))) +
      geom_histogram(alpha = 0.6, position = "identity", bins = 30) +
      labs(title = "Propensity Score Distribution",
           x = "Propensity Score",
           y = "Frequency",
           fill = "Treatment") +
      theme_minimal()
  })
  
  # 처리된 데이터 표시
  output$processed_data <- DT::renderDT({
    if (input$ps_method == "matching") {
      req(ps_data()$data_match)
      ps_data()$data_match
    } else {
      req(ps_data()$data_ps)
      ps_data()$data_ps
    }
  }, options = list(scrollX = TRUE))
  
  # 균형 검사
  output$balance_summary <- renderPrint({
    if (input$ps_method == "matching") {
      req(ps_data()$match_object)
      summary(ps_data()$match_object)
    } else {
      cat("Balance check available for matching method only")
    }
  })
}

shinyApp(ui = ui, server = server)
```

### 고급 분석 예제

```r
# 성향점수 분석 후 결과 분석
server <- function(input, output, session) {
  ps_data <- callModule(FilePs, "ps_analysis")
  
  # 성향점수 분석 후 효과 추정
  treatment_effect <- reactive({
    req(ps_data()$data_match)
    
    matched_data <- ps_data()$data_match
    outcome_var <- input$outcome_variable
    treatment_var <- input$treatment_variable
    
    # 매칭된 데이터에서 치료 효과 추정
    treated <- matched_data[matched_data[[treatment_var]] == 1, ]
    control <- matched_data[matched_data[[treatment_var]] == 0, ]
    
    # 평균 치료 효과 (ATE)
    ate <- mean(treated[[outcome_var]], na.rm = TRUE) - 
           mean(control[[outcome_var]], na.rm = TRUE)
    
    # t-검정
    t_test <- t.test(treated[[outcome_var]], 
                    control[[outcome_var]])
    
    return(list(
      ate = ate,
      t_test = t_test,
      treated_mean = mean(treated[[outcome_var]], na.rm = TRUE),
      control_mean = mean(control[[outcome_var]], na.rm = TRUE)
    ))
  })
  
  output$treatment_effect <- renderPrint({
    effect <- treatment_effect()
    req(effect)
    
    cat("Average Treatment Effect (ATE):", round(effect$ate, 4), "\n")
    cat("Treated group mean:", round(effect$treated_mean, 4), "\n")
    cat("Control group mean:", round(effect$control_mean, 4), "\n")
    cat("P-value:", round(effect$t_test$p.value, 4), "\n")
    cat("95% CI:", round(effect$t_test$conf.int, 4), "\n")
  })
}
```

## Advanced Features

### 동적 변수 선택

```r
# 성향점수 모델을 위한 동적 변수 선택
output$covariate_selection <- renderUI({
  req(ps_data()$data)
  
  data <- ps_data()$data
  numeric_vars <- names(data)[sapply(data, is.numeric)]
  factor_vars <- names(data)[sapply(data, is.factor)]
  
  tagList(
    h4("Select Covariates for PS Model"),
    checkboxGroupInput("ps_covariates",
                      "Continuous Variables:",
                      choices = numeric_vars),
    checkboxGroupInput("ps_factors", 
                      "Categorical Variables:",
                      choices = factor_vars)
  )
})
```

### 균형 진단

```r
# 매칭 전후 균형 비교
balance_diagnosis <- reactive({
  req(ps_data()$data, ps_data()$data_match)
  
  original <- ps_data()$data
  matched <- ps_data()$data_match
  treatment_var <- input$treatment_variable
  covariates <- input$ps_covariates
  
  # 매칭 전 표준화된 차이
  before_balance <- sapply(covariates, function(var) {
    treated_mean <- mean(original[original[[treatment_var]] == 1, var], na.rm = TRUE)
    control_mean <- mean(original[original[[treatment_var]] == 0, var], na.rm = TRUE)
    pooled_sd <- sd(original[[var]], na.rm = TRUE)
    
    (treated_mean - control_mean) / pooled_sd
  })
  
  # 매칭 후 표준화된 차이
  after_balance <- sapply(covariates, function(var) {
    treated_mean <- mean(matched[matched[[treatment_var]] == 1, var], na.rm = TRUE)
    control_mean <- mean(matched[matched[[treatment_var]] == 0, var], na.rm = TRUE)
    pooled_sd <- sd(matched[[var]], na.rm = TRUE)
    
    (treated_mean - control_mean) / pooled_sd
  })
  
  return(data.frame(
    Variable = covariates,
    Before_Matching = round(before_balance, 3),
    After_Matching = round(after_balance, 3),
    Improvement = round(abs(before_balance) - abs(after_balance), 3)
  ))
})

output$balance_table <- DT::renderDT({
  balance_diagnosis()
}, options = list(pageLength = 10))
```

### 민감도 분석

```r
# 숨겨진 혼동변수에 대한 민감도 분석
sensitivity_analysis <- reactive({
  req(ps_data()$data_match)
  
  matched_data <- ps_data()$data_match
  outcome_var <- input$outcome_variable
  treatment_var <- input$treatment_variable
  
  # Rosenbaum bounds
  # (실제 구현은 rbounds 패키지 등 사용)
  
  # 감마 값에 따른 p-value 범위
  gamma_values <- seq(1, 2, 0.1)
  
  # 예시 계산 (실제로는 더 복잡한 알고리즘 필요)
  sensitivity_results <- data.frame(
    Gamma = gamma_values,
    P_value_lower = runif(length(gamma_values), 0.001, 0.05),
    P_value_upper = runif(length(gamma_values), 0.05, 0.5)
  )
  
  return(sensitivity_results)
})
```

## Integration with MatchIt

### MatchIt 패키지 연동

```r
# MatchIt을 사용한 고급 매칭
advanced_matching <- reactive({
  req(ps_data()$data)
  
  data <- ps_data()$data
  treatment_var <- input$treatment_variable
  covariates <- input$ps_covariates
  
  # 매칭 공식 생성
  formula_str <- paste(treatment_var, "~", paste(covariates, collapse = " + "))
  match_formula <- as.formula(formula_str)
  
  # 다양한 매칭 방법
  match_method <- switch(input$match_method,
    "nearest" = "nearest",
    "optimal" = "optimal", 
    "genetic" = "genetic",
    "nearest"  # 기본값
  )
  
  # MatchIt 실행
  match_result <- MatchIt::matchit(
    formula = match_formula,
    data = data,
    method = match_method,
    distance = "logit",
    caliper = 0.2,
    ratio = 1
  )
  
  return(match_result)
})

# 매칭된 데이터 추출
matched_data_extract <- reactive({
  req(advanced_matching())
  
  match_obj <- advanced_matching()
  MatchIt::match.data(match_obj)
})
```

## Performance Considerations

### 대용량 데이터 처리

```r
# 큰 데이터셋을 위한 최적화
optimized_ps_analysis <- function(data, treatment_var, covariates) {
  # 1. 데이터 샘플링 (필요한 경우)
  if (nrow(data) > 10000) {
    sample_size <- min(10000, nrow(data))
    data_sample <- data[sample(nrow(data), sample_size), ]
  } else {
    data_sample <- data
  }
  
  # 2. 성향점수 모델 피팅
  ps_formula <- as.formula(paste(treatment_var, "~", 
                                paste(covariates, collapse = " + ")))
  
  ps_model <- glm(ps_formula, data = data_sample, family = binomial())
  
  # 3. 전체 데이터에 성향점수 적용
  data$propensity_score <- predict(ps_model, newdata = data, type = "response")
  
  return(list(
    data_ps = data,
    ps_model = ps_model
  ))
}
```

## Dependencies

### 필수 패키지

```r
library(shiny)        # Shiny 웹 애플리케이션
library(MatchIt)      # 성향점수 매칭
library(DT)           # 데이터 테이블
library(ggplot2)      # 시각화
```

### 선택적 패키지

```r
library(cobalt)       # 균형 진단
library(WeightIt)     # 가중치 계산
library(rbounds)      # 민감도 분석
library(optmatch)     # 최적 매칭
library(twang)        # GBM 기반 성향점수
```

## Error Handling

### 일반적인 문제 해결

```r
# 1. 성향점수 모델 수렴 실패
# 해결: 변수 선택 재검토, 상호작용항 제거

# 2. 매칭 실패 (매칭되는 대상이 없음)
# 해결: caliper 값 조정, 매칭 방법 변경

# 3. 극단적 성향점수 값
# 해결: 공통 지지영역(common support) 확인

# 4. 불균형한 치료군 크기
# 해결: 가중치 방법 고려, 층화 분석 사용
```

## See Also

- `DataManager.R` - 데이터 관리 클래스
- `csvFileInput.R` - 일반 데이터 입력 모듈
- `jsPropensityGadget.R` - 성향점수 분석 Gadget
- `regress.R` - 회귀분석 모듈