# svyglm Documentation

## Overview

`svyglm.R`은 jstable 패키지에서 가중치가 적용된 설문조사 데이터의 일반화선형모델(GLM) 분석 결과를 표시하는 함수를 제공합니다. survey 패키지의 svyglm 함수와 연동하여 복잡한 표본설계를 고려한 회귀분석 결과를 사용자 친화적인 테이블로 변환합니다.

## Functions

### `svyregress.display()`

survey GLM 객체의 결과를 테이블 형태로 표시합니다.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `svyglm.obj` | svyglm | - | survey::svyglm로 생성된 객체 |
| `decimal` | integer | 2 | 소수점 자릿수 |
| `pcut.univariate` | numeric | NULL | 단변량 분석 p-value 임계값 |

#### Returns

Survey GLM 모델의 종합 결과를 포함하는 리스트:
1. **First line**: 회귀 유형 설명
2. **Table**: 분석 결과 테이블 (계수, 신뢰구간, p-value)
3. **Last lines**: 추가 모델 정보

#### Example

```r
library(survey)
data(api)

# 데이터 준비
apistrat$tt <- c(rep(1, 20), rep(0, nrow(apistrat) - 20))

# Survey design 생성
dstrat <- svydesign(
  id = ~1, 
  strata = ~stype, 
  weights = ~pw, 
  data = apistrat, 
  fpc = ~fpc
)

# Survey GLM 모델 (선형회귀)
linear_model <- svyglm(
  api00 ~ ell + meals + cname + mobility, 
  design = dstrat
)
linear_result <- svyregress.display(linear_model)

# Survey GLM 모델 (로지스틱회귀)
logistic_model <- svyglm(
  tt ~ ell + meals + mobility, 
  design = dstrat,
  family = binomial
)
logistic_result <- svyregress.display(logistic_model)

# 소수점 자릿수 조정
detailed_result <- svyregress.display(linear_model, decimal = 3)

# p-value 임계값 적용
filtered_result <- svyregress.display(linear_model, pcut.univariate = 0.1)
```

## Supported Model Types

### 선형회귀 (family = gaussian)

연속형 결과변수를 위한 가중치 적용 선형회귀

```r
library(survey)

# Survey design
design <- svydesign(
  ids = ~cluster_id,
  strata = ~stratum,
  weights = ~weight,
  data = continuous_data
)

# 선형회귀 모델
linear_model <- svyglm(
  continuous_outcome ~ treatment + age + sex,
  design = design,
  family = gaussian
)

result <- svyregress.display(linear_model)
```

### 로지스틱회귀 (family = binomial)

이진 결과변수를 위한 가중치 적용 로지스틱회귀

```r
# 로지스틱회귀 모델
logistic_model <- svyglm(
  binary_outcome ~ treatment + age + sex,
  design = design,
  family = binomial
)

result <- svyregress.display(logistic_model)
```

### 포아송회귀 (family = poisson)

계수 데이터를 위한 가중치 적용 포아송회귀

```r
# 포아송회귀 모델
poisson_model <- svyglm(
  count_outcome ~ treatment + age + sex,
  design = design,
  family = poisson
)

result <- svyregress.display(poisson_model)
```

## Usage Notes

### 기본 사용 패턴

```r
library(survey)

# 1. Survey design 생성
design <- svydesign(
  ids = ~primary_unit,
  strata = ~stratum,
  weights = ~sampling_weight,
  data = survey_data
)

# 2. 연속형 결과변수 분석
continuous_model <- svyglm(
  income ~ education + age + sex,
  design = design,
  family = gaussian
)

# 3. 이진 결과변수 분석
binary_model <- svyglm(
  employed ~ education + age + sex,
  design = design,
  family = binomial
)

# 4. 결과 표시
continuous_result <- svyregress.display(continuous_model)
binary_result <- svyregress.display(binary_model)
```

### 복잡한 표본설계 적용

```r
# 1. 다단계 군집 표본
multistage_design <- svydesign(
  ids = ~psu + ssu,
  strata = ~stratum,
  weights = ~weight,
  nest = TRUE,
  data = complex_survey
)

# 2. 유한모집단 보정
fpc_design <- svydesign(
  ids = ~cluster_id,
  strata = ~stratum, 
  weights = ~weight,
  fpc = ~fpc_cluster,
  data = finite_population_data
)

# 3. 모델 적합 및 결과
models <- list(
  multistage = svyglm(outcome ~ predictors, design = multistage_design),
  fpc = svyglm(outcome ~ predictors, design = fpc_design)
)

results <- lapply(models, svyregress.display)
```

### 가중치 효과 비교

```r
# 비가중 vs 가중 모델 비교
unweighted_model <- glm(
  outcome ~ treatment + age + sex,
  data = survey_data$variables,
  family = binomial
)

weighted_model <- svyglm(
  outcome ~ treatment + age + sex,
  design = survey_design,
  family = binomial
)

# 결과 비교
unweighted_result <- glmshow.display(unweighted_model)
weighted_result <- svyregress.display(weighted_model)

# 오즈비 비교
comparison <- data.frame(
  Variable = rownames(unweighted_result$table),
  Unweighted_OR = unweighted_result$table$OR,
  Weighted_OR = weighted_result$table$OR
)
```

## Output Format

### 선형회귀 결과

| Column | Description |
|--------|-------------|
| Variable | 변수명 |
| Coefficient (univariate) | 단변량 회귀계수 |
| 95% CI (univariate) | 단변량 95% 신뢰구간 |
| P-value (univariate) | 단변량 p-value |
| Coefficient (multivariate) | 다변량 회귀계수 |
| 95% CI (multivariate) | 다변량 95% 신뢰구간 |
| P-value (multivariate) | 다변량 p-value |

### 로지스틱회귀 결과

| Column | Description |
|--------|-------------|
| Variable | 변수명 |
| OR (univariate) | 단변량 오즈비 |
| 95% CI (univariate) | 단변량 95% 신뢰구간 |
| P-value (univariate) | 단변량 p-value |
| OR (multivariate) | 다변량 오즈비 |
| 95% CI (multivariate) | 다변량 95% 신뢰구간 |
| P-value (multivariate) | 다변량 p-value |

### 포아송회귀 결과

| Column | Description |
|--------|-------------|
| Variable | 변수명 |
| RR (univariate) | 단변량 발생률비 |
| 95% CI (univariate) | 단변량 95% 신뢰구간 |
| P-value (univariate) | 단변량 p-value |
| RR (multivariate) | 다변량 발생률비 |
| 95% CI (multivariate) | 다변량 95% 신뢰구간 |
| P-value (multivariate) | 다변량 p-value |

## Statistical Considerations

### 설계 효과 (Design Effect)

```r
# 설계 효과 계산
library(survey)

# 연속형 변수의 설계 효과
deff_mean <- svymean(~income, design = survey_design, deff = TRUE)
print(deff_mean)

# 범주형 변수의 설계 효과
deff_prop <- svytotal(~education, design = survey_design, deff = TRUE)
print(deff_prop)

# 회귀계수의 설계 효과
# 비가중 모델의 분산
unweighted_var <- diag(vcov(unweighted_model))

# 가중 모델의 분산
weighted_var <- diag(vcov(weighted_model))

# 설계 효과
design_effect <- weighted_var / unweighted_var
print(design_effect)
```

### 신뢰구간 및 검정

```r
# Survey GLM의 신뢰구간
confint(weighted_model)

# Wald 검정
anova(weighted_model)

# 모델 유의성 검정
summary(weighted_model)

# 개별 계수 검정
coef_test <- summary(weighted_model)$coefficients
significant_vars <- coef_test[coef_test[,4] < 0.05, ]
```

### 모델 적합도 평가

```r
# R-squared (survey 설계에서는 제한적)
# Pseudo R-squared 계산

# 1. McFadden's R²
null_model <- svyglm(outcome ~ 1, design = design, family = family)
mcfadden_r2 <- 1 - (AIC(full_model) - AIC(null_model)) / AIC(null_model)

# 2. Cox & Snell R²
n <- sum(weights(design))
cox_snell_r2 <- 1 - exp((deviance(full_model) - deviance(null_model)) / n)

# 3. Nagelkerke R²
nagelkerke_r2 <- cox_snell_r2 / (1 - exp(-deviance(null_model) / n))
```

## Advanced Applications

### 하위집단 분석

```r
# 성별 하위집단 분석
male_design <- subset(design, sex == "Male")
female_design <- subset(design, sex == "Female")

male_model <- svyglm(
  outcome ~ treatment + age,
  design = male_design,
  family = binomial
)

female_model <- svyglm(
  outcome ~ treatment + age,
  design = female_design,
  family = binomial
)

# 결과 비교
male_result <- svyregress.display(male_model)
female_result <- svyregress.display(female_model)

# 상호작용 검정
interaction_model <- svyglm(
  outcome ~ treatment * sex + age,
  design = design,
  family = binomial
)
interaction_result <- svyregress.display(interaction_model)
```

### 경향 분석 (Trend Analysis)

```r
# 순서형 변수의 경향 검정
# 교육수준: 초등학교(1), 중학교(2), 고등학교(3), 대학교(4)
survey_data$education_numeric <- as.numeric(survey_data$education)

trend_model <- svyglm(
  health_outcome ~ education_numeric + age + sex,
  design = design,
  family = binomial
)

trend_result <- svyregress.display(trend_model)

# 범주형으로도 분석하여 비교
categorical_model <- svyglm(
  health_outcome ~ factor(education) + age + sex,
  design = design,
  family = binomial
)

categorical_result <- svyregress.display(categorical_model)
```

### 다층 분석 (Multilevel Analysis)

```r
# 지역 효과를 고려한 분석
regional_model <- svyglm(
  outcome ~ individual_factors + factor(region),
  design = design,
  family = binomial
)

regional_result <- svyregress.display(regional_model)

# 지역 간 변이 평가
region_effects <- coef(regional_model)[grep("region", names(coef(regional_model)))]
region_se <- sqrt(diag(vcov(regional_model)))[grep("region", names(coef(regional_model)))]

region_summary <- data.frame(
  Region = names(region_effects),
  Coefficient = region_effects,
  SE = region_se,
  P_value = 2 * pnorm(-abs(region_effects / region_se))
)
```

## Model Diagnostics

### 기본 진단

```r
# 1. 잔차 분석
residuals_model <- residuals(weighted_model, type = "pearson")
fitted_values <- fitted(weighted_model)

# 2. 잔차 vs 적합값 플롯
plot(fitted_values, residuals_model,
     xlab = "Fitted Values", ylab = "Pearson Residuals",
     main = "Residuals vs Fitted")
abline(h = 0, col = "red")

# 3. Q-Q 플롯 (연속형 결과변수)
if(family(weighted_model)$family == "gaussian") {
  qqnorm(residuals_model)
  qqline(residuals_model)
}

# 4. 이상치 탐지
outliers <- which(abs(residuals_model) > 3)
if(length(outliers) > 0) {
  print(paste("Potential outliers at observations:", paste(outliers, collapse = ", ")))
}
```

### 영향관측치 분석

```r
# Survey 설계에서의 영향관측치 (제한적)
# 가중치 극값 확인
extreme_weights <- which(weights(design) > quantile(weights(design), 0.95) |
                        weights(design) < quantile(weights(design), 0.05))

# Cook's distance (근사치)
# 표준 GLM에서는 cooks.distance() 사용 가능하지만
# Survey GLM에서는 제한적

# 대안: 잭나이프 재표본
jackknife_coefs <- svyglm(
  outcome ~ predictors,
  design = design,
  family = family,
  influence = TRUE  # 영향관측치 정보 포함
)
```

### 모델 선택

```r
# 1. 정보기준을 이용한 모델 비교
models <- list(
  model1 = svyglm(outcome ~ var1, design = design, family = family),
  model2 = svyglm(outcome ~ var1 + var2, design = design, family = family),
  model3 = svyglm(outcome ~ var1 + var2 + var3, design = design, family = family)
)

# AIC 비교
aic_values <- sapply(models, AIC)
best_model <- models[[which.min(aic_values)]]

# 2. 우도비 검정
anova(models$model1, models$model2, method = "LRT")

# 3. 단계적 선택 (제한적 지원)
# 전체 모델에서 시작
full_model <- svyglm(outcome ~ ., design = design, family = family)
```

## Integration with Other Functions

### DT 테이블과 연동

```r
library(DT)

# Survey GLM 결과를 interactive table로 표시
result <- svyregress.display(weighted_model)

datatable(
  result$table,
  options = opt.tbreg("survey_glm_results"),
  caption = "Survey-weighted Regression Results"
)
```

### 서브그룹 분석과 연동

```r
# TableSubgroupGLM과 유사한 결과 생성
subgroups <- unique(survey_data$subgroup_var)

subgroup_results <- lapply(subgroups, function(sg) {
  sg_design <- subset(design, subgroup_var == sg)
  sg_model <- svyglm(outcome ~ treatment, design = sg_design, family = binomial)
  svyregress.display(sg_model)
})

names(subgroup_results) <- subgroups

# Forest plot 데이터 준비
forest_data <- do.call(rbind, lapply(names(subgroup_results), function(sg) {
  result <- subgroup_results[[sg]]$table
  treatment_row <- result[result$Variable == "treatment", ]
  data.frame(
    Subgroup = sg,
    OR = treatment_row$OR,
    Lower = treatment_row$CI_lower,
    Upper = treatment_row$CI_upper,
    P_value = treatment_row$P_value
  )
}))
```

## Dependencies

- `survey` package
- 기본 R 통계 함수들

## Common Applications

### 건강 설문조사 분석

```r
library(survey)

# 국민건강영양조사 스타일 분석
health_design <- svydesign(
  ids = ~psu,
  strata = ~stratum,
  weights = ~weight,
  nest = TRUE,
  data = health_survey
)

# 비만과 관련 요인 분석
obesity_model <- svyglm(
  obesity ~ age + sex + income + education + physical_activity,
  design = health_design,
  family = binomial
)

obesity_result <- svyregress.display(obesity_model)
```

### 경제활동 조사 분석

```r
# 경제활동인구조사 스타일 분석
labor_design <- svydesign(
  ids = ~household_id,
  weights = ~person_weight,
  data = labor_survey
)

# 소득 결정 요인 분석
income_model <- svyglm(
  log_income ~ education + experience + sex + region,
  design = labor_design,
  family = gaussian
)

income_result <- svyregress.display(income_model)

# 취업 확률 분석
employment_model <- svyglm(
  employed ~ education + age + sex + region,
  design = labor_design,
  family = binomial
)

employment_result <- svyregress.display(employment_model)
```

### 인과추론 분석

```r
# 역확률 가중치를 이용한 인과효과 추정
ipw_design <- svydesign(
  ids = ~1,
  weights = ~ipw,  # Inverse probability weights
  data = causal_data
)

# 평균 인과효과 추정
causal_model <- svyglm(
  outcome ~ treatment,
  design = ipw_design,
  family = gaussian
)

causal_result <- svyregress.display(causal_model)

# 조건부 평균 인과효과
conditional_causal_model <- svyglm(
  outcome ~ treatment + baseline_covariates,
  design = ipw_design,
  family = gaussian
)

conditional_result <- svyregress.display(conditional_causal_model)
```

## See Also

- `survey::svyglm()` - Survey 일반화선형모델
- `glmshow.display()` - 일반 GLM 결과 표시
- `TableSubgroupGLM()` - GLM 서브그룹 분석
- `survey::svydesign()` - Survey design 객체 생성
- `svyregress.display()` - Survey 회귀분석 결과 표시