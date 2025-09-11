# tb1 Documentation

## Overview
`tb1.R`은 jsmodule 패키지의 기술통계표(Table 1) 생성을 위한 Shiny 모듈입니다. 의학 및 보건 연구에서 흔히 사용되는 "Table 1"을 생성하며, 연속형과 범주형 변수의 기술통계, 그룹별 비교, 통계적 검정, 복합표본조사 데이터 지원 등의 기능을 제공합니다.

## Module Components

### UI Functions

#### `tb1moduleUI(id)`
Table 1 생성을 위한 사용자 인터페이스를 생성합니다.

**Parameters:**
- `id`: 모듈의 고유 식별자 (문자열)

**UI Elements:**
- 그룹 변수 선택기 (선택적)
- 포함할 변수 선택기 (다중선택)
- 소수점 자릿수 설정 (0-4자리)
- 모든 수준 표시 체크박스
- 통계검정 포함 체크박스
- Fisher 정확검정 옵션

### Server Functions

#### `tb1module(input, output, session, data, data_label, data_varStruct = NULL, nfactor.limit = 10, design.survey = NULL, showAllLevels = T, argsExact = list(workspace = 2e+05))`
정적 데이터에 대한 Table 1을 생성하는 서버 함수입니다.

**Parameters:**
- `input`, `output`, `session`: Shiny 서버 매개변수
- `data`: 분석할 데이터셋 (data.frame)
- `data_label`: 변수 라벨 정보
- `data_varStruct`: 변수 구조 리스트 (선택적)
- `nfactor.limit`: 범주형 변수의 최대 수준 수 (기본값: 10)
- `design.survey`: 복합표본 설계 객체 (선택적)
- `showAllLevels`: 모든 범주형 수준 표시 여부 (기본값: TRUE)
- `argsExact`: Fisher 정확검정 매개변수 (기본값: list(workspace = 2e+05))

#### `tb1module2(input, output, session, data, data_label, data_varStruct = NULL, nfactor.limit = 10, design.survey = NULL, showAllLevels = T, argsExact = list(workspace = 2e+05))`
반응형 데이터에 대한 Table 1을 생성하는 서버 함수입니다.

**Parameters:**
- 매개변수는 `tb1module`과 동일하지만 `data`가 reactive 객체

**Features:**
- 실시간 데이터 업데이트 반영
- 동적 변수 선택
- 반응형 테이블 생성

## Usage Examples

### Basic Table 1
```r
library(shiny)
library(jsmodule)
library(DT)

# UI
ui <- fluidPage(
  titlePanel("Descriptive Statistics Table"),
  sidebarLayout(
    sidebarPanel(
      tb1moduleUI("table1")
    ),
    mainPanel(
      DTOutput("desc_table"),
      wellPanel(
        h5("Table Caption"),
        textOutput("table_caption")
      )
    )
  )
)

# Server
server <- function(input, output, session) {
  # 데이터 준비
  data <- reactive({
    mtcars$vs <- factor(mtcars$vs, levels = c(0, 1), 
                       labels = c("V-shaped", "Straight"))
    mtcars$am <- factor(mtcars$am, levels = c(0, 1), 
                       labels = c("Automatic", "Manual"))
    mtcars
  })
  
  data_label <- reactive({
    jstable::mk.lev(data())
  })
  
  # Table 1 모듈 호출
  table1_results <- callModule(
    tb1module2, "table1",
    data = data,
    data_label = data_label
  )
  
  # 결과 출력
  output$desc_table <- renderDT({
    table1_results()$table
  }, options = list(scrollX = TRUE))
  
  output$table_caption <- renderText({
    table1_results()$caption
  })
}

shinyApp(ui, server)
```

### Stratified Analysis by Group
```r
# Server with grouping
server <- function(input, output, session) {
  # 그룹 변수가 있는 데이터 준비
  data <- reactive({
    iris$Species_Group <- factor(iris$Species)
    iris
  })
  
  data_label <- reactive({
    jstable::mk.lev(data())
  })
  
  # 그룹별 비교 테이블
  grouped_results <- callModule(
    tb1module2, "grouped_table",
    data = data,
    data_label = data_label
  )
  
  # 결과에 자동으로 그룹별 통계와 p-값 포함
}
```

### Survey-Weighted Table 1
```r
library(survey)

server <- function(input, output, session) {
  # 복합표본 데이터 준비
  data <- reactive({
    data.frame(
      id = 1:500,
      strata = sample(1:5, 500, replace = TRUE),
      weights = runif(500, 0.5, 3.0),
      age = rnorm(500, 45, 15),
      gender = sample(c("Male", "Female"), 500, replace = TRUE),
      treatment = sample(c("A", "B", "C"), 500, replace = TRUE),
      outcome = rbinom(500, 1, 0.3)
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
  
  # 가중 기술통계표
  weighted_results <- callModule(
    tb1module2, "weighted_table",
    data = data,
    data_label = data_label,
    design.survey = design
  )
}
```

## Advanced Features

### Variable Structure Definition
```r
server <- function(input, output, session) {
  # 변수 유형 구조 정의
  var_structure <- reactive({
    list(
      continuous = c("age", "weight", "height", "bmi"),
      categorical = c("gender", "treatment_group", "education"),
      binary = c("diabetes", "hypertension", "smoking")
    )
  })
  
  results <- callModule(
    tb1module2, "structured_table",
    data = data,
    data_label = data_label,
    data_varStruct = var_structure
  )
}
```

### Custom Factor Level Limits
```r
server <- function(input, output, session) {
  # 범주형 변수 수준 제한
  results <- callModule(
    tb1module2, "limited_table",
    data = data,
    data_label = data_label,
    nfactor.limit = 6,          # 최대 6개 수준까지만 허용
    showAllLevels = FALSE       # 기준 범주 제외 옵션
  )
}
```

### Custom Statistical Tests
```r
server <- function(input, output, session) {
  # Fisher 정확검정 설정 사용자화
  custom_exact_args <- list(
    workspace = 5e+05,          # 더 큰 작업공간
    hybrid = TRUE,              # 하이브리드 방법 사용
    simulate.p.value = TRUE,    # p-값 시뮬레이션
    B = 10000                   # 몬테카를로 반복 수
  )
  
  results <- callModule(
    tb1module2, "custom_test_table",
    data = data,
    data_label = data_label,
    argsExact = custom_exact_args
  )
}
```

## Technical Details

### Statistical Methods

#### Continuous Variables
- **중심경향성**: 평균, 중앙값
- **변산성**: 표준편차, 사분위범위
- **분포**: 왜도, 첨도 (선택적)
- **검정**: t-test, ANOVA, Kruskal-Wallis

#### Categorical Variables  
- **빈도**: 절대빈도, 상대빈도(%)
- **검정**: Chi-square test, Fisher exact test
- **연관성**: Cramer's V, Phi coefficient

#### Statistical Tests Applied
```r
# 연속형 변수 (2그룹)
t.test(variable ~ group, data = data)

# 연속형 변수 (3그룹 이상) 
aov(variable ~ group, data = data)

# 범주형 변수
chisq.test(table(data$variable, data$group))
fisher.test(table(data$variable, data$group))
```

### Output Format
생성되는 테이블 구조:
```r
# 연속형 변수 행 예시
Variable    | Overall      | Group A      | Group B      | p-value
Age (mean±SD)| 45.2±12.3   | 43.1±11.8   | 47.3±12.8   | 0.023

# 범주형 변수 행 예시  
Gender      |              |              |              | 0.156
  Male      | 125 (62.5%)  | 65 (65.0%)   | 60 (60.0%)   |
  Female    | 75 (37.5%)   | 35 (35.0%)   | 40 (40.0%)   |
```

### Survey Weight Adjustments
복합표본 데이터에서는 가중치를 적용한 통계량 계산:
```r
# 가중 평균 및 분산
survey::svymean(~variable, design = survey_design)
survey::svyvar(~variable, design = survey_design)

# 가중 비율
survey::svytable(~variable + group, design = survey_design)

# 가중 검정
survey::svychisq(~variable + group, design = survey_design)
```

## Customization Options

### Decimal Precision
```r
# UI에서 설정 가능한 소수점 자릿수
# 0: 정수 표시
# 1: 소수 첫째 자리까지
# 2: 소수 둘째 자리까지 (기본값)
# 3: 소수 셋째 자리까지
# 4: 소수 넷째 자리까지
```

### Statistical Test Inclusion
- 그룹별 비교시 자동 검정 수행
- p-값 표시 여부 선택 가능
- 검정 방법 자동 선택 (정규성, 등분산성 검사 기반)

### Variable Display Options
- 모든 범주 수준 표시 vs 기준 범주 제외
- 변수명 vs 라벨 표시
- 정렬 순서 사용자화

## Dependencies

### Required Packages
```r
library(shiny)          # 웹 애플리케이션 프레임워크
library(DT)             # 대화형 테이블
library(data.table)     # 데이터 조작
library(jstable)        # 통계 테이블 생성
library(survey)         # 복합표본 분석
library(stats)          # 기본 통계 함수
```

### Optional Packages
```r
library(tableone)       # 대안 테이블 생성
library(Hmisc)          # 고급 통계 요약
library(psych)          # 기술통계
```

## Performance Considerations

### Memory Management
- 큰 데이터셋: 필요한 변수만 선택
- 복합표본: 설계 객체 효율적 관리
- 테이블 캐싱: 반복 계산 방지

### Computational Efficiency  
- **병렬 처리**: 여러 변수 동시 계산
- **지연 계산**: 필요시에만 통계 계산
- **메모리 최적화**: 중간 결과 정리

## Error Handling

### Common Issues
1. **빈 셀**: 범주형 변수에서 0 빈도 처리
2. **정확검정 실패**: 큰 테이블에서 메모리 부족
3. **수렴 실패**: 복잡한 복합표본 설계
4. **데이터 타입**: 예상과 다른 변수 타입

### Validation Checks
- 그룹 변수 유효성 검사
- 변수 타입 자동 감지
- 결측값 처리 확인
- 통계검정 적용 조건 검증

## Export Options

### Table Export
- CSV 형식으로 내보내기
- Excel 형식 지원
- 복사 가능한 형식
- 논문용 포맷팅

### Reproducibility
```r
# 분석 재현을 위한 코드 생성
cat("# Generated Table 1 code\n")
cat("library(jstable)\n")
cat("CreateTableOne(vars = selected_vars, 
                   strata = group_var, 
                   data = data)\n")
```

## Version Notes
이 문서는 jsmodule 패키지의 Table 1 생성 모듈을 기반으로 작성되었습니다. 최신 버전에서는 추가 기능이나 매개변수 변경이 있을 수 있습니다.