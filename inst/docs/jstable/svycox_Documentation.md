# svycox Documentation

## Overview

`svycox.R`은 jstable 패키지에서 가중치가 적용된 설문조사 데이터의 Cox 비례위험모델 분석 결과를 표시하는 함수를 제공합니다. survey 패키지의 svycoxph 함수와 연동하여 복잡한 표본설계를 고려한 생존분석 결과를 사용자 친화적인 테이블로 변환합니다.

## Functions

### `svycox.display()`

survey Cox 비례위험모델의 결과를 테이블 형태로 표시합니다.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `svycoxph.obj` | svycoxph | - | survey::svycoxph로 생성된 객체 |
| `decimal` | integer | 2 | 소수점 자릿수 |
| `pcut.univariate` | numeric | NULL | 단변량 분석 p-value 임계값 |

#### Returns

Survey Cox 모델의 종합 결과를 포함하는 리스트:
1. **Table**: 분석 결과 테이블
2. **Metrics**: 모델 평가 지표
3. **Caption**: 모델 설명

#### Example

```r
library(survey)
library(survival)
data(pbc)

# 데이터 준비
pbc$sex <- factor(pbc$sex)
pbc$stage <- factor(pbc$stage)
pbc$randomized <- with(pbc, !is.na(trt) & trt > 0)

# Survey design 생성
dpbc <- svydesign(
  id = ~1, 
  prob = ~randprob, 
  strata = ~edema,
  data = subset(pbc, randomized)
)

# Survey Cox 모델 적합
model <- svycoxph(
  Surv(time, status > 0) ~ sex + protime + albumin + stage,
  design = dpbc
)

# 결과 표시
result <- svycox.display(model)
print(result)

# 소수점 자릿수 조정
detailed_result <- svycox.display(model, decimal = 3)

# p-value 임계값 적용
filtered_result <- svycox.display(model, pcut.univariate = 0.1)
```

### `extractAIC.svycoxph()`

survey Cox 모델에서 AIC 값을 추출합니다.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `fit` | svycoxph | - | survey Cox 모델 객체 |
| `scale` | numeric | NULL | 스케일 매개변수 (사용되지 않음) |
| `k` | numeric | 2 | 자유도의 가중치 |
| `...` | - | - | 추가 인수 |

#### Example

```r
# Survey Cox 모델의 AIC 추출
aic_value <- extractAIC(model)
print(aic_value)

# 여러 모델 비교
model1 <- svycoxph(Surv(time, status > 0) ~ sex, design = dpbc)
model2 <- svycoxph(Surv(time, status > 0) ~ sex + albumin, design = dpbc)
model3 <- svycoxph(Surv(time, status > 0) ~ sex + albumin + stage, design = dpbc)

aic_comparison <- data.frame(
  Model = c("Model1", "Model2", "Model3"),
  AIC = c(extractAIC(model1)[2], extractAIC(model2)[2], extractAIC(model3)[2])
)
```

## Survey Design in Survival Analysis

### 복잡한 표본설계 고려

```r
library(survey)
library(survival)

# 1. 층화 표본설계
stratified_design <- svydesign(
  ids = ~1,
  strata = ~stratum,
  weights = ~weight,
  data = survival_data
)

# 2. 군집 표본설계
cluster_design <- svydesign(
  ids = ~cluster_id,
  weights = ~weight,
  data = survival_data
)

# 3. 다단계 표본설계
multistage_design <- svydesign(
  ids = ~primary_unit + secondary_unit,
  strata = ~stratum,
  weights = ~weight,
  nest = TRUE,
  data = survival_data
)

# 각 설계에 대한 Cox 모델
models <- list(
  stratified = svycoxph(Surv(time, event) ~ treatment + age, 
                        design = stratified_design),
  cluster = svycoxph(Surv(time, event) ~ treatment + age, 
                     design = cluster_design),
  multistage = svycoxph(Surv(time, event) ~ treatment + age, 
                        design = multistage_design)
)

# 결과 비교
results <- lapply(models, svycox.display)
```

## Usage Notes

### 기본 사용 패턴

```r
library(survey)
library(survival)

# 1. 생존 데이터 준비
survival_data$event <- as.numeric(survival_data$status == "dead")
survival_data$time_years <- survival_data$time_days / 365.25

# 2. Survey design 생성
design <- svydesign(
  ids = ~hospital_id,
  strata = ~region,
  weights = ~sampling_weight,
  data = survival_data
)

# 3. Survey Cox 모델 적합
cox_model <- svycoxph(
  Surv(time_years, event) ~ treatment + age + comorbidity,
  design = design
)

# 4. 결과 표시
result <- svycox.display(cox_model)
```

### 가중치의 중요성

```r
# 비가중 vs 가중 Cox 모델 비교
unweighted_cox <- coxph(
  Surv(time, event) ~ treatment + age,
  data = survey_data$variables
)

weighted_cox <- svycoxph(
  Surv(time, event) ~ treatment + age,
  design = survey_design
)

# 결과 비교
unweighted_result <- cox2.display(unweighted_cox)
weighted_result <- svycox.display(weighted_cox)

# 위험비 비교
comparison <- data.frame(
  Variable = rownames(unweighted_result$table),
  Unweighted_HR = unweighted_result$table$HR,
  Weighted_HR = weighted_result$table$HR
)
```

### 복잡한 생존 분석

```r
# 1. 경쟁 위험 분석 (Competing risks)
# Note: svycoxph는 표준 Cox 모델만 지원
competing_model <- svycoxph(
  Surv(time, event == "primary_outcome") ~ treatment + covariates,
  design = design
)

# 2. 시간 의존적 공변량
# 데이터 변환 후 분석
time_varying_data <- survSplit(
  Surv(time, event) ~ ., 
  data = survey_data$variables,
  cut = c(30, 90, 180),  # 30일, 90일, 180일에서 분할
  episode = "time_period"
)

# 새로운 survey design
tv_design <- svydesign(
  ids = ~hospital_id,
  weights = ~sampling_weight,
  data = time_varying_data
)

tv_model <- svycoxph(
  Surv(tstart, time, event) ~ treatment * time_period + age,
  design = tv_design
)
```

## Output Format

### 결과 테이블 구조

| Column | Description |
|--------|-------------|
| Variable | 변수명 |
| HR (univariate) | 단변량 위험비 |
| 95% CI (univariate) | 단변량 95% 신뢰구간 |
| P-value (univariate) | 단변량 p-value |
| HR (multivariate) | 다변량 위험비 |
| 95% CI (multivariate) | 다변량 95% 신뢰구간 |
| P-value (multivariate) | 다변량 p-value |

### 모델 메트릭

- **관측치 수**: 분석에 포함된 대상자 수
- **사건 수**: 관찰된 사건 발생 수
- **AIC**: 아카이케 정보기준
- **Concordance**: 일치도 지수

## Statistical Considerations

### Survey 가중치의 영향

```r
# 설계 효과 (Design Effect) 계산
# 가중치로 인한 분산 증가 정도

# 비가중 모델의 분산
unweighted_var <- diag(vcov(unweighted_cox))

# 가중 모델의 분산  
weighted_var <- diag(vcov(weighted_cox))

# 설계 효과
design_effect <- weighted_var / unweighted_var

# 해석: > 1이면 가중치로 인한 분산 증가
print(design_effect)
```

### 신뢰구간 및 검정

```r
# Robust 표준오차를 고려한 신뢰구간
confint(weighted_cox)

# Wald 검정
anova(weighted_cox)

# 전체 모델 유의성 검정
summary(weighted_cox)$sctest
```

### 비례위험 가정 검정

```r
# Survey Cox 모델에서는 표준 검정법 제한
# 대안적 접근법:

# 1. 잔차 분석 (제한적)
residuals_cox <- residuals(weighted_cox, type = "martingale")

# 2. 시간 구간별 분석
early_period <- svycoxph(
  Surv(pmin(time, 365), event) ~ treatment + age,
  design = design
)

late_period <- svycoxph(
  Surv(pmax(time - 365, 0), event) ~ treatment + age,
  design = design,
  subset = time > 365
)

# 위험비 비교
early_result <- svycox.display(early_period)
late_result <- svycox.display(late_period)
```

## Advanced Applications

### 하위집단 분석

```r
# 성별 하위집단 분석
male_design <- subset(design, sex == "Male")
female_design <- subset(design, sex == "Female")

male_model <- svycoxph(
  Surv(time, event) ~ treatment + age,
  design = male_design
)

female_model <- svycoxph(
  Surv(time, event) ~ treatment + age,
  design = female_design
)

# 결과 비교
male_result <- svycox.display(male_model)
female_result <- svycox.display(female_model)

# 상호작용 검정
interaction_model <- svycoxph(
  Surv(time, event) ~ treatment * sex + age,
  design = design
)
interaction_result <- svycox.display(interaction_model)
```

### 층화 분석

```r
# 지역별 층화 Cox 모델
stratified_model <- svycoxph(
  Surv(time, event) ~ treatment + age + strata(region),
  design = design
)

stratified_result <- svycox.display(stratified_model)

# 층별 기저 위험 확인 (제한적 기능)
# survfit으로 생존 곡선 추정
survival_curves <- svykm(
  Surv(time, event) ~ treatment + strata(region),
  design = design
)
```

### 예측 모델링

```r
# 위험 점수 계산
risk_scores <- predict(weighted_cox, type = "risk")

# 생존 확률 예측 (제한적)
# 새로운 데이터에 대한 예측
new_data <- data.frame(
  treatment = c("A", "B"),
  age = c(65, 70),
  comorbidity = c("Low", "High")
)

# 가중치 적용한 예측 (복잡한 계산 필요)
predicted_hr <- predict(weighted_cox, newdata = new_data, type = "risk")
```

## Model Diagnostics

### 기본 진단

```r
# 1. 모델 요약
summary(weighted_cox)

# 2. AIC 기반 모델 선택
step_model <- step(weighted_cox)  # 제한적 지원

# 3. 영향관측치 (제한적)
# Survey 설계에서는 표준 진단법 제한
# 대안: 가중치 극값 확인
extreme_weights <- which(design$prob < quantile(design$prob, 0.05) | 
                        design$prob > quantile(design$prob, 0.95))
```

### 모델 검증

```r
# 교차 검증 (복잡한 survey 설계에서는 제한적)
# Bootstrap 방법 (가중치 고려 필요)

# 단순화된 검증: 훈련/검증 분할
set.seed(123)
train_ids <- sample(unique(design$cluster), 
                    size = length(unique(design$cluster)) * 0.7)

train_design <- subset(design, cluster %in% train_ids)
validation_design <- subset(design, !cluster %in% train_ids)

# 훈련 모델
train_model <- svycoxph(
  Surv(time, event) ~ treatment + age,
  design = train_design
)

# 검증 (예측 성능 평가는 제한적)
validation_predictions <- predict(train_model, 
                                 newdata = validation_design$variables)
```

## Integration with Other Functions

### DT 테이블과 연동

```r
library(DT)

# Survey Cox 결과를 interactive table로 표시
result <- svycox.display(weighted_cox)

datatable(
  result$table,
  options = opt.tbreg("survey_cox_results"),
  caption = "Survey-weighted Cox Regression Results"
)
```

### Forest Plot 생성

```r
# 서브그룹 분석 결과를 Forest plot으로
library(forestplot)

# 여러 하위집단 모델 결과 수집
subgroup_results <- list(
  overall = svycox.display(overall_model),
  male = svycox.display(male_model),
  female = svycox.display(female_model),
  young = svycox.display(young_model),
  old = svycox.display(old_model)
)

# Forest plot 데이터 준비
forest_data <- do.call(rbind, lapply(names(subgroup_results), function(group) {
  result <- subgroup_results[[group]]$table
  data.frame(
    Subgroup = group,
    HR = result$HR[result$Variable == "treatment"],
    Lower = result$CI_lower[result$Variable == "treatment"],
    Upper = result$CI_upper[result$Variable == "treatment"]
  )
}))
```

## Dependencies

- `survey` package
- `survival` package
- 기본 R 통계 함수들

## Common Applications

### 인구 기반 코호트 연구

```r
# 국가 건강 데이터베이스 분석
national_design <- svydesign(
  ids = ~hospital + patient_id,
  strata = ~region,
  weights = ~population_weight,
  nest = TRUE,
  data = national_cohort
)

# 치료 효과 분석
treatment_effect <- svycoxph(
  Surv(followup_years, mortality) ~ new_treatment + age + sex + comorbidities,
  design = national_design
)

result <- svycox.display(treatment_effect)
```

### 임상시험 가중치 분석

```r
# 역확률 가중치를 이용한 인과추론
ipw_design <- svydesign(
  ids = ~1,
  weights = ~ipw,  # Inverse probability weights
  data = observational_study
)

# 치료 효과 추정
causal_effect <- svycoxph(
  Surv(time_to_event, event) ~ treatment,
  design = ipw_design
)

causal_result <- svycox.display(causal_effect)
```

### 메타분석 스타일 분석

```r
# 다기관 연구에서 센터별 가중치
multicenter_design <- svydesign(
  ids = ~center + patient_id,
  weights = ~center_weight * patient_weight,
  data = multicenter_survival
)

# 전체 효과 추정
pooled_effect <- svycoxph(
  Surv(survival_time, death) ~ treatment + center,
  design = multicenter_design
)

pooled_result <- svycox.display(pooled_effect)
```

## See Also

- `survey::svycoxph()` - Survey Cox 비례위험모델
- `cox2.display()` - 일반 Cox 모델 결과 표시
- `survival::coxph()` - 표준 Cox 모델
- `survey::svydesign()` - Survey design 객체 생성
- `TableSubgroupCox()` - Cox 모델 서브그룹 분석