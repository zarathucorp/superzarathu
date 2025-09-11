# regress Documentation

## Overview
`regress.R`은 jsmodule 패키지의 회귀분석을 위한 Shiny 모듈 모음입니다. 선형회귀분석을 위한 `regressModule2`와 로지스틱회귀분석을 위한 `logisticModule2`를 제공하며, 복합표본조사 데이터 분석, 단변량 사전선택, 하위그룹 분석 등 고급 통계분석 기능을 지원합니다.

## Module Components

### UI Functions

#### `regressModuleUI(id)`
선형회귀분석을 위한 사용자 인터페이스를 생성합니다.

**Parameters:**
- `id`: 모듈의 고유 식별자 (문자열)

**UI Elements:**
- 종속변수 선택기
- 독립변수 선택기 (다중선택 지원)
- 소수점 자릿수 설정 (1-4자리)
- 하위그룹 분석 체크박스
- P-value 필터링 체크박스

#### `logisticModuleUI(id)`
로지스틱회귀분석을 위한 사용자 인터페이스를 생성합니다.

**Parameters:**
- `id`: 모듈의 고유 식별자 (문자열)

**UI Elements:**
- 이진 종속변수 선택기
- 독립변수 선택기
- 통계 옵션 설정
- 분석 결과 표시 옵션

### Server Functions

#### `regressModule2(input, output, session, data, data_label, data_varStruct = NULL, nfactor.limit = 10, design.survey = NULL, default.unires = T, limit.unires = 20, vec.event = NULL)`
선형회귀분석을 수행하는 서버 함수입니다.

**Parameters:**
- `input`, `output`, `session`: Shiny 서버 매개변수
- `data`: 분석할 데이터셋 (reactive)
- `data_label`: 변수 라벨 정보 (reactive)
- `data_varStruct`: 변수 구조 리스트 (선택적)
- `nfactor.limit`: 범주형 변수의 최대 수준 수 (기본값: 10)
- `design.survey`: 복합표본 설계 객체 (선택적)
- `default.unires`: 단변량 분석 기본 사용 여부 (기본값: TRUE)
- `limit.unires`: 기본 선택 변수 최대 개수 (기본값: 20)
- `vec.event`: 이벤트 변수 벡터 (선택적)

**Features:**
- 일반 및 복합표본조사 데이터 지원
- 자동 변수 선택 및 단계별 회귀
- 하위그룹별 분석
- 모델 진단 및 검정
- 결과 테이블 및 캡션 생성

#### `logisticModule2(input, output, session, data, data_label, data_varStruct = NULL, nfactor.limit = 10, design.survey = NULL, default.unires = T, limit.unires = 20, vec.event = NULL)`
로지스틱회귀분석을 수행하는 서버 함수입니다.

**Parameters:**
- 매개변수는 `regressModule2`와 동일

**Features:**
- 이진 분류 모델링
- 오즈비(Odds Ratio) 계산
- 모델 적합도 검정
- ROC 분석 지원

## Usage Examples

### Basic Linear Regression
```r
library(shiny)
library(jsmodule)
library(DT)

# UI
ui <- fluidPage(
  titlePanel("Linear Regression Analysis"),
  sidebarLayout(
    sidebarPanel(
      regressModuleUI("linear_reg")
    ),
    mainPanel(
      DTOutput("regression_table"),
      wellPanel(
        h5("Model Summary"),
        textOutput("regression_caption")
      )
    )
  )
)

# Server
server <- function(input, output, session) {
  # 데이터 준비
  data <- reactive({
    mtcars
  })
  
  data_label <- reactive({
    jstable::mk.lev(mtcars)
  })
  
  # 회귀분석 모듈 호출
  regression_results <- callModule(
    regressModule2, "linear_reg",
    data = data,
    data_label = data_label
  )
  
  # 결과 출력
  output$regression_table <- renderDT({
    regression_results()$table
  }, options = list(scrollX = TRUE))
  
  output$regression_caption <- renderText({
    regression_results()$caption
  })
}

shinyApp(ui, server)
```

### Basic Logistic Regression
```r
# UI
ui <- fluidPage(
  titlePanel("Logistic Regression Analysis"),
  sidebarLayout(
    sidebarPanel(
      logisticModuleUI("logistic_reg")
    ),
    mainPanel(
      DTOutput("logistic_table"),
      wellPanel(
        h5("Model Summary"),
        textOutput("logistic_caption")
      )
    )
  )
)

# Server
server <- function(input, output, session) {
  # 이진 결과 데이터 준비
  data <- reactive({
    mtcars$vs_binary <- factor(mtcars$vs, levels = c(0, 1), labels = c("V-shaped", "Straight"))
    mtcars
  })
  
  data_label <- reactive({
    jstable::mk.lev(data())
  })
  
  # 로지스틱 회귀분석 모듈 호출
  logistic_results <- callModule(
    logisticModule2, "logistic_reg",
    data = data,
    data_label = data_label
  )
  
  # 결과 출력
  output$logistic_table <- renderDT({
    logistic_results()$table
  })
  
  output$logistic_caption <- renderText({
    logistic_results()$caption
  })
}

shinyApp(ui, server)
```

### Survey-Weighted Analysis
```r
library(survey)

server <- function(input, output, session) {
  # 복합표본 데이터 준비
  data <- reactive({
    # NHANES 스타일 데이터 예시
    data.frame(
      id = 1:1000,
      strata = sample(1:10, 1000, replace = TRUE),
      weights = runif(1000, 0.5, 2.0),
      outcome = rnorm(1000),
      age = sample(18:80, 1000, replace = TRUE),
      gender = sample(c("M", "F"), 1000, replace = TRUE)
    )
  })
  
  # 복합표본 설계 정의
  design <- reactive({
    svydesign(
      ids = ~1,
      strata = ~strata, 
      weights = ~weights,
      data = data()
    )
  })
  
  data_label <- reactive({
    jstable::mk.lev(data())
  })
  
  # 가중 회귀분석
  weighted_results <- callModule(
    regressModule2, "weighted_reg",
    data = data,
    data_label = data_label,
    design.survey = design
  )
}
```

## Advanced Features

### Variable Selection with Univariate Pre-screening
```r
server <- function(input, output, session) {
  # 단변량 사전선택 활성화
  results <- callModule(
    regressModule2, "advanced_reg",
    data = data,
    data_label = data_label,
    default.unires = TRUE,      # 단변량 사전선택 사용
    limit.unires = 15          # 최대 15개 변수까지 선택
  )
}
```

### Factor Level Limitation
```r
server <- function(input, output, session) {
  # 범주형 변수 수준 제한
  results <- callModule(
    regressModule2, "limited_reg",
    data = data,
    data_label = data_label,
    nfactor.limit = 5          # 최대 5개 수준까지만 허용
  )
}
```

### Variable Structure Specification
```r
server <- function(input, output, session) {
  # 변수 구조 정의
  var_struct <- reactive({
    list(
      continuous = c("age", "weight", "height"),
      categorical = c("gender", "treatment_group"),
      ordinal = c("education_level", "income_bracket")
    )
  })
  
  results <- callModule(
    regressModule2, "structured_reg",
    data = data,
    data_label = data_label,
    data_varStruct = var_struct
  )
}
```

### Event Variable Handling
```r
server <- function(input, output, session) {
  # 특별 처리가 필요한 변수들
  event_variables <- reactive(c("baseline_measurement", "treatment_start"))
  
  results <- callModule(
    regressModule2, "event_reg",
    data = data,
    data_label = data_label,
    vec.event = event_variables
  )
}
```

## Technical Details

### Statistical Methods

#### Linear Regression
```r
# 내부적으로 사용되는 모델
lm(formula = dependent ~ independent_vars, data = data)

# 또는 복합표본의 경우
survey::svyglm(formula = dependent ~ independent_vars, 
                design = survey_design, 
                family = gaussian())
```

#### Logistic Regression
```r
# 일반 로지스틱 회귀
glm(formula = dependent ~ independent_vars, 
    data = data, 
    family = binomial())

# 복합표본 로지스틱 회귀
survey::svyglm(formula = dependent ~ independent_vars, 
                design = survey_design, 
                family = binomial())
```

### Model Selection Process
1. **단변량 스크리닝**: P-value < 0.2 기준
2. **다중공선성 검사**: VIF < 10 기준  
3. **단계별 선택**: AIC 기준 전진/후진/단계별 선택
4. **모델 진단**: 잔차 분석, 영향점 검사

### Output Components
반환되는 객체 구조:
```r
list(
  table = DT_formatted_table,      # 결과 테이블
  caption = model_description,      # 모델 설명
  model = fitted_model,            # 적합된 모델 객체 (선택적)
  diagnostics = diagnostic_plots   # 진단 그래프 (선택적)
)
```

## Model Diagnostics

### Linear Regression Diagnostics
- **Residual plots**: 등분산성 검사
- **Q-Q plots**: 정규성 검사  
- **Leverage plots**: 영향점 식별
- **Cook's distance**: 이상치 탐지

### Logistic Regression Diagnostics
- **ROC curve**: 모델 판별력
- **Hosmer-Lemeshow test**: 적합도 검정
- **Residual deviance**: 모델 적합도
- **Pseudo R-squared**: 설명력 지표

## Dependencies

### Required Packages
```r
library(shiny)          # 웹 애플리케이션 프레임워크
library(DT)             # 대화형 테이블
library(data.table)     # 데이터 조작
library(survey)         # 복합표본 분석
library(stats)          # 기본 통계 함수
library(purrr)          # 함수형 프로그래밍
library(jstable)        # 테이블 생성 유틸리티
```

### Optional Packages
```r
library(car)            # 회귀진단 (VIF, etc.)
library(MASS)           # 고급 통계 방법
library(broom)          # 모델 결과 정리
```

## Performance Considerations

### Memory Management
- 큰 데이터셋: 필요한 변수만 선택
- 복합표본: 설계 객체 효율적 관리
- 모델 객체: 불필요한 저장 방지

### Computational Efficiency
- **변수 사전선택**: 계산 시간 단축
- **범주형 변수 제한**: 메모리 사용량 감소
- **점진적 모델링**: 단계별 복잡도 증가

## Error Handling

### Common Issues
1. **완전분리**: 로지스틱 회귀에서 발생 가능
2. **다중공선성**: 높은 VIF 값 처리
3. **수렴 실패**: 모델 복잡도 조정
4. **데이터 불균형**: 표본 크기 불충분

### Validation Checks
- 입력 데이터 형식 검증
- 종속변수 타입 확인
- 결측값 처리 방법 검증
- 모델 수렴성 검사

## Version Notes
이 문서는 jsmodule 패키지의 회귀분석 모듈을 기반으로 작성되었습니다. 최신 버전에서는 추가 기능이나 매개변수 변경이 있을 수 있습니다.