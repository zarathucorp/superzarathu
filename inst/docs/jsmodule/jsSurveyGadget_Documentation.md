# jsSurveyGadget Documentation

## Overview
`jsSurveyGadget.R`은 jsmodule 패키지의 복합표본조사 데이터 분석(Complex Survey Data Analysis) 전용 Shiny 가젯입니다. 국가통계조사, 건강검진조사, 사회조사 등의 복합표본설계 데이터에서 층화, 집락, 가중치를 고려한 고급 통계분석을 제공합니다.

## Main Functions

### `jsSurveyGadget(data, nfactor.limit = 20)`
R 데이터셋을 위한 복합표본조사 분석 전용 가젯을 실행합니다.

**Parameters:**
- `data`: 분석할 복합표본조사 R 데이터 객체 (data.frame, data.table 등)
- `nfactor.limit`: 범주형 변수의 최대 수준 수 (기본값: 20)

**Returns:**
- 복합표본조사 데이터 분석에 특화된 Shiny 가젯 인터페이스

### `jsSurveyExtAddin(nfactor.limit = 20, max.filesize = 2048)`
외부 데이터 파일을 지원하는 확장 버전 복합표본조사 분석 도구입니다.

**Parameters:**
- `nfactor.limit`: 범주형 변수의 최대 수준 수 (기본값: 20)
- `max.filesize`: 업로드 가능한 최대 파일 크기 (MB 단위, 기본값: 2048)

**Returns:**
- 파일 업로드 기능이 포함된 복합표본조사 분석 가젯

## Usage Examples

### Basic Survey Data Analysis
```r
library(jsmodule)
library(survey)

# 복합표본조사 데이터 생성 예시 (KNHANES 스타일)
survey_data <- data.frame(
  id = 1:2000,
  strata = sample(1:20, 2000, replace = TRUE),      # 층화변수
  cluster = sample(1:100, 2000, replace = TRUE),    # 집락변수  
  weight = runif(2000, 0.5, 3.0),                  # 표본가중치
  age = sample(19:80, 2000, replace = TRUE),
  gender = sample(c("Male", "Female"), 2000, replace = TRUE),
  education = sample(c("Elementary", "Middle", "High", "College"), 
                    2000, replace = TRUE, prob = c(0.1, 0.2, 0.4, 0.3)),
  income = sample(1:5, 2000, replace = TRUE),       # 소득분위
  region = sample(c("Seoul", "Gyeonggi", "Other"), 
                 2000, replace = TRUE, prob = c(0.3, 0.3, 0.4)),
  hypertension = rbinom(2000, 1, 0.25),
  diabetes = rbinom(2000, 1, 0.1),
  bmi = rnorm(2000, 24, 3),
  systolic_bp = rnorm(2000, 120, 15),
  cholesterol = rnorm(2000, 200, 40)
)

# 복합표본조사 분석 가젯 실행
jsSurveyGadget(survey_data)
```

### National Health Survey Analysis
```r
library(jsmodule)

# 국민건강영양조사(KNHANES) 스타일 데이터
knhanes_style <- data.frame(
  year = rep(c(2019, 2020, 2021), each = 800),
  psu = rep(1:120, 20),                            # 조사구(PSU)
  kstrata = rep(1:40, 60),                         # 층화변수
  wt_itvw = runif(2400, 100, 5000),               # 면접조사 가중치
  wt_ex = runif(2400, 80, 4500),                  # 검진조사 가중치
  
  # 인구사회학적 변수
  sex = sample(c(1, 2), 2400, replace = TRUE),     # 1=남, 2=여
  age = sample(19:80, 2400, replace = TRUE),
  edu = sample(1:4, 2400, replace = TRUE),         # 교육수준
  marr = sample(1:3, 2400, replace = TRUE),        # 혼인상태
  region = sample(1:4, 2400, replace = TRUE),      # 지역
  
  # 건강관련 변수
  height = rnorm(2400, 165, 10),
  weight = rnorm(2400, 65, 12),
  waist = rnorm(2400, 85, 10),
  systolic = rnorm(2400, 118, 16),
  diastolic = rnorm(2400, 76, 10),
  glucose = rlnorm(2400, 4.5, 0.3),
  hba1c = rnorm(2400, 5.4, 0.8),
  
  # 질병 및 건강행동
  dm = rbinom(2400, 1, 0.08),                     # 당뇨병
  htn = rbinom(2400, 1, 0.22),                    # 고혈압
  smoke = sample(1:3, 2400, replace = TRUE),       # 흡연상태
  alcohol = sample(1:4, 2400, replace = TRUE)      # 음주상태
)

# 복합표본조사 분석 가젯 실행
jsSurveyGadget(knhanes_style, nfactor.limit = 15)
```

### External Survey Data Import
```r
library(jsmodule)

# 외부 복합표본조사 파일 업로드 지원
jsSurveyExtAddin(max.filesize = 3000)  # 3GB 지원
```

## Interface Components

### Survey Design Setup
- **가중치 변수**: 표본가중치, 층화가중치 등 선택
- **층화변수**: 층화 설계 변수 지정  
- **집락변수**: 1차/2차 표집단위(PSU/SSU) 설정
- **모집단 크기**: 유한모집단 보정계수 설정

### Weighted Descriptive Statistics
- **가중 빈도**: 범주형 변수의 가중 분포
- **가중 평균**: 연속형 변수의 모집단 추정값
- **신뢰구간**: 복합표본설계를 고려한 95% 신뢰구간
- **설계효과**: 단순무작위추출 대비 분산 증가

### Survey Regression Analysis
- **가중 선형회귀**: 연속형 종속변수
- **가중 로지스틱회귀**: 이진형 종속변수
- **가중 다항로지스틱**: 다범주 종속변수
- **가중 생존분석**: 시간-이벤트 데이터

### Design-based Inference
- **표준오차 추정**: 테일러 급수/재표집 방법
- **신뢰구간**: Wald/Rao-Scott 조정 신뢰구간
- **가설검정**: F검정/Rao-Scott 검정
- **다중비교**: Bonferroni/Holm 조정

## Survey Design Implementation

### Survey Design Object Creation
```r
library(survey)

# 복합표본설계 객체 생성
survey_design <- svydesign(
  ids = ~psu,                    # 집락변수
  strata = ~kstrata,             # 층화변수
  weights = ~wt_itvw,            # 가중치
  nest = TRUE,                   # 층화된 집락
  data = knhanes_style
)

# 사후층화 조정 (선택적)
pop_totals <- data.frame(
  sex = c("Male", "Female"),
  Freq = c(25000000, 25000000)  # 모집단 성비
)

calibrated_design <- calibrate(
  survey_design, 
  formula = ~sex, 
  population = pop_totals
)
```

### Subpopulation Analysis
```r
# 특정 하위모집단 분석 (성인만)
adult_design <- subset(survey_design, age >= 19)

# 조건부 분석 (당뇨병 환자만)
diabetes_design <- subset(survey_design, dm == 1)
```

### Domain Analysis
```r
# 지역별 도메인 분석
by_region <- svyby(
  ~systolic, 
  ~region, 
  design = survey_design, 
  svymean, 
  na.rm = TRUE
)
```

## Statistical Analysis Methods

### Weighted Descriptive Statistics
```r
# 가중 평균 및 비율
svymean(~bmi, design = survey_design)
svymean(~diabetes, design = survey_design)

# 가중 분위수
svyquantile(~income, design = survey_design, 
           quantiles = c(0.25, 0.5, 0.75))

# 가중 교차표
svytable(~gender + education, design = survey_design)
```

### Survey Regression Models
```r
# 가중 선형회귀
linear_model <- svyglm(
  systolic_bp ~ age + gender + bmi + education,
  design = survey_design,
  family = gaussian()
)

# 가중 로지스틱회귀  
logistic_model <- svyglm(
  hypertension ~ age + gender + bmi + income,
  design = survey_design,
  family = binomial()
)

# 가중 생존분석 (시간제한적)
cox_model <- svycoxph(
  Surv(time, event) ~ age + gender + treatment,
  design = survey_design
)
```

### Hypothesis Testing
```r
# 독립성 검정 (Rao-Scott 조정)
svychisq(~gender + diabetes, design = survey_design)

# 평균 차이 검정
svyttest(systolic_bp ~ gender, design = survey_design)

# ANOVA (복합표본 F검정)
svyanova(bmi ~ education, design = survey_design)
```

## Advanced Features

### Multiple Imputation for Survey Data
```r
library(mitools)

# 결측값 다중대체
imputed_data <- mice(survey_data, m = 5)

# 각 대체데이터에서 복합표본설계
imputed_designs <- lapply(1:5, function(i) {
  complete_data <- complete(imputed_data, i)
  svydesign(ids = ~cluster, strata = ~strata, 
           weights = ~weight, data = complete_data)
})

# 다중대체 결과 통합
mi_results <- with(imputationList(imputed_designs), 
                  svyglm(outcome ~ predictors, family = binomial()))
pooled_results <- MIcombine(mi_results)
```

### Variance Estimation Methods
```r
# 재표집 방법 (Jackknife)
jk_design <- as.svrepdesign(survey_design, type = "JK1")

# Bootstrap 방법
bs_design <- as.svrepdesign(survey_design, type = "bootstrap", 
                           replicates = 1000)

# BRR (Balanced Repeated Replication)
brr_design <- as.svrepdesign(survey_design, type = "BRR")
```

### Calibration and Raking
```r
# 사후층화 (Post-stratification)
pop_margins <- data.frame(
  age_group = c("19-39", "40-64", "65+"),
  Freq = c(20000000, 15000000, 8000000)
)

calibrated_design <- postStratify(
  survey_design, 
  strata = ~age_group, 
  population = pop_margins
)

# 레이킹 (Raking)
rake_design <- rake(
  survey_design,
  sample.margins = list(~age_group, ~gender, ~region),
  population.margins = list(age_totals, gender_totals, region_totals)
)
```

## Visualization Components

### Survey-weighted Plots
```r
library(ggplot2)

# 가중 막대그래프
weighted_props <- svymean(~education, design = survey_design)
barplot_data <- data.frame(
  education = names(weighted_props),
  proportion = as.numeric(weighted_props),
  se = SE(weighted_props)
)

ggplot(barplot_data, aes(x = education, y = proportion)) +
  geom_bar(stat = "identity") +
  geom_errorbar(aes(ymin = proportion - 1.96*se, 
                    ymax = proportion + 1.96*se), width = 0.2) +
  labs(title = "Weighted Education Distribution with 95% CI")
```

### Complex Survey Scatterplots
```r
# 설계가중치를 반영한 산점도
svyplot(systolic_bp ~ age, design = survey_design,
        style = "bubble", col = "blue", alpha = 0.6)

# 가중 회귀선 추가
abline(svyglm(systolic_bp ~ age, design = survey_design), 
       col = "red", lwd = 2)
```

### Domain Comparison Plots
```r
# 지역별 비교 박스플롯
regional_means <- svyby(~bmi, ~region, design = survey_design, svymean)

ggplot(regional_means, aes(x = region, y = bmi)) +
  geom_point(size = 3) +
  geom_errorbar(aes(ymin = bmi - 1.96*se, ymax = bmi + 1.96*se), 
                width = 0.2) +
  labs(title = "Regional BMI Means with 95% CI", 
       y = "BMI (kg/m²)", x = "Region")
```

## Quality Control Features

### Survey Design Validation
```r
# 설계 정보 확인
summary(survey_design)

# 가중치 분포 확인
summary(weights(survey_design))

# 설계효과 계산
design_effects <- svymean(~bmi, design = survey_design, deff = TRUE)
print(attr(design_effects, "deff"))

# 유효표본크기
effective_n <- degf(survey_design) + 1
print(paste("Effective sample size:", effective_n))
```

### Diagnostic Checks
```r
# 가중치 극값 탐지
weight_summary <- summary(survey_data$weight)
extreme_weights <- which(survey_data$weight > quantile(survey_data$weight, 0.95) |
                        survey_data$weight < quantile(survey_data$weight, 0.05))

# 층별 표본크기 확인
strata_counts <- table(survey_data$strata)
small_strata <- names(strata_counts)[strata_counts < 2]

if(length(small_strata) > 0) {
  warning("Some strata have fewer than 2 observations")
}
```

### Missing Data Assessment
```r
# 결측값 패턴 분석
missing_pattern <- survey_data %>%
  summarise_all(~sum(is.na(.))) %>%
  gather(variable, missing_count) %>%
  mutate(missing_percent = missing_count / nrow(survey_data) * 100)

# 가중치별 결측값 분포
weighted_missing <- svymean(~is.na(outcome), design = survey_design)
```

## Technical Implementation

### Dependencies
```r
# 필수 패키지들
required_packages <- c(
  "shiny",           # 웹 애플리케이션
  "survey",          # 복합표본조사 분석
  "sampling",        # 표본설계
  "DT",              # 대화형 테이블  
  "ggplot2",         # 시각화
  "dplyr",           # 데이터 조작
  "mitools",         # 다중대체 분석
  "jstable"          # 통계 테이블 생성
)
```

### Memory Management
- **대용량 데이터**: 스트리밍 처리 기법
- **가중치 계산**: 메모리 효율적 알고리즘
- **재표집**: 병렬 처리 지원
- **캐싱**: 반복 계산 결과 저장

### Performance Optimization
```r
# 병렬 처리 설정
library(parallel)
options(survey.parallel = detectCores() - 1)

# 메모리 효율적 계산
options(survey.lonely.psu = "adjust")  # 단일 PSU 처리
options(survey.adjust.domain.lonely = TRUE)  # 도메인 분석 조정
```

## Export and Reporting

### Results Export
```r
# 복합표본조사 결과 내보내기
export_formats <- list(
  weighted_tables = c("CSV", "Excel", "SAS"),
  survey_objects = c("RDS", "RData"),
  plots = c("PNG", "PDF", "TIFF"),
  reports = c("HTML", "PDF", "Word")
)
```

### Reproducible Analysis
```r
# 분석 재현을 위한 코드 생성
generate_survey_code <- function(design_vars, analysis_vars) {
  code_template <- paste0(
    "# Survey design\n",
    "design <- svydesign(ids = ~", design_vars$psu, 
    ", strata = ~", design_vars$strata,
    ", weights = ~", design_vars$weights, 
    ", data = data)\n\n",
    "# Analysis\n",
    "results <- svymean(~", paste(analysis_vars, collapse = " + "), 
    ", design = design)\n"
  )
  
  return(code_template)
}
```

### Standard Error Reporting
- **Taylor 급수**: 1차 근사 표준오차
- **Jackknife**: 재표집 기반 표준오차  
- **Bootstrap**: 부트스트랩 표준오차
- **BRR**: 균형반복복제 표준오차

## Best Practices Integration

### Survey Analysis Guidelines
- **설계 정보 확인**: PSU, 층화, 가중치 검증
- **모집단 추론**: 표본에서 모집단으로 일반화
- **부분모집단 분석**: domain() 함수 활용
- **결측값 처리**: 설계기반 결측값 처리

### Reporting Standards
- **가중 표본크기**: 실제 및 유효표본크기 보고
- **신뢰구간**: 95% 설계기반 신뢰구간
- **설계효과**: 복합설계 영향 정량화
- **변동계수**: 추정값의 상대적 정밀도

## Version Notes
이 문서는 jsmodule 패키지의 복합표본조사 분석 가젯을 기반으로 작성되었습니다. 최신 버전에서는 추가 표본설계 방법이나 분석 기능이 포함될 수 있습니다.