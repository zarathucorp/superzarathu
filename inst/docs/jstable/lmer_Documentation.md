# lmer Documentation

## Overview

`lmer.R`은 jstable 패키지에서 선형 혼합효과 모델(Linear Mixed-Effects Model)의 분석 결과를 처리하고 표시하는 함수들을 제공합니다. lme4 패키지의 lmer 및 glmer 객체를 기반으로 하여 고정효과와 임의효과가 모두 포함된 모델의 결과를 사용자 친화적인 형태로 변환합니다.

## Functions

### `lmerExp(lmer.coef, family = "binomial", dec)`

lmer 계수를 적절한 통계적 측정단위로 변환합니다.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `lmer.coef` | data.frame | - | lmer 계수 테이블 |
| `family` | character | "binomial" | 통계 패밀리 |
| `dec` | integer | - | 소수점 자릿수 |

#### Supported Families

| Family | Transformation | Interpretation |
|--------|----------------|---------------|
| `gaussian` | Coefficient | 선형 관계의 기울기 |
| `binomial` | OR (Odds Ratio) | 오즈비 |
| `poisson` | RR (Rate Ratio) | 발생률비 |

#### Example

```r
library(lme4)
data(sleepstudy)

# 선형 혼합효과모델
lmer_model <- lmer(Reaction ~ Days + (1|Subject), data = sleepstudy)
coef_table <- summary(lmer_model)$coefficients

# 계수 변환 (연속형 결과변수)
transformed_coef <- lmerExp(coef_table, family = "gaussian", dec = 2)
print(transformed_coef)

# 로지스틱 혼합효과모델 예시
binary_model <- glmer(cbind(incidence, size - incidence) ~ period + (1|herd), 
                      data = cbpp, family = binomial)
binary_coef <- summary(binary_model)$coefficients
binary_transformed <- lmerExp(binary_coef, family = "binomial", dec = 3)
```

### `lmer.display()`

lmerMod 또는 glmerMod 객체의 종합적인 결과를 표시합니다.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `lmerMod.obj` | lmerMod/glmerMod | - | lme4로 생성된 혼합효과 모델 객체 |
| `dec` | integer | 2 | 소수점 자릿수 |
| `ci.ranef` | logical | FALSE | 임의효과 신뢰구간 표시 여부 |
| `pcut.univariate` | numeric | NULL | 단변량 분석 p-value 임계값 |
| `data_for_univariate` | data.frame | NULL | 단변량 분석용 데이터 |

#### Returns

고정효과, 임의효과, 모델 메트릭을 포함하는 종합 결과

#### Example

```r
library(lme4)
data(sleepstudy)

# 기본 선형 혼합효과모델
lmer_model <- lmer(Reaction ~ Days + (Days|Subject), data = sleepstudy)
result <- lmer.display(lmer_model)
print(result)

# 임의효과 신뢰구간 포함
result_with_ci <- lmer.display(lmer_model, ci.ranef = TRUE)

# 소수점 자릿수 조정
detailed_result <- lmer.display(lmer_model, dec = 3)

# p-value 임계값 적용
filtered_result <- lmer.display(
  lmer_model, 
  pcut.univariate = 0.1,
  data_for_univariate = sleepstudy
)
```

## Mixed-Effects Model Types

### Linear Mixed-Effects Models (lmer)

연속형 결과변수를 위한 혼합효과모델

```r
library(lme4)

# 1. 임의절편 모델
model1 <- lmer(outcome ~ treatment + time + (1|subject), data = data)

# 2. 임의기울기 모델  
model2 <- lmer(outcome ~ treatment + time + (time|subject), data = data)

# 3. 임의절편 + 임의기울기 모델
model3 <- lmer(outcome ~ treatment + time + (1 + time|subject), data = data)

# 결과 표시
result1 <- lmer.display(model1)
result2 <- lmer.display(model2)  
result3 <- lmer.display(model3)
```

### Generalized Linear Mixed-Effects Models (glmer)

이진 또는 계수 결과변수를 위한 일반화 혼합효과모델

```r
library(lme4)

# 1. 로지스틱 혼합효과모델
data(cbpp)
logistic_model <- glmer(cbind(incidence, size - incidence) ~ period + (1|herd), 
                        data = cbpp, family = binomial)
logistic_result <- lmer.display(logistic_model)

# 2. 포아송 혼합효과모델 (예시)
# poisson_model <- glmer(count ~ treatment + (1|cluster), 
#                        data = count_data, family = poisson)
# poisson_result <- lmer.display(poisson_model)
```

## Usage Notes

### 기본 사용 패턴

```r
library(lme4)

# 1. 데이터 탐색
data(sleepstudy)
head(sleepstudy)
summary(sleepstudy)

# 2. 모델 적합
# 반복측정 데이터: 개인별 임의절편
model <- lmer(Reaction ~ Days + (1|Subject), data = sleepstudy)

# 3. 결과 확인
summary(model)
result <- lmer.display(model)

# 4. 모델 진단
plot(model)
qqnorm(resid(model))
```

### 복잡한 임의효과 구조

```r
# 1. 다중 그룹화 변수
multi_group <- lmer(score ~ treatment + time + 
                    (1|hospital) + (1|physician), 
                    data = clinical_data)

# 2. 교차 임의효과
crossed_effects <- lmer(yield ~ fertilizer + 
                        (1|field) + (1|variety), 
                        data = agricultural_data)

# 3. 중첩 임의효과
nested_effects <- lmer(test_score ~ teaching_method + 
                       (1|school/classroom), 
                       data = education_data)

# 각 모델 결과 표시
multi_result <- lmer.display(multi_group)
crossed_result <- lmer.display(crossed_effects)
nested_result <- lmer.display(nested_effects)
```

### 모델 비교

```r
# 모델 복잡도 증가 순서로 비교
model0 <- lm(Reaction ~ Days, data = sleepstudy)  # 일반 선형모델
model1 <- lmer(Reaction ~ Days + (1|Subject), data = sleepstudy)  # 임의절편
model2 <- lmer(Reaction ~ Days + (Days|Subject), data = sleepstudy)  # 임의기울기

# 모델 비교
anova(model1, model2)
AIC(model1, model2)
BIC(model1, model2)

# 결과 비교
result1 <- lmer.display(model1)
result2 <- lmer.display(model2)
```

## Output Format

### 결과 구조

`lmer.display()` 함수는 다음을 포함하는 리스트를 반환합니다:

1. **Caption**: 모델 유형 및 설명
2. **Fixed Effects Table**: 고정효과 결과
3. **Random Effects Summary**: 임의효과 분산 성분
4. **Model Metrics**: AIC, BIC, ICC 등

### 고정효과 테이블

#### 선형 혼합효과모델

| Column | Description |
|--------|-------------|
| Variable | 변수명 |
| Coefficient | 회귀계수 |
| 95% CI | 95% 신뢰구간 |
| P-value | 유의확률 |

#### 로지스틱 혼합효과모델

| Column | Description |
|--------|-------------|
| Variable | 변수명 |
| OR | 오즈비 |
| 95% CI | 95% 신뢰구간 |
| P-value | 유의확률 |

### 임의효과 요약

| Component | Description |
|-----------|-------------|
| Groups | 그룹화 변수 |
| Variance | 분산 성분 |
| Std.Dev. | 표준편차 |
| Correlation | 임의효과 간 상관 (해당시) |

## Statistical Interpretation

### 고정효과 (Fixed Effects)

```r
# 연속형 결과변수
model <- lmer(outcome ~ treatment + time + (1|subject), data = data)
result <- lmer.display(model)

# 해석:
# - 계수: 다른 변수 고정 시 해당 변수 1단위 증가의 효과
# - 신뢰구간: 모집단 효과의 추정 범위
# - p-value: 효과가 0과 다른지에 대한 검정
```

### 임의효과 (Random Effects)

```r
# 임의효과 분석
VarCorr(model)  # 분산-공분산 구조
ranef(model)    # 개별 그룹의 임의효과 값

# 해석:
# - 분산 성분: 그룹 간 변이의 크기
# - ICC: 그룹 내 상관계수
# - 개별 예측값: 그룹별 편차
```

### 모델 적합도

```r
# 정보 기준
AIC(model)
BIC(model)

# 분산 설명
r.squaredGLMM(model)  # 조건부 및 주변 R²

# 잔차 분석
plot(model)
qqnorm(ranef(model)$Subject[,1])
```

## Model Diagnostics

### 기본 진단

```r
# 1. 잔차 분석
plot(fitted(model), resid(model))
abline(h = 0, col = "red")

# 2. 정규성 검정
qqnorm(resid(model))
qqline(resid(model))

# 3. 임의효과 정규성
qqnorm(ranef(model)$Subject[,1])
qqline(ranef(model)$Subject[,1])
```

### 고급 진단

```r
library(performance)

# 모델 성능 평가
model_performance(model)

# 이상치 탐지
check_outliers(model)

# 영향관측치
influence(model)

# 모델 가정 검정
check_model(model)
```

## Advanced Applications

### 반복측정 ANOVA

```r
# 전통적 반복측정 ANOVA 대안
repeated_measures <- lmer(score ~ treatment * time + (1|subject), 
                         data = longitudinal_data)
rm_result <- lmer.display(repeated_measures)

# 시간 효과의 다양한 모델링
time_trends <- list(
  linear = lmer(score ~ treatment * time + (1|subject), data = data),
  quadratic = lmer(score ~ treatment * poly(time, 2) + (1|subject), data = data),
  random_slope = lmer(score ~ treatment * time + (time|subject), data = data)
)

results <- lapply(time_trends, lmer.display)
```

### 군집 무작위 시험

```r
# 클러스터 무작위화 시험 분석
cluster_trial <- lmer(outcome ~ intervention + baseline + 
                      (1|cluster), 
                      data = crt_data)
crt_result <- lmer.display(cluster_trial)

# ICC 계산 및 해석
icc_value <- VarCorr(cluster_trial)$cluster[1] / 
             (VarCorr(cluster_trial)$cluster[1] + sigma(cluster_trial)^2)
```

### 메타분석

```r
# 무작위효과 메타분석
meta_analysis <- lmer(effect_size ~ 1 + (1|study), 
                      weights = 1/variance,
                      data = meta_data)
meta_result <- lmer.display(meta_analysis)
```

## Dependencies

- `lme4` package
- `Matrix` package (lme4 의존성)
- 기본 R 통계 함수들

## Common Issues

### 수렴 문제

```r
# 수렴하지 않는 경우
model <- lmer(outcome ~ treatment + (1|subject), 
              data = data,
              control = lmerControl(optimizer = "bobyqa"))

# 또는 다른 옵티마이저 시도
model <- lmer(outcome ~ treatment + (1|subject), 
              data = data,
              control = lmerControl(optimizer = "Nelder_Mead"))
```

### 특이 적합 (Singular Fit)

```r
# 임의효과 분산이 0에 가까운 경우
# 더 단순한 모델 시도
simplified_model <- lmer(outcome ~ treatment + (1|subject), data = data)

# 또는 정규화
model_regularized <- lmer(outcome ~ treatment + (1|subject), 
                         data = data,
                         control = lmerControl(check.conv.singular = "ignore"))
```

## See Also

- `lme4::lmer()` - 선형 혼합효과모델
- `lme4::glmer()` - 일반화 선형 혼합효과모델
- `coxme.display()` - 혼합효과 Cox 모델
- `geeglm.display()` - GEE 모델
- `nlme` package - 대안적 혼합효과 모델링