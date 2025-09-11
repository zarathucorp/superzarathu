# gee Documentation

## Overview
`gee.R`은 jsmodule 패키지의 일반화추정방정식(Generalized Estimating Equation, GEE) 분석을 위한 Shiny 모듈입니다. 반복측정 데이터나 군집화된 데이터에서 상관구조를 고려한 회귀분석을 수행할 수 있으며, 연속형 종속변수를 위한 선형 GEE와 이진형 종속변수를 위한 로지스틱 GEE 모듈을 제공합니다.

## Module Components

### UI Functions

#### `GEEModuleUI(id)`
GEE 분석을 위한 사용자 인터페이스를 생성합니다.

**Parameters:**
- `id`: 모듈의 고유 식별자 (문자열)

**UI Elements:**
- 종속변수 선택기 (selectInput)
- 독립변수 선택기 (selectizeInput)
- 소수점 자릿수 설정 슬라이더 (1-4자리)
- 하위그룹 분석 옵션 체크박스
- P-value 필터링 옵션 체크박스

### Server Functions

#### `GEEModuleLinear(input, output, session, data, data_label, id.gee, vec.event = NULL)`
연속형 종속변수를 위한 선형 GEE 분석을 수행하는 서버 함수입니다.

**Parameters:**
- `input`, `output`, `session`: Shiny 서버 매개변수
- `data`: 분석할 데이터셋 (reactive)
- `data_label`: 변수 라벨 정보 (reactive)
- `id.gee`: 반복측정 식별자 변수 (reactive)
- `vec.event`: 이벤트 변수 벡터 (선택적)

**Features:**
- 반응형 데이터 처리
- 하위그룹별 분석 지원
- 유연한 변수 선택
- 자동 통계 테이블 생성
- 결과 캡션 생성

#### `GEEModuleLogistic(input, output, session, data, data_label, id.gee, vec.event = NULL)`
이진형 종속변수를 위한 로지스틱 GEE 분석을 수행하는 서버 함수입니다.

**Parameters:**
- 매개변수는 `GEEModuleLinear`와 동일

**Features:**
- 이진 분류 결과 분석
- 오즈비(Odds Ratio) 계산
- 로지스틱 회귀 기반 GEE 모델링

## Usage Examples

### Basic Linear GEE Analysis
```r
library(shiny)
library(jsmodule)

# UI
ui <- fluidPage(
  sidebarLayout(
    sidebarPanel(
      GEEModuleUI("linear_gee")
    ),
    mainPanel(
      DTOutput("linear_table"),
      wellPanel(
        h5("Caption"),
        textOutput("linear_caption")
      )
    )
  )
)

# Server
server <- function(input, output, session) {
  # 데이터 준비
  data <- reactive({
    # 반복측정 데이터 예시
    data.table::as.data.table(
      expand.grid(
        id = 1:50,
        time = 1:4
      )
    )[, value := rnorm(.N, mean = 10 + 0.5 * time, sd = 2)]
  })
  
  data_label <- reactive({
    jstable::mk.lev(data())
  })
  
  id_gee <- reactive("id")
  
  # GEE 모듈 호출
  linear_results <- callModule(
    GEEModuleLinear, "linear_gee",
    data = data,
    data_label = data_label,
    id.gee = id_gee
  )
  
  # 결과 출력
  output$linear_table <- renderDT({
    linear_results()$table
  })
  
  output$linear_caption <- renderText({
    linear_results()$caption
  })
}

shinyApp(ui, server)
```

### Basic Logistic GEE Analysis
```r
# UI (동일한 구조)
ui <- fluidPage(
  sidebarLayout(
    sidebarPanel(
      GEEModuleUI("logistic_gee")
    ),
    mainPanel(
      DTOutput("logistic_table"),
      wellPanel(
        h5("Caption"),
        textOutput("logistic_caption")
      )
    )
  )
)

# Server
server <- function(input, output, session) {
  # 이진 결과 데이터 준비
  data <- reactive({
    data.table::as.data.table(
      expand.grid(
        id = 1:100,
        time = 1:3
      )
    )[, outcome := rbinom(.N, 1, 0.3 + 0.1 * time)]
  })
  
  data_label <- reactive({
    jstable::mk.lev(data())
  })
  
  id_gee <- reactive("id")
  
  # 로지스틱 GEE 모듈 호출
  logistic_results <- callModule(
    GEEModuleLogistic, "logistic_gee",
    data = data,
    data_label = data_label,
    id.gee = id_gee
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

## Advanced Features

### Subgroup Analysis
```r
# 하위그룹 분석이 활성화된 경우
server <- function(input, output, session) {
  data <- reactive({
    # 그룹 변수가 포함된 데이터
    dt <- data.table::as.data.table(
      expand.grid(
        id = 1:60,
        time = 1:4,
        group = c("A", "B", "C")
      )
    )
    dt[, outcome := rnorm(.N, mean = ifelse(group == "A", 12, 10), sd = 2)]
    return(dt)
  })
  
  # 모듈에서 자동으로 하위그룹별 분석 수행
}
```

### Event Variable Handling
```r
server <- function(input, output, session) {
  # 이벤트 변수 정의
  event_vars <- reactive(c("treatment", "baseline_score"))
  
  # GEE 모듈에 이벤트 변수 전달
  results <- callModule(
    GEEModuleLinear, "gee_analysis",
    data = data,
    data_label = data_label,
    id.gee = id_gee,
    vec.event = event_vars
  )
}
```

### Custom P-value Filtering
```r
# UI에서 P-value 필터 옵션을 체크하면
# 자동으로 유의한 결과만 표시
# (p < 0.05 기준)
```

## Technical Details

### Statistical Method
- **GEE 모델**: 반복측정/군집 데이터의 상관구조를 고려
- **상관구조**: 독립(independence), 교환가능(exchangeable), AR(1) 등
- **링크함수**: 
  - 선형: identity link
  - 로지스틱: logit link

### Model Specification
```r
# 내부적으로 사용되는 GEE 모델 형태
geepack::geeglm(
  formula = dependent_var ~ independent_vars,
  data = data,
  id = cluster_id,
  family = family_specification,
  corstr = "independence"  # 기본값
)
```

### Output Format
반환되는 객체는 다음을 포함합니다:
- `$table`: DT 형식의 결과 테이블
- `$caption`: 분석 결과에 대한 텍스트 설명
- 계수 추정값, 표준오차, 신뢰구간, P-값 포함

## Dependencies

### Required Packages
```r
library(shiny)          # 웹 애플리케이션 프레임워크
library(DT)             # 대화형 테이블
library(data.table)     # 데이터 조작
library(geepack)        # GEE 분석
library(jstable)        # 테이블 생성 유틸리티
```

### System Requirements
- R >= 3.6.0
- 충분한 메모리 (큰 데이터셋의 경우)

## Error Handling

### Common Issues
1. **반복측정 ID 누락**: `id.gee` 매개변수 필수 확인
2. **데이터 타입 불일치**: 종속변수와 모델 타입 일치 확인
3. **수렴 실패**: 모델 복잡도 조정 필요

### Validation
- 입력 데이터 형식 자동 검증
- 변수 선택 유효성 확인
- 모델 수렴성 검사

## Performance Considerations

### Optimization Tips
- 큰 데이터셋: 필요한 변수만 선택
- 복잡한 모델: 단계별 변수 추가
- 메모리 관리: 중간 결과 정리

### Scalability
- 반복측정 수: 수천 개 관측치까지 처리 가능
- 변수 수: 수십 개 독립변수 처리 가능
- 그룹 수: 수백 개 하위그룹 분석 가능

## Version Notes
이 문서는 jsmodule 패키지의 GEE 모듈을 기반으로 작성되었습니다. 최신 버전에서는 추가 기능이나 매개변수 변경이 있을 수 있습니다.