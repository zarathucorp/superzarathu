# DataManager Documentation

## Overview

`DataManager.R`은 jsmodule 패키지의 핵심 R6 클래스로, Shiny 모듈에서 데이터 로딩, 전처리, 그리고 UI 요소 관리를 담당합니다. 다양한 데이터 형식을 지원하고, 동적 데이터 변환 기능을 제공하며, 다른 jsmodule 컴포넌트들과의 원활한 통합을 가능하게 합니다.

## Class Definition

### `DataManager` (R6 Class)

데이터 관리와 전처리를 위한 종합적인 R6 클래스입니다.

#### Public Fields

| Field | Type | Description |
|-------|------|-------------|
| `input` | - | Shiny 모듈의 입력 객체 |
| `output` | - | Shiny 모듈의 출력 객체 |
| `session` | - | Shiny 모듈의 세션 객체 |
| `ns` | function | Shiny 모듈의 네임스페이스 함수 |
| `nfactor.limit` | integer | 범주형 변수 변환 임계값 (기본값: 20) |
| `initial_data_info` | reactive | 초기 로드된 데이터 정보 |
| `processed_data` | reactive | 변환된 최종 데이터 |

#### Public Methods

##### `initialize(input, output, session, nfactor.limit = 20)`

DataManager 클래스의 생성자입니다.

```r
# 기본 초기화
data_manager <- DataManager$new(
  input = input,
  output = output,
  session = session,
  nfactor.limit = 25
)
```

**Parameters:**
- `input`: Shiny 입력 객체
- `output`: Shiny 출력 객체  
- `session`: Shiny 세션 객체
- `nfactor.limit`: 범주형 변수로 제안할 고유값 임계치

##### `get_reactive_data()`

최종 처리된 데이터를 반환하는 반응형 함수입니다.

```r
# 처리된 데이터 접근
reactive_data <- data_manager$get_reactive_data()

# 사용 예시
observe({
  data <- reactive_data()
  if (!is.null(data$data)) {
    print(paste("Loaded", nrow(data$data), "rows"))
  }
})
```

**Returns:**
- `data`: 처리된 데이터프레임
- `label`: 변수 레이블 정보
- `factor_vars`: 범주형 변수 목록
- `class_vars`: 변수 클래스 정보

## Core Functionality

### 데이터 로딩 기능

#### 지원하는 파일 형식

```r
# DataManager가 지원하는 파일 형식들
supported_formats <- c(
  ".csv",         # 쉼표로 구분된 값
  ".xlsx",        # Excel 파일
  ".xls",         # 구버전 Excel
  ".sav",         # SPSS 파일
  ".sas7bdat",    # SAS 파일
  ".dta"          # Stata 파일
)
```

#### 파일 읽기 과정

```r
# 1. 파일 확장자 감지
# 2. 적절한 읽기 함수 선택
# 3. 인코딩 처리
# 4. 초기 데이터 타입 분석
# 5. 변수 레이블 추출 (해당하는 경우)
```

### 데이터 변환 기능

#### 자동 변수 타입 감지

```r
# nfactor.limit을 기준으로 자동 분류
# 고유값 <= nfactor.limit → 범주형 변수 제안
# 고유값 > nfactor.limit → 연속형 변수 유지

# 예시: nfactor.limit = 20
numeric_var_with_few_levels <- c(1, 2, 3, 1, 2, 3)  # → 범주형 제안
numeric_var_with_many_levels <- rnorm(100)          # → 연속형 유지
```

#### 지원하는 변환 작업

```r
# 1. 변수 타입 변환
# Numeric to Factor
# Factor to Numeric
# Character to Factor

# 2. 이진 변수 변환
# Reference level 설정
# 0/1 코딩

# 3. 데이터 서브셋팅
# 조건부 행 선택
# 변수 선택/제외

# 4. 결측치 처리
# NA 값 확인
# 결측치 패턴 분석
```

## Usage Examples

### 기본 사용법

```r
library(shiny)
library(jsmodule)

# Shiny 모듈에서 DataManager 사용
csvFileServer <- function(input, output, session) {
  # DataManager 인스턴스 생성
  data_manager <- DataManager$new(
    input = input,
    output = output,
    session = session,
    nfactor.limit = 25
  )
  
  # 처리된 데이터 반환
  return(data_manager$get_reactive_data())
}
```

### 고급 사용법

```r
# 커스텀 데이터 처리 파이프라인
advancedDataServer <- function(input, output, session) {
  # DataManager 초기화
  data_manager <- DataManager$new(input, output, session)
  
  # 기본 데이터 가져오기
  base_data <- data_manager$get_reactive_data()
  
  # 추가 전처리
  enhanced_data <- reactive({
    req(base_data()$data)
    
    raw_data <- base_data()$data
    
    # 커스텀 전처리 로직
    processed <- raw_data %>%
      mutate(
        # 새로운 변수 생성
        age_group = cut(age, breaks = c(0, 30, 50, 70, Inf),
                       labels = c("Young", "Middle", "Senior", "Elder")),
        # 결측치 처리
        income_clean = ifelse(is.na(income), median(income, na.rm = TRUE), income)
      ) %>%
      filter(!is.na(primary_outcome))  # 주요 변수 결측치 제거
    
    return(list(
      data = processed,
      label = base_data()$label,
      factor_vars = c(base_data()$factor_vars, "age_group")
    ))
  })
  
  return(enhanced_data)
}
```

### 다중 데이터소스 관리

```r
# 여러 데이터 소스를 관리하는 경우
multiDataServer <- function(input, output, session) {
  # 여러 DataManager 인스턴스
  data_managers <- list(
    primary = DataManager$new(input, output, session),
    secondary = DataManager$new(input, output, session)
  )
  
  # 데이터 결합
  combined_data <- reactive({
    primary_data <- data_managers$primary$get_reactive_data()
    secondary_data <- data_managers$secondary$get_reactive_data()
    
    req(primary_data()$data, secondary_data()$data)
    
    # 데이터 결합 로직
    merged <- merge(primary_data()$data, 
                   secondary_data()$data, 
                   by = "id", 
                   all.x = TRUE)
    
    return(list(
      data = merged,
      label = rbind(primary_data()$label, secondary_data()$label)
    ))
  })
  
  return(combined_data)
}
```

## Advanced Features

### 동적 UI 생성

```r
# DataManager는 데이터 내용에 따라 동적 UI 생성 지원
output$dynamic_ui <- renderUI({
  data_info <- data_manager$initial_data_info()
  req(data_info)
  
  # 변수 타입에 따른 동적 입력 위젯 생성
  variable_inputs <- lapply(names(data_info$data), function(var_name) {
    var_data <- data_info$data[[var_name]]
    
    if (is.numeric(var_data)) {
      numericInput(paste0("transform_", var_name),
                  label = paste("Transform", var_name),
                  value = 1, min = 0)
    } else if (is.factor(var_data)) {
      selectInput(paste0("level_", var_name),
                 label = paste("Reference level for", var_name),
                 choices = levels(var_data))
    }
  })
  
  do.call(tagList, variable_inputs)
})
```

### 데이터 품질 검사

```r
# 데이터 품질 모니터링
data_quality_check <- reactive({
  data <- data_manager$get_reactive_data()
  req(data$data)
  
  df <- data$data
  
  quality_report <- list(
    total_rows = nrow(df),
    total_cols = ncol(df),
    missing_percent = sum(is.na(df)) / (nrow(df) * ncol(df)) * 100,
    duplicate_rows = sum(duplicated(df)),
    numeric_vars = sum(sapply(df, is.numeric)),
    factor_vars = sum(sapply(df, is.factor)),
    character_vars = sum(sapply(df, is.character))
  )
  
  return(quality_report)
})

# 품질 리포트 출력
output$quality_summary <- renderText({
  quality <- data_quality_check()
  req(quality)
  
  paste(
    "Data Quality Summary:",
    sprintf("Rows: %d, Columns: %d", quality$total_rows, quality$total_cols),
    sprintf("Missing data: %.2f%%", quality$missing_percent),
    sprintf("Duplicates: %d rows", quality$duplicate_rows),
    sep = "\n"
  )
})
```

## Integration Patterns

### 다른 jsmodule과의 연동

```r
# tb1 모듈과 연동
server <- function(input, output, session) {
  # 데이터 관리
  data_input <- callModule(csvFile, "datafile")
  
  # 기술통계 모듈
  callModule(tb1module, "table1", 
            data = reactive(data_input()$data),
            data_label = reactive(data_input()$label))
  
  # 회귀분석 모듈
  callModule(regressModule2, "regression",
            data = reactive(data_input()$data),
            data_label = reactive(data_input()$label))
}
```

### 반응형 데이터 체인

```r
# 데이터 변환 체인 구성
server <- function(input, output, session) {
  # 1단계: 기본 데이터 로드
  raw_data <- callModule(csvFile, "upload")
  
  # 2단계: 데이터 정제
  cleaned_data <- reactive({
    req(raw_data()$data)
    
    # 정제 로직
    clean_df <- raw_data()$data %>%
      filter(!is.na(primary_var)) %>%
      mutate(transformed_var = log(numeric_var + 1))
    
    return(list(
      data = clean_df,
      label = raw_data()$label
    ))
  })
  
  # 3단계: 분석별 데이터 준비
  analysis_data <- reactive({
    req(cleaned_data()$data)
    
    # 분석용 데이터 준비
    # ...
  })
}
```

## Performance Optimization

### 메모리 효율성

```r
# 큰 데이터셋 처리를 위한 최적화
optimized_data_manager <- function(input, output, session) {
  data_manager <- DataManager$new(input, output, session)
  
  # 캐싱을 통한 성능 향상
  cached_data <- reactive({
    data_manager$get_reactive_data()
  }) %>% bindCache(input$file)
  
  # 필요한 경우에만 데이터 로드
  lazy_data <- reactive({
    req(input$analyze_button)  # 버튼 클릭 시에만 로드
    cached_data()
  })
  
  return(lazy_data)
}
```

### 비동기 처리

```r
# 큰 파일 처리를 위한 비동기 로딩
library(future)
library(promises)

async_data_load <- function(input, output, session) {
  data_manager <- DataManager$new(input, output, session)
  
  # 비동기 데이터 로드
  data_promise <- reactive({
    req(input$file)
    
    future({
      # 시간이 오래 걸리는 데이터 처리
      data_manager$get_reactive_data()
    }) %...>% {
      # 성공 시 처리
      result
    } %...!% {
      # 오류 시 처리
      showNotification("데이터 로드 중 오류가 발생했습니다.", type = "error")
      NULL
    }
  })
  
  return(data_promise)
}
```

## Error Handling

### 견고한 오류 처리

```r
# 오류 처리가 포함된 DataManager 사용
robust_data_server <- function(input, output, session) {
  # 오류 상태 추적
  error_state <- reactiveVal(NULL)
  
  data_manager <- DataManager$new(input, output, session)
  
  # 안전한 데이터 접근
  safe_data <- reactive({
    tryCatch({
      result <- data_manager$get_reactive_data()
      error_state(NULL)  # 오류 상태 초기화
      return(result)
    }, error = function(e) {
      error_state(e$message)
      showNotification(paste("데이터 처리 오류:", e$message), 
                      type = "error", duration = 10)
      return(NULL)
    })
  })
  
  # 오류 상태 표시
  output$error_display <- renderText({
    if (!is.null(error_state())) {
      paste("오류:", error_state())
    } else {
      ""
    }
  })
  
  return(safe_data)
}
```

## Dependencies

### 필수 패키지

```r
# DataManager 클래스에서 사용하는 주요 패키지
library(R6)          # R6 클래스 시스템
library(shiny)       # Shiny 웹 애플리케이션
library(DT)          # 데이터 테이블
library(readxl)      # Excel 파일 읽기
library(haven)       # SPSS, SAS, Stata 파일 읽기
library(dplyr)       # 데이터 조작
```

### 선택적 패키지

```r
library(shinycssloaders)  # 로딩 애니메이션
library(shinyWidgets)     # 향상된 위젯
library(future)           # 비동기 처리
library(promises)         # Promise 기반 비동기
```

## See Also

- `csvFileInput.R` - CSV 파일 입력 모듈
- `FileSurveyInput.R` - 설문조사 데이터 입력 모듈
- `utils.R` - 유틸리티 함수들
- `tb1.R` - 기술통계 테이블 모듈