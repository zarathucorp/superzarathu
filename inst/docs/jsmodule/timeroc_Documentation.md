# timeroc Documentation

## Overview
`timeroc.R`은 jsmodule 패키지의 시간의존적 ROC 분석(Time-dependent ROC Analysis)을 위한 Shiny 모듈입니다. 생존분석 데이터에서 예측모델의 시간에 따른 예측 성능을 평가하며, Cox 비례위험모델의 예측 정확도를 시간 경과에 따라 분석할 수 있습니다.

## Module Components

### UI Functions

#### `timerocUI(id)`
시간의존적 ROC 분석을 위한 사용자 인터페이스를 생성합니다.

**Parameters:**
- `id`: 모듈의 고유 식별자 (문자열)

**UI Elements:**
- 이벤트 변수 선택기 (생존 상태)
- 시간 변수 선택기 (생존 시간)
- 독립변수 선택기 (예측변수들)
- 평가 시점 설정 (numeric input)
- 모델 비교 옵션
- 하위그룹 분석 체크박스

### Server Functions

#### `timerocModule(input, output, session, data, data_label, data_varStruct = NULL, nfactor.limit = 10, design.survey = NULL)`
정적 데이터에 대한 시간의존적 ROC 분석을 수행하는 서버 함수입니다.

**Parameters:**
- `input`, `output`, `session`: Shiny 서버 매개변수
- `data`: 분석할 생존 데이터셋 (data.frame)
- `data_label`: 변수 라벨 정보
- `data_varStruct`: 변수 구조 리스트 (선택적)
- `nfactor.limit`: 범주형 변수의 최대 수준 수 (기본값: 10)
- `design.survey`: 복합표본 설계 객체 (선택적)

#### `timerocModule2(input, output, session, data, data_label, data_varStruct = NULL, nfactor.limit = 10, design.survey = NULL)`
반응형 데이터에 대한 시간의존적 ROC 분석을 수행하는 서버 함수입니다.

**Parameters:**
- 매개변수는 `timerocModule`과 동일하지만 `data`가 reactive 객체

### Helper Functions

#### `timeROChelper(data, event, time, indep.var, time.point, nfactor.limit = 10)`
시간의존적 ROC 분석을 위한 데이터 전처리 및 모델 적합을 수행합니다.

**Parameters:**
- `data`: 분석 데이터
- `event`: 이벤트 변수명
- `time`: 시간 변수명  
- `indep.var`: 독립변수 벡터
- `time.point`: 평가 시점
- `nfactor.limit`: 범주형 변수 제한

#### `timeROC_table(timeROC_result, digit = 3)`
ROC 분석 결과를 테이블 형식으로 정리합니다.

**Parameters:**
- `timeROC_result`: timeROC 분석 결과 객체
- `digit`: 소수점 자릿수 (기본값: 3)

## Usage Examples

### Basic Time-dependent ROC Analysis
```r
library(shiny)
library(jsmodule)
library(survival)
library(timeROC)

# UI
ui <- fluidPage(
  titlePanel("Time-dependent ROC Analysis"),
  sidebarLayout(
    sidebarPanel(
      timerocUI("timeroc_analysis")
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("ROC Curves", 
                 plotOutput("roc_plot", height = "600px")),
        tabPanel("Performance Table", 
                 DTOutput("performance_table")),
        tabPanel("Model Comparison", 
                 DTOutput("comparison_table"))
      )
    )
  )
)

# Server
server <- function(input, output, session) {
  # 생존 데이터 준비
  survival_data <- reactive({
    # lung 데이터셋 사용 예시
    data(lung, package = "survival")
    lung_clean <- lung[complete.cases(lung), ]
    lung_clean$status_binary <- ifelse(lung_clean$status == 2, 1, 0)
    lung_clean
  })
  
  data_labels <- reactive({
    jstable::mk.lev(survival_data())
  })
  
  # ROC 분석 모듈 호출
  roc_results <- callModule(
    timerocModule2, "timeroc_analysis",
    data = survival_data,
    data_label = data_labels
  )
  
  # ROC 곡선 플롯
  output$roc_plot <- renderPlot({
    req(roc_results())
    roc_results()$plot
  })
  
  # 성능 테이블
  output$performance_table <- renderDT({
    req(roc_results())
    roc_results()$table
  }, options = list(scrollX = TRUE))
  
  # 모델 비교 테이블
  output$comparison_table <- renderDT({
    req(roc_results())
    if(!is.null(roc_results()$comparison)) {
      roc_results()$comparison
    }
  })
}

shinyApp(ui, server)
```

### Multiple Time Points Analysis
```r
server <- function(input, output, session) {
  # 다중 시점 분석
  multiple_timepoints <- reactive({
    data <- survival_data()
    
    # 여러 시점에서의 ROC 분석
    time_points <- c(365, 730, 1095)  # 1년, 2년, 3년
    
    results_list <- list()
    for(i in seq_along(time_points)) {
      results_list[[i]] <- timeROChelper(
        data = data,
        event = "status_binary",
        time = "time",
        indep.var = c("age", "sex", "ph.ecog"),
        time.point = time_points[i]
      )
    }
    
    names(results_list) <- paste0("Year_", c(1, 2, 3))
    return(results_list)
  })
  
  # 시점별 AUC 비교 플롯
  output$auc_comparison <- renderPlot({
    req(multiple_timepoints())
    
    auc_values <- sapply(multiple_timepoints(), function(x) x$AUC)
    time_points <- c(1, 2, 3)
    
    plot(time_points, auc_values, 
         type = "b", pch = 19,
         xlab = "Years", ylab = "AUC",
         main = "Time-dependent AUC",
         ylim = c(0.5, 1.0))
    
    abline(h = 0.5, lty = 2, col = "red")  # 기준선
  })
}
```

### Model Comparison Analysis
```r
server <- function(input, output, session) {
  # 모델 비교 분석
  model_comparison <- reactive({
    data <- survival_data()
    
    # 기본 모델 (임상 변수만)
    basic_model <- timeROChelper(
      data = data,
      event = "status_binary", 
      time = "time",
      indep.var = c("age", "sex"),
      time.point = 730
    )
    
    # 확장 모델 (임상 + 검사 변수)
    extended_model <- timeROChelper(
      data = data,
      event = "status_binary",
      time = "time", 
      indep.var = c("age", "sex", "ph.ecog", "ph.karno"),
      time.point = 730
    )
    
    return(list(
      basic = basic_model,
      extended = extended_model
    ))
  })
  
  # 모델 비교 결과
  output$model_comparison <- renderDT({
    req(model_comparison())
    
    basic_auc <- model_comparison()$basic$AUC
    extended_auc <- model_comparison()$extended$AUC
    
    comparison_table <- data.frame(
      Model = c("Basic (Age + Sex)", "Extended (Age + Sex + Performance)"),
      AUC = c(basic_auc, extended_auc),
      `AUC_Lower_CI` = c(
        model_comparison()$basic$AUC.lower,
        model_comparison()$extended$AUC.lower
      ),
      `AUC_Upper_CI` = c(
        model_comparison()$basic$AUC.upper,
        model_comparison()$extended$AUC.upper
      ),
      stringsAsFactors = FALSE
    )
    
    comparison_table
  })
}
```

## Advanced Features

### Subgroup Analysis
```r
server <- function(input, output, session) {
  # 하위그룹별 ROC 분석
  subgroup_analysis <- reactive({
    data <- survival_data()
    
    # 성별에 따른 하위그룹 분석
    male_data <- data[data$sex == 1, ]
    female_data <- data[data$sex == 2, ]
    
    male_roc <- timeROChelper(
      data = male_data,
      event = "status_binary",
      time = "time",
      indep.var = c("age", "ph.ecog"),
      time.point = 730
    )
    
    female_roc <- timeROChelper(
      data = female_data, 
      event = "status_binary",
      time = "time",
      indep.var = c("age", "ph.ecog"),
      time.point = 730
    )
    
    return(list(male = male_roc, female = female_roc))
  })
}
```

### Survey-Weighted Analysis
```r
library(survey)

server <- function(input, output, session) {
  # 복합표본 설계
  survey_design <- reactive({
    data <- survival_data()
    svydesign(
      ids = ~1,
      weights = ~1,  # 실제로는 적절한 가중치 사용
      data = data
    )
  })
  
  # 가중 ROC 분석
  weighted_results <- callModule(
    timerocModule2, "weighted_roc",
    data = survival_data,
    data_label = data_labels,
    design.survey = survey_design
  )
}
```

## Technical Details

### Statistical Methods

#### Time-dependent ROC Curve
시간 t에서의 ROC 곡선은 다음과 같이 정의됩니다:
- **Sensitivity(c,t)**: P(M > c | T ≤ t)
- **Specificity(c,t)**: P(M ≤ c | T > t)

여기서 M은 예측 마커, T는 생존시간, c는 임계값입니다.

#### AUC Calculation
```r
# Cumulative/Dynamic AUC 계산
# Heagerty & Zheng (2005) 방법 사용
AUC(t) = P(M_i > M_j | T_i ≤ t < T_j)
```

#### Performance Metrics
- **Harrell's C-index**: 일치 확률의 전반적 측도
- **AUC(t)**: 시점 t에서의 곡선하면적
- **Brier Score**: 예측 오차의 평균 제곱
- **NRI**: 순재분류개선지수
- **IDI**: 통합판별개선지수

### Model Fitting Process
1. **Cox 모델 적합**: 생존 데이터에 Cox 비례위험모델 적용
2. **위험점수 계산**: 선형 예측자(linear predictor) 추출
3. **시간의존적 ROC**: 특정 시점에서 ROC 곡선 계산
4. **성능 지표**: AUC, C-index, Brier score 계산

### Output Components
반환되는 객체 구조:
```r
list(
  plot = ggplot_roc_curves,          # ROC 곡선 그래프
  table = performance_metrics_table,  # 성능 지표 테이블
  model = cox_model_object,          # 적합된 Cox 모델
  timeROC = timeROC_result_object,   # timeROC 분석 결과
  comparison = model_comparison_table # 모델 비교 테이블 (선택적)
)
```

## Interpretation Guidelines

### AUC Values
- **AUC = 0.5**: 무작위 예측 (예측력 없음)
- **0.5 < AUC < 0.7**: 낮은 예측 정확도
- **0.7 ≤ AUC < 0.8**: 보통 예측 정확도
- **0.8 ≤ AUC < 0.9**: 좋은 예측 정확도
- **AUC ≥ 0.9**: 우수한 예측 정확도

### C-index Values
- **C = 0.5**: 무작위 순위매김
- **C > 0.6**: 실용적으로 유용
- **C > 0.7**: 좋은 판별력
- **C > 0.8**: 우수한 판별력

### Statistical Significance
- **95% 신뢰구간**: AUC의 불확실성 정량화
- **DeLong test**: 두 ROC 곡선 비교
- **P-value < 0.05**: 통계적 유의성

## Dependencies

### Required Packages
```r
library(shiny)          # 웹 애플리케이션 프레임워크
library(survival)       # 생존분석
library(timeROC)        # 시간의존적 ROC 분석
library(survivalROC)    # 생존 ROC 분석
library(DT)             # 대화형 테이블
library(ggplot2)        # 그래프 생성
```

### Optional Packages
```r
library(survC1)         # C-index 계산
library(Hmisc)          # C-index (rcorr.cens)
library(pROC)           # ROC 분석 및 비교
library(riskRegression) # 위험 예측 모델
```

## Performance Considerations

### Memory Management
- 큰 데이터셋: 필요한 변수만 선택
- 시간 범위: 적절한 평가 시점 선택
- 그래프 렌더링: 해상도 최적화

### Computational Efficiency
- **Bootstrap 횟수**: 신뢰구간 계산 시 적절한 반복수 설정
- **시점 선택**: 과도한 시점 분석 피하기
- **모델 복잡도**: 변수 수와 샘플 크기 균형

## Error Handling

### Common Issues
1. **수렴 실패**: Cox 모델 적합 실패
2. **시점 오류**: 관측 범위를 벗어난 시점 설정
3. **데이터 부족**: 특정 시점에서 이벤트 부족
4. **공변량 문제**: 다중공선성, 결측값

### Validation Checks
- 이벤트 및 시간 변수 유효성
- 시점 설정의 적절성
- 모델 적합도 진단
- 예측 성능의 통계적 유의성

## Clinical Applications

### Prognostic Model Validation
- 기존 예후 점수의 검증
- 새로운 바이오마커 평가
- 임상 의사결정 도구 개발

### Biomarker Evaluation
- 시간에 따른 마커 성능 변화
- 다중 마커 조합 효과
- 최적 임계값 결정

## Version Notes
이 문서는 jsmodule 패키지의 시간의존적 ROC 분석 모듈을 기반으로 작성되었습니다. 최신 버전에서는 추가 기능이나 매개변수 변경이 있을 수 있습니다.