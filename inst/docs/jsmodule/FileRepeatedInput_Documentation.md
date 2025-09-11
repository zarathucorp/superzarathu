# FileRepeatedInput Documentation

## Overview

`FileRepeatedInput.R`은 jsmodule 패키지의 반복측정 데이터 전용 입력 모듈로, Shiny 애플리케이션에서 종단면 연구(longitudinal study)와 반복측정 분석을 위한 데이터 파일을 업로드하고 처리하는 기능을 제공합니다. 이 모듈은 기본적인 데이터 업로드 기능에 더해 반복측정 변수 선택, 시간 순서 정렬, 그리고 개체별 데이터 구조화 기능을 포함합니다.

## Module Components

### `FileRepeatedInput(id, label)`

반복측정 데이터 파일 업로드를 위한 Shiny 모듈 UI를 생성합니다.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `id` | character | - | 모듈의 고유 식별자 |
| `label` | character | "Upload data (csv/xlsx/sav/sas7bdat/dta)" | 파일 입력 레이블 |

#### Returns

Shiny UI 객체 (tagList with dynamic UI elements)

#### Example

```r
library(shiny)
library(jsmodule)

# UI 정의
ui <- fluidPage(
  titlePanel("Repeated Measures Data Analysis"),
  sidebarLayout(
    sidebarPanel(
      FileRepeatedInput("datafile", label = "반복측정 데이터 업로드")
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Data", DT::DTOutput("data_table")),
        tabPanel("Labels", DT::DTOutput("label_table")),
        tabPanel("Summary", verbatimTextOutput("data_summary"))
      )
    )
  )
)
```

### `FileRepeated(input, output, session, nfactor.limit = 20)`

반복측정 데이터 파일 업로드와 처리를 위한 서버 사이드 로직을 제공합니다.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `input` | - | - | Shiny 입력 객체 |
| `output` | - | - | Shiny 출력 객체 |
| `session` | - | - | Shiny 세션 객체 |
| `nfactor.limit` | integer | 20 | 범주형 변수로 제안할 고유값 임계치 |

#### Returns

다음을 포함하는 반응형 리스트:
- `data`: 처리된 반복측정 데이터프레임 (시간 순서 정렬)
- `label`: 변수 레이블 정보
- `naomit.id`: 결측치 제거 정보
- `repeated_id`: 반복측정 식별 변수

## Specialized Features for Repeated Measures

### 반복측정 변수 선택

```r
# 모듈에서 제공하는 반복측정 특화 기능:
# 1. 개체 식별 변수 (Subject ID) 선택
# 2. 시간 변수 (Time/Visit) 선택
# 3. 측정 순서 정렬 및 검증
# 4. 개체별 데이터 완결성 확인
```

### 데이터 구조 최적화

```r
# 반복측정 분석을 위한 데이터 전처리:
# - Long format 데이터 구조 유지
# - 시간 변수를 기준으로 정렬
# - 개체별 측정 시점 검증
# - 불완전한 관측치 처리 옵션
```

## Usage Examples

### 기본 사용법

```r
library(shiny)
library(jsmodule)
library(DT)

# 완전한 Shiny 앱 예제
ui <- fluidPage(
  titlePanel("Repeated Measures Analysis"),
  sidebarLayout(
    sidebarPanel(
      FileRepeatedInput("datafile")
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Raw Data", 
                 DT::DTOutput("raw_data")),
        tabPanel("Data Structure", 
                 verbatimTextOutput("structure")),
        tabPanel("Variable Labels", 
                 DT::DTOutput("labels")),
        tabPanel("Missing Data", 
                 verbatimTextOutput("missing_info"))
      )
    )
  )
)

server <- function(input, output, session) {
  # 반복측정 데이터 모듈 서버
  data_input <- callModule(FileRepeated, "datafile", 
                          nfactor.limit = 25)
  
  # 원본 데이터 표시
  output$raw_data <- DT::renderDT({
    req(data_input()$data)
    data_input()$data
  }, options = list(scrollX = TRUE))
  
  # 데이터 구조 정보
  output$structure <- renderPrint({
    req(data_input()$data)
    str(data_input()$data)
  })
  
  # 변수 레이블 표시
  output$labels <- DT::renderDT({
    req(data_input()$label)
    data_input()$label
  })
  
  # 결측치 정보
  output$missing_info <- renderPrint({
    req(data_input()$naomit.id)
    cat("Missing data pattern:\n")
    print(data_input()$naomit.id)
  })
}

shinyApp(ui = ui, server = server)
```

### 고급 사용법

```r
# 반복측정 분석과 연동된 고급 워크플로
server <- function(input, output, session) {
  # 반복측정 데이터 로드
  repeated_data <- callModule(FileRepeated, "datafile")
  
  # 데이터 품질 검사
  data_quality <- reactive({
    req(repeated_data()$data)
    
    df <- repeated_data()$data
    repeated_id <- repeated_data()$repeated_id
    
    # 개체별 측정 횟수 확인
    measurement_counts <- df %>%
      count(!!sym(repeated_id)) %>%
      summarise(
        min_measures = min(n),
        max_measures = max(n),
        mean_measures = round(mean(n), 2),
        complete_cases = sum(n == max(n))
      )
    
    return(measurement_counts)
  })
  
  # 종단 데이터 시각화 준비
  longitudinal_plot_data <- reactive({
    req(repeated_data()$data)
    
    df <- repeated_data()$data
    # 시간에 따른 변화 패턴 분석용 데이터 준비
    # ...
  })
  
  # 품질 리포트 출력
  output$quality_report <- renderText({
    quality <- data_quality()
    req(quality)
    
    paste(
      "Repeated Measures Data Quality:",
      sprintf("Subjects: %d", nrow(repeated_data()$data) / quality$mean_measures),
      sprintf("Average measurements per subject: %.1f", quality$mean_measures),
      sprintf("Complete cases: %d", quality$complete_cases),
      sep = "\n"
    )
  })
}
```

## Data Processing Features

### 반복측정 특화 전처리

```r
# 모듈에서 자동으로 처리하는 반복측정 데이터 특징:
# 1. 개체 식별자 (Subject ID) 검증
# 2. 시간 변수 (Time/Visit) 순서 정렬
# 3. Long format 데이터 구조 유지
# 4. 불균형 반복측정 (unbalanced repeated measures) 처리
# 5. 기저선과 추적관찰 데이터 구분
```

### 데이터 검증 기능

```r
# 반복측정 데이터 완결성 검사:
# - 각 개체별 최소 측정 횟수 확인
# - 시간 변수의 일관성 검증
# - 결측 패턴 분석
# - 이상치 개체 식별
```

## Integration with Analysis Modules

### 종단 분석 모듈과의 연동

```r
# 반복측정 데이터를 분석 모듈에 전달
server <- function(input, output, session) {
  # 데이터 입력
  repeated_input <- callModule(FileRepeated, "upload")
  
  # 혼합효과 모델 분석
  callModule(lmerModule, "mixed_model",
            data = reactive(repeated_input()$data),
            data_label = reactive(repeated_input()$label))
  
  # GEE 분석
  callModule(geeModule, "gee_analysis", 
            data = reactive(repeated_input()$data),
            data_label = reactive(repeated_input()$label))
}
```

### 생존분석과의 연동

```r
# 반복측정 생존분석 워크플로
server <- function(input, output, session) {
  repeated_data <- callModule(FileRepeated, "datafile")
  
  # 시간-의존 생존분석 준비
  survival_ready_data <- reactive({
    req(repeated_data()$data)
    
    # 반복측정 데이터를 생존분석 형태로 변환
    survival_format <- repeated_data()$data %>%
      # counting process format 변환
      arrange(subject_id, time_var) %>%
      group_by(subject_id) %>%
      mutate(
        tstart = lag(time_var, default = 0),
        tstop = time_var
      )
    
    return(survival_format)
  })
}
```

## Error Handling & Validation

### 반복측정 데이터 특화 오류 처리

```r
# 일반적인 반복측정 데이터 문제들:
# 1. Wide format 데이터 업로드
# 해결: Long format 변환 안내 또는 자동 변환 기능

# 2. 개체 식별자 누락
# 해결: 필수 변수 선택 강제 및 검증

# 3. 시간 변수 불일치
# 해결: 시간 변수 형식 통일 및 순서 검증

# 4. 불완전한 반복측정
# 해결: 결측 패턴 분석 및 처리 옵션 제공
```

### 데이터 품질 검증

```r
# 품질 검증 체크리스트
server <- function(input, output, session) {
  repeated_data <- callModule(FileRepeated, "datafile")
  
  # 데이터 검증
  validation_results <- reactive({
    req(repeated_data()$data)
    
    df <- repeated_data()$data
    
    checks <- list(
      has_subject_id = !is.null(repeated_data()$repeated_id),
      min_observations = nrow(df) >= 10,
      has_time_var = any(sapply(df, function(x) is.numeric(x) || lubridate::is.Date(x))),
      balanced_design = length(unique(table(df[repeated_data()$repeated_id]))) == 1
    )
    
    return(checks)
  })
  
  # 검증 결과 표시
  output$validation_status <- renderText({
    checks <- validation_results()
    req(checks)
    
    status_messages <- c(
      if(checks$has_subject_id) "✓ Subject ID identified" else "✗ Subject ID missing",
      if(checks$min_observations) "✓ Sufficient observations" else "✗ Too few observations",
      if(checks$has_time_var) "✓ Time variable found" else "✗ Time variable missing",
      if(checks$balanced_design) "✓ Balanced design" else "ℹ Unbalanced design detected"
    )
    
    paste(status_messages, collapse = "\n")
  })
}
```

## Performance Considerations

### 대용량 반복측정 데이터

```r
# 큰 종단 데이터셋 처리 최적화
# 1. 청크 단위 데이터 로딩
# 2. 개체별 병렬 처리
# 3. 메모리 효율적인 데이터 구조
# 4. 진행 상황 표시
```

### 반응성 최적화

```r
# 반복측정 데이터의 반응성 최적화
server <- function(input, output, session) {
  repeated_data <- callModule(FileRepeated, "datafile")
  
  # 캐싱으로 성능 향상
  processed_data <- reactive({
    req(repeated_data()$data)
    # 복잡한 전처리 로직
    repeated_data()$data
  }) %>% bindCache(repeated_data()$data)
  
  # 점진적 로딩
  paged_data <- reactive({
    req(processed_data())
    # 페이지별 데이터 로딩
  })
}
```

## Dependencies

### 필수 패키지

- `shiny` - 기본 Shiny 기능
- `DT` - 데이터 테이블 표시
- `dplyr` - 데이터 조작
- `DataManager` - jsmodule 내부 데이터 관리 클래스

### 선택적 패키지

- `lubridate` - 날짜/시간 처리
- `tidyr` - 데이터 형태 변환
- `ggplot2` - 종단 데이터 시각화

## See Also

- `csvFileInput.R` - 기본 데이터 입력 모듈
- `DataManager.R` - 데이터 관리 R6 클래스
- `lmer.R` - 혼합효과 모델 분석 모듈
- `gee.R` - 일반화 추정 방정식 모듈
- `FileSurveyInput.R` - 설문조사 데이터 입력 모듈