# FileSurveyInput Documentation

## Overview

`FileSurveyInput.R`은 jsmodule 패키지의 설문조사 데이터 전용 입력 모듈로, Shiny 애플리케이션에서 복합표본설계(complex survey design) 데이터를 업로드하고 처리하는 기능을 제공합니다. 이 모듈은 가중치(weight), 층화변수(strata), 집락변수(cluster) 등 설문조사 특유의 설계 요소를 자동으로 감지하고 survey 객체를 생성하여 적절한 통계분석을 가능하게 합니다.

## Module Components

### `FileSurveyInput(id, label)`

설문조사 데이터 파일 업로드를 위한 Shiny 모듈 UI를 생성합니다.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `id` | character | - | 모듈의 고유 식별자 |
| `label` | character | "Upload data (csv/xlsx/sav/sas7bdat/dta)" | 파일 입력 레이블 |

#### Returns

Shiny UI 객체 (tagList with survey design controls)

#### Example

```r
library(shiny)
library(jsmodule)
library(survey)

# UI 정의
ui <- fluidPage(
  titlePanel("Complex Survey Data Analysis"),
  sidebarLayout(
    sidebarPanel(
      FileSurveyInput("datafile", label = "설문조사 데이터 업로드")
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Survey Design", verbatimTextOutput("survey_summary")),
        tabPanel("Data", DT::DTOutput("data_table")),
        tabPanel("Weights", DT::DTOutput("weight_info")),
        tabPanel("Design Variables", DT::DTOutput("design_vars"))
      )
    )
  )
)
```

### `FileSurvey(input, output, session, nfactor.limit = 20)`

설문조사 데이터 파일 업로드와 처리를 위한 서버 사이드 로직을 제공합니다.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `input` | - | - | Shiny 입력 객체 |
| `output` | - | - | Shiny 출력 객체 |
| `session` | - | - | Shiny 세션 객체 |
| `nfactor.limit` | integer | 20 | 범주형 변수로 제안할 고유값 임계치 |

#### Returns

다음을 포함하는 반응형 리스트:
- `data`: 처리된 설문조사 데이터프레임
- `label`: 변수 레이블 정보
- `naomit`: 결측치 제거 정보
- `survey`: survey 패키지의 설계 객체 (survey.design)

## Survey Design Features

### 복합표본설계 지원

```r
# 모듈에서 지원하는 설문조사 설계 요소:
# 1. 가중치 (Weight): 표본추출 확률의 역수
# 2. 층화변수 (Strata): 모집단을 동질적 층으로 구분
# 3. 집락변수 (Cluster/PSU): 1차 표본추출단위
# 4. 복합설계: 층화 + 집락 + 가중치 조합
```

### 자동 설계 감지

```r
# 설문조사 설계 변수 자동 감지 규칙:
# - 가중치: "weight", "wt", "sampling_weight" 등의 변수명
# - 층화: "strata", "stratum", "psu", "domain" 등의 변수명
# - 집락: "cluster", "psu", "primary_unit" 등의 변수명
# - 유한모집단수정계수 (FPC): "fpc", "pop_size" 등의 변수명
```

## Usage Examples

### 기본 사용법

```r
library(shiny)
library(jsmodule)
library(survey)
library(DT)

# 완전한 Shiny 앱 예제
ui <- fluidPage(
  titlePanel("Survey Data Analysis"),
  sidebarLayout(
    sidebarPanel(
      FileSurveyInput("datafile")
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Survey Design", 
                 h4("Survey Design Summary"),
                 verbatimTextOutput("design_summary"),
                 h4("Design Effect"),
                 verbatimTextOutput("design_effect")),
        tabPanel("Weighted Data", 
                 DT::DTOutput("weighted_data")),
        tabPanel("Variable Labels", 
                 DT::DTOutput("labels")),
        tabPanel("Missing Data", 
                 verbatimTextOutput("missing_pattern"))
      )
    )
  )
)

server <- function(input, output, session) {
  # 설문조사 데이터 모듈 서버
  survey_input <- callModule(FileSurvey, "datafile", 
                            nfactor.limit = 25)
  
  # 설계 요약 정보
  output$design_summary <- renderPrint({
    req(survey_input()$survey)
    summary(survey_input()$survey)
  })
  
  # 설계 효과 계산
  output$design_effect <- renderPrint({
    req(survey_input()$survey)
    
    # 연속형 변수에 대한 설계효과 계산
    numeric_vars <- survey_input()$data %>%
      select_if(is.numeric) %>%
      names()
    
    if(length(numeric_vars) > 0) {
      deff_results <- lapply(numeric_vars[1:min(3, length(numeric_vars))], function(var) {
        tryCatch({
          deff <- svymean(as.formula(paste("~", var)), survey_input()$survey, deff = TRUE)
          c(variable = var, design_effect = attr(deff, "deff"))
        }, error = function(e) NULL)
      })
      
      do.call(rbind, deff_results[!sapply(deff_results, is.null)])
    }
  })
  
  # 가중 데이터 표시
  output$weighted_data <- DT::renderDT({
    req(survey_input()$data)
    survey_input()$data
  }, options = list(scrollX = TRUE))
  
  # 변수 레이블
  output$labels <- DT::renderDT({
    req(survey_input()$label)
    survey_input()$label
  })
  
  # 결측 패턴
  output$missing_pattern <- renderPrint({
    req(survey_input()$naomit)
    cat("Missing data information:\n")
    print(survey_input()$naomit)
  })
}

shinyApp(ui = ui, server = server)
```

### 고급 사용법

```r
# 복잡한 설문조사 분석 워크플로
server <- function(input, output, session) {
  # 설문조사 데이터 로드
  survey_data <- callModule(FileSurvey, "datafile")
  
  # 가중 기술통계
  weighted_summary <- reactive({
    req(survey_data()$survey)
    
    design <- survey_data()$survey
    
    # 범주형 변수들에 대한 가중 비율
    categorical_vars <- survey_data()$data %>%
      select_if(is.factor) %>%
      names()
    
    if(length(categorical_vars) > 0) {
      prop_results <- lapply(categorical_vars[1:3], function(var) {
        tryCatch({
          props <- svytable(as.formula(paste("~", var)), design)
          prop_table <- prop.table(props) * 100
          data.frame(
            variable = var,
            category = names(prop_table),
            weighted_percent = as.numeric(prop_table),
            stringsAsFactors = FALSE
          )
        }, error = function(e) NULL)
      })
      
      do.call(rbind, prop_results[!sapply(prop_results, is.null)])
    }
  })
  
  # 복합표본 회귀분석 준비
  survey_regression_data <- reactive({
    req(survey_data()$survey)
    
    # 회귀분석용 데이터 준비
    design_obj <- survey_data()$survey
    
    list(
      design = design_obj,
      variables = names(survey_data()$data),
      numeric_vars = survey_data()$data %>% select_if(is.numeric) %>% names(),
      factor_vars = survey_data()$data %>% select_if(is.factor) %>% names()
    )
  })
  
  # 가중 요약통계 출력
  output$weighted_summary <- renderDT({
    req(weighted_summary())
    weighted_summary()
  })
}
```

## Survey Design Types

### 단순확률표본 (Simple Random Sampling)

```r
# 가중치만 있는 경우
survey_design <- svydesign(
  ids = ~1,                    # 집락 없음
  weights = ~weight_var,       # 가중치 변수
  data = survey_data
)
```

### 층화표본 (Stratified Sampling)

```r
# 층화변수가 있는 경우
survey_design <- svydesign(
  ids = ~1,                    # 집락 없음
  strata = ~strata_var,        # 층화변수
  weights = ~weight_var,       # 가중치 변수
  data = survey_data
)
```

### 집락표본 (Cluster Sampling)

```r
# 집락변수가 있는 경우
survey_design <- svydesign(
  ids = ~cluster_var,          # 집락변수 (PSU)
  weights = ~weight_var,       # 가중치 변수
  data = survey_data
)
```

### 복합설계 (Complex Design)

```r
# 층화 + 집락 + 가중치
survey_design <- svydesign(
  ids = ~cluster_var,          # 집락변수
  strata = ~strata_var,        # 층화변수
  weights = ~weight_var,       # 가중치 변수
  data = survey_data
)
```

## Integration with Analysis Modules

### 가중 기술통계와 연동

```r
# 설문조사 데이터를 기술통계 모듈에 전달
server <- function(input, output, session) {
  # 설문조사 데이터 입력
  survey_input <- callModule(FileSurvey, "upload")
  
  # 가중 기술통계
  callModule(svyCreateTableOneModule, "table1",
            data = reactive(survey_input()$data),
            data_label = reactive(survey_input()$label),
            design_survey = reactive(survey_input()$survey))
}
```

### 가중 회귀분석과 연동

```r
# 설문조사 회귀분석 워크플로
server <- function(input, output, session) {
  survey_data <- callModule(FileSurvey, "datafile")
  
  # 가중 로지스틱 회귀
  callModule(svyglmModule, "weighted_glm",
            data = reactive(survey_data()$data),
            data_label = reactive(survey_data()$label),
            design_survey = reactive(survey_data()$survey))
  
  # 가중 콕스 회귀
  callModule(svycoxModule, "weighted_cox",
            data = reactive(survey_data()$data),
            data_label = reactive(survey_data()$label),
            design_survey = reactive(survey_data()$survey))
}
```

## Error Handling & Validation

### 설문조사 설계 검증

```r
# 설문조사 설계 유효성 검사
server <- function(input, output, session) {
  survey_data <- callModule(FileSurvey, "datafile")
  
  # 설계 검증
  design_validation <- reactive({
    req(survey_data()$survey)
    
    design <- survey_data()$survey
    data <- survey_data()$data
    
    validation_results <- list(
      has_weights = !is.null(design$prob),
      has_strata = !is.null(design$strata),
      has_clusters = !is.null(design$cluster),
      weight_range = if(!is.null(design$prob)) range(1/design$prob, na.rm = TRUE) else NULL,
      total_observations = nrow(data),
      effective_sample_size = if(!is.null(design$prob)) sum(design$prob, na.rm = TRUE) else nrow(data)
    )
    
    return(validation_results)
  })
  
  # 검증 결과 표시
  output$design_validation <- renderText({
    validation <- design_validation()
    req(validation)
    
    messages <- c(
      if(validation$has_weights) "✓ Weights detected" else "ℹ No weights specified",
      if(validation$has_strata) "✓ Stratification detected" else "ℹ No stratification",
      if(validation$has_clusters) "✓ Clustering detected" else "ℹ No clustering",
      sprintf("Total observations: %d", validation$total_observations),
      if(!is.null(validation$effective_sample_size)) 
        sprintf("Effective sample size: %.0f", validation$effective_sample_size) else ""
    )
    
    paste(messages[messages != ""], collapse = "\n")
  })
}
```

### 일반적인 오류 상황

```r
# 설문조사 데이터의 일반적인 문제들:
# 1. 가중치 변수 누락 또는 잘못된 형식
# 해결: 자동 감지 및 사용자 선택 옵션 제공

# 2. 층화변수의 빈 층 (empty strata)
# 해결: 층 결합 또는 제거 옵션

# 3. 집락 내 단일 관측치
# 해결: 집락 구조 재검토 또는 단순설계 전환

# 4. 극단적인 가중치 값
# 해결: 가중치 범위 검사 및 경고 메시지
```

## Performance Considerations

### 대용량 설문조사 데이터

```r
# 큰 설문조사 데이터 처리 최적화
# 1. survey 객체 생성 최적화
# 2. 메모리 효율적인 가중치 계산
# 3. 청크 단위 집계 처리
# 4. 캐싱을 통한 반복 계산 방지
```

### 복잡한 설계 최적화

```r
# 복합설계 성능 최적화
server <- function(input, output, session) {
  survey_data <- callModule(FileSurvey, "datafile")
  
  # 설계 객체 캐싱
  cached_design <- reactive({
    req(survey_data()$survey)
    survey_data()$survey
  }) %>% bindCache(survey_data()$data)
  
  # 집계 결과 캐싱
  cached_summary <- reactive({
    req(cached_design())
    # 복잡한 집계 계산
    svymean(~., cached_design())
  }) %>% bindCache(cached_design())
}
```

## Dependencies

### 필수 패키지

- `shiny` - 기본 Shiny 기능
- `survey` - 복합표본설계 분석
- `DT` - 데이터 테이블 표시
- `DataManager` - jsmodule 내부 데이터 관리 클래스

### 선택적 패키지

- `sampling` - 표본설계 보조 기능
- `srvyr` - survey + dplyr 통합
- `broom` - 모델 결과 정리

## Security Considerations

### 설문조사 데이터 보안

```r
# 설문조사 데이터 특유의 보안 고려사항:
# 1. 개인정보 식별 위험 (가중치를 통한 역추적)
# 2. 소규모 층이나 집락의 익명성 보장
# 3. 가중치 정보의 민감성
# 4. 설계 정보 노출 방지
```

## See Also

- `csvFileInput.R` - 기본 데이터 입력 모듈
- `DataManager.R` - 데이터 관리 R6 클래스
- `svyCreateTableOneJS.R` - 가중 기술통계 테이블
- `svyglm.R` - 가중 일반화선형모델
- `svycox.R` - 가중 콕스 회귀모델