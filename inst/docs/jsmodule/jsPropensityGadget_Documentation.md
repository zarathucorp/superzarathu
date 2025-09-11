# jsPropensityGadget Documentation

## Overview
`jsPropensityGadget.R`은 jsmodule 패키지의 성향점수분석(Propensity Score Analysis) 전용 Shiny 가젯입니다. 관찰연구에서 인과추론을 위한 성향점수 매칭, 층화, 역확률가중 등의 고급 통계분석 기능을 대화형 인터페이스로 제공합니다.

## Main Functions

### `jsPropensityGadget(data, nfactor.limit = 20)`
R 데이터셋을 위한 성향점수분석 전용 가젯을 실행합니다.

**Parameters:**
- `data`: 분석할 R 데이터 객체 (data.frame, data.table 등)
- `nfactor.limit`: 범주형 변수의 최대 수준 수 (기본값: 20)

**Returns:**
- 성향점수분석에 특화된 Shiny 가젯 인터페이스

### `jsPropensityExtAddin(nfactor.limit = 20, max.filesize = 2048)`
외부 데이터 파일을 지원하는 확장 버전 성향점수분석 도구입니다.

**Parameters:**
- `nfactor.limit`: 범주형 변수의 최대 수준 수 (기본값: 20)
- `max.filesize`: 업로드 가능한 최대 파일 크기 (MB 단위, 기본값: 2048)

**Returns:**
- 파일 업로드 기능이 포함된 성향점수분석 가젯

## Usage Examples

### Basic Propensity Score Analysis
```r
library(jsmodule)

# 기본 데이터셋으로 성향점수분석
# 치료변수가 있는 관찰연구 데이터
treatment_data <- data.frame(
  id = 1:1000,
  treatment = rbinom(1000, 1, 0.3),
  age = rnorm(1000, 50, 15),
  gender = sample(c("M", "F"), 1000, replace = TRUE),
  comorbidity = rbinom(1000, 1, 0.4),
  outcome = rnorm(1000, 100, 20)
)

jsPropensityGadget(treatment_data)
```

### External Data Analysis
```r
library(jsmodule)

# 외부 파일에서 데이터 불러와서 분석
jsPropensityExtAddin()

# 큰 파일 지원 설정
jsPropensityExtAddin(max.filesize = 3000)  # 3GB 지원
```

### Clinical Research Example
```r
library(jsmodule)

# 실제 임상연구 데이터 예시
clinical_data <- data.frame(
  patient_id = 1:500,
  treatment_group = sample(c("Drug_A", "Control"), 500, replace = TRUE),
  age = rnorm(500, 65, 12),
  sex = sample(c("Male", "Female"), 500, replace = TRUE),
  hypertension = rbinom(500, 1, 0.6),
  diabetes = rbinom(500, 1, 0.3),
  baseline_score = rnorm(500, 50, 10),
  follow_up_score = rnorm(500, 45, 15),
  event = rbinom(500, 1, 0.2),
  time_to_event = rexp(500, 0.01)
)

# 성향점수분석 가젯 실행
jsPropensityGadget(clinical_data, nfactor.limit = 15)
```

## Interface Components

### Data Preparation Section
- **파일 업로드**: 다양한 형식의 데이터 파일 지원
- **변수 타입 설정**: 치료변수, 결과변수, 공변량 자동 감지
- **데이터 전처리**: 결측값 처리, 변수 변환

### Propensity Score Estimation
- **모델 선택**: 로지스틱 회귀, 일반화 부스팅 모델 등
- **변수 선택**: 자동/수동 공변량 선택
- **모델 진단**: AUC, 호스머-레메쇼 검정 등

### Matching Methods
- **1:1 매칭**: 최근접 이웃 매칭
- **1:n 매칭**: 다중 대조군 매칭
- **최적 매칭**: 전체 매칭 거리 최소화
- **캘리퍼 매칭**: 거리 임계값 설정

### Weighting Methods
- **IPTW**: 역확률가중 (Inverse Probability of Treatment Weighting)
- **SMRW**: 표준화 사망비 가중
- **ATT**: 처리군에서 처리효과 추정
- **ATE**: 모집단 평균 처리효과

### Balance Assessment
- **Table 1**: 매칭 전후 기술통계 비교
- **SMD**: 표준화평균차이 계산
- **Love Plot**: 균형성 시각화
- **밀도 그래프**: 성향점수 분포 비교

## Advanced Analysis Features

### Outcome Analysis
```r
# 분석 워크플로우 예시

# 1단계: 성향점수분석 설정
ps_analysis <- list(
  treatment_var = "treatment_group",
  outcome_var = "follow_up_score", 
  covariates = c("age", "sex", "hypertension", "diabetes", "baseline_score"),
  matching_method = "nearest",
  caliper = 0.2
)

# 2단계: 가젯에서 대화형 분석 수행
jsPropensityGadget(clinical_data)
```

### Sensitivity Analysis
- **은닉 편향 분석**: Rosenbaum 민감도 분석
- **E-value**: 관찰되지 않은 교란변수 영향 평가
- **Multiple Imputation**: 결측값에 대한 민감도 분석

### Subgroup Analysis
- **층화분석**: 특정 하위그룹별 치료효과
- **효과 수정**: 상호작용 효과 평가
- **이질성 검정**: 그룹 간 치료효과 차이

## Propensity Score Methods

### Model Specification
```r
# 성향점수 모델 예시
propensity_model <- glm(
  treatment ~ age + sex + comorbidity + baseline_score,
  data = data,
  family = binomial()
)

# 성향점수 계산
data$propensity_score <- predict(propensity_model, type = "response")
```

### Matching Algorithms
```r
# MatchIt 패키지 활용 매칭
library(MatchIt)

# 1:1 최근접 이웃 매칭
match_result <- matchit(
  treatment ~ age + sex + comorbidity,
  data = data,
  method = "nearest",
  ratio = 1,
  caliper = 0.25
)

# 매칭된 데이터 추출
matched_data <- match.data(match_result)
```

### Weighting Implementation
```r
# IPTW 가중치 계산
data$iptw_weight <- ifelse(
  data$treatment == 1,
  1 / data$propensity_score,
  1 / (1 - data$propensity_score)
)

# 가중치 절단 (극값 처리)
data$iptw_weight_trimmed <- pmin(
  data$iptw_weight, 
  quantile(data$iptw_weight, 0.95)
)
```

## Balance Assessment Tools

### Standardized Mean Difference
```r
# SMD 계산 함수
calculate_smd <- function(var, treatment, matched = FALSE, weights = NULL) {
  if(matched) {
    # 매칭된 데이터에서 SMD
    treated <- var[treatment == 1]
    control <- var[treatment == 0]
  } else {
    # 가중치 적용 SMD (IPTW의 경우)
    if(!is.null(weights)) {
      # 가중 평균 및 분산 계산
      treated_mean <- weighted.mean(var[treatment == 1], weights[treatment == 1])
      control_mean <- weighted.mean(var[treatment == 0], weights[treatment == 0])
      # ... 추가 계산
    }
  }
  
  pooled_sd <- sqrt((var(treated) + var(control)) / 2)
  smd <- (mean(treated) - mean(control)) / pooled_sd
  
  return(abs(smd))
}
```

### Visual Balance Assessment
- **Love Plot**: 매칭 전후 SMD 비교
- **밀도 그래프**: 공변량 분포 비교  
- **QQ Plot**: 분포 일치성 검사
- **성향점수 히스토그램**: 공통 지지 확인

## Treatment Effect Estimation

### Average Treatment Effect (ATE)
```r
# 매칭 후 처리효과 추정
ate_matched <- lm(outcome ~ treatment, data = matched_data)

# IPTW 후 처리효과 추정  
ate_weighted <- lm(outcome ~ treatment, 
                   data = data, 
                   weights = iptw_weight_trimmed)
```

### Confidence Intervals
- **Bootstrap**: 재표본추출을 통한 신뢰구간
- **Robust SE**: 이분산성을 고려한 표준오차
- **Cluster SE**: 군집화된 표준오차

### Multiple Outcomes
- **주요 결과**: Primary endpoint 분석
- **부차적 결과**: Secondary endpoint 분석
- **복합 결과**: Composite outcome 처리

## Quality Control Features

### Matching Quality Assessment
```r
# 매칭 품질 평가 지표
quality_metrics <- list(
  balance_improved = mean(smd_after < smd_before),
  excellent_balance = sum(smd_after < 0.1) / length(smd_after),
  adequate_balance = sum(smd_after < 0.25) / length(smd_after),
  sample_retained = nrow(matched_data) / nrow(original_data)
)
```

### Diagnostics and Warnings
- **공통 지지 위반**: 성향점수 범위 불일치 경고
- **극단적 가중치**: IPTW에서 매우 큰 가중치 탐지
- **매칭 실패**: 적절한 대조군 찾기 실패
- **균형 실패**: SMD > 0.25인 변수들 경고

## Technical Implementation

### Dependencies
```r
# 필수 패키지들
required_packages <- c(
  "shiny",           # 웹 애플리케이션
  "MatchIt",         # 성향점수 매칭
  "WeightIt",        # 가중치 추정
  "cobalt",          # 균형 평가
  "ggplot2",         # 시각화
  "dplyr",           # 데이터 조작
  "survey",          # 가중 분석
  "survival"         # 생존분석
)
```

### Performance Optimization
- **메모리 효율성**: 큰 데이터셋을 위한 최적화
- **병렬 처리**: 매칭 알고리즘 병렬화
- **캐싱**: 반복 계산 결과 저장
- **프로그레스바**: 장시간 계산 진행상황 표시

### Error Handling
```r
# 일반적인 오류 처리
tryCatch({
  # 매칭 수행
  match_result <- matchit(formula, data, method, ...)
}, error = function(e) {
  showNotification(
    paste("Matching failed:", e$message),
    type = "error"
  )
})
```

## Best Practices Integration

### Study Design Considerations
- **교란변수 선택**: 도메인 전문지식 기반
- **표본 크기**: 매칭 후 충분한 표본 확보
- **결과 정의**: 명확한 결과변수 정의
- **추적관찰 기간**: 충분한 관찰 기간

### Reporting Guidelines
- **STROBE**: 관찰연구 보고 지침
- **매칭 세부사항**: 알고리즘, 캘리퍼, 비율 명시
- **균형 평가**: 모든 공변량의 SMD 보고
- **민감도 분석**: 은닉 편향 가능성 평가

## Export and Reporting

### Analysis Results Export
```r
# 결과 내보내기 옵션
export_formats <- list(
  balance_table = c("CSV", "Excel", "LaTeX"),
  plots = c("PNG", "PDF", "SVG"),
  matched_data = c("CSV", "RDS"),
  analysis_report = c("HTML", "PDF", "Word")
)
```

### Automated Reporting
- **균형표**: 매칭 전후 비교 테이블
- **진단 그래프**: Love plot, 밀도 그래프 등
- **처리효과**: 추정값, 신뢰구간, P-값
- **민감도 분석**: 강건성 평가 결과

## Version Notes
이 문서는 jsmodule 패키지의 성향점수분석 가젯을 기반으로 작성되었습니다. 최신 버전에서는 추가 매칭 방법이나 균형 평가 기능이 포함될 수 있습니다.