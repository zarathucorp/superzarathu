# SuperZarathu 공통 지시사항

## 🔴 필수 준수 사항

### 언어 설정
- **모든 코드는 R로 작성하세요**
- Python, JavaScript, SQL 등 다른 언어 사용 금지
- R 버전 4.0 이상 기준으로 작성

### 프로젝트 구조 준수
```
project/
├── data/
│   ├── raw/         # 원본 데이터만
│   └── processed/   # 처리된 데이터만
├── scripts/
│   ├── utils/       # 재사용 함수들
│   ├── analysis/    # 분석 스크립트
│   ├── plots/       # 시각화 함수
│   └── tables/      # 테이블 생성 함수
├── output/
│   ├── plots/       # 그래프 출력
│   ├── tables/      # 테이블 출력
│   └── reports/     # 보고서
├── app.R            # Shiny 앱
├── global.R         # 전역 설정
└── run_analysis.R   # 메인 실행
```

## ⚠️ 보안 및 성능 규칙

### 절대 하지 말아야 할 것들
- ❌ `print(data)` - 전체 데이터 출력 금지
- ❌ `View(data)` - 데이터 뷰어 사용 금지
- ❌ `data` - 콘솔에 데이터 객체 직접 출력 금지
- ❌ 개인정보(주민번호, 환자명, ID) 노출 금지
- ❌ 파일 경로에 하드코딩된 절대경로 사용 금지

### 반드시 사용해야 할 것들
- ✅ `head(data, 5)` - 상위 5행만 확인
- ✅ `str(data)` - 구조만 확인
- ✅ `summary(data)` - 통계 요약만
- ✅ `dim(data)` - 크기만 확인
- ✅ `names(data)` - 변수명만 확인
- ✅ 상대경로 사용 (예: "data/raw/file.csv")

## 📦 패키지 사용 규칙

### 필수 패키지
```r
# 데이터 처리
library(data.table)
library(tidyverse)
library(openxlsx)

# 통계 분석
library(jstable)
library(jskm)
library(jsmodule)
library(survival)
library(survminer)

# 시각화
library(ggplot2)
library(plotly)
library(pheatmap)

# Shiny
library(shiny)
library(shinydashboard)
library(DT)
```

### 패키지 설치 확인
- 패키지 사용 전 반드시 설치 여부 확인
- 필요시 `install.packages()` 코드 제공
- CRAN에 없는 패키지는 GitHub 설치 명령 제공

## 📝 코드 작성 규칙

### 함수 정의
```r
# 좋은 예: 명확한 함수명과 주석
preprocess_data <- function(input_file, output_file = NULL) {
  # 데이터 읽기
  data <- read.csv(input_file)
  
  # 처리
  # ...
  
  # 저장
  if (!is.null(output_file)) {
    saveRDS(data, output_file)
  }
  
  return(data)
}
```

### 에러 처리
```r
# 항상 에러 처리 포함
tryCatch({
  # 위험한 작업
  data <- read.csv(file_path)
}, error = function(e) {
  message("Error reading file: ", e$message)
  return(NULL)
})
```

### 경로 처리
```r
# 좋은 예: file.path() 사용
data_path <- file.path("data", "raw", "mydata.csv")

# 나쁜 예: 하드코딩
# data_path <- "/Users/john/project/data/raw/mydata.csv"
```

## 🎯 작업 순서

### 1단계: 데이터 전처리
- `data/raw/`에서 데이터 읽기
- 정제 및 변환
- `data/processed/`에 RDS로 저장

### 2단계: 라벨링
- `data/processed/`에서 데이터 읽기
- 변수명과 값 라벨링
- 코드북 생성/적용

### 3단계: 분석
- 기술통계 (Table 1)
- 추론통계 (회귀분석, 생존분석)
- 결과 해석

### 4단계: 시각화
- 적절한 그래프 타입 선택
- ggplot2 기반 시각화
- `output/plots/`에 저장

### 5단계: 보고서
- 결과 정리
- 테이블과 그래프 통합
- `output/reports/`에 저장

## 🌐 자연어 이해

### 한국어 요청 처리
- "~해줘", "~하세요" 등 존댓말/반말 모두 이해
- 의학/통계 용어 한글 표현 인식
  - "생존분석" = Survival Analysis
  - "기초특성표" = Table 1
  - "회귀분석" = Regression

### 파일명 추론
- "최신 데이터" → 가장 최근 수정된 파일
- "설문 데이터" → survey가 포함된 파일명
- 명시적 파일명 없으면 자동 탐지

## 🔧 디버깅 지침

### 문제 발생시
1. 에러 메시지 전체 확인
2. `traceback()` 실행
3. 데이터 구조 확인 (`str()`)
4. 패키지 버전 확인 (`packageVersion()`)

### 로그 작성
```r
# 진행 상황 로그
message("Step 1: Loading data...")
message(sprintf("Loaded %d rows and %d columns", nrow(data), ncol(data)))

# 경고
warning("Missing values detected in column: ", col_name)

# 에러
stop("File not found: ", file_path)
```

## 🚀 최종 체크리스트

작업 완료 전 확인:
- [ ] R 코드만 사용했는가?
- [ ] 프로젝트 구조를 준수했는가?
- [ ] 민감정보가 노출되지 않았는가?
- [ ] 에러 처리가 포함되었는가?
- [ ] 상대경로를 사용했는가?
- [ ] 필요한 패키지를 모두 로드했는가?
- [ ] 결과물이 적절한 폴더에 저장되는가?