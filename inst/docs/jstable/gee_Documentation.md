# gee Documentation

## Overview

`gee.R`은 jstable 패키지에서 일반화 추정 방정식(Generalized Estimating Equations, GEE) 모델의 분석과 결과 표시를 담당하는 함수들을 제공합니다. 군집화된 데이터나 반복측정 데이터의 분석에 특화되어 있으며, 관측치 간의 상관관계를 고려한 회귀분석을 수행할 수 있습니다.

## Functions

### `geeUni()`

단변량 일반화 추정 방정식의 계수를 추출합니다.

#### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `y` | character | 종속변수명 |
| `x` | character | 독립변수명 |
| `data` | data.frame | 분석할 데이터프레임 |
| `id.vec` | vector | 클러스터/그룹 ID 벡터 |
| `family` | character | 확률분포 패밀리 ("gaussian", "binomial", "poisson" 등) |
| `cor.type` | character | 상관구조 유형 (기본값: "exchangeable") |

#### Returns

계수, 표준오차, p-value를 포함하는 결과

#### Example

```r
library(geepack)
data(dietox)

# 단변량 GEE 분석
gee_uni_result <- geeUni(
  y = "Weight", 
  x = "Time", 
  data = dietox, 
  id.vec = dietox$Pig,
  family = "gaussian", 
  cor.type = "exchangeable"
)

print(gee_uni_result)
```

### `geeExp()`

GEE 계수를 적절한 단위로 변환합니다.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `gee.coef` | data.frame | - | GEE 계수 객체 |
| `family` | character | "binomial" | 모델 패밀리 |
| `dec` | integer | - | 소수점 자릿수 |

#### Returns

변환된 계수와 신뢰구간, p-value

#### Example

```r
# geeUni 결과를 변환
gee_transformed <- geeExp(gee_uni_result, family = "gaussian", dec = 2)
print(gee_transformed)

# 이항 분포의 경우 (오즈비 변환)
gee_binary <- geeExp(gee_uni_result, family = "binomial", dec = 3)
```

### `geeglm.display()`

GEE 모델의 종합적인 결과를 생성합니다.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `geeglm.obj` | geeglm | - | geeglm 패키지로 생성된 GEE 모델 객체 |
| `decimal` | integer | 2 | 소수점 자릿수 |
| `pcut.univariate` | numeric | NULL | 단변량 분석 p-value 임계값 |
| `data_for_univariate` | data.frame | NULL | 단변량 분석용 데이터 |

#### Returns

캡션, 주요 테이블, 메트릭을 포함하는 리스트

#### Example

```r
library(geepack)
data(dietox)

# GEE 모델 생성
gee_model <- geeglm(
  Weight ~ Time + Cu,
  id = Pig, 
  data = dietox,
  family = gaussian, 
  corstr = "exchangeable"
)

# 결과 표시
gee_result <- geeglm.display(gee_model)
print(gee_result)

# 소수점 자릿수 조정
gee_detailed <- geeglm.display(gee_model, decimal = 3)

# p-value 임계값 적용
gee_filtered <- geeglm.display(
  gee_model, 
  pcut.univariate = 0.1,
  data_for_univariate = dietox
)
```

## Correlation Structures

GEE에서 지원하는 상관구조 유형들:

| Structure | Description | Use Case |
|-----------|-------------|----------|
| `independence` | 독립 | 군집 내 상관 없음 |
| `exchangeable` | 교환가능 | 군집 내 일정한 상관 |
| `ar1` | 1차 자기회귀 | 시간순서 의존성 |
| `unstructured` | 비구조화 | 임의의 상관 패턴 |

## Usage Notes

### 기본 사용 패턴

```r
library(geepack)

# 1. 데이터 준비
data(dietox)
head(dietox)

# 2. GEE 모델 적합
model <- geeglm(
  Weight ~ Time + Cu + factor(Litter),
  id = Pig,
  data = dietox,
  family = gaussian,
  corstr = "exchangeable"
)

# 3. 결과 표시
result <- geeglm.display(model)
```

### 다양한 분포 패밀리 사용

```r
# 1. 연속형 결과변수 (정규분포)
gaussian_model <- geeglm(
  continuous_outcome ~ treatment + time,
  id = subject_id,
  data = longitudinal_data,
  family = gaussian,
  corstr = "ar1"
)

# 2. 이진 결과변수 (이항분포)
binomial_model <- geeglm(
  binary_outcome ~ treatment + time,
  id = subject_id,
  data = longitudinal_data,
  family = binomial,
  corstr = "exchangeable"
)

# 3. 계수 데이터 (포아송분포)
poisson_model <- geeglm(
  count_outcome ~ treatment + time,
  id = subject_id,
  data = longitudinal_data,
  family = poisson,
  corstr = "ar1"
)
```

### 고급 분석 옵션

```r
# 단변량 분석 필터링
filtered_result <- geeglm.display(
  model,
  pcut.univariate = 0.05,
  data_for_univariate = dietox
)

# 상세 소수점 설정
detailed_result <- geeglm.display(model, decimal = 4)

# 개별 함수 활용
univariate_coef <- geeUni("Weight", "Time", dietox, dietox$Pig, "gaussian")
transformed_coef <- geeExp(univariate_coef, "gaussian", 2)
```

## Output Format

### 결과 구조

`geeglm.display()` 함수는 다음을 포함하는 리스트를 반환합니다:

1. **Caption**: 모델 정보 및 설명
2. **Main Table**: 주요 분석 결과
3. **Metrics**: 모델 평가 지표

### 테이블 내용

#### 연속형 결과변수 (family = gaussian)

| Column | Description |
|--------|-------------|
| Variable | 변수명 |
| Coefficient (univariate) | 단변량 회귀계수 |
| 95% CI (univariate) | 단변량 95% 신뢰구간 |
| P-value (univariate) | 단변량 p-value |
| Coefficient (multivariate) | 다변량 회귀계수 |
| 95% CI (multivariate) | 다변량 95% 신뢰구간 |
| P-value (multivariate) | 다변량 p-value |

#### 이진 결과변수 (family = binomial)

| Column | Description |
|--------|-------------|
| Variable | 변수명 |
| OR (univariate) | 단변량 오즈비 |
| 95% CI (univariate) | 단변량 95% 신뢰구간 |
| P-value (univariate) | 단변량 p-value |
| OR (multivariate) | 다변량 오즈비 |
| 95% CI (multivariate) | 다변량 95% 신뢰구간 |
| P-value (multivariate) | 다변량 p-value |

## Statistical Considerations

### GEE vs. 혼합효과모델 비교

| Aspect | GEE | Mixed Effects Model |
|--------|-----|-------------------|
| 추정 방법 | 주변 효과 (Population-averaged) | 조건부 효과 (Subject-specific) |
| 해석 | 모집단 평균 효과 | 개별 대상자 효과 |
| 결측치 처리 | MAR 가정 | MCAR/MAR 가정 |
| 계산 복잡도 | 상대적 단순 | 상대적 복잡 |

### 상관구조 선택 지침

1. **Exchangeable**: 군집 내 관측치가 동일한 상관
2. **AR(1)**: 시간 간격에 따른 상관 감소
3. **Unstructured**: 소수의 시점, 복잡한 패턴
4. **Independence**: 상관 없음, GLM과 동일

### 모델 진단

```r
# 1. 상관구조 비교
models <- list(
  independence = geeglm(Weight ~ Time, id = Pig, data = dietox, corstr = "independence"),
  exchangeable = geeglm(Weight ~ Time, id = Pig, data = dietox, corstr = "exchangeable"),
  ar1 = geeglm(Weight ~ Time, id = Pig, data = dietox, corstr = "ar1")
)

# 2. QIC 비교 (작을수록 좋음)
sapply(models, QIC)

# 3. 잔차 분석
residuals <- residuals(model)
plot(fitted(model), residuals)
```

## Common Applications

### 임상시험 반복측정

```r
# 시간에 따른 치료효과 평가
clinical_model <- geeglm(
  symptom_score ~ treatment * time + baseline_score,
  id = patient_id,
  data = clinical_trial,
  family = gaussian,
  corstr = "ar1"
)
```

### 군집 무작위 시험

```r
# 클러스터별 무작위화
cluster_model <- geeglm(
  outcome ~ intervention + cluster_characteristics,
  id = cluster_id,
  data = cluster_trial,
  family = binomial,
  corstr = "exchangeable"
)
```

### 코호트 연구

```r
# 반복 측정된 위험요인 분석
cohort_model <- geeglm(
  disease_status ~ exposure + age + time,
  id = subject_id,
  data = cohort_data,
  family = binomial,
  corstr = "exchangeable"
)
```

## Dependencies

- `geepack` package
- 기본 R 통계 함수들

## Troubleshooting

### 일반적인 문제들

1. **수렴 실패**
```r
# 최대 반복 횟수 증가
model <- geeglm(..., control = geese.control(maxit = 100))
```

2. **상관구조 문제**
```r
# 더 단순한 상관구조 시도
model <- geeglm(..., corstr = "independence")
```

3. **결측치 처리**
```r
# 완전한 케이스만 사용
complete_data <- na.omit(data)
```

## See Also

- `geepack::geeglm()` - GEE 모델 적합
- `geepack::geese()` - 확장된 GEE
- `lmer.display()` - 선형 혼합효과 모델
- `glmshow.display()` - GLM 결과 표시