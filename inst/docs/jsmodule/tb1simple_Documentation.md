# tb1simple Documentation

## Overview
`tb1simple.R`은 jsmodule 패키지의 성향점수분석(Propensity Score Analysis)을 위한 간단한 비교표 생성 Shiny 모듈입니다. 원본 데이터, 성향점수 매칭 데이터, 역확률가중(IPTW) 데이터에 대한 기술통계표를 생성하여 치료효과 분석에서 그룹 간 균형성을 평가할 수 있습니다.

## Module Components

### UI Functions

#### `tb1simpleUI(id)`
성향점수분석을 위한 간단한 비교표 UI를 생성합니다.

**Parameters:**
- `id`: 모듈의 고유 식별자 (문자열)

**UI Elements:**
- 테이블 유형 선택기 (원본/매칭/IPTW)
- 포함할 변수 선택기 (다중선택)
- 소수점 자릿수 설정 (1-4자리)
- 모든 수준 표시 체크박스
- 표준화평균차이(SMD) 표시 옵션

### Server Functions

#### `tb1simple(input, output, session, data, matdata = data, data_label, group_var, showAllLevels = T)`
정적 데이터에 대한 성향점수 비교표를 생성하는 서버 함수입니다.

**Parameters:**
- `input`, `output`, `session`: Shiny 서버 매개변수
- `data`: 원본 데이터셋 (data.frame)
- `matdata`: 매칭된 데이터셋 (기본값: data와 동일)
- `data_label`: 변수 라벨 정보
- `group_var`: 그룹(치료) 변수명
- `showAllLevels`: 모든 범주형 수준 표시 여부 (기본값: TRUE)

#### `tb1simple2(input, output, session, data, matdata = data, data_label, group_var, showAllLevels = T)`
반응형 데이터에 대한 성향점수 비교표를 생성하는 서버 함수입니다.

**Parameters:**
- 매개변수는 `tb1simple`과 동일하지만 `data`와 `matdata`가 reactive 객체

**Features:**
- 실시간 데이터 업데이트
- 동적 변수 선택
- 다중 테이블 동시 생성

## Usage Examples

### Basic Propensity Score Analysis Table
```r
library(shiny)
library(jsmodule)
library(DT)

# UI
ui <- fluidPage(
  titlePanel("Propensity Score Analysis Tables"),
  sidebarLayout(
    sidebarPanel(
      # 파일 입력 모듈
      FilePsInput("ps_data"),
      hr(),
      # 테이블 설정
      tb1simpleUI("ps_table")
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Original Data", 
                 DTOutput("original_table"),
                 textOutput("original_caption")),
        tabPanel("PS Matched", 
                 DTOutput("matched_table"),
                 textOutput("matched_caption")),
        tabPanel("IPTW", 
                 DTOutput("iptw_table"),
                 textOutput("iptw_caption"))
      )
    )
  )
)

# Server
server <- function(input, output, session) {
  # 파일 입력 처리
  ps_data_input <- callModule(FilePsInput, "ps_data")
  
  # 원본 데이터
  original_data <- reactive({
    ps_data_input$data()
  })
  
  # 매칭 데이터 (예시)
  matched_data <- reactive({
    # 실제로는 MatchIt, optmatch 등을 사용하여 매칭
    # 여기서는 예시로 동일 데이터 사용
    original_data()
  })
  
  # 라벨 정보
  data_labels <- reactive({
    jstable::mk.lev(original_data())
  })
  
  # 그룹 변수
  group_variable <- reactive("treatment")  # 치료변수명
  
  # 테이블 생성 모듈 호출
  table_results <- callModule(
    tb1simple2, "ps_table",
    data = original_data,
    matdata = matched_data,
    data_label = data_labels,
    group_var = group_variable
  )
  
  # 결과 출력
  output$original_table <- renderDT({
    table_results()$original$table
  })
  
  output$matched_table <- renderDT({
    table_results()$matched$table
  })
  
  output$iptw_table <- renderDT({
    table_results()$iptw$table
  })
  
  output$original_caption <- renderText({
    table_results()$original$caption
  })
  
  output$matched_caption <- renderText({
    table_results()$matched$caption
  })
  
  output$iptw_caption <- renderText({
    table_results()$iptw$caption
  })
}

shinyApp(ui, server)
```

### Real Propensity Score Matching Example
```r
library(MatchIt)
library(WeightIt)

server <- function(input, output, session) {
  # 원본 데이터 준비
  original_data <- reactive({
    # 실제 관찰 연구 데이터 예시
    data.frame(
      id = 1:1000,
      treatment = rbinom(1000, 1, 0.4),
      age = rnorm(1000, 50, 15),
      gender = sample(c("M", "F"), 1000, replace = TRUE),
      income = rlnorm(1000, 10, 0.5),
      education = sample(1:4, 1000, replace = TRUE),
      outcome = rnorm(1000, 100, 20)
    )
  })
  
  # 성향점수 매칭 수행
  matched_data <- reactive({
    # MatchIt을 사용한 1:1 매칭
    match_result <- matchit(
      treatment ~ age + gender + income + education,
      data = original_data(),
      method = "nearest",
      ratio = 1
    )
    
    # 매칭된 데이터 추출
    match.data(match_result)
  })
  
  # IPTW 가중치 계산
  weighted_data <- reactive({
    # WeightIt을 사용한 역확률가중
    weight_result <- weightit(
      treatment ~ age + gender + income + education,
      data = original_data(),
      method = "ps",
      estimand = "ATT"
    )
    
    # 가중치가 추가된 데이터
    data_with_weights <- original_data()
    data_with_weights$weights <- weight_result$weights
    return(data_with_weights)
  })
  
  data_labels <- reactive({
    jstable::mk.lev(original_data())
  })
  
  # 비교표 생성
  comparison_results <- callModule(
    tb1simple2, "comparison",
    data = original_data,
    matdata = matched_data,
    data_label = data_labels,
    group_var = reactive("treatment")
  )
}
```

## Advanced Features

### Standardized Mean Difference (SMD)
```r
# SMD 계산이 포함된 테이블
server <- function(input, output, session) {
  # SMD 값이 자동으로 계산되어 테이블에 포함
  # |SMD| < 0.1: 우수한 균형
  # |SMD| < 0.25: 허용 가능한 균형  
  # |SMD| >= 0.25: 불균형
  
  results <- callModule(
    tb1simple2, "smd_table",
    data = data,
    matdata = matched_data,
    data_label = data_label,
    group_var = group_var
  )
  
  # 결과에 SMD 열이 자동으로 포함됨
}
```

### Custom Variable Selection
```r
server <- function(input, output, session) {
  # 특정 변수들만 포함하는 테이블
  custom_data <- reactive({
    original_data()[, c("treatment", "age", "gender", "outcome")]
  })
  
  results <- callModule(
    tb1simple2, "custom_table",
    data = custom_data,
    matdata = custom_data,  # 매칭이 없는 경우
    data_label = data_label,
    group_var = reactive("treatment")
  )
}
```

### Multiple Treatment Groups
```r
server <- function(input, output, session) {
  # 다중 치료군 데이터
  multi_treatment_data <- reactive({
    data.frame(
      id = 1:600,
      treatment = sample(c("Control", "Treatment A", "Treatment B"), 
                        600, replace = TRUE),
      age = rnorm(600, 45, 12),
      outcome = rnorm(600, 80, 15)
    )
  })
  
  # 3군 비교 테이블
  multi_results <- callModule(
    tb1simple2, "multi_treatment",
    data = multi_treatment_data,
    data_label = reactive(jstable::mk.lev(multi_treatment_data())),
    group_var = reactive("treatment")
  )
}
```

## Technical Details

### Statistical Methods

#### Balance Assessment
- **연속형 변수**: 표준화평균차이(SMD), t-test
- **범주형 변수**: 표준화평균차이(SMD), Chi-square test
- **SMD 계산**: (mean1 - mean2) / pooled_sd

#### Statistical Tests
```r
# 연속형 변수 (정규성 확인 후)
# 정규분포: t.test()
# 비정규분포: wilcox.test()

# 범주형 변수  
# 기대빈도 >= 5: chisq.test()
# 기대빈도 < 5: fisher.test()
```

### Output Structure
각 테이블 타입별 결과 구조:
```r
list(
  original = list(
    table = DT_formatted_table,
    caption = "Original data comparison"
  ),
  matched = list(
    table = DT_formatted_table,
    caption = "Propensity score matched data comparison"
  ),
  iptw = list(
    table = DT_formatted_table,
    caption = "IPTW weighted data comparison"
  )
)
```

### Table Format Example
```r
# 결과 테이블 구조
Variable        | Control      | Treatment    | SMD    | p-value
Age (mean±SD)   | 45.2±12.3   | 47.1±11.8   | 0.156  | 0.023
Gender (%)      |             |              | 0.089  | 0.234  
  Male          | 125 (62.5%) | 130 (65.0%)  |        |
  Female        | 75 (37.5%)  | 70 (35.0%)   |        |
```

## Quality Assessment

### Balance Criteria
- **SMD < 0.1**: 우수한 균형 (excellent balance)
- **SMD < 0.25**: 허용 가능한 균형 (acceptable balance)  
- **SMD ≥ 0.25**: 심각한 불균형 (serious imbalance)

### Matching Success Evaluation
```r
# 매칭 전후 비교
balance_assessment <- function(original_smd, matched_smd) {
  improvement <- abs(original_smd) - abs(matched_smd)
  percent_improvement <- (improvement / abs(original_smd)) * 100
  
  return(list(
    improvement = improvement,
    percent_improvement = percent_improvement,
    success = abs(matched_smd) < 0.1
  ))
}
```

## Dependencies

### Required Packages
```r
library(shiny)          # 웹 애플리케이션 프레임워크
library(DT)             # 대화형 테이블
library(data.table)     # 데이터 조작
library(jstable)        # 통계 테이블 생성
```

### Optional Packages for PS Analysis
```r
library(MatchIt)        # 성향점수 매칭
library(WeightIt)       # 역확률가중
library(optmatch)       # 최적 매칭
library(twang)          # 성향점수 추정
library(survey)         # 가중 분석
```

## Performance Considerations

### Memory Management
- 큰 데이터셋: 필요한 변수만 선택
- 매칭 결과: 임시 객체 정리
- 테이블 렌더링: 페이징 사용

### Computational Efficiency
- **캐싱**: 반복 계산 방지
- **지연 계산**: 필요시에만 테이블 생성
- **병렬 처리**: 다중 테이블 동시 생성

## Error Handling

### Common Issues
1. **그룹 불균형**: 극단적인 그룹 크기 차이
2. **변수 타입**: 예상과 다른 데이터 타입
3. **매칭 실패**: 공통 지지 부족
4. **가중치 극값**: 매우 큰 또는 작은 가중치

### Validation Checks
- 그룹 변수 존재 확인
- 데이터 타입 검증
- SMD 계산 가능성 확인
- 통계검정 적용 조건 검증

## Best Practices

### Reporting Guidelines
1. **원본 데이터**: 매칭/가중 전 불균형 확인
2. **매칭 후**: 균형 개선도 평가
3. **IPTW**: 극단적 가중치 검사
4. **SMD**: 모든 변수에서 < 0.1 목표

### Quality Control
```r
# 균형 평가 체크리스트
balance_check <- function(smd_values) {
  excellent <- sum(abs(smd_values) < 0.1)
  acceptable <- sum(abs(smd_values) < 0.25)
  problematic <- sum(abs(smd_values) >= 0.25)
  
  cat("Balance Assessment:\n")
  cat("Excellent balance (SMD < 0.1):", excellent, "variables\n")
  cat("Acceptable balance (SMD < 0.25):", acceptable, "variables\n") 
  cat("Problematic balance (SMD >= 0.25):", problematic, "variables\n")
}
```

## Version Notes
이 문서는 jsmodule 패키지의 성향점수분석용 간단한 비교표 모듈을 기반으로 작성되었습니다. 최신 버전에서는 추가 기능이나 매개변수 변경이 있을 수 있습니다.