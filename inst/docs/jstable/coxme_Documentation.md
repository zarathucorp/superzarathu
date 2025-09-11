# coxme Documentation

## Overview

`coxme.R`은 jstable 패키지에서 혼합효과 Cox 모델(mixed-effects Cox model)의 결과를 처리하고 표시하는 함수들을 제공합니다. coxme 패키지를 기반으로 하여 고정효과와 임의효과가 모두 포함된 생존분석 모델의 결과를 사용자 친화적인 형태로 변환합니다.

## Functions

### `coxmeTable(mod)`

coxme 객체에서 고정효과 테이블을 추출합니다.

#### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `mod` | coxme | coxme 패키지로 생성된 혼합효과 Cox 모델 객체 |

#### Returns

고정효과의 beta, se, z, p 값을 포함하는 테이블

#### Example

```r
library(survival)
library(coxme)
data(lung)

fit <- coxme(Surv(time, status) ~ ph.ecog + age + (1 | inst), data = lung)
fixed_effects <- jstable:::coxmeTable(fit)
print(fixed_effects)
```

### `coxExp(cox.coef, dec)`

Cox 모델 계수를 위험비(HR) 단위로 변환합니다.

#### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `cox.coef` | data.frame | Cox 모델 계수 테이블 |
| `dec` | integer | 소수점 자릿수 |

#### Returns

변환된 계수와 95% 신뢰구간, p-value를 포함하는 테이블

#### Example

```r
library(survival)
library(coxme)
data(lung)

fit <- coxme(Surv(time, status) ~ ph.ecog + age + (1 | inst), data = lung)
coef_table <- jstable:::coxmeTable(fit)
hr_table <- jstable:::coxExp(coef_table, dec = 3)
print(hr_table)
```

### `extractAIC.coxme(fit, scale = NULL, k = 2, ...)`

coxme 객체에서 AIC 값을 추출합니다.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `fit` | coxme | - | coxme 객체 |
| `scale` | NULL | NULL | 스케일 매개변수 (사용되지 않음) |
| `k` | numeric | 2 | 자유도의 가중치 |
| `...` | - | - | 추가 인수 |

#### Returns

AIC 값 (Integrated, Penalized)

#### Example

```r
library(survival)
library(coxme)
data(lung)

fit <- coxme(Surv(time, status) ~ ph.ecog + age + (1 | inst), data = lung)
aic_value <- extractAIC(fit)
print(aic_value)
```

### `coxme.display(coxme.obj, dec = 2, pcut.univariate = NULL)`

coxme 객체의 종합적인 결과를 표시합니다.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `coxme.obj` | coxme | - | coxme 객체 |
| `dec` | integer | 2 | 소수점 자릿수 |
| `pcut.univariate` | numeric | NULL | 단변량 분석 p-value 임계값 |

#### Returns

혼합효과 Cox 모델의 종합 결과 테이블

#### Example

```r
library(survival)
library(coxme)
data(lung)

# 기본 혼합효과 Cox 모델
fit <- coxme(Surv(time, status) ~ ph.ecog + age + (1 | inst), data = lung)
result <- coxme.display(fit)
print(result)

# 소수점 자릿수 조정
result_detailed <- coxme.display(fit, dec = 3)

# p-value 임계값 적용
result_filtered <- coxme.display(fit, pcut.univariate = 0.1)
```

## Usage Notes

### 기본 사용법

```r
library(survival)
library(coxme)
data(lung)

# 혼합효과 Cox 모델 생성
# (1 | inst): 기관별 임의절편
model <- coxme(Surv(time, status) ~ ph.ecog + age + (1 | inst), data = lung)

# 결과 표시
result <- coxme.display(model)
```

### 고급 모델링

```r
# 복잡한 임의효과 구조
complex_model <- coxme(Surv(time, status) ~ ph.ecog + age + sex + 
                       (1 | inst) + (ph.ecog | inst), data = lung)

# 결과 확인
complex_result <- coxme.display(complex_model, dec = 3)

# 개별 구성요소 확인
fixed_effects <- jstable:::coxmeTable(complex_model)
aic_values <- extractAIC(complex_model)
```

### 모델 비교

```r
# 여러 모델 비교
model1 <- coxme(Surv(time, status) ~ ph.ecog + (1 | inst), data = lung)
model2 <- coxme(Surv(time, status) ~ ph.ecog + age + (1 | inst), data = lung)
model3 <- coxme(Surv(time, status) ~ ph.ecog + age + sex + (1 | inst), data = lung)

# AIC 비교
aic1 <- extractAIC(model1)
aic2 <- extractAIC(model2)
aic3 <- extractAIC(model3)

comparison <- data.frame(
  Model = c("Model1", "Model2", "Model3"),
  AIC = c(aic1[2], aic2[2], aic3[2])
)
```

## Model Specification

### 임의효과 구문

| Syntax | Description | Example |
|--------|-------------|---------|
| `(1 \| group)` | 임의절편 | `(1 \| hospital)` |
| `(var \| group)` | 임의기울기 | `(treatment \| hospital)` |
| `(1 + var \| group)` | 임의절편 + 임의기울기 | `(1 + age \| hospital)` |

### 일반적인 모델 패턴

```r
# 1. 임의절편만 포함
simple_random <- coxme(Surv(time, status) ~ treatment + (1 | center), data = data)

# 2. 임의절편과 임의기울기
complex_random <- coxme(Surv(time, status) ~ treatment + age + 
                        (1 + treatment | center), data = data)

# 3. 다중 그룹화 변수
multi_group <- coxme(Surv(time, status) ~ treatment + 
                     (1 | center) + (1 | physician), data = data)
```

## Output Format

### 결과 구조

`coxme.display()` 함수는 다음을 포함하는 리스트를 반환합니다:

1. **Caption**: 모델 설명
2. **Fixed Effects Table**: 고정효과 결과
3. **Random Effects Summary**: 임의효과 요약
4. **Model Metrics**: AIC, likelihood 등

### 테이블 내용

| Column | Description |
|--------|-------------|
| Variable | 변수명 |
| HR | 위험비 (Hazard Ratio) |
| 95% CI | 95% 신뢰구간 |
| P-value | 유의확률 |
| Random Effect | 임의효과 분산 |

## Statistical Interpretation

### 고정효과 (Fixed Effects)
- **위험비**: 기준 그룹 대비 위험의 배수
- **신뢰구간**: 추정값의 불확실성
- **p-value**: 통계적 유의성

### 임의효과 (Random Effects)
- **분산 성분**: 그룹 간 변이의 크기
- **상관계수**: 임의효과 간 상관관계
- **Shrinkage**: 개별 그룹 예측값의 수축

## Dependencies

- `survival` package
- `coxme` package
- `Matrix` package (coxme 의존성)

## Common Issues

### 모델 수렴 문제

```r
# 수렴하지 않는 경우 옵션 조정
fit <- coxme(Surv(time, status) ~ treatment + (1 | center), 
             data = data, 
             control = coxme.control(iter.max = 100, toler.chol = 1e-10))
```

### 데이터 준비

```r
# 결측치 처리
data_complete <- na.omit(data)

# 그룹 변수 확인
table(data$group_variable)  # 그룹별 관측치 수 확인
```

## See Also

- `coxme::coxme()` - 혼합효과 Cox 모델
- `survival::coxph()` - 일반 Cox 모델
- `cox2.display()` - 일반 Cox 모델 표시
- `lmer.display()` - 선형 혼합효과 모델