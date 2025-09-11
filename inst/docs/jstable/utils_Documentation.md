# utils Documentation

## Overview

`utils.R`은 jstable 패키지에서 다양한 분석 함수들에서 공통으로 사용되는 유틸리티 함수들을 제공합니다. 주로 사건 계수, 서브그룹 요약, 그리고 데이터 변환 작업을 지원하는 헬퍼 함수들이 포함되어 있습니다.

## Functions

### `count_event_by()`

생존분석에서 사건과 서브그룹 수를 계산합니다.

#### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `formula` | formula | 생존분석 공식 (Surv 객체 포함) |
| `data` | data.frame | 공식과 일치하는 데이터 |
| `count_by_var` | character | 서브그룹을 계산할 변수들 |
| `var_subgroup` | character | 서브그룹 분석용 변수 |
| `decimal.percent` | integer | 백분율 소수점 자릿수 (기본값: 1) |

#### Returns

사건과 서브그룹 수를 포함하는 테이블

#### Example

```r
library(survival)
data(lung)

# 기본 사건 계수
event_summary <- count_event_by(
  formula = Surv(time, status) ~ sex,
  data = lung,
  count_by_var = "sex",
  var_subgroup = "ph.ecog"
)
print(event_summary)

# 소수점 자릿수 조정
detailed_summary <- count_event_by(
  formula = Surv(time, status) ~ sex,
  data = lung,
  count_by_var = "sex",
  var_subgroup = "ph.ecog",
  decimal.percent = 2
)
```

### `collapse_counts()`

그룹화 변수가 2개 이상의 수준을 가질 때 계수 열을 축약합니다.

#### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `df` | data.frame | TableSubgroup 함수들에서 생성된 데이터프레임 |
| `count_by` | character | 열 축약을 위한 변수명 |

#### Returns

간소화된 계수 보고를 포함하는 수정된 데이터프레임

#### Example

```r
# TableSubgroup 함수 결과 가정
subgroup_result <- data.frame(
  Variable = c("Treatment A", "Treatment B", "Treatment C"),
  Count_Group1 = c(25, 30, 20),
  Count_Group2 = c(22, 28, 18),
  Percent_Group1 = c(52.1, 51.7, 52.6),
  Percent_Group2 = c(47.9, 48.3, 47.4)
)

# 계수 축약
collapsed_result <- collapse_counts(
  df = subgroup_result,
  count_by = "Treatment"
)
print(collapsed_result)
```

### `count_event_by_glm()`

GLM 분석을 위한 사건 및 서브그룹 요약을 수행하며, 고정효과 구문의 자동 파싱을 지원합니다.

#### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `formula` | formula | 반응변수 공식 |
| `data` | data.frame/survey.design | 데이터프레임 또는 survey design 객체 |
| `count_by_var` | character | 층화 변수 |
| `var_subgroup` | character | 서브그룹 변수명 |
| `decimal.percent` | integer | 백분율/평균 소수점 자릿수 (기본값: 1) |
| `family` | character | 통계 패밀리 ("gaussian", "binomial", "poisson", "quasipoisson") |

#### Returns

그룹화 열과 메트릭 열을 포함하는 tibble

#### Example

```r
library(survival)
data(lung)

# 이진 결과변수 준비
lung$mortality <- as.integer(lung$status == 2)

# GLM 사건 계수 (이항분포)
glm_summary <- count_event_by_glm(
  formula = mortality ~ sex,
  data = lung,
  count_by_var = "sex",
  var_subgroup = "ph.ecog",
  family = "binomial"
)
print(glm_summary)

# 연속형 결과변수 (정규분포)
continuous_summary <- count_event_by_glm(
  formula = age ~ sex,
  data = lung,
  count_by_var = "sex",
  var_subgroup = "ph.ecog",
  family = "gaussian",
  decimal.percent = 2
)

# 계수 데이터 (포아송분포)
# 가상의 계수 변수 생성
lung$event_count <- rpois(nrow(lung), lambda = 2)

poisson_summary <- count_event_by_glm(
  formula = event_count ~ sex,
  data = lung,
  count_by_var = "sex", 
  var_subgroup = "ph.ecog",
  family = "poisson"
)
```

## Usage Notes

### 생존분석에서의 활용

```r
library(survival)

# 1. 기본 생존 데이터 요약
data(colon)
colon_subset <- subset(colon, etype == 2)  # 재발 이벤트만

# 치료군별 사건 요약
treatment_summary <- count_event_by(
  formula = Surv(time, status) ~ rx,
  data = colon_subset,
  count_by_var = "rx",
  var_subgroup = "sex"
)

# 2. 여러 서브그룹 변수
multiple_subgroups <- lapply(c("sex", "age_group", "stage"), function(sg) {
  count_event_by(
    formula = Surv(time, status) ~ rx,
    data = colon_subset,
    count_by_var = "rx",
    var_subgroup = sg
  )
})

names(multiple_subgroups) <- c("sex", "age_group", "stage")
```

### GLM 분석에서의 활용

```r
# 1. 다양한 패밀리별 요약

# 이항분포: 합병증 발생률
complication_summary <- count_event_by_glm(
  formula = complication ~ treatment,
  data = clinical_data,
  count_by_var = "treatment",
  var_subgroup = "hospital_type",
  family = "binomial"
)

# 정규분포: 연속형 결과
continuous_summary <- count_event_by_glm(
  formula = recovery_score ~ treatment,
  data = clinical_data,
  count_by_var = "treatment",
  var_subgroup = "hospital_type", 
  family = "gaussian"
)

# 포아송분포: 감염 발생 건수
infection_summary <- count_event_by_glm(
  formula = infection_count ~ ward_type,
  data = hospital_data,
  count_by_var = "ward_type",
  var_subgroup = "season",
  family = "poisson"
)
```

### Survey 데이터에서의 활용

```r
library(survey)

# Survey design 생성
survey_design <- svydesign(
  ids = ~cluster_id,
  strata = ~stratum,
  weights = ~weight,
  data = survey_data
)

# Survey 가중치를 고려한 요약
survey_summary <- count_event_by_glm(
  formula = health_outcome ~ intervention,
  data = survey_design,
  count_by_var = "intervention",
  var_subgroup = "region",
  family = "binomial"
)
```

## Data Processing Workflows

### 서브그룹 분석 전처리

```r
# 1. 서브그룹 변수 준비
prepare_subgroups <- function(data) {
  data$age_group <- cut(data$age, 
                       breaks = c(0, 50, 65, Inf),
                       labels = c("Young", "Middle", "Elder"))
  
  data$bmi_category <- cut(data$bmi,
                          breaks = c(0, 18.5, 25, 30, Inf),
                          labels = c("Underweight", "Normal", "Overweight", "Obese"))
  
  return(data)
}

# 2. 다중 서브그룹 분석
analyze_multiple_subgroups <- function(formula, data, treatment_var, subgroup_vars) {
  results <- list()
  
  for(sg in subgroup_vars) {
    if(is.Surv(eval(formula[[2]], data))) {
      # 생존분석
      results[[sg]] <- count_event_by(
        formula = formula,
        data = data,
        count_by_var = treatment_var,
        var_subgroup = sg
      )
    } else {
      # GLM 분석
      results[[sg]] <- count_event_by_glm(
        formula = formula,
        data = data,
        count_by_var = treatment_var,
        var_subgroup = sg,
        family = "binomial"  # 예시
      )
    }
  }
  
  return(results)
}

# 사용 예시
prepared_data <- prepare_subgroups(clinical_data)
subgroup_results <- analyze_multiple_subgroups(
  formula = Surv(time, event) ~ treatment,
  data = prepared_data,
  treatment_var = "treatment",
  subgroup_vars = c("age_group", "bmi_category", "sex")
)
```

### 결과 통합 및 형식화

```r
# 여러 서브그룹 결과를 하나의 테이블로 통합
combine_subgroup_results <- function(results_list) {
  combined <- do.call(rbind, lapply(names(results_list), function(sg_name) {
    result <- results_list[[sg_name]]
    result$Subgroup_Type <- sg_name
    return(result)
  }))
  
  # 행 순서 정리
  combined <- combined[order(combined$Subgroup_Type), ]
  rownames(combined) <- NULL
  
  return(combined)
}

# 축약된 보고서 생성
create_summary_report <- function(combined_results) {
  # 유의한 결과만 필터링
  significant <- combined_results[combined_results$P_value < 0.05, ]
  
  # 효과 크기별 정렬
  if("HR" %in% names(significant)) {
    significant <- significant[order(abs(log(significant$HR)), decreasing = TRUE), ]
  } else if("OR" %in% names(significant)) {
    significant <- significant[order(abs(log(significant$OR)), decreasing = TRUE), ]
  }
  
  return(significant)
}
```

## Integration with Main Analysis Functions

### ForestCox와의 연동

```r
# TableSubgroupCox에서 내부적으로 사용
forest_cox_data <- function(formula, data, subgroup_var) {
  # count_event_by로 기본 통계 생성
  event_counts <- count_event_by(
    formula = formula,
    data = data,
    count_by_var = as.character(formula)[3],
    var_subgroup = subgroup_var
  )
  
  # Cox 모델 결과와 결합
  cox_results <- TableSubgroupCox(
    formula = formula,
    var_subgroup = subgroup_var,
    data = data
  )
  
  # 통합 결과
  integrated <- merge(event_counts, cox_results, by = "Subgroup")
  return(integrated)
}
```

### ForestGLM과의 연동

```r
# TableSubgroupGLM에서 내부적으로 사용
forest_glm_data <- function(formula, data, subgroup_var, family) {
  # count_event_by_glm로 기본 통계 생성
  glm_counts <- count_event_by_glm(
    formula = formula,
    data = data,
    count_by_var = as.character(formula)[3],
    var_subgroup = subgroup_var,
    family = family
  )
  
  # GLM 모델 결과와 결합
  glm_results <- TableSubgroupGLM(
    formula = formula,
    var_subgroup = subgroup_var,
    data = data,
    family = family
  )
  
  # 통합 결과
  integrated <- merge(glm_counts, glm_results, by = "Subgroup")
  return(integrated)
}
```

## Performance Optimization

### 대용량 데이터 처리

```r
# 1. 청크 단위 처리
process_large_dataset <- function(data, chunk_size = 10000) {
  n_chunks <- ceiling(nrow(data) / chunk_size)
  results <- list()
  
  for(i in 1:n_chunks) {
    start_row <- (i - 1) * chunk_size + 1
    end_row <- min(i * chunk_size, nrow(data))
    
    chunk_data <- data[start_row:end_row, ]
    
    # 청크별 처리
    chunk_result <- count_event_by_glm(
      formula = outcome ~ treatment,
      data = chunk_data,
      count_by_var = "treatment",
      var_subgroup = "center",
      family = "binomial"
    )
    
    results[[i]] <- chunk_result
  }
  
  # 결과 통합
  final_result <- do.call(rbind, results)
  return(final_result)
}

# 2. 병렬 처리
library(parallel)

parallel_subgroup_analysis <- function(data, subgroup_vars, cores = 2) {
  cl <- makeCluster(cores)
  
  results <- parLapply(cl, subgroup_vars, function(sg) {
    count_event_by_glm(
      formula = outcome ~ treatment,
      data = data,
      count_by_var = "treatment",
      var_subgroup = sg,
      family = "binomial"
    )
  })
  
  stopCluster(cl)
  names(results) <- subgroup_vars
  return(results)
}
```

## Dependencies

- 기본 R 함수들 (`cut`, `aggregate`, `merge` 등)
- `survival` package (생존분석 관련 함수)
- `survey` package (survey 데이터 분석 시)
- `dplyr` package (데이터 처리, 선택적)

## Common Use Cases

### 임상시험 분석

```r
# 다기관 임상시험의 센터별 효과 평가
multicenter_summary <- count_event_by(
  formula = Surv(time_to_progression, progression) ~ treatment,
  data = clinical_trial,
  count_by_var = "treatment",
  var_subgroup = "center"
)

# 기준선 특성별 치료 효과
baseline_subgroups <- c("age_group", "disease_stage", "prior_therapy")
baseline_results <- lapply(baseline_subgroups, function(sg) {
  count_event_by_glm(
    formula = response ~ treatment,
    data = clinical_trial,
    count_by_var = "treatment", 
    var_subgroup = sg,
    family = "binomial"
  )
})
```

### 역학 연구

```r
# 지역별 질병 발생률
regional_incidence <- count_event_by_glm(
  formula = disease_onset ~ exposure,
  data = cohort_study,
  count_by_var = "exposure",
  var_subgroup = "region",
  family = "binomial"
)

# 연령대별 위험 요인 효과
age_stratified <- count_event_by_glm(
  formula = cardiovascular_event ~ smoking,
  data = population_study,
  count_by_var = "smoking",
  var_subgroup = "age_decade",
  family = "binomial"
)
```

### 품질 개선 연구

```r
# 병동별 합병증 발생률
ward_complications <- count_event_by_glm(
  formula = complication ~ intervention,
  data = quality_improvement,
  count_by_var = "intervention",
  var_subgroup = "ward_type",
  family = "binomial"
)

# 시간대별 의료 오류 빈도
error_frequency <- count_event_by_glm(
  formula = error_count ~ shift_type,
  data = safety_data,
  count_by_var = "shift_type",
  var_subgroup = "department",
  family = "poisson"
)
```

## See Also

- `TableSubgroupCox()` - Cox 모델 서브그룹 분석
- `TableSubgroupGLM()` - GLM 서브그룹 분석  
- `survival::Surv()` - 생존 객체 생성
- `survey::svydesign()` - Survey design 객체 생성
- `dplyr` package - 데이터 조작 함수들