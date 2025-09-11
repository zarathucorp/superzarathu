# forestcox Documentation

## Overview

`forestcox.R`은 jstable 패키지에서 Cox 비례위험모델의 서브그룹 분석을 수행하고 Forest plot 형태의 결과를 생성하는 함수들을 제공합니다. 단일 또는 다중 서브그룹 분석을 통해 다양한 하위집단에서의 치료효과나 위험요인의 영향을 시각적으로 비교할 수 있습니다.

## Functions

### `TableSubgroupCox()`

Cox/survey Cox 모델의 서브그룹 분석을 수행합니다.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `formula` | formula | - | 생존분석 공식 (Surv 객체 포함) |
| `var_subgroup` | character | - | 서브그룹 분석용 변수 |
| `data` | data.frame/survey.design | - | 데이터 또는 survey design 객체 |
| `time_eventrate` | numeric | 3 * 365 | Kaplan-Meier 사건율 계산 시점 (일) |
| `var_cov` | character | NULL | 공변량 변수들 |
| `decimal.hr` | integer | 2 | 위험비 소수점 자릿수 |
| `decimal.percent` | integer | 1 | 백분율 소수점 자릿수 |
| `decimal.pvalue` | integer | 3 | p-value 소수점 자릿수 |
| `line` | logical | FALSE | 서브그룹 간 구분선 표시 |
| `cluster` | character | NULL | 클러스터 변수 |
| `strata` | character | NULL | 층화 변수 |
| `data.label` | data.frame | NULL | 변수 레이블 데이터 |

#### Example

```r
library(survival)
data(lung)

# 기본 서브그룹 분석
lung$kk <- factor(as.integer(lung$pat.karno >= 70))
result1 <- TableSubgroupCox(
  formula = Surv(time, status) ~ sex, 
  var_subgroup = "kk", 
  data = lung, 
  time_eventrate = 100
)

# 공변량 포함
result2 <- TableSubgroupCox(
  formula = Surv(time, status) ~ sex, 
  var_subgroup = "kk", 
  var_cov = c("age", "ph.ecog"),
  data = lung
)

# Survey 데이터 사용
library(survey)
lung_survey <- svydesign(ids = ~1, data = lung, weights = ~wt.loss)
result3 <- TableSubgroupCox(
  formula = Surv(time, status) ~ sex, 
  var_subgroup = "kk", 
  data = lung_survey
)
```

### `TableSubgroupMultiCox()`

다중 서브그룹 변수에 대한 Cox 모델 분석을 수행합니다.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `formula` | formula | - | 생존분석 공식 |
| `var_subgroups` | character vector | - | 다중 서브그룹 변수들 |
| `data` | data.frame/survey.design | - | 데이터 또는 survey design 객체 |
| `time_eventrate` | numeric | 3 * 365 | 사건율 계산 시점 |
| `line` | logical | FALSE | 서브그룹 변수 간 구분선 표시 |
| `var_cov` | character | NULL | 공변량 변수들 |
| `decimal.hr` | integer | 2 | 위험비 소수점 자릿수 |
| `decimal.percent` | integer | 1 | 백분율 소수점 자릿수 |
| `decimal.pvalue` | integer | 3 | p-value 소수점 자릿수 |
| `cluster` | character | NULL | 클러스터 변수 |
| `strata` | character | NULL | 층화 변수 |
| `data.label` | data.frame | NULL | 변수 레이블 데이터 |

#### Example

```r
library(survival)
data(lung)

# 다중 서브그룹 변수 준비
lung$kk <- factor(as.integer(lung$pat.karno >= 70))
lung$kk1 <- factor(as.integer(lung$age >= 65))

# 다중 서브그룹 분석
result <- TableSubgroupMultiCox(
  formula = Surv(time, status) ~ sex,
  var_subgroups = c("kk", "kk1"),
  data = lung, 
  time_eventrate = 100,
  line = TRUE
)

# 공변량 포함 다중 분석
result_cov <- TableSubgroupMultiCox(
  formula = Surv(time, status) ~ sex,
  var_subgroups = c("kk", "kk1"),
  var_cov = c("ph.ecog"),
  data = lung,
  line = TRUE
)
```

## Usage Notes

### 기본 사용 패턴

```r
library(survival)
data(lung)

# 1. 데이터 준비
lung$performance <- factor(ifelse(lung$ph.ecog <= 1, "Good", "Poor"))
lung$age_group <- factor(ifelse(lung$age >= 65, "Elderly", "Younger"))

# 2. 단일 서브그룹 분석
single_result <- TableSubgroupCox(
  formula = Surv(time, status) ~ sex,
  var_subgroup = "performance",
  data = lung
)

# 3. 다중 서브그룹 분석
multi_result <- TableSubgroupMultiCox(
  formula = Surv(time, status) ~ sex,
  var_subgroups = c("performance", "age_group"),
  data = lung,
  line = TRUE
)
```

### Survey 데이터 활용

```r
library(survey)

# Survey design 생성
design <- svydesign(
  ids = ~cluster_id,
  strata = ~stratum,
  weights = ~weight,
  data = survey_data
)

# Survey Cox 서브그룹 분석
survey_result <- TableSubgroupCox(
  formula = Surv(time, event) ~ treatment,
  var_subgroup = "center_type",
  data = design
)
```

### 고급 설정

```r
# 클러스터링 및 층화 적용
advanced_result <- TableSubgroupCox(
  formula = Surv(time, status) ~ treatment,
  var_subgroup = "hospital_type",
  var_cov = c("age", "sex", "comorbidity"),
  cluster = "hospital_id",
  strata = "region",
  data = clinical_data,
  decimal.hr = 3,
  decimal.pvalue = 4
)
```

## Output Format

### 결과 테이블 구조

| Column | Description |
|--------|-------------|
| Subgroup | 서브그룹 범주 |
| No. of Subjects | 대상자 수 |
| No. of Events | 사건 발생 수 |
| Event Rate (%) | 사건 발생률 |
| HR | 위험비 (Hazard Ratio) |
| 95% CI | 95% 신뢰구간 |
| P-value | 유의확률 |
| P for interaction | 상호작용 p-value |

### 해석 가이드

- **HR > 1**: 노출군에서 위험 증가
- **HR < 1**: 노출군에서 위험 감소  
- **HR = 1**: 위험 차이 없음
- **95% CI**: 신뢰구간이 1을 포함하지 않으면 통계적 유의
- **P for interaction**: 서브그룹 간 효과 차이의 유의성

## Statistical Considerations

### 사건율 계산
- **Kaplan-Meier 추정법**: 생존함수를 이용한 사건율 계산
- **시점 설정**: `time_eventrate` 매개변수로 분석 시점 지정
- **중도절단 처리**: 생존분석의 특성을 반영한 정확한 사건율

### 상호작용 검정
- **목적**: 서브그룹 간 치료효과 차이 평가
- **방법**: Cox 모델에 상호작용항 포함
- **해석**: p < 0.05인 경우 서브그룹 간 효과 차이 존재

### 다중비교 보정
```r
# Bonferroni 보정 고려
alpha_adjusted <- 0.05 / number_of_subgroups
```

## Visualization Integration

Forest plot 생성을 위한 결과 활용:

```r
# 결과를 이용한 Forest plot
library(forestplot)

# 데이터 변환
forest_data <- result[, c("HR", "95% CI", "P-value")]

# Forest plot 생성 (예시)
forestplot(
  labeltext = result$Subgroup,
  mean = result$HR,
  lower = result$CI_lower,
  upper = result$CI_upper
)
```

## Dependencies

- `survival` package
- `survey` package (survey 데이터 분석 시)
- 기본 R 통계 함수들

## Common Applications

### 임상시험 분석
- **주요 endpoint**: 치료군 vs 대조군 효과
- **서브그룹**: 연령, 성별, 질병 중증도별 분석
- **목적**: 치료효과의 일관성 평가

### 관찰연구 분석  
- **위험요인 분석**: 노출요인의 영향 평가
- **서브그룹**: 인구학적, 임상적 특성별 분석
- **목적**: 위험요인의 이질성 탐색

## See Also

- `survival::coxph()` - Cox 비례위험모델
- `survey::svycoxph()` - Survey Cox 모델
- `TableSubgroupMultiGLM()` - GLM 서브그룹 분석
- `forestplot` package - Forest plot 시각화