# csvFileInput Documentation

## Overview

`csvFileInput.R`은 jsmodule 패키지의 데이터 입력 모듈로, Shiny 애플리케이션에서 다양한 형식의 데이터 파일을 업로드하고 처리하는 기능을 제공합니다. CSV, Excel, SPSS, SAS, Stata 등 다양한 통계 소프트웨어 형식을 지원하며, 데이터 타입 변환과 레이블 관리 기능을 포함합니다.

## Module Components

### `csvFileInput(id, label)`

데이터 파일 업로드를 위한 Shiny 모듈 UI를 생성합니다.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `id` | character | - | 모듈의 고유 식별자 |
| `label` | character | "Upload data (csv/xlsx/sav/sas7bdat/dta)" | 파일 입력 레이블 |

#### Returns

Shiny UI 객체 (fileInput과 동적 UI 요소들)

#### Example

```r
library(shiny)
library(jsmodule)

# UI 정의
ui <- fluidPage(
  titlePanel("Data File Upload"),
  sidebarLayout(
    sidebarPanel(
      csvFileInput("datafile")
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Data", DT::DTOutput("data_table")),
        tabPanel("Labels", DT::DTOutput("label_table"))
      )
    )
  )
)
```

### `csvFile(input, output, session, nfactor.limit = 20)`

데이터 파일 업로드와 처리를 위한 서버 사이드 로직을 제공합니다.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `input` | - | - | Shiny 입력 객체 |
| `output` | - | - | Shiny 출력 객체 |
| `session` | - | - | Shiny 세션 객체 |
| `nfactor.limit` | integer | 20 | 범주형 변수로 제안할 고유값 임계치 |

#### Returns

다음을 포함하는 반응형 리스트:
- `data`: 처리된 데이터프레임
- `label`: 변수 레이블 정보
- `factor_vars`: 범주형 변수 목록
- `continuous_vars`: 연속형 변수 목록

## Supported File Formats

### 파일 형식 지원

| Format | Extension | Description | Required Package |
|--------|-----------|-------------|------------------|
| CSV | .csv | 쉼표로 구분된 값 | base R |
| Excel | .xlsx, .xls | Microsoft Excel | `readxl` |
| SPSS | .sav | SPSS 데이터 파일 | `haven` |
| SAS | .sas7bdat | SAS 데이터 파일 | `haven` |
| Stata | .dta | Stata 데이터 파일 | `haven` |

### 파일 읽기 옵션

```r
# CSV 파일 업로드 시 제공되는 옵션들:
# - Header: 첫 번째 행이 변수명인지 여부
# - Separator: 구분자 선택 (쉼표, 세미콜론, 탭)
# - Quote: 인용 부호 처리
# - Decimal: 소수점 표시 방법
```

## Usage Notes

### 기본 사용 패턴

```r
library(shiny)
library(jsmodule)
library(DT)

# 완전한 Shiny 앱 예제
ui <- fluidPage(
  titlePanel("Data Analysis App"),
  sidebarLayout(
    sidebarPanel(
      # 파일 업로드 모듈
      csvFileInput("datafile", label = "데이터 파일 선택")
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Raw Data", 
                 DT::DTOutput("raw_data")),
        tabPanel("Data Summary", 
                 verbatimTextOutput("summary")),
        tabPanel("Variable Labels", 
                 DT::DTOutput("labels"))
      )
    )
  )
)

server <- function(input, output, session) {
  # 파일 업로드 모듈 서버
  data_input <- callModule(csvFile, "datafile", 
                          nfactor.limit = 25)
  
  # 업로드된 데이터 표시
  output$raw_data <- DT::renderDT({
    req(data_input()$data)
    data_input()$data
  }, options = list(scrollX = TRUE))
  
  # 데이터 요약
  output$summary <- renderPrint({
    req(data_input()$data)
    summary(data_input()$data)
  })
  
  # 변수 레이블 표시
  output$labels <- DT::renderDT({
    req(data_input()$label)
    data_input()$label
  })
}

shinyApp(ui = ui, server = server)
```

### 고급 사용법

```r
# 다중 파일 업로드와 데이터 결합
server <- function(input, output, session) {
  # 첫 번째 데이터셋
  data1 <- callModule(csvFile, "file1")
  
  # 두 번째 데이터셋  
  data2 <- callModule(csvFile, "file2")
  
  # 데이터 결합
  combined_data <- reactive({
    req(data1()$data, data2()$data)
    
    # 공통 변수로 결합
    merge(data1()$data, data2()$data, by = "id", all = TRUE)
  })
  
  output$combined_table <- DT::renderDT({
    combined_data()
  })
}
```

## Data Processing Features

### 자동 변수 타입 추론

```r
# nfactor.limit 설정에 따른 변수 타입 추천
# 고유값이 20개 이하 → 범주형 변수로 제안
# 고유값이 20개 초과 → 연속형 변수로 유지

# 사용자가 직접 변수 타입 변경 가능:
# - Numeric to Factor: 연속형을 범주형으로
# - Factor to Numeric: 범주형을 연속형으로
```

### 데이터 변환 옵션

```r
# 모듈에서 제공하는 데이터 변환 기능:
# 1. 변수 타입 변경
# 2. 레이블 편집
# 3. 결측치 처리
# 4. 변수명 수정
```

## Integration with DataManager

### DataManager R6 클래스 활용

```r
# csvFile 모듈은 내부적으로 DataManager 클래스 사용
# 데이터 처리와 변환 작업을 효율적으로 관리

# DataManager의 주요 기능:
# - 데이터 읽기 및 파싱
# - 변수 타입 관리
# - 레이블 정보 저장
# - 데이터 검증
```

### 반응형 데이터 흐름

```r
# 모듈의 반환값 구조
reactive_data <- callModule(csvFile, "upload")

# 접근 방법:
# reactive_data()$data        # 실제 데이터
# reactive_data()$label       # 변수 레이블
# reactive_data()$factor_vars # 범주형 변수 목록
# reactive_data()$class_vars  # 변수 클래스 정보
```

## Error Handling

### 일반적인 오류 상황

```r
# 1. 지원하지 않는 파일 형식
# 해결: 지원되는 확장자(.csv, .xlsx, .sav, .sas7bdat, .dta) 사용

# 2. 파일 크기 제한
# 해결: Shiny 앱의 maxRequestSize 옵션 조정
options(shiny.maxRequestSize = 100*1024^2)  # 100MB

# 3. 인코딩 문제
# 해결: CSV 파일의 경우 UTF-8 인코딩 권장

# 4. 메모리 부족
# 해결: 큰 데이터의 경우 샘플링 또는 청크 단위 처리 고려
```

### 디버깅 팁

```r
# 데이터 업로드 상태 확인
server <- function(input, output, session) {
  data_input <- callModule(csvFile, "datafile")
  
  # 디버깅용 출력
  observe({
    if (!is.null(data_input()$data)) {
      cat("Data uploaded successfully\n")
      cat("Dimensions:", dim(data_input()$data), "\n")
      cat("Variables:", names(data_input()$data), "\n")
    }
  })
}
```

## Performance Considerations

### 대용량 파일 처리

```r
# 큰 파일 처리를 위한 최적화
# 1. 진행 상황 표시
withProgress(message = "Loading data...", {
  data_input <- callModule(csvFile, "datafile")
})

# 2. 청크 단위 읽기 (CSV의 경우)
# 3. 메모리 사용량 모니터링
# 4. 불필요한 변수 제거
```

### 반응성 최적화

```r
# 불필요한 재계산 방지
server <- function(input, output, session) {
  data_input <- callModule(csvFile, "datafile")
  
  # 데이터가 변경될 때만 업데이트
  processed_data <- reactive({
    req(data_input()$data)
    # 데이터 전처리 로직
    data_input()$data
  }) %>% bindCache(data_input()$data)
}
```

## Dependencies

### 필수 패키지

- `shiny` - 기본 Shiny 기능
- `DT` - 데이터 테이블 표시
- `readxl` - Excel 파일 읽기
- `haven` - SPSS, SAS, Stata 파일 읽기

### 선택적 패키지

- `shinycssloaders` - 로딩 애니메이션
- `shinyWidgets` - 향상된 UI 위젯
- `shinydashboard` - 대시보드 레이아웃

## Security Considerations

### 파일 업로드 보안

```r
# 1. 파일 타입 검증
# 모듈에서 자동으로 확장자 확인

# 2. 파일 크기 제한
# Shiny 설정으로 제어

# 3. 업로드된 파일 스캐닝
# 프로덕션 환경에서는 추가 보안 검사 권장

# 4. 임시 파일 정리
# Shiny가 자동으로 세션 종료 시 정리
```

## See Also

- `DataManager.R` - 데이터 관리 R6 클래스
- `FileSurveyInput.R` - 설문조사 데이터 전용 입력 모듈
- `FileRepeatedInput.R` - 반복측정 데이터 입력 모듈
- `FilePsInput.R` - 성향점수 분석용 데이터 입력 모듈