# glmshow Documentation

## Overview

`glmshow.R`은 jstable 패키지에서 일반화선형모델(GLM)의 결과를 사용자 친화적인 테이블 형태로 표시하는 함수들을 제공합니다. 선형회귀와 로지스틱회귀 모델의 요약 통계와 계수를 깔끔하게 정리하여 출력할 수 있습니다.

## Functions

### `coefNA(model)`

결측치를 포함한 계수 테이블을 생성합니다.

#### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `model` | glm | glm 객체 (gaussian 또는 binomial 패밀리) |

#### Returns

결측치 처리된 계수 테이블

#### Example

```r
# 기본 사용법
model <- glm(mpg ~ wt + qsec, data = mtcars, family = gaussian)
coef_table <- coefNA(model)
print(coef_table)

# 로지스틱 회귀
model_logit <- glm(vs ~ wt + qsec, data = mtcars, family = binomial)
coef_table_logit <- coefNA(model_logit)
```

### `glmshow.display()`

GLM 객체의 요약 테이블을 표시합니다.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `glm.object` | glm | - | glm 객체 |
| `decimal` | integer | 2 | 소수점 자릿수 |
| `pcut.univariate` | numeric | NULL | 단변량 분석 p-value 임계값 |

#### Returns

회귀분석 결과의 종합 테이블

#### Example

```r
# 선형회귀 모델 표시
linear_model <- glm(mpg ~ wt + qsec + hp, data = mtcars, family = gaussian)
linear_result <- glmshow.display(linear_model)
print(linear_result)

# 로지스틱회귀 모델 표시
logistic_model <- glm(vs ~ wt + qsec + hp, data = mtcars, family = binomial)
logistic_result <- glmshow.display(logistic_model)

# 소수점 자릿수 조정
detailed_result <- glmshow.display(linear_model, decimal = 3)

# p-value 임계값 적용
filtered_result <- glmshow.display(linear_model, pcut.univariate = 0.1)
```

## Usage Notes

### 기본 사용 패턴

```r
# 1. 선형회귀 분석
linear_model <- glm(mpg ~ wt + hp + qsec, data = mtcars)
linear_summary <- glmshow.display(linear_model)

# 2. 로지스틱회귀 분석
mtcars$high_mpg <- ifelse(mtcars$mpg > median(mtcars$mpg), 1, 0)
logistic_model <- glm(high_mpg ~ wt + hp, data = mtcars, family = binomial)
logistic_summary <- glmshow.display(logistic_model)

# 3. 결과 확인
print(linear_summary)
print(logistic_summary)
```

### 고급 설정

```r
# 상세한 소수점 설정
detailed_model <- glm(mpg ~ wt + hp + qsec + gear, data = mtcars)
detailed_summary <- glmshow.display(detailed_model, decimal = 4)

# 변수 선택을 위한 p-value 임계값
model_with_filter <- glmshow.display(
  detailed_model, 
  pcut.univariate = 0.05
)

# 개별 계수 테이블 확인
coef_only <- coefNA(detailed_model)
```

### 다양한 분포 패밀리

```r
# 1. 정규분포 (선형회귀)
gaussian_model <- glm(mpg ~ wt + hp, data = mtcars, family = gaussian)
gaussian_result <- glmshow.display(gaussian_model)

# 2. 이항분포 (로지스틱회귀)
binomial_model <- glm(vs ~ wt + hp, data = mtcars, family = binomial)
binomial_result <- glmshow.display(binomial_model)

# 3. 포아송분포 (계수 회귀)
mtcars$gear_count <- mtcars$gear
poisson_model <- glm(gear_count ~ wt + hp, data = mtcars, family = poisson)
poisson_result <- glmshow.display(poisson_model)
```

## Output Format

### 결과 구조

`glmshow.display()` 함수는 다음을 포함하는 결과를 반환합니다:

1. **Model Type**: 회귀 유형 (Linear regression / Logistic regression)
2. **Coefficients Table**: 계수, 신뢰구간, p-value
3. **Model Statistics**: R-squared, AIC, 관측치 수 등

### 선형회귀 결과 테이블

| Column | Description |
|--------|-------------|
| Variable | 변수명 |
| Coefficient | 회귀계수 |
| 95% CI | 95% 신뢰구간 |
| P-value | 유의확률 |

### 로지스틱회귀 결과 테이블

| Column | Description |
|--------|-------------|
| Variable | 변수명 |
| OR | 오즈비 (Odds Ratio) |
| 95% CI | 95% 신뢰구간 |
| P-value | 유의확률 |

### 모델 통계

- **관측치 수**: 분석에 포함된 데이터 수
- **R-squared**: 결정계수 (선형회귀)
- **AIC**: 아카이케 정보기준
- **Log-likelihood**: 로그우도

## Statistical Interpretation

### 선형회귀 (family = gaussian)

```r
model <- glm(mpg ~ wt + hp, data = mtcars, family = gaussian)
result <- glmshow.display(model)

# 해석:
# - 계수: 독립변수 1단위 증가 시 종속변수 변화량
# - 양수: 양의 관계, 음수: 음의 관계
# - p-value < 0.05: 통계적으로 유의한 관계
```

### 로지스틱회귀 (family = binomial)

```r
model <- glm(vs ~ wt + hp, data = mtcars, family = binomial)
result <- glmshow.display(model)

# 해석:
# - OR > 1: 노출군에서 오즈 증가
# - OR < 1: 노출군에서 오즈 감소
# - OR = 1: 오즈 차이 없음
# - 95% CI가 1을 포함하지 않으면 통계적으로 유의
```

## Model Diagnostics

### 모델 적합도 확인

```r
# 1. 잔차 분석
model <- glm(mpg ~ wt + hp, data = mtcars)
par(mfrow = c(2, 2))
plot(model)

# 2. 영향관측치 확인
library(car)
influencePlot(model)

# 3. 다중공선성 확인
vif(model)
```

### 로지스틱회귀 특별 진단

```r
# 1. Hosmer-Lemeshow 검정
library(ResourceSelection)
hoslem.test(model$y, fitted(model))

# 2. ROC 곡선
library(pROC)
roc_curve <- roc(model$y, fitted(model))
auc(roc_curve)

# 3. 분류 정확도
predicted <- ifelse(fitted(model) > 0.5, 1, 0)
table(model$y, predicted)
```

## Advanced Usage

### 변수 선택

```r
# 1. 단계적 선택법
full_model <- glm(mpg ~ ., data = mtcars)
step_model <- step(full_model, direction = "both")
step_result <- glmshow.display(step_model)

# 2. p-value 기반 필터링
all_vars_model <- glm(mpg ~ wt + hp + qsec + gear + carb, data = mtcars)
significant_only <- glmshow.display(
  all_vars_model, 
  pcut.univariate = 0.05
)
```

### 모델 비교

```r
# 여러 모델 비교
model1 <- glm(mpg ~ wt, data = mtcars)
model2 <- glm(mpg ~ wt + hp, data = mtcars)
model3 <- glm(mpg ~ wt + hp + qsec, data = mtcars)

results <- list(
  Model1 = glmshow.display(model1),
  Model2 = glmshow.display(model2),
  Model3 = glmshow.display(model3)
)

# AIC 비교
aic_comparison <- data.frame(
  Model = c("Model1", "Model2", "Model3"),
  AIC = c(AIC(model1), AIC(model2), AIC(model3))
)
```

## Integration with Other Functions

### DT 테이블과 연동

```r
library(DT)

# GLM 결과를 DT 테이블로 표시
model <- glm(mpg ~ wt + hp, data = mtcars)
result <- glmshow.display(model)

datatable(
  result$table,
  options = opt.tbreg("glm_results"),
  caption = "GLM Analysis Results"
)
```

### 레이블 적용

```r
# 변수 레이블 적용
model <- glm(mpg ~ wt + hp, data = mtcars)
result <- glmshow.display(model)

# 레이블 데이터 생성
labels <- mk.lev(mtcars)

# 레이블 적용
labeled_result <- LabelepiDisplay(result, label = TRUE, ref = labels)
```

## Dependencies

- 기본 R 통계 함수들 (`glm`, `summary` 등)
- `stats` package

## Common Applications

### 임상연구
- **치료효과 분석**: 치료군 vs 대조군 비교
- **위험요인 분석**: 질병 발생에 영향을 미치는 요인들
- **예후인자 분석**: 생존 또는 회복에 영향을 미치는 변수들

### 경제/사회과학
- **수요 예측**: 제품 판매량에 영향을 미치는 요인들
- **정책 효과 분석**: 정책 시행이 결과에 미치는 영향
- **고객 만족도 분석**: 서비스 요인과 만족도 관계

### 품질관리
- **공정 개선**: 제품 품질에 영향을 미치는 공정 변수들
- **불량률 분석**: 불량 발생에 영향을 미치는 요인들
- **성능 예측**: 제품 성능에 영향을 미치는 설계 변수들

## See Also

- `glm()` - 일반화선형모델
- `summary.glm()` - GLM 요약 통계
- `geeglm.display()` - GEE 모델 결과 표시
- `lmer.display()` - 혼합효과 모델 결과 표시