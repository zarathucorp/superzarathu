# svyjskm Documentation

## Overview

`svyjskm.R`은 jskm 패키지에서 가중치가 적용된 설문조사 데이터의 Kaplan-Meier 생존곡선을 시각화하는 함수를 제공합니다. survey 패키지의 svykm 객체와 연동하여 복잡한 표본설계를 고려한 출판 품질의 생존곡선 플롯을 생성합니다.

## Functions

### `svyjskm()`

Survey 가중 Kaplan-Meier 생존곡선 플롯을 생성합니다.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `sfit` | svykm | - | survey::svykm 객체 |
| `theme` | character | NULL | 플롯 테마 ("nejm", "jama" 등) |
| `xlabs` | character | "Time-to-event" | X축 레이블 |
| `ylabs` | character | "Survival probability" | Y축 레이블 |
| `xlims` | numeric | NULL | X축 범위 |
| `ylims` | numeric | c(0,1) | Y축 범위 |
| `pval` | logical | FALSE | p-value 표시 여부 |
| `pval.coord` | numeric | NULL | p-value 표시 위치 |
| `pval.testname` | logical | FALSE | 검정 방법명 표시 여부 |
| `ci` | logical | NULL | 신뢰구간 표시 여부 |
| `table` | logical | FALSE | 위험대상자 수 테이블 표시 |
| `marks` | logical | TRUE | 중도절단 표시 여부 |
| `shape` | numeric | 3 | 중도절단 마커 모양 |
| `legend` | logical | TRUE | 범례 표시 여부 |
| `legend.labs` | character | NULL | 범례 레이블 |
| `timeby` | numeric | NULL | X축 눈금 간격 |
| `cumhaz` | logical | FALSE | 누적위험함수 플롯 |
| `cut.landmark` | numeric | NULL | 랜드마크 분석 시점 |
| `linecols` | character | "Set1" | 선 색상 팔레트 |
| `dashed` | logical | FALSE | 점선 사용 여부 |
| `hr` | logical | FALSE | 위험비 표시 여부 |

#### Example

```r
library(survey)
library(survival)
library(jskm)

# 예제 데이터 준비 (PBC 데이터)
data(pbc, package = "survival")
pbc$randomized <- with(pbc, !is.na(trt) & trt > 0)

# 편향 모델 생성 (역확률 가중치용)
biasmodel <- glm(randomized ~ age * edema, data = pbc)
pbc$randprob <- fitted(biasmodel)

# Survey design 객체 생성
dpbc <- svydesign(
  id = ~1, 
  prob = ~randprob, 
  strata = ~edema, 
  data = subset(pbc, randomized)
)

# Survey Kaplan-Meier 적합
svy_fit <- svykm(Surv(time, status > 0) ~ sex, design = dpbc)

# 기본 플롯
svyjskm(svy_fit)

# 고급 옵션을 사용한 플롯
svyjskm(svy_fit,
        table = TRUE,              # 위험대상자 테이블
        pval = TRUE,               # p-value 표시
        pval.testname = TRUE,      # 검정명 표시
        ci = TRUE,                 # 신뢰구간 표시
        theme = "nejm",            # NEJM 스타일
        xlabs = "Time (days)",
        ylabs = "Survival probability",
        legend.labs = c("Male", "Female")
)

# 누적위험함수 플롯
svyjskm(svy_fit,
        cumhaz = TRUE,
        ylabs = "Cumulative hazard",
        pval = TRUE
)
```

## Survey Design Integration

### 복잡한 표본설계 지원

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

svy_strat <- svykm(Surv(time, event) ~ treatment, design = stratified_design)
svyjskm(svy_strat, pval = TRUE, table = TRUE)

# 2. 군집 표본설계
cluster_design <- svydesign(
  ids = ~cluster_id,
  weights = ~weight,
  data = survival_data
)

svy_cluster <- svykm(Surv(time, event) ~ treatment, design = cluster_design)
svyjskm(svy_cluster, theme = "jama")

# 3. 다단계 표본설계
multistage_design <- svydesign(
  ids = ~psu + ssu,
  strata = ~stratum,
  weights = ~weight,
  nest = TRUE,
  data = complex_survey_data
)

svy_multi <- svykm(Surv(time, event) ~ treatment, design = multistage_design)
svyjskm(svy_multi, ci = TRUE, pval = TRUE)
```

### 역확률 가중치 (Inverse Probability Weighting)

```r
# 관찰연구에서 선택 편향 보정
observational_data <- read.csv("observational_study.csv")

# 치료 할당 확률 모델
ps_model <- glm(treatment ~ age + sex + comorbidity + baseline_score,
                data = observational_data,
                family = binomial)

# 역확률 가중치 계산
observational_data$ps <- fitted(ps_model)
observational_data$ipw <- ifelse(observational_data$treatment == 1,
                                1 / observational_data$ps,
                                1 / (1 - observational_data$ps))

# IPW survey design
ipw_design <- svydesign(
  ids = ~1,
  weights = ~ipw,
  data = observational_data
)

# 가중 생존분석
ipw_survival <- svykm(Surv(time, event) ~ treatment, design = ipw_design)

# 플롯 생성
svyjskm(ipw_survival,
        pval = TRUE,
        hr = TRUE,                 # 위험비 표시
        table = TRUE,
        legend.labs = c("Control", "Treatment"),
        xlabs = "Follow-up time (months)"
)
```

## Usage Notes

### 기본 사용 패턴

```r
library(survey)
library(survival)
library(jskm)

# 1. Survey design 생성
design <- svydesign(
  ids = ~hospital_id,
  strata = ~region,
  weights = ~sampling_weight,
  data = multicenter_study
)

# 2. Survey Kaplan-Meier 적합
svy_km <- svykm(Surv(survival_time, death) ~ intervention, 
                design = design)

# 3. 플롯 생성
svyjskm(svy_km,
        table = TRUE,
        pval = TRUE,
        theme = "nejm"
)
```

### 가중치의 중요성

```r
# 비가중 vs 가중 생존곡선 비교
library(ggplot2)
library(gridExtra)

# 비가중 분석
unweighted_km <- survfit(Surv(time, event) ~ treatment, 
                        data = survey_data$variables)
p1 <- jskm(unweighted_km, 
           main = "Unweighted Analysis",
           pval = TRUE)

# 가중 분석  
weighted_km <- svykm(Surv(time, event) ~ treatment, 
                    design = survey_design)
p2 <- svyjskm(weighted_km,
              main = "Survey-weighted Analysis", 
              pval = TRUE)

# 비교 플롯
grid.arrange(p1, p2, ncol = 2)
```

### 하위집단 분석

```r
# 성별 하위집단 분석
male_design <- subset(design, sex == "Male")
female_design <- subset(design, sex == "Female")

male_km <- svykm(Surv(time, event) ~ treatment, design = male_design)
female_km <- svykm(Surv(time, event) ~ treatment, design = female_design)

# 하위집단별 플롯
p_male <- svyjskm(male_km, 
                  main = "Male Patients",
                  pval = TRUE, 
                  table = TRUE)

p_female <- svyjskm(female_km,
                   main = "Female Patients", 
                   pval = TRUE,
                   table = TRUE)

grid.arrange(p_male, p_female, ncol = 2)
```

## Advanced Visualization Options

### 테마 및 스타일링

```r
# NEJM 스타일
svyjskm(svy_fit,
        theme = "nejm",
        table = TRUE,
        pval = TRUE,
        xlabs = "Time (months)",
        ylabs = "Overall survival"
)

# JAMA 스타일
svyjskm(svy_fit,
        theme = "jama", 
        ci = TRUE,
        marks = FALSE,
        linecols = "jco"
)

# 사용자 정의 스타일
svyjskm(svy_fit,
        linecols = c("#E31A1C", "#1F78B4", "#33A02C"),
        dashed = TRUE,
        shape = 4,
        legend.labs = c("Group A", "Group B", "Group C")
)
```

### 색상 팔레트

```r
# 다양한 색상 팔레트
palettes <- c("Set1", "Dark2", "jco", "npg", "aaas", "nejm", "jama")

for(pal in palettes) {
  p <- svyjskm(svy_fit,
               linecols = pal,
               main = paste("Palette:", pal),
               legend = TRUE)
  print(p)
}
```

### 랜드마크 분석

```r
# 2년 랜드마크 분석
landmark_time <- 730  # 2년

# 랜드마크 시점까지 생존한 환자만 포함
landmark_design <- subset(design, time >= landmark_time)

# 랜드마크 분석
landmark_km <- svykm(Surv(time - landmark_time, event) ~ treatment,
                    design = landmark_design)

svyjskm(landmark_km,
        table = TRUE,
        pval = TRUE,
        xlabs = "Time since 2-year landmark (days)",
        main = "2-Year Landmark Analysis"
)
```

## Statistical Considerations

### Survey 가중치의 효과

```r
# 설계 효과 (Design Effect) 평가
library(survey)

# 단순 생존율과 가중 생존율 비교
simple_surv <- survfit(Surv(time, event) ~ 1, data = survey_data$variables)
weighted_surv <- svykm(Surv(time, event) ~ 1, design = survey_design)

# 특정 시점에서의 생존율 비교
time_point <- 365
simple_prob <- summary(simple_surv, times = time_point)$surv
weighted_prob <- summary(weighted_surv, times = time_point)$surv

cat("Simple survival probability:", simple_prob, "\n")
cat("Weighted survival probability:", weighted_prob, "\n")
cat("Difference:", abs(simple_prob - weighted_prob), "\n")
```

### 신뢰구간 계산

```r
# Survey 가중 신뢰구간
svyjskm(svy_fit,
        ci = TRUE,
        pval = TRUE,
        table = TRUE,
        xlabs = "Time (days)",
        ylabs = "Survival probability (95% CI)"
)

# 신뢰구간 없는 플롯 (단순화)
svyjskm(svy_fit,
        ci = FALSE,
        marks = FALSE
)
```

### 검정 통계량

```r
# Survey 로그-순위 검정
# svykm 객체에서 p-value는 자동으로 계산됨
svy_result <- svykm(Surv(time, event) ~ treatment, design = design)

# p-value 추출
p_value <- svylogrank(Surv(time, event) ~ treatment, design = design)

# 플롯에 p-value 표시
svyjskm(svy_result,
        pval = TRUE,
        pval.testname = TRUE,  # "Survey logrank test" 표시
        pval.coord = c(100, 0.2)
)
```

## Output Customization

### 축 및 레이블 설정

```r
# 상세한 축 설정
svyjskm(svy_fit,
        xlims = c(0, 1500),              # X축 범위
        ylims = c(0.3, 1),               # Y축 범위
        xlabs = "Follow-up time (days)",
        ylabs = "Cumulative survival",
        timeby = 300,                    # X축 눈금 간격
        table = TRUE
)

# 백분율 표시
svyjskm(svy_fit,
        ylabs = "Survival (%)",
        # 내부적으로 0-1을 0-100%로 변환
        table = TRUE
)
```

### 위험대상자 테이블

```r
# 위험대상자 테이블 커스터마이징
svyjskm(svy_fit,
        table = TRUE,
        timeby = 365,                    # 연간 간격으로 표시
        xlabs = "Time (years)",
        # 테이블 포맷은 theme에 따라 자동 조정
        theme = "nejm"
)
```

### 범례 설정

```r
# 범례 커스터마이징
svyjskm(svy_fit,
        legend = TRUE,
        legend.labs = c("Standard Care", "Experimental Treatment"),
        # 범례 위치는 ggplot2 테마에 따라 조정
        theme = "jama"
)

# 범례 제거
svyjskm(svy_fit, legend = FALSE)
```

## Integration with Other Functions

### jskm과의 비교

```r
library(gridExtra)

# 일반 jskm (비가중)
regular_fit <- survfit(Surv(time, event) ~ treatment, 
                      data = survey_data$variables)
p1 <- jskm(regular_fit, 
          main = "Standard Kaplan-Meier",
          pval = TRUE,
          table = TRUE)

# survey jskm (가중)
survey_fit <- svykm(Surv(time, event) ~ treatment, 
                   design = survey_design)
p2 <- svyjskm(survey_fit,
             main = "Survey-weighted Kaplan-Meier",
             pval = TRUE, 
             table = TRUE)

# 나란히 비교
grid.arrange(p1, p2, ncol = 2)
```

### ggplot2 확장

```r
# svyjskm도 ggplot 객체를 반환하므로 추가 수정 가능
p <- svyjskm(svy_fit, table = TRUE, pval = TRUE)

# 추가 ggplot 레이어
enhanced_plot <- p +
  ggtitle("Survey-weighted Survival Analysis") +
  theme(plot.title = element_text(hjust = 0.5, size = 14, face = "bold")) +
  annotate("text", x = 500, y = 0.3, 
           label = paste("Design effect:", round(deff, 2)),
           size = 3) +
  labs(caption = "Weighted for complex sampling design")

print(enhanced_plot)
```

## Performance and Optimization

### 대용량 Survey 데이터

```r
# 큰 survey 데이터에서의 최적화
large_design <- svydesign(
  ids = ~cluster_id,
  strata = ~stratum,
  weights = ~weight,
  data = large_survey_data
)

# 효율적인 플롯 옵션
svyjskm_optimized <- function(sfit, ...) {
  svyjskm(sfit,
          marks = FALSE,        # 마커 제거로 성능 향상
          ci = FALSE,           # 신뢰구간 제거
          table = FALSE,        # 테이블 제거
          ...)
}

# 사용
large_km <- svykm(Surv(time, event) ~ treatment, design = large_design)
svyjskm_optimized(large_km, pval = TRUE)
```

### 메모리 관리

```r
# 메모리 효율적인 하위집단 분석
subgroup_analysis <- function(design, subgroup_var, levels) {
  results <- list()
  
  for(level in levels) {
    # 하위집단별로 별도 처리
    sub_design <- subset(design, get(subgroup_var) == level)
    sub_km <- svykm(Surv(time, event) ~ treatment, design = sub_design)
    
    # 플롯 생성 및 저장
    results[[level]] <- svyjskm(sub_km,
                               main = paste(subgroup_var, "=", level),
                               pval = TRUE)
  }
  
  return(results)
}

# 사용 예시
age_plots <- subgroup_analysis(design, "age_group", c("Young", "Middle", "Old"))
```

## Troubleshooting

### 일반적인 문제들

```r
# 1. svykm 객체가 아닌 경우
# Error: 해결법
survey_km <- svykm(Surv(time, event) ~ group, design = design)
svyjskm(survey_km)  # survfit이 아닌 svykm 사용

# 2. Survey design 문제
# 가중치 확인
summary(design)
# 극값 확인
summary(weights(design))

# 3. 수렴 문제
# 작은 하위집단에서 발생할 수 있음
min_size <- 30
large_groups <- names(table(survey_data$group))[table(survey_data$group) >= min_size]
filtered_data <- subset(survey_data, group %in% large_groups)
```

### 성능 최적화

```r
# 느린 렌더링 해결
svyjskm(svy_fit,
        # 단순화 옵션
        marks = FALSE,
        ci = FALSE,
        dashed = FALSE,
        # 해상도 조정
        theme = NULL  # 기본 테마 사용
)
```

## Dependencies

- `survey` package - svykm 객체 및 survey design
- `survival` package - 생존분석 기본 함수
- `ggplot2` package - 플롯 생성
- `gridExtra` package - 테이블 레이아웃
- `RColorBrewer` package - 색상 팔레트

## See Also

- `survey::svykm()` - Survey Kaplan-Meier 추정
- `survey::svylogrank()` - Survey 로그-순위 검정
- `jskm()` - 표준 Kaplan-Meier 플롯
- `survey::svydesign()` - Survey design 객체 생성
- `survival::survfit()` - 표준 Kaplan-Meier 추정

## References

1. Lumley, T. (2010). *Complex Surveys: A Guide to Analysis Using R*. Wiley.
2. Binder, D. A. (1992). Fitting Cox's proportional hazards models from survey data. *Biometrika*, 79(1), 139-147.
3. Lin, D. Y. (2000). On fitting Cox's proportional hazards models to survey data. *Biometrika*, 87(1), 37-47.