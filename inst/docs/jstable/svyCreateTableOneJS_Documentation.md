# svyCreateTableOneJS Documentation

## Overview

`svyCreateTableOneJS.R`은 jstable 패키지에서 가중치가 적용된 설문조사 데이터(survey data)의 기술통계 테이블을 생성하는 함수를 제공합니다. survey 패키지와 연동하여 복잡한 표본설계를 고려한 정확한 모집단 추정치와 표준오차를 계산할 수 있습니다.

## Functions

### `svyCreateTableOneJS()`

설문조사 데이터용 기술통계 테이블을 생성하는 향상된 함수입니다.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `vars` | character | - | 요약할 변수들 |
| `strata` | character | NULL | 1차 계층화 변수 |
| `strata2` | character | NULL | 2차 계층화 변수 |
| `data` | survey.design | - | survey design 객체 |
| `factorVars` | character | NULL | 범주형 변수들 |
| `includeNA` | logical | FALSE | NA를 factor 레벨로 처리 |
| `test` | logical | TRUE | 그룹 간 비교 검정 수행 |
| `showAllLevels` | logical | TRUE | 모든 범주 레벨 표시 |
| `printToggle` | logical | FALSE | 출력 여부 |
| `quote` | logical | FALSE | Excel용 따옴표 |
| `smd` | logical | FALSE | 표준화 평균 차이 계산 |
| `Labels` | logical | FALSE | 변수 레이블 사용 |
| `nonnormal` | character | NULL | 비모수 검정할 변수들 |
| `catDigits` | integer | 1 | 범주형 변수 소수점 자릿수 |
| `contDigits` | integer | 2 | 연속형 변수 소수점 자릿수 |
| `pDigits` | integer | 3 | p-value 소수점 자릿수 |
| `addOverall` | logical | FALSE | 전체 열 추가 |
| `pairwise` | logical | FALSE | 쌍별 비교 표시 |
| `n_original` | logical | TRUE | 원본 데이터 n으로 대체 |

#### Example

```r
library(survey)
data(nhanes)

# Survey design 객체 생성
nhanes$SDMVPSU <- as.factor(nhanes$SDMVPSU)
nhanesSvy <- svydesign(
  ids = ~SDMVPSU, 
  strata = ~SDMVSTRA, 
  weights = ~WTMEC2YR,
  nest = TRUE, 
  data = nhanes
)

# 기본 survey table 1 생성
result1 <- svyCreateTableOneJS(
  vars = c("HI_CHOL", "race", "agecat", "RIAGENDR"),
  strata = "RIAGENDR", 
  data = nhanesSvy,
  factorVars = c("HI_CHOL", "race", "RIAGENDR")
)

# 이중 계층화
result2 <- svyCreateTableOneJS(
  vars = c("HI_CHOL", "race", "agecat"),
  strata = "RIAGENDR",
  strata2 = "agecat",
  data = nhanesSvy,
  factorVars = c("HI_CHOL", "race", "RIAGENDR")
)

# 고급 옵션 적용
result3 <- svyCreateTableOneJS(
  vars = c("HI_CHOL", "race", "agecat"),
  strata = "RIAGENDR", 
  data = nhanesSvy,
  factorVars = c("HI_CHOL", "race"),
  test = TRUE,
  smd = TRUE,
  addOverall = TRUE,
  catDigits = 2,
  contDigits = 1
)
```

## Survey Design Integration

### 복잡한 표본설계 지원

```r
# 1. 층화 표본
stratified_design <- svydesign(
  ids = ~1,
  strata = ~stratum,
  weights = ~weight,
  data = survey_data
)

# 2. 군집 표본
cluster_design <- svydesign(
  ids = ~cluster_id,
  weights = ~weight,
  data = survey_data
)

# 3. 다단계 표본
multistage_design <- svydesign(
  ids = ~primary_unit + secondary_unit,
  strata = ~stratum,
  weights = ~weight,
  nest = TRUE,
  data = survey_data
)

# 4. 유한모집단 보정
fpc_design <- svydesign(
  ids = ~cluster_id,
  strata = ~stratum,
  weights = ~weight,
  fpc = ~fpc_primary,
  data = survey_data
)

# 각 설계에 대한 테이블 생성
results <- lapply(
  list(stratified_design, cluster_design, multistage_design, fpc_design),
  function(design) {
    svyCreateTableOneJS(
      vars = c("var1", "var2", "var3"),
      strata = "group",
      data = design
    )
  }
)
```

## Usage Notes

### 기본 사용 패턴

```r
library(survey)

# 1. Survey design 생성
design <- svydesign(
  ids = ~psu,
  strata = ~stratum,
  weights = ~weight,
  data = survey_data
)

# 2. 변수 선택 및 준비
vars_continuous <- c("age", "income", "bmi")
vars_categorical <- c("sex", "education", "smoking")
all_vars <- c(vars_continuous, vars_categorical)

# 3. 기술통계 테이블 생성
table1 <- svyCreateTableOneJS(
  vars = all_vars,
  strata = "treatment_group",
  data = design,
  factorVars = vars_categorical
)

print(table1)
```

### 이중 계층화 분석

```r
# 성별과 연령군으로 이중 계층화
double_strata <- svyCreateTableOneJS(
  vars = c("cholesterol", "bp_systolic", "diabetes"),
  strata = "sex",
  strata2 = "age_group",
  data = health_survey,
  factorVars = "diabetes",
  test = TRUE
)

# 결과 해석:
# - 주요 계층: 성별 (남자 vs 여자)
# - 부계층: 연령군 (청년, 중년, 노년)
# - 각 조합별 통계량 제공
```

### 고급 통계 옵션

```r
# 포괄적 분석 옵션
comprehensive_table <- svyCreateTableOneJS(
  vars = c("age", "income", "education", "health_status"),
  strata = "intervention",
  data = trial_survey,
  factorVars = c("education", "health_status"),
  test = TRUE,              # 통계 검정
  smd = TRUE,               # 표준화 평균 차이
  addOverall = TRUE,        # 전체 그룹 열
  nonnormal = "income",     # 비모수 검정 변수
  includeNA = TRUE,         # 결측치 포함
  catDigits = 2,           # 범주형 2자리
  contDigits = 1,          # 연속형 1자리
  pDigits = 4              # p-value 4자리
)
```

## Output Format

### 기본 테이블 구조

#### 연속형 변수
| Variable | Overall | Group 1 | Group 2 | P-value | SMD |
|----------|---------|---------|---------|---------|-----|
| Age (years) | 45.2 ± 12.3 | 44.8 ± 11.9 | 45.6 ± 12.7 | 0.123 | 0.063 |

#### 범주형 변수
| Variable | Overall | Group 1 | Group 2 | P-value | SMD |
|----------|---------|---------|---------|---------|-----|
| Sex |  |  |  | 0.045 | 0.182 |
| Male | 1250 (48.2) | 625 (49.1) | 625 (47.3) |  |  |
| Female | 1345 (51.8) | 649 (50.9) | 696 (52.7) |  |  |

### 이중 계층화 결과

```
                 Stratified by sex and age_group
                 Male              Female
                 Young   Old       Young   Old      p      test
  n                150    180       145     175              
  Cholesterol (mean (SD)) 180.2 (25.3) 195.4 (30.1) 175.8 (22.9) 188.9 (28.5) 0.012 
  Diabetes (%)      25 (16.7)  45 (25.0)  20 (13.8)  38 (21.7) 0.089  
```

## Statistical Considerations

### 가중치의 영향

```r
# 비가중 vs 가중 결과 비교
unweighted <- CreateTableOneJS(
  vars = vars,
  strata = "group",
  data = survey_data$variables  # 원본 데이터
)

weighted <- svyCreateTableOneJS(
  vars = vars,
  strata = "group", 
  data = survey_design          # survey design 객체
)

# 가중치 효과 확인
comparison <- list(
  unweighted = unweighted,
  weighted = weighted
)
```

### 설계 효과 (Design Effect)

```r
# 설계 효과 계산
library(survey)

# 연속형 변수의 설계 효과
deff_continuous <- svyvar(~age, design = survey_design, deff = TRUE)

# 범주형 변수의 설계 효과  
deff_categorical <- svytotal(~sex, design = survey_design, deff = TRUE)

# 해석: deff > 1이면 단순무작위표본보다 분산 증가
```

### 신뢰구간 조정

```r
# Bonferroni 보정
adjusted_alpha <- 0.05 / number_of_comparisons

# 보정된 신뢰구간으로 테이블 생성
bonferroni_table <- svyCreateTableOneJS(
  vars = vars,
  strata = "group",
  data = design,
  # 내부적으로 p-value 보정은 별도 처리 필요
)
```

## Advanced Features

### 결측치 처리

```r
# 결측치를 별도 범주로 처리
missing_as_category <- svyCreateTableOneJS(
  vars = c("income", "education", "health_insurance"),
  strata = "region",
  data = survey_design,
  factorVars = c("education", "health_insurance"),
  includeNA = TRUE  # 결측치를 팩터 레벨로 포함
)

# 결측치 패턴 분석
library(VIM)
aggr(survey_data$variables[vars], col = c('navyblue','red'), numbers = TRUE)
```

### 표준화 평균 차이 (SMD)

```r
# SMD 해석 가이드라인:
# - |SMD| < 0.1: 무시할 만한 차이
# - 0.1 ≤ |SMD| < 0.3: 작은 차이  
# - 0.3 ≤ |SMD| < 0.5: 중간 차이
# - |SMD| ≥ 0.5: 큰 차이

smd_table <- svyCreateTableOneJS(
  vars = vars,
  strata = "treatment",
  data = rct_survey,
  smd = TRUE
)

# SMD가 큰 변수들 식별
high_smd_vars <- smd_table[abs(smd_table$SMD) > 0.3, ]
```

### 쌍별 비교

```r
# 3개 이상 그룹의 쌍별 비교
pairwise_table <- svyCreateTableOneJS(
  vars = vars,
  strata = "treatment_arm",  # 3개 그룹: A, B, C
  data = multiarm_survey,
  pairwise = TRUE,          # 모든 쌍별 비교
  test = TRUE
)

# 결과: A vs B, A vs C, B vs C 각각의 p-value
```

## Integration with Other Functions

### DT 테이블과 연동

```r
library(DT)

# Survey table을 interactive table로 표시
survey_table <- svyCreateTableOneJS(
  vars = vars,
  strata = "group",
  data = design
)

datatable(
  survey_table,
  options = opt.tb1("survey_table1"),
  caption = "Survey-weighted Descriptive Statistics"
)
```

### 레이블 적용

```r
# 변수 레이블과 함께 사용
labeled_data <- survey_data
attr(labeled_data$age, "label") <- "Age (years)"
attr(labeled_data$income, "label") <- "Annual Income ($)"

# 레이블이 적용된 survey design
labeled_design <- svydesign(
  ids = ~psu,
  weights = ~weight,
  data = labeled_data
)

# 레이블이 반영된 테이블
labeled_table <- svyCreateTableOneJS(
  vars = c("age", "income"),
  strata = "group",
  data = labeled_design,
  Labels = TRUE
)
```

## Dependencies

- `survey` package
- `tableone` package (기반 함수)
- 기본 R 통계 함수들

## Common Applications

### 건강 설문조사 분석

```r
library(survey)

# NHANES 스타일 설계
health_design <- svydesign(
  ids = ~psu,
  strata = ~stratum,  
  weights = ~sample_weight,
  nest = TRUE,
  data = health_survey
)

# 인구집단별 건강 지표 비교
health_table <- svyCreateTableOneJS(
  vars = c("bmi", "blood_pressure", "cholesterol", "diabetes"),
  strata = "income_level",
  data = health_design,
  factorVars = "diabetes"
)
```

### 사회경제 조사 분석

```r
# 경제활동인구조사 스타일
economic_design <- svydesign(
  ids = ~household_id,
  weights = ~person_weight,
  data = labor_survey
)

# 교육수준별 경제활동 분석  
economic_table <- svyCreateTableOneJS(
  vars = c("employment_status", "income", "working_hours"),
  strata = "education_level",
  data = economic_design,
  factorVars = "employment_status"
)
```

### 임상연구 가중치 분석

```r
# 역확률 가중치를 이용한 관찰연구
ipw_design <- svydesign(
  ids = ~1,
  weights = ~ipw,  # 역확률 가중치
  data = observational_study
)

# 치료군별 baseline 특성 비교
ipw_table <- svyCreateTableOneJS(
  vars = baseline_vars,
  strata = "treatment",
  data = ipw_design,
  smd = TRUE  # 가중치 적용 후 균형 확인
)
```

## See Also

- `survey::svydesign()` - Survey design 객체 생성
- `CreateTableOneJS()` - 비가중 기술통계 테이블
- `tableone::svyCreateTableOne()` - 원본 survey table 함수
- `survey::svymean()`, `survey::svytotal()` - Survey 요약 통계