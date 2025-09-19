# superzarathu

[![GitHub](https://img.shields.io/badge/GitHub-zarathucorp%2Fsuperzarathu-blue)](https://github.com/zarathucorp/superzarathu)
[![R Package](https://img.shields.io/badge/R%20Package-0.2.0-green)](https://github.com/zarathucorp/superzarathu)

> AI 어시스턴트(Claude Code & Gemini CLI)를 위한 데이터 분석 워크플로우 커스텀 명령어 생성 패키지

[English Documentation](README.md)

## 개요

`superzarathu`는 데이터 분석 워크플로우를 위한 지능형 템플릿과 커스텀 명령어를 생성하는 R 패키지입니다. **Claude Code**와 **Gemini CLI**를 모두 지원하며, 데이터 전처리, 라벨링, 통계 분석, 시각화, Shiny 애플리케이션 개발을 위한 사전 정의된 워크플로우를 제공합니다.

### 주요 기능

- 🤖 **AI 주도 워크플로우**: AI 어시스턴트가 이해하고 실행하기 최적화된 템플릿
- 📊 **데이터 처리**: 임상시험 데이터 지원을 포함한 고급 전처리
- 🩺 **데이터 닥터**: 종합적인 데이터 건강 체크 및 진단
- 📋 **엑셀 품질 검사**: AI 친화적 출력을 제공하는 종합적인 엑셀 데이터 품질 평가
- 🏷️ **스마트 라벨링**: jstable 통합으로 자동 변수 라벨링
- 📈 **통계 분석**: 한국 의료 통계 패키지(jstable, jskm, jsmodule) 템플릿
- 🎨 **시각화**: ggplot2 및 인터랙티브 그래픽 생성
- ⚡ **Shiny 앱**: 빠른 Shiny 애플리케이션 개발 템플릿

## 설치 방법

GitHub에서 개발 버전을 설치할 수 있습니다:

```r
# devtools 사용
install.packages("devtools")
devtools::install_github("zarathucorp/superzarathu")

# remotes 사용 (더 가벼운 대안)
install.packages("remotes")
remotes::install_github("zarathucorp/superzarathu")

# pak 사용 (최신 방법)
install.packages("pak")
pak::pak("zarathucorp/superzarathu")
```

## 빠른 시작

### 기본 설정

```r
library(superzarathu)

# Claude Code용 설정
sz_setup("claude")

# Gemini CLI용 설정
sz_setup("gemini")
```

### 명령어 사용법

설정 후 자연어 명령어를 사용하세요:

```r
# 데이터 전처리
"데이터 전처리해줘"
"반복 측정 임상시험 데이터 처리해줘"

# 데이터 건강 체크
"데이터 진단해줘"
"데이터 건강 체크해줘"
"데이터 문제점 찾아줘"

# 데이터 라벨링
"데이터 라벨링해줘"
"jstable로 라벨 적용해줘"

# 통계 분석
"기술통계표 만들어줘"
"생존분석 수행해줘"

# 시각화
"forest plot 그려줘"
"인터랙티브 플롯 만들어줘"

# Shiny 앱
"shiny 대시보드 만들어줘"
```

## 사용 가능한 명령어

### 데이터 처리

- `sz:preprocess` - 데이터 정제 및 변환
- `sz:doctor` - 데이터 건강 체크 및 진단
- `sz:label` - 변수 라벨링 및 메타데이터 관리
- `excel_health_check()` - 종합적인 엑셀 데이터 품질 평가

### 통계 분석

- `sz:table` - jstable을 사용한 기술통계 및 분석 테이블

### 시각화

- `sz:plot` - ggplot2와 jskm을 사용한 정적 및 인터랙티브 플롯

### Shiny 개발

- `sz:rshiny` - jsmodule을 사용한 Shiny 애플리케이션 템플릿

## 엑셀 데이터 품질 평가

`excel_health_check()` 함수는 엑셀 파일의 종합적인 품질 평가를 제공합니다:

```r
library(superzarathu)

# 현재 디렉토리의 모든 엑셀 파일 검사
result <- excel_health_check()

# 특정 파일들만 검사
result <- excel_health_check(files = c("data1.xlsx", "data2.xlsx"))

# JSON 출력만 생성
result <- excel_health_check(output_format = "json")
```

### 기능

- **19가지 품질 검사 유형**: 구조적 문제, 표기법 불일치, 값 오류, 데이터 누락, 숨겨진 문제
- **헤더 구조 시각화**: 알고리즘 감지 결과와 실제 내용을 비교할 수 있는 확장 컨텍스트 제공
- **AI/인간 분석 지원**: 코드북/예시 행과 실제 헤더를 구분할 수 있는 상세 시각화
- **AI 친화적 출력**: 더 나은 AI 이해를 위한 스키마가 포함된 JSON 결과
- **상세 보고서**: 실행 가능한 권장사항이 포함된 마크다운 보고서
- **데이터 보존**: 읽기 전용 접근법 - 원본 파일을 절대 수정하지 않음
- **R 표준**: R 관례에 따라 빈 문자열을 NA로 변환

### 출력 파일

- `sz_excel_results_YYYYMMDD_HHMMSS.json` - 상세 결과
- `sz_excel_schema.json` - AI 상호 운용성을 위한 JSON 스키마
- `sz_excel_report_YYYYMMDD_HHMMSS.md` - 사람이 읽기 쉬운 보고서

## 템플릿 특징

### 고급 데이터 전처리

- 📁 `data/raw/`에서 자동 파일 탐지
- 🔄 임상시험 반복 측정 처리 (V1, V2, V3)
- 📅 지능형 날짜 변환 및 나이 계산
- 🧹 다양한 전략의 NA 처리
- 📌 S3/로컬 저장소를 위한 pins 패키지 통합

### 데이터 건강 체크 (Doctor)

- 🎯 데이터 품질 점수 (A+ ~ F 등급)
- 🔍 자동 패턴 감지 (반복 측정, 임상시험, 설문조사)
- ⚠️ 컬럼별 문제점 식별
- ❓ 데이터 생산자를 위한 지능형 질문 생성
- 📄 상세 진단이 포함된 Markdown 리포트 생성

### 스마트 라벨링 시스템

- 🏷️ jstable::mk.lev() 통합
- 🔢 자동 0/1 → No/Yes 변환
- 📊 Factor/continuous 변수 자동 분류
- 📖 코드북 자동 탐지 및 적용
- 🌐 다국어 라벨 지원

### AI 워크플로우 접근법

템플릿은 2단계 접근법을 사용합니다:

1. **탐색 단계** (직접 실행)

   ```bash
   Rscript -e "str(data, list.len=5)"
   ```

2. **처리 단계** (스크립트 생성)
   ```r
   # 재현 가능한 스크립트 생성
   source("scripts/preprocess_data.R")
   ```

## 프로젝트 구조

패키지는 체계적인 프로젝트 구조를 생성합니다:

```
project/
├── data/
│   ├── raw/        # 원본 데이터 파일
│   └── processed/  # 정제된 데이터 (RDS)
├── scripts/
│   ├── utils/      # 헬퍼 함수
│   ├── analysis/   # 분석 스크립트
│   └── plots/      # 시각화 스크립트
├── output/
│   ├── tables/     # 생성된 테이블
│   └── plots/      # 생성된 플롯
└── app.R           # Shiny 애플리케이션
```

## 시스템 요구사항

### 핵심 의존성

- R (≥ 3.5.0)
- data.table
- openxlsx
- ggplot2

### 권장 패키지

- jstable (의료 통계)
- jskm (생존 곡선)
- jsmodule (Shiny 모듈)
- pins (데이터 버전 관리)

## 실제 사용 예시

### 임상시험 데이터 처리

```r
# AI에게 지시
"임상시험 데이터 전처리해줘"

# AI가 자동으로:
# 1. Excel 파일 구조 파악 (시트, 컬럼 수 확인)
# 2. 반복 측정 구조 감지 (V1, V2, V3)
# 3. 날짜 변환 및 나이 계산
# 4. 스크립트 생성 및 실행
```

### 데이터 건강 체크

```r
# AI에게 지시
"데이터 진단해줘"

# AI가 자동으로:
# 1. 데이터 품질 점수 계산 (A+ ~ F)
# 2. 컬럼별 문제점 식별
# 3. 데이터 패턴 감지 (반복 측정, 임상시험 등)
# 4. 데이터 생산자를 위한 질문 목록 생성
# 5. Markdown 리포트 생성
```

### 데이터 라벨링

```r
# AI에게 지시
"데이터에 라벨 붙여줘"

# AI가 자동으로:
# 1. 코드북 탐색 (Excel 시트, 별도 파일)
# 2. 0/1 변수 → No/Yes 자동 변환
# 3. jstable로 라벨 테이블 생성
# 4. factor/continuous 분류
```

## 기여하기

기여를 환영합니다! Pull Request를 보내주세요.

1. 저장소 포크
2. 기능 브랜치 생성 (`git checkout -b feature/AmazingFeature`)
3. 변경사항 커밋 (`git commit -m 'Add some AmazingFeature'`)
4. 브랜치 푸시 (`git push origin feature/AmazingFeature`)
5. Pull Request 열기

## 제작자

- **Zarathu Corp** - [office@zarathu.com](mailto:office@zarathu.com)
- **허재웅** - [jwheo@zarathu.com](mailto:jwheo@zarathu.com)

## 라이센스

이 프로젝트는 MIT 라이센스를 따릅니다 - 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

## 감사의 글

- Claude Code와 Gemini CLI와의 원활한 통합을 위해 제작되었습니다
- 의료 및 임상 연구 워크플로우에 최적화되어 있습니다
- 실제 데이터 분석 패턴을 기반으로 한 템플릿

## 지원

문제 및 질문:

- 🐛 [버그 신고](https://github.com/zarathucorp/superzarathu/issues)
- 💡 [기능 요청](https://github.com/zarathucorp/superzarathu/issues)
- 📧 [지원 문의](mailto:office@zarathu.com)
