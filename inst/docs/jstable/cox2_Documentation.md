# cox2 Documentation

## Overview

`cox2.R`은 jstable 패키지에서 Cox 비례위험모델의 결과를 표 형태로 표시하는 함수를 제공합니다. 특히 'frailty'나 'cluster' 모델을 지원하며, 다변량 생존분석 결과를 사용자 친화적인 테이블로 변환합니다.

## Functions

### `cox2.display()`

Cox 비례위험모델 객체의 결과를 테이블 형태로 표시합니다.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `cox.obj.withmodel` | coxph | - | model = TRUE 옵션으로 생성된 coxph 객체 |
| `dec` | integer | 2 | 소수점 자릿수 |
| `msm` | logical | NULL | 다상태 모델 여부 |
| `pcut.univariate` | numeric | NULL | 단변량 분석 p-value 임계값 |
| `data_for_univariate` | data.frame | NULL | 단변량 분석용 데이터 |

#### Key Features

- **Cluster/Frailty 모델 지원**: cluster() 및 frailty() 함수를 포함한 Cox 모델 지원
- **단변량/다변량 분석**: 자동으로 단변량 및 다변량 분석 결과 제공
- **위험비 계산**: Hazard Ratio와 95% 신뢰구간 자동 계산
- **모델 메트릭**: AIC, Concordance index 등 모델 평가 지표 포함

#### Example

```r
library(survival)
data(lung)

# Cluster 모델
fit1 <- coxph(Surv(time, status) ~ ph.ecog + age + cluster(inst), 
              data = lung, model = TRUE)
result1 <- cox2.display(fit1)

# Frailty 모델
fit2 <- coxph(Surv(time, status) ~ ph.ecog + age + frailty(inst), 
              data = lung, model = TRUE)
result2 <- cox2.display(fit2)

# p-value 임계값 적용
fit3 <- coxph(Surv(time, status) ~ ph.ecog + age + sex, 
              data = lung, model = TRUE)
result3 <- cox2.display(fit3, pcut.univariate = 0.1)
```

## Output Format

### 결과 구조

함수는 다음을 포함하는 리스트를 반환합니다:

1. **Caption**: 모델 정보 및 설명
2. **Main Table**: 주요 분석 결과 테이블
3. **Metrics**: 모델 평가 지표

### 테이블 내용

| Column | Description |
|--------|-------------|
| Variable | 변수명 |
| HR (univariate) | 단변량 위험비 |
| 95% CI (univariate) | 단변량 95% 신뢰구간 |
| P-value (univariate) | 단변량 p-value |
| HR (multivariate) | 다변량 위험비 |
| 95% CI (multivariate) | 다변량 95% 신뢰구간 |
| P-value (multivariate) | 다변량 p-value |

## Usage Notes

### 기본 사용법

```r
library(survival)
data(lung)

# 기본 Cox 모델
basic_model <- coxph(Surv(time, status) ~ age + sex + ph.ecog, 
                     data = lung, model = TRUE)
basic_result <- cox2.display(basic_model)

# 결과 확인
print(basic_result)
```

### 고급 설정

```r
# 소수점 자릿수 조정
detailed_result <- cox2.display(basic_model, dec = 3)

# 단변량 분석 필터링
filtered_result <- cox2.display(basic_model, 
                                pcut.univariate = 0.05,
                                data_for_univariate = lung)
```

### Cluster/Frailty 모델 활용

```r
# Cluster 모델 - 기관별 클러스터링
cluster_model <- coxph(Surv(time, status) ~ age + sex + cluster(inst), 
                       data = lung, model = TRUE)
cluster_result <- cox2.display(cluster_model)

# Frailty 모델 - 기관별 임의효과
frailty_model <- coxph(Surv(time, status) ~ age + sex + frailty(inst), 
                       data = lung, model = TRUE)
frailty_result <- cox2.display(frailty_model)
```

## Model Requirements

### 필수 조건

1. **model = TRUE**: coxph 객체 생성 시 반드시 model = TRUE 옵션 사용
2. **Survival 객체**: Surv() 함수로 생성된 생존 객체 필요
3. **완전한 데이터**: 결측치 처리가 완료된 데이터

### 지원하는 모델 유형

- **기본 Cox 모델**: `coxph(Surv(time, status) ~ covariates)`
- **Cluster 모델**: `coxph(Surv(time, status) ~ covariates + cluster(id))`
- **Frailty 모델**: `coxph(Surv(time, status) ~ covariates + frailty(id))`
- **층화 모델**: `coxph(Surv(time, status) ~ covariates + strata(factor))`

## Statistical Details

### 위험비 (Hazard Ratio)
- **해석**: 기준 그룹 대비 위험의 상대적 비율
- **계산**: exp(coefficient)
- **신뢰구간**: exp(coefficient ± 1.96 × SE)

### 모델 평가 지표
- **AIC**: 모델 선택 기준
- **Concordance Index**: 예측 정확도 측정
- **Likelihood Ratio Test**: 모델 유의성 검정

## Dependencies

- `survival` package
- 기본 R 통계 함수들

## Error Handling

### 일반적인 오류

1. **Model option missing**: model = TRUE 옵션 누락
```r
# 잘못된 예
model_wrong <- coxph(Surv(time, status) ~ age, data = lung)

# 올바른 예
model_correct <- coxph(Surv(time, status) ~ age, data = lung, model = TRUE)
```

2. **Missing data**: 결측치 처리 필요
```r
# 결측치 확인 및 처리
summary(lung)
lung_complete <- na.omit(lung)
```

## See Also

- `survival::coxph()` - Cox 비례위험모델
- `survival::Surv()` - 생존 객체 생성
- `coxme.display()` - 혼합효과 Cox 모델
- `svycox.display()` - 가중치 적용 Cox 모델