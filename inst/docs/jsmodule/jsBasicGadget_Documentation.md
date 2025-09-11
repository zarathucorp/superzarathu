# jsBasicGadget Documentation

## Overview
`jsBasicGadget.R`은 jsmodule 패키지의 기본 통계분석용 Shiny 가젯(Gadget)입니다. R 환경에서 대화형 통계분석 도구를 제공하며, 데이터 탐색, 기술통계, 회귀분석, 시각화 등 다양한 통계분석 기능을 통합된 인터페이스로 제공합니다.

## Main Functions

### `jsBasicGadget(data, nfactor.limit = 20)`
R 데이터셋을 위한 대화형 통계분석 가젯을 실행합니다.

**Parameters:**
- `data`: 분석할 R 데이터 객체 (data.frame, data.table 등)
- `nfactor.limit`: 범주형 변수의 최대 수준 수 (기본값: 20)

**Returns:**
- Shiny 가젯 인터페이스를 실행하며, 분석 결과를 대화형으로 제공

### `jsBasicExtAddin(nfactor.limit = 20, max.filesize = 2048)`
외부 데이터 파일 지원이 포함된 확장 버전 통계분석 도구를 실행합니다.

**Parameters:**
- `nfactor.limit`: 범주형 변수의 최대 수준 수 (기본값: 20)
- `max.filesize`: 업로드 가능한 최대 파일 크기 (MB 단위, 기본값: 2048)

**Returns:**
- 파일 업로드 기능이 포함된 Shiny 가젯 인터페이스

## Usage Examples

### Basic Usage with R Dataset
```r
library(jsmodule)

# mtcars 데이터셋으로 기본 분석
jsBasicGadget(mtcars)

# iris 데이터셋으로 분석 (범주형 변수 수준 제한)
jsBasicGadget(iris, nfactor.limit = 10)

# 생존 분석 데이터 예시
library(survival)
jsBasicGadget(lung)
```

### External Data Analysis
```r
library(jsmodule)

# 외부 파일 지원 버전 실행
jsBasicExtAddin()

# 큰 파일 지원을 위한 설정
jsBasicExtAddin(max.filesize = 5000)  # 5GB까지 지원

# 범주형 변수 수준 제한
jsBasicExtAddin(nfactor.limit = 15)
```

### Integration with RStudio
```r
# RStudio Addins 메뉴에서 실행 가능
# "jsmodule - Statistical Analysis"를 선택하여 실행
```

## Interface Components

### Data Import Section
- **파일 업로드**: CSV, Excel, SAS, SPSS, Stata 파일 지원
- **데이터 미리보기**: 업로드된 데이터 구조 확인
- **변수 타입 설정**: 자동 타입 감지 및 수동 조정

### Descriptive Analysis
- **Table 1**: 기본 기술통계표 생성
- **변수별 요약**: 연속형/범주형 변수 요약 통계
- **그룹별 비교**: 층화 분석 및 통계검정

### Visualization Tools
- **기본 그래프**: 히스토그램, 상자그림, 산점도
- **고급 시각화**: ggplot2 기반 맞춤형 그래프
- **상관관계 매트릭스**: 변수 간 상관관계 시각화

### Statistical Analysis
- **선형회귀**: 연속형 종속변수 분석
- **로지스틱회귀**: 이진형 종속변수 분석
- **생존분석**: Cox 비례위험모델, Kaplan-Meier 곡선
- **ROC 분석**: 예측 성능 평가

### Advanced Features
- **하위그룹 분석**: 특정 조건별 분층 분석
- **Forest Plot**: 메타분석 스타일 결과 시각화
- **결과 내보내기**: 테이블 및 그래프 저장

## Supported File Formats

### Input Data Formats
```r
# 지원 파일 형식
supported_formats <- c(
  "CSV files (*.csv)",
  "Excel files (*.xlsx, *.xls)", 
  "SAS files (*.sas7bdat)",
  "SPSS files (*.sav)",
  "Stata files (*.dta)",
  "R data files (*.rdata, *.rds)"
)
```

### Data Processing
- **자동 인코딩 감지**: UTF-8, EUC-KR 등 한국어 인코딩 지원
- **결측값 처리**: NA, 빈 문자열 등 자동 감지
- **변수 타입 추론**: 숫자, 문자, 날짜 등 자동 분류

## Interface Layout

### Sidebar Panel
- 데이터 업로드/선택
- 분석 옵션 설정
- 변수 선택 도구
- 출력 형식 설정

### Main Panel
- 분석 결과 테이블
- 시각화 출력
- 모델 요약
- 진단 도구

### Tab Structure
```r
# 주요 탭 구성
tabs <- list(
  "Data" = "데이터 탐색 및 기술통계",
  "Table" = "기술통계표 (Table 1)",
  "Plot" = "데이터 시각화",
  "Regression" = "회귀분석",
  "Survival" = "생존분석",
  "ROC" = "ROC 분석",
  "Subgroup" = "하위그룹 분석"
)
```

## Advanced Configuration

### Custom Settings
```r
# 사용자 정의 설정 예시
custom_config <- list(
  nfactor.limit = 15,           # 범주형 변수 제한
  max.filesize = 1000,          # 파일 크기 제한 (MB)
  default.digits = 3,           # 소수점 자릿수
  plot.theme = "minimal",       # 그래프 테마
  export.format = c("png", "pdf") # 내보내기 형식
)

jsBasicExtAddin(
  nfactor.limit = custom_config$nfactor.limit,
  max.filesize = custom_config$max.filesize
)
```

### Performance Optimization
```r
# 메모리 사용량 최적화
options(
  shiny.maxRequestSize = 2048*1024^2,  # 2GB 파일 업로드
  DT.options = list(pageLength = 25),  # 테이블 페이지 크기
  ggplot2.continuous.colour = "viridis" # 색상 팔레트
)
```

## Integration Examples

### RStudio Addins Integration
```r
# .rs 파일에서 Addins 등록
# File: inst/rstudio/addins.dcf

Name: jsmodule - Statistical Analysis
Description: Interactive statistical analysis tool
Binding: jsBasicExtAddin
Interactive: true
```

### Custom Data Pipeline
```r
# 데이터 전처리 후 가젯 실행
library(dplyr)
library(jsmodule)

# 데이터 전처리
processed_data <- raw_data %>%
  mutate(
    age_group = cut(age, breaks = c(0, 30, 50, 70, Inf)),
    bmi_category = case_when(
      bmi < 18.5 ~ "Underweight",
      bmi < 25 ~ "Normal", 
      bmi < 30 ~ "Overweight",
      TRUE ~ "Obese"
    )
  ) %>%
  filter(!is.na(outcome))

# 가젯으로 분석
jsBasicGadget(processed_data, nfactor.limit = 12)
```

### Batch Analysis Workflow
```r
# 여러 데이터셋 순차 분석
datasets <- list(
  clinical = clinical_data,
  laboratory = lab_data,
  imaging = image_data
)

# 각 데이터셋별 분석
for(dataset_name in names(datasets)) {
  cat("Analyzing:", dataset_name, "\n")
  jsBasicGadget(datasets[[dataset_name]])
}
```

## Technical Details

### Dependencies
```r
# 필수 패키지
required_packages <- c(
  "shiny",           # 웹 애플리케이션 프레임워크
  "shinycssloaders", # 로딩 애니메이션
  "shinyWidgets",    # 고급 UI 위젯
  "DT",              # 대화형 테이블
  "data.table",      # 고성능 데이터 처리
  "ggplot2",         # 고급 그래프
  "plotly",          # 대화형 그래프
  "survival",        # 생존분석
  "jstable"          # 통계 테이블 생성
)
```

### System Requirements
- **R Version**: R >= 4.0.0 권장
- **Memory**: 최소 4GB RAM (큰 데이터셋의 경우 더 많이 필요)
- **Browser**: Chrome, Firefox, Safari, Edge 지원
- **Platform**: Windows, macOS, Linux

### Performance Characteristics
- **파일 크기**: 기본 2GB까지 업로드 지원
- **처리 속도**: 100만 행 데이터까지 실시간 처리
- **동시 분석**: 단일 세션에서 여러 분석 동시 수행
- **메모리 효율성**: data.table 기반 메모리 최적화

## Error Handling

### Common Issues and Solutions

#### File Upload Errors
```r
# 파일 크기 초과 시
if(file.size > max.filesize * 1024^2) {
  showNotification(
    "File size exceeds limit. Please increase max.filesize parameter.",
    type = "error"
  )
}

# 지원하지 않는 파일 형식
if(!file_extension %in% supported_formats) {
  showNotification(
    "Unsupported file format. Please convert to CSV or Excel.",
    type = "warning"
  )
}
```

#### Data Processing Errors
```r
# 범주형 변수 수준 초과
if(length(levels(factor_var)) > nfactor.limit) {
  showNotification(
    paste("Variable has too many levels. Increase nfactor.limit or recode variable."),
    type = "warning"
  )
}

# 메모리 부족
if(object.size(data) > available_memory * 0.8) {
  showNotification(
    "Dataset too large for available memory. Consider sampling or increasing RAM.",
    type = "error"
  )
}
```

### Debugging Features
- **데이터 미리보기**: 업로드된 데이터 구조 확인
- **변수 정보**: 각 변수의 타입, 결측값, 고유값 수 표시
- **분석 로그**: 수행된 분석 단계별 기록
- **오류 메시지**: 사용자 친화적 오류 설명

## Export Capabilities

### Result Export Options
```r
# 지원하는 내보내기 형식
export_options <- list(
  tables = c("CSV", "Excel", "HTML"),
  plots = c("PNG", "PDF", "SVG", "JPEG"),
  reports = c("HTML", "PDF", "Word")
)
```

### Automated Reporting
```r
# 분석 결과 자동 보고서 생성
generate_report <- function(analysis_results) {
  rmarkdown::render(
    input = "analysis_template.Rmd",
    params = list(
      data = analysis_results$data,
      tables = analysis_results$tables,
      plots = analysis_results$plots
    ),
    output_format = "html_document"
  )
}
```

## Version Notes
이 문서는 jsmodule 패키지의 기본 통계분석 가젯을 기반으로 작성되었습니다. 최신 버전에서는 추가 기능이나 인터페이스 변경이 있을 수 있습니다.