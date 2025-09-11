# jsRepeatedGadget Documentation

## Overview
`jsRepeatedGadget.R`은 jsmodule 패키지의 반복측정자료 분석(Repeated Measures Analysis) 전용 Shiny 가젯입니다. 종단연구, 패널연구, 코호트연구 등에서 발생하는 반복측정 데이터에 대한 고급 통계분석을 대화형 인터페이스로 제공합니다.

## Main Functions

### `jsRepeatedGadget(data, nfactor.limit = 20)`
R 데이터셋을 위한 반복측정 분석 전용 가젯을 실행합니다.

**Parameters:**
- `data`: 분석할 반복측정 R 데이터 객체 (data.frame, data.table 등)
- `nfactor.limit`: 범주형 변수의 최대 수준 수 (기본값: 20)

**Returns:**
- 반복측정 데이터 분석에 특화된 Shiny 가젯 인터페이스

### `jsRepeatedAddin()`
RStudio Addins 메뉴에서 실행 가능한 반복측정 분석 도구입니다.

**Returns:**
- RStudio 환경에서 직접 실행되는 가젯 인터페이스

### `jsRepeatedExtAddin(nfactor.limit = 20, max.filesize = 2048)`
외부 데이터 파일을 지원하는 확장 버전 반복측정 분석 도구입니다.

**Parameters:**
- `nfactor.limit`: 범주형 변수의 최대 수준 수 (기본값: 20)
- `max.filesize`: 업로드 가능한 최대 파일 크기 (MB 단위, 기본값: 2048)

**Returns:**
- 파일 업로드 기능이 포함된 반복측정 분석 가젯

## Usage Examples

### Basic Repeated Measures Analysis
```r
library(jsmodule)

# 반복측정 데이터 생성 예시
repeated_data <- data.frame(
  id = rep(1:50, each = 4),
  time = rep(c(0, 3, 6, 12), 50),  # 개월
  treatment = rep(sample(c("A", "B"), 50, replace = TRUE), each = 4),
  age = rep(rnorm(50, 65, 10), each = 4),
  gender = rep(sample(c("M", "F"), 50, replace = TRUE), each = 4),
  measurement = rnorm(200, 100, 15) + rep(rnorm(50, 0, 5), each = 4),
  response = rbinom(200, 1, 0.3)
)

# 반복측정 분석 가젯 실행
jsRepeatedGadget(repeated_data)
```

### RStudio Addins Integration
```r
# RStudio의 Addins 메뉴에서 실행
# "jsmodule - Repeated Measures Analysis" 선택
jsRepeatedAddin()
```

### Clinical Longitudinal Study
```r
library(jsmodule)

# 임상 종단연구 데이터 예시
clinical_longitudinal <- data.frame(
  patient_id = rep(1:100, each = 5),
  visit = rep(c("Baseline", "Month_1", "Month_3", "Month_6", "Month_12"), 100),
  visit_num = rep(c(0, 1, 3, 6, 12), 100),
  treatment_arm = rep(sample(c("Placebo", "Drug_10mg", "Drug_20mg"), 100, replace = TRUE), each = 5),
  age = rep(sample(18:80, 100), each = 5),
  sex = rep(sample(c("Male", "Female"), 100, replace = TRUE), each = 5),
  baseline_severity = rep(rnorm(100, 50, 10), each = 5),
  primary_outcome = rnorm(500, 45, 12),
  adverse_event = rbinom(500, 1, 0.15),
  dropout = c(rep(0, 400), rbinom(100, 1, 0.2))  # 후반부 탈락 증가
)

# 종단 분석 가젯 실행
jsRepeatedGadget(clinical_longitudinal, nfactor.limit = 15)
```

### External Data Import
```r
library(jsmodule)

# 외부 종단 데이터 파일 업로드 지원
jsRepeatedExtAddin(max.filesize = 1500)  # 1.5GB 지원
```

## Interface Components

### Data Structure Setup
- **ID 변수 선택**: 개체 식별자 설정
- **시간 변수 선택**: 측정 시점 변수 지정
- **측정값 변수**: 반복측정 대상 변수들 선택
- **그룹 변수**: 처리군/대조군 등 비교 그룹

### Data Exploration Tools
- **종단 프로파일**: 개체별 시간에 따른 변화 패턴
- **평균 변화 곡선**: 그룹별 평균 변화 추세
- **상관구조 분석**: 시점 간 상관관계 평가
- **결측값 패턴**: 탈락 패턴 및 결측값 분석

### Statistical Analysis Methods
- **GEE (일반화추정방정식)**: 연속형/이진형 결과변수
- **Mixed Effects Models**: 선형/일반화 선형 혼합모델
- **생존분석**: 시간-의존 Cox 회귀
- **반복측정 ANOVA**: 전통적 분산분석

### Visualization Tools
- **스파게티 플롯**: 개체별 변화 궤적
- **평균 프로파일 플롯**: 그룹별 평균 변화
- **상자그림**: 시점별 분포 비교
- **상관 히트맵**: 시점 간 상관구조

## Advanced Analysis Features

### Generalized Estimating Equations (GEE)
```r
# GEE 분석 설정 예시
gee_analysis <- list(
  outcome = "primary_outcome",
  predictors = c("treatment_arm", "visit_num", "age", "sex"),
  id_var = "patient_id",
  time_var = "visit_num",
  correlation_structure = "exchangeable",  # or "independence", "ar1"
  family = "gaussian"  # or "binomial", "poisson"
)

# 가젯에서 대화형 설정 수행
jsRepeatedGadget(clinical_longitudinal)
```

### Missing Data Handling
- **Complete Case Analysis**: 완전한 관측값만 사용
- **Available Case Analysis**: 각 시점별 사용 가능한 모든 데이터
- **Pattern-Mixture Models**: 결측 패턴별 분석
- **Multiple Imputation**: 다중대체법 (선택적)

### Correlation Structure Modeling
```r
# 상관구조 옵션들
correlation_structures <- list(
  independence = "각 관측값이 독립",
  exchangeable = "시점 간 동일한 상관관계",
  ar1 = "1차 자기회귀 구조", 
  unstructured = "제약 없는 상관구조"
)

# 최적 상관구조 선택을 위한 QIC 비교
model_comparison <- data.frame(
  Structure = names(correlation_structures),
  QIC = c(2341.2, 2298.5, 2287.1, 2301.8),
  Best = c("", "", "✓", "")
)
```

### Time-varying Covariates
- **시변 공변량**: 시간에 따라 변하는 예측변수
- **지연 효과**: 이전 시점 값의 영향
- **누적 효과**: 시간 누적 노출 효과
- **상호작용**: 시간과 치료의 상호작용

## Statistical Models

### Linear GEE for Continuous Outcomes
```r
# 연속형 결과변수에 대한 GEE 모델
library(geepack)

gee_continuous <- geeglm(
  primary_outcome ~ treatment_arm + visit_num + age + sex + 
                   treatment_arm:visit_num,  # 상호작용
  data = clinical_longitudinal,
  id = patient_id,
  family = gaussian,
  corstr = "ar1"
)
```

### Logistic GEE for Binary Outcomes
```r
# 이진 결과변수에 대한 GEE 모델
gee_binary <- geeglm(
  adverse_event ~ treatment_arm + visit_num + age + sex,
  data = clinical_longitudinal,
  id = patient_id,
  family = binomial,
  corstr = "exchangeable"
)
```

### Mixed Effects Models
```r
# 선형 혼합효과 모델
library(lme4)

lmm_model <- lmer(
  primary_outcome ~ treatment_arm + visit_num + age + sex +
                   (1 + visit_num | patient_id),  # 랜덤 절편 및 기울기
  data = clinical_longitudinal
)

# 일반화 선형 혼합효과 모델
glmm_model <- glmer(
  adverse_event ~ treatment_arm + visit_num + age + sex +
                 (1 | patient_id),
  data = clinical_longitudinal,
  family = binomial
)
```

## Model Diagnostics and Validation

### Residual Analysis
- **표준화 잔차**: 이상치 및 패턴 탐지
- **QQ 플롯**: 정규성 가정 검증
- **산점도**: 등분산성 검토
- **영향점 진단**: 쿡의 거리, 레버리지

### Model Selection Criteria
```r
# 모델 선택 기준
model_selection <- data.frame(
  Model = c("Independence", "Exchangeable", "AR(1)", "Unstructured"),
  QIC = c(2341.2, 2298.5, 2287.1, 2301.8),
  AIC = c(2339.5, 2296.8, 2285.4, 2308.3),
  BIC = c(2352.1, 2309.4, 2298.0, 2345.7)
)

# 최적 모델: AR(1) 구조가 가장 낮은 QIC/AIC/BIC
```

### Cross-validation
- **Leave-one-out**: 개체별 교차검증
- **Time-series CV**: 시점별 예측 성능
- **K-fold CV**: 반복측정을 고려한 교차검증

## Visualization Components

### Individual Trajectories
```r
# 개체별 변화 궤적 (스파게티 플롯)
library(ggplot2)

spaghetti_plot <- ggplot(clinical_longitudinal, 
                        aes(x = visit_num, y = primary_outcome, 
                            group = patient_id, color = treatment_arm)) +
  geom_line(alpha = 0.3) +
  geom_smooth(aes(group = treatment_arm), method = "loess", se = TRUE) +
  labs(title = "Individual Trajectories by Treatment Arm",
       x = "Visit (Months)", y = "Primary Outcome")
```

### Mean Profile Plots
```r
# 평균 프로파일 플롯
mean_profile <- clinical_longitudinal %>%
  group_by(treatment_arm, visit_num) %>%
  summarise(
    mean_outcome = mean(primary_outcome, na.rm = TRUE),
    se_outcome = sd(primary_outcome, na.rm = TRUE) / sqrt(n()),
    .groups = "drop"
  )

profile_plot <- ggplot(mean_profile, 
                      aes(x = visit_num, y = mean_outcome, 
                          color = treatment_arm, fill = treatment_arm)) +
  geom_line(size = 1) +
  geom_point(size = 3) +
  geom_ribbon(aes(ymin = mean_outcome - 1.96*se_outcome,
                  ymax = mean_outcome + 1.96*se_outcome), 
              alpha = 0.2) +
  labs(title = "Mean Response Profiles with 95% CI",
       x = "Visit (Months)", y = "Mean Primary Outcome")
```

### Correlation Heatmaps
- **피어슨 상관**: 시점 간 선형 상관관계
- **스피어만 상관**: 비모수적 상관관계  
- **ICC**: 클래스 내 상관계수
- **자기상관함수**: 시차별 상관구조

## Technical Implementation

### Dependencies
```r
# 필수 패키지들
required_packages <- c(
  "shiny",           # 웹 애플리케이션
  "geepack",         # GEE 분석
  "lme4",            # 혼합효과 모델
  "nlme",            # 비선형 혼합효과 모델
  "ggplot2",         # 시각화
  "dplyr",           # 데이터 조작
  "tidyr",           # 데이터 변환
  "corrplot",        # 상관관계 시각화
  "plotly"           # 대화형 그래프
)
```

### Performance Optimization
- **데이터 최적화**: 불필요한 변수 제거
- **병렬 처리**: 대용량 데이터 처리
- **메모리 관리**: 효율적 메모리 사용
- **캐싱**: 반복 계산 결과 저장

### Error Handling
```r
# 일반적인 오류 처리
validate_repeated_data <- function(data, id_var, time_var) {
  # ID 변수 존재 확인
  if(!id_var %in% names(data)) {
    stop("ID variable not found in data")
  }
  
  # 시간 변수 존재 확인  
  if(!time_var %in% names(data)) {
    stop("Time variable not found in data")
  }
  
  # 반복측정 구조 확인
  n_obs_per_id <- data %>% 
    group_by(!!sym(id_var)) %>% 
    summarise(n_obs = n()) %>%
    pull(n_obs)
  
  if(all(n_obs_per_id == 1)) {
    warning("Data appears to be cross-sectional, not repeated measures")
  }
}
```

## Quality Control Features

### Data Validation
- **균형성 검사**: 측정 시점별 표본 크기
- **결측 패턴**: 체계적 결측값 탐지
- **이상치 탐지**: 극값 및 영향점 식별
- **일관성 검사**: 논리적 일관성 확인

### Model Diagnostics
```r
# GEE 모델 진단
gee_diagnostics <- function(gee_model) {
  # 잔차 분석
  residuals <- residuals(gee_model)
  fitted_values <- fitted(gee_model)
  
  # QIC 정보
  qic_value <- QIC(gee_model)
  
  # 수렴 정보
  convergence <- gee_model$converged
  
  return(list(
    residuals = residuals,
    fitted = fitted_values,
    qic = qic_value,
    converged = convergence
  ))
}
```

## Export and Reporting

### Results Export
```r
# 결과 내보내기 형식
export_options <- list(
  model_summary = c("HTML", "LaTeX", "Word"),
  coefficient_table = c("CSV", "Excel"),
  plots = c("PNG", "PDF", "SVG"),
  data_processed = c("CSV", "RDS", "SAS", "SPSS")
)
```

### Automated Report Generation
- **모델 요약**: 계수, 표준오차, P-값
- **진단 그래프**: 잔차 플롯, QQ 플롯
- **예측 그래프**: 적합값 vs 관측값
- **해석 가이드**: 결과 해석 방법 설명

## Best Practices Integration

### Study Design Considerations
- **측정 시점**: 충분한 측정 횟수 및 간격
- **표본 크기**: 탈락률을 고려한 표본 설계
- **결측값 최소화**: 추적관찰 전략 수립
- **공변량 수집**: 시변 공변량 계획

### Analysis Guidelines
- **탐색적 분석**: 데이터 구조 이해 우선
- **모델 선택**: 이론적 근거 기반 선택
- **가정 확인**: 모델 가정 검증 필수
- **민감도 분석**: 강건성 확인

## Version Notes
이 문서는 jsmodule 패키지의 반복측정 분석 가젯을 기반으로 작성되었습니다. 최신 버전에서는 추가 모델링 방법이나 시각화 기능이 포함될 수 있습니다.