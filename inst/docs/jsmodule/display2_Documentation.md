# display2 Documentation

## Overview
`display2.R`은 jsmodule 패키지의 회귀분석 결과 표시 유틸리티 모음입니다. 기존 `epiDisplay` 패키지의 함수들을 개선하여 더 유연하고 사용자 친화적인 회귀분석 결과 출력 기능을 제공합니다. 선형회귀와 로지스틱회귀 모델의 결과를 깔끔하고 해석하기 쉬운 형태로 표시합니다.

## Main Functions

### `regress.display2(regress.model, alpha = 0.05, crude = F, crude.p.value = F, decimal = 2, simplified = F)`
개선된 선형회귀 결과 표시 함수입니다.

**Parameters:**
- `regress.model`: 선형회귀 모델 객체 (lm 또는 glm 객체)
- `alpha`: 유의수준 (기본값: 0.05, 95% 신뢰구간)
- `crude`: 단변량 회귀계수 표시 여부 (기본값: FALSE)
- `crude.p.value`: 단변량 P-값 표시 여부 (기본값: FALSE)  
- `decimal`: 소수점 자릿수 (기본값: 2)
- `simplified`: 간소화된 출력 모드 (기본값: FALSE)

**Returns:**
- 포맷된 회귀분석 결과 테이블 (data.frame)

### `logistic.display2(logistic.model, alpha = 0.05, crude = T, crude.p.value = F, decimal = 2, simplified = F)`
개선된 로지스틱회귀 결과 표시 함수입니다.

**Parameters:**
- `logistic.model`: 로지스틱회귀 모델 객체 (family = binomial인 glm 객체)
- `alpha`: 유의수준 (기본값: 0.05, 95% 신뢰구간)
- `crude`: 단변량 오즈비 표시 여부 (기본값: TRUE)
- `crude.p.value`: 단변량 P-값 표시 여부 (기본값: FALSE)
- `decimal`: 소수점 자릿수 (기본값: 2)
- `simplified`: 간소화된 출력 모드 (기본값: FALSE)

**Returns:**
- 포맷된 로지스틱회귀 결과 테이블 (data.frame)

## Usage Examples

### Linear Regression Display
```r
library(jsmodule)

# 기본 선형회귀 모델
linear_model <- lm(mpg ~ cyl + disp + hp + wt, data = mtcars)

# 기본 출력
regress.display2(linear_model)

# 단변량 계수 포함 출력
regress.display2(linear_model, crude = TRUE, crude.p.value = TRUE)

# 높은 정밀도 출력
regress.display2(linear_model, decimal = 4, alpha = 0.01)
```

### Logistic Regression Display
```r
library(jsmodule)

# 로지스틱회귀 모델 (자동변속기 예측)
logistic_model <- glm(am ~ cyl + disp + hp + wt, 
                     data = mtcars, 
                     family = binomial)

# 기본 출력 (단변량 포함)
logistic.display2(logistic_model)

# 다변량만 출력
logistic.display2(logistic_model, crude = FALSE)

# 단변량 P-값 포함 출력
logistic.display2(logistic_model, crude = TRUE, crude.p.value = TRUE, decimal = 3)
```

### Complex Model with Interactions
```r
library(jsmodule)

# 상호작용 항이 포함된 모델
interaction_model <- lm(mpg ~ cyl * disp + hp + wt, data = mtcars)

# 상호작용 결과 표시
regress.display2(interaction_model, crude = TRUE)

# 범주형 변수가 포함된 로지스틱 모델
mtcars$cyl_cat <- factor(mtcars$cyl, levels = c(4, 6, 8), 
                        labels = c("4cyl", "6cyl", "8cyl"))

categorical_model <- glm(am ~ cyl_cat + hp + wt, 
                        data = mtcars, 
                        family = binomial)

logistic.display2(categorical_model, crude = TRUE)
```

### Simplified Output Mode
```r
# 간소화된 출력 (핵심 결과만)
regress.display2(linear_model, simplified = TRUE)
logistic.display2(logistic_model, simplified = TRUE)
```

## Output Format

### Linear Regression Output
```r
# regress.display2() 출력 예시
#                    Coef(95%CI)    P-value   Crude Coef(95%CI)   Crude P
# (Intercept)     37.23(21.05,53.41)  <0.001                              
# cyl             -0.94(-2.35,0.47)    0.181     -2.88(-3.96,-1.80)  <0.001
# disp            -0.01(-0.03,0.00)    0.055     -0.04(-0.05,-0.03)  <0.001  
# hp              -0.02(-0.04,0.01)    0.248     -0.07(-0.09,-0.04)  <0.001
# wt              -3.20(-4.74,-1.65)  <0.001     -5.34(-6.49,-4.20)  <0.001
```

### Logistic Regression Output  
```r
# logistic.display2() 출력 예시
#                    OR(95%CI)         P-value   Crude OR(95%CI)     Crude P
# (Intercept)     45.31(2.14,959.01)   0.013                              
# cyl              0.36(0.13,1.03)     0.057      0.15(0.05,0.48)   0.001
# disp             0.99(0.98,1.01)     0.324      0.98(0.97,0.99)   0.003
# hp               1.01(0.99,1.03)     0.358      0.98(0.96,1.00)   0.078
# wt               0.11(0.02,0.66)     0.017      0.16(0.05,0.48)   0.001
```

## Advanced Features

### Custom Confidence Intervals
```r
# 99% 신뢰구간
regress.display2(linear_model, alpha = 0.01)
logistic.display2(logistic_model, alpha = 0.01)

# 90% 신뢰구간  
regress.display2(linear_model, alpha = 0.10)
logistic.display2(logistic_model, alpha = 0.10)
```

### Precision Control
```r
# 소수점 자릿수 조정
regress.display2(linear_model, decimal = 1)   # 소수 첫째 자리
regress.display2(linear_model, decimal = 4)   # 소수 넷째 자리

# 로지스틱 회귀에서 OR 정밀도
logistic.display2(logistic_model, decimal = 3)
```

### Integration with Other Packages
```r
library(broom)
library(stargazer)

# broom과 함께 사용
tidy_results <- regress.display2(linear_model, crude = TRUE)
augmented_data <- augment(linear_model)

# 결과 비교
standard_tidy <- tidy(linear_model, conf.int = TRUE)
enhanced_display <- regress.display2(linear_model, crude = TRUE)
```

## Model Diagnostics Integration

### Residual Analysis
```r
# 모델 진단과 함께 사용
model <- lm(mpg ~ cyl + disp + hp + wt, data = mtcars)

# 결과 표시
regress.display2(model, crude = TRUE)

# 잔차 분석
par(mfrow = c(2, 2))
plot(model)

# 영향점 탐지
influence_measures <- influence.measures(model)
summary(influence_measures)
```

### Model Comparison
```r
# 여러 모델 비교
model1 <- lm(mpg ~ cyl + disp, data = mtcars)
model2 <- lm(mpg ~ cyl + disp + hp + wt, data = mtcars)

# 각 모델 결과 표시
cat("=== Model 1 ===\n")
print(regress.display2(model1, crude = TRUE))

cat("\n=== Model 2 ===\n")  
print(regress.display2(model2, crude = TRUE))

# AIC 비교
AIC(model1, model2)
```

## Technical Implementation

### Error Handling
```r
# 모델 객체 검증
validate_model <- function(model, type = "linear") {
  if(!inherits(model, c("lm", "glm"))) {
    stop("Model must be lm or glm object")
  }
  
  if(type == "logistic") {
    if(model$family$family != "binomial") {
      stop("Logistic model must have binomial family")
    }
  }
  
  if(is.null(model$coefficients)) {
    stop("Model has no coefficients")
  }
}
```

### Coefficient Processing
```r
# 계수 변환 및 포맷팅
format_coefficient <- function(coef, se, alpha = 0.05, decimal = 2) {
  z_value <- qnorm(1 - alpha/2)
  lower_ci <- coef - z_value * se
  upper_ci <- coef + z_value * se
  
  formatted <- sprintf(
    paste0("%.", decimal, "f(", "%.", decimal, "f,", "%.", decimal, "f)"),
    coef, lower_ci, upper_ci
  )
  
  return(formatted)
}

# 오즈비 변환 (로지스틱 회귀용)
format_odds_ratio <- function(coef, se, alpha = 0.05, decimal = 2) {
  or <- exp(coef)
  z_value <- qnorm(1 - alpha/2)
  lower_ci <- exp(coef - z_value * se)
  upper_ci <- exp(coef + z_value * se)
  
  formatted <- sprintf(
    paste0("%.", decimal, "f(", "%.", decimal, "f,", "%.", decimal, "f)"),
    or, lower_ci, upper_ci
  )
  
  return(formatted)
}
```

### P-value Formatting
```r
# P-값 포맷팅
format_pvalue <- function(p, decimal = 3) {
  if(p < 0.001) {
    return("<0.001")
  } else if(p < 0.01) {
    return(sprintf("%.3f", p))
  } else {
    return(sprintf(paste0("%.", decimal, "f"), p))
  }
}
```

## Output Customization

### Table Styling
```r
# DT 패키지와 함께 사용
library(DT)

results <- regress.display2(linear_model, crude = TRUE)

datatable(results,
  options = list(
    pageLength = 15,
    autoWidth = TRUE,
    scrollX = TRUE
  ),
  caption = "Linear Regression Results"
) %>%
  formatStyle(
    columns = "P.value",
    backgroundColor = styleInterval(0.05, c("lightpink", "white"))
  )
```

### Export Options
```r
# CSV 내보내기
results <- logistic.display2(logistic_model, crude = TRUE)
write.csv(results, "logistic_results.csv", row.names = FALSE)

# Excel 내보내기
library(openxlsx)
wb <- createWorkbook()
addWorksheet(wb, "Logistic Results")
writeData(wb, "Logistic Results", results)
saveWorkbook(wb, "analysis_results.xlsx")
```

## Integration with Statistical Packages

### With jstable Package
```r
library(jstable)

# jstable과 함께 사용
data_label <- mk.lev(mtcars)
model <- glm(am ~ cyl + disp + hp, data = mtcars, family = binomial)

# enhanced display
enhanced_results <- logistic.display2(model, crude = TRUE)

# jstable 결과와 비교
jstable_results <- CreateTableOne(vars = c("cyl", "disp", "hp"), 
                                 strata = "am", data = mtcars)
```

### With broom Package
```r
library(broom)

model <- lm(mpg ~ cyl + disp + hp + wt, data = mtcars)

# broom 기본 출력
tidy_results <- tidy(model, conf.int = TRUE)

# enhanced display 출력
enhanced_results <- regress.display2(model, crude = TRUE)

# 결과 비교
comparison <- data.frame(
  Variable = tidy_results$term,
  Broom_Estimate = tidy_results$estimate,
  Enhanced_Available = rownames(enhanced_results) %in% tidy_results$term
)
```

## Performance Considerations

### Memory Efficiency
- 큰 모델: 필요한 통계량만 계산
- 배치 처리: 여러 모델 동시 처리
- 캐싱: 반복 계산 결과 저장

### Computational Speed
- 벡터화 연산: 루프 최소화
- 효율적 행렬 연산: 선형대수 최적화
- 조건부 계산: 필요시에만 단변량 분석

## Dependencies

### Required Packages
```r
# 필수 의존성
library(stats)          # 기본 통계 함수

# 권장 패키지
library(broom)          # 모델 결과 정리
library(DT)             # 테이블 표시
library(openxlsx)       # Excel 내보내기
```

### Optional Enhancements
```r
# 추가 기능을 위한 패키지
library(stargazer)      # LaTeX/HTML 테이블
library(xtable)         # 테이블 포맷팅
library(knitr)          # Markdown 통합
library(pander)         # Pandoc 테이블
```

## Version Notes
이 문서는 jsmodule 패키지의 회귀분석 표시 유틸리티를 기반으로 작성되었습니다. 기존 `epiDisplay` 패키지의 개선된 버전으로 더 유연하고 현대적인 출력 기능을 제공합니다.