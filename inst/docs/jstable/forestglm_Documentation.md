# forestglm Documentation

## Overview

`forestglm.R`은 jstable 패키지에서 일반화선형모델(GLM)의 서브그룹 분석을 수행하고 Forest plot 형태의 결과를 생성하는 함수들을 제공합니다. 다양한 확률분포 패밀리(gaussian, binomial, poisson 등)를 지원하며, 단일 또는 다중 서브그룹 분석을 통해 치료효과나 위험요인의 영향을 하위집단별로 비교할 수 있습니다.

## Functions

### `TableSubgroupGLM()`

일반화선형모델의 서브그룹 분석을 수행합니다.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `formula` | formula | - | 통계모델 공식 |
| `var_subgroup` | character | NULL | 서브그룹 분석용 변수 |
| `var_cov` | character | NULL | 공변량 변수들 |
| `data` | data.frame/survey.design | - | 데이터 또는 survey design 객체 |
| `family` | character | "gaussian" | 확률분포 패밀리 |
| `decimal.estimate` | integer | 2 | 추정값 소수점 자릿수 |
| `decimal.percent` | integer | 1 | 백분율 소수점 자릿수 |
| `decimal.pvalue` | integer | 3 | p-value 소수점 자릿수 |
| `line` | logical | FALSE | 서브그룹 간 구분선 표시 |
| `cluster` | character | NULL | 클러스터 변수 |
| `strata` | character | NULL | 층화 변수 |
| `labeldata` | data.frame | NULL | 변수 레이블 데이터 |

#### Supported Families

| Family | Description | Link Function | Example Use |
|--------|-------------|---------------|-------------|
| `gaussian` | 정규분포 | identity | 연속형 결과변수 (선형회귀) |
| `binomial` | 이항분포 | logit | 이진 결과변수 (로지스틱회귀) |
| `poisson` | 포아송분포 | log | 계수 데이터 (포아송회귀) |
| `quasipoisson` | 준포아송분포 | log | 과분산된 계수 데이터 |

#### Example

```r
library(survival)
data(lung)

# 데이터 준비 (이진 결과변수)
lung %>% 
  mutate(
    status = as.integer(status == 1),
    sex = factor(sex),
    performance = factor(ifelse(ph.ecog <= 1, "Good", "Poor"))
  ) -> lung_processed

# 로지스틱 회귀 서브그룹 분석
result1 <- TableSubgroupGLM(
  formula = status ~ sex, 
  var_subgroup = "performance",
  data = lung_processed, 
  family = "binomial"
)

# 공변량 포함
result2 <- TableSubgroupGLM(
  formula = status ~ sex, 
  var_subgroup = "performance",
  var_cov = c("age", "meal.cal"),
  data = lung_processed, 
  family = "binomial"
)

# 선형회귀 분석
result3 <- TableSubgroupGLM(
  formula = age ~ sex,
  var_subgroup = "performance", 
  data = lung_processed,
  family = "gaussian"
)
```

### `TableSubgroupMultiGLM()`

다중 서브그룹 변수에 대한 GLM 분석을 수행합니다.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `formula` | formula | - | 통계모델 공식 |
| `var_subgroups` | character vector | - | 다중 서브그룹 변수들 |
| `var_cov` | character | NULL | 공변량 변수들 |
| `data` | data.frame/survey.design | - | 데이터 또는 survey design 객체 |
| `family` | character | "gaussian" | 확률분포 패밀리 |
| `decimal.estimate` | integer | 2 | 추정값 소수점 자릿수 |
| `decimal.percent` | integer | 1 | 백분율 소수점 자릿수 |
| `decimal.pvalue` | integer | 3 | p-value 소수점 자릿수 |
| `line` | logical | FALSE | 서브그룹 변수 간 구분선 표시 |
| `cluster` | character | NULL | 클러스터 변수 |
| `strata` | character | NULL | 층화 변수 |
| `labeldata` | data.frame | NULL | 변수 레이블 데이터 |

#### Example

```r
library(survival)
data(lung)

# 데이터 준비
lung %>% 
  mutate(
    status = as.integer(status == 1),
    performance = factor(ifelse(ph.ecog <= 1, "Good", "Poor")),
    age_group = factor(ifelse(age >= 65, "Elderly", "Younger"))
  ) -> lung_multi

# 다중 서브그룹 분석
result <- TableSubgroupMultiGLM(
  formula = status ~ sex,
  var_subgroups = c("performance", "age_group"),
  data = lung_multi, 
  family = "binomial",
  line = TRUE
)

# 공변량 포함 다중 분석
result_cov <- TableSubgroupMultiGLM(
  formula = status ~ sex,
  var_subgroups = c("performance", "age_group"),
  var_cov = c("meal.cal"),
  data = lung_multi,
  family = "binomial"
)
```

## Usage Notes

### 기본 사용 패턴

```r
# 1. 이진 결과변수 (로지스틱 회귀)
binary_result <- TableSubgroupGLM(
  formula = outcome ~ treatment,
  var_subgroup = "center_type",
  data = clinical_data,
  family = "binomial"
)

# 2. 연속형 결과변수 (선형회귀)
continuous_result <- TableSubgroupGLM(
  formula = score ~ treatment,
  var_subgroup = "age_group",
  data = clinical_data,
  family = "gaussian"
)

# 3. 계수 데이터 (포아송 회귀)
count_result <- TableSubgroupGLM(
  formula = events ~ exposure,
  var_subgroup = "region",
  data = epidemiology_data,
  family = "poisson"
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

# Survey GLM 서브그룹 분석
survey_result <- TableSubgroupGLM(
  formula = outcome ~ treatment,
  var_subgroup = "hospital_type",
  data = design,
  family = "binomial"
)
```

### 고급 설정

```r
# 상세 설정 예시
detailed_result <- TableSubgroupGLM(
  formula = outcome ~ treatment,
  var_subgroup = "center_type",
  var_cov = c("age", "sex", "baseline_score"),
  data = clinical_data,
  family = "binomial",
  decimal.estimate = 3,
  decimal.percent = 2,
  decimal.pvalue = 4,
  cluster = "center_id",
  strata = "region"
)
```

## Output Format

### 결과 테이블 구조

#### 이진 결과변수 (family = "binomial")

| Column | Description |
|--------|-------------|
| Subgroup | 서브그룹 범주 |
| No. of Subjects | 대상자 수 |
| No. of Events | 사건 발생 수 |
| Event Rate (%) | 사건 발생률 |
| OR/RR | 오즈비 또는 상대위험비 |
| 95% CI | 95% 신뢰구간 |
| P-value | 유의확률 |
| P for interaction | 상호작용 p-value |

#### 연속형 결과변수 (family = "gaussian")

| Column | Description |
|--------|-------------|
| Subgroup | 서브그룹 범주 |
| No. of Subjects | 대상자 수 |
| Mean ± SD | 평균 ± 표준편차 |
| Coefficient | 회귀계수 |
| 95% CI | 95% 신뢰구간 |
| P-value | 유의확률 |
| P for interaction | 상호작용 p-value |

#### 계수 데이터 (family = "poisson")

| Column | Description |
|--------|-------------|
| Subgroup | 서브그룹 범주 |
| No. of Subjects | 대상자 수 |
| Events/Person-time | 사건수/인시 |
| Rate Ratio | 발생률비 |
| 95% CI | 95% 신뢰구간 |
| P-value | 유의확률 |
| P for interaction | 상호작용 p-value |

## Statistical Interpretation

### 효과 측정지표

#### 로지스틱 회귀 (family = "binomial")
- **오즈비 (OR)**: 노출군과 비노출군의 오즈 비율
- **해석**: OR > 1 (위험 증가), OR < 1 (위험 감소), OR = 1 (차이 없음)

#### 선형회귀 (family = "gaussian")  
- **회귀계수**: 독립변수 1단위 증가 시 종속변수 변화량
- **해석**: 양수 (양의 관계), 음수 (음의 관계), 0 (관계 없음)

#### 포아송 회귀 (family = "poisson")
- **발생률비 (IRR)**: 노출군과 비노출군의 발생률 비율  
- **해석**: IRR > 1 (발생률 증가), IRR < 1 (발생률 감소), IRR = 1 (차이 없음)

### 상호작용 검정
- **목적**: 서브그룹 간 치료효과 차이 평가
- **방법**: GLM에 상호작용항 포함
- **해석**: p < 0.05인 경우 서브그룹 간 효과 차이 존재

## Model Diagnostics

### 모델 적합도 확인

```r
# 잔차 분석
model <- glm(outcome ~ treatment, data = data, family = "binomial")
plot(model)

# 이상치 탐지
library(car)
outlierTest(model)

# 영향관측치 확인
influencePlot(model)
```

### 가정 확인

```r
# 선형성 확인 (연속형 결과변수)
library(car)
residualPlots(model)

# 다중공선성 확인
vif(model)

# 과분산 확인 (포아송 회귀)
dispersiontest(model)
```

## Dependencies

- 기본 R 통계 함수들 (`glm`, `family` 등)
- `survey` package (survey 데이터 분석 시)
- `dplyr` package (데이터 처리)

## Common Applications

### 임상시험 분석
- **이진 endpoint**: 치료 성공/실패율 비교
- **연속형 endpoint**: 증상 점수 변화량 비교
- **서브그룹**: 연령, 성별, 질병 중증도별 분석

### 역학연구
- **환자-대조군 연구**: 위험요인의 오즈비 계산
- **코호트 연구**: 발생률비 또는 상대위험비 계산
- **서브그룹**: 지역, 시기, 인구학적 특성별 분석

### 품질개선 연구
- **이진 outcome**: 합병증 발생률, 재입원율
- **계수 outcome**: 감염 발생 건수, 낙상 발생 건수
- **서브그룹**: 병동, 진료과, 시간대별 분석

## See Also

- `glm()` - 일반화선형모델
- `survey::svyglm()` - Survey GLM
- `TableSubgroupCox()` - Cox 모델 서브그룹 분석
- `glmshow.display()` - GLM 결과 표시
- `forestplot` package - Forest plot 시각화