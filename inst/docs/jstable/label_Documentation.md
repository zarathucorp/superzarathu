# label Documentation

## Overview

`label.R`은 jstable 패키지에서 변수 레이블과 수준(level) 정보를 추출하고 적용하는 함수들을 제공합니다. 통계분석 결과 테이블에 의미 있는 변수명과 범주명을 표시하여 결과의 가독성과 해석 가능성을 향상시킵니다.

## Functions

### `mk.lev.var(data, vname)`

단일 변수의 레이블과 수준 정보를 추출합니다.

#### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `data` | data.frame | 입력 데이터 |
| `vname` | character | 레이블과 수준을 추출할 변수명 |

#### Returns

변수의 레이블과 수준 정보

#### Example

```r
# 단일 변수의 레이블 추출
iris_sepal_info <- mk.lev.var(iris, "Sepal.Length")
print(iris_sepal_info)

# 팩터 변수의 수준 추출
iris_species_info <- mk.lev.var(iris, "Species")
print(iris_species_info)
```

### `mk.lev(data)`

데이터프레임의 모든 변수에 대한 레이블과 수준 정보를 추출합니다.

#### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `data` | data.frame | 입력 데이터 |

#### Returns

모든 변수의 레이블과 수준 정보를 포함하는 리스트

#### Example

```r
# 전체 데이터의 레이블 정보 추출
iris_labels <- mk.lev(iris)
print(iris_labels)

# 특정 변수들만 확인
lapply(names(iris), function(x) {
  jstable::mk.lev.var(iris, x)
})
```

### `LabelepiDisplay(epiDisplay.obj, label = FALSE, ref)`

epiDisplay 객체에 레이블 정보를 적용합니다.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `epiDisplay.obj` | list | - | epiDisplay 또는 glmshow 객체 |
| `label` | logical | FALSE | 레이블 정보 적용 여부 |
| `ref` | data.frame | - | mk.lev 함수로 생성된 레이블 데이터 |

#### Example

```r
# GLM 분석 후 레이블 적용
fit <- glm(Sepal.Length ~ Sepal.Width + Species, data = iris)
fit_table <- glmshow.display(fit)

# 레이블 데이터 생성
iris_labels <- mk.lev(iris)

# 레이블 적용
labeled_result <- LabelepiDisplay(
  fit_table, 
  label = TRUE, 
  ref = iris_labels
)
print(labeled_result)
```

### `LabeljsTable(obj.table, ref)`

jstable의 분석 결과 테이블에 레이블을 적용합니다.

#### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `obj.table` | data.frame | 레이블을 적용할 테이블 |
| `ref` | data.frame | mk.lev 함수로 생성된 레이블 데이터 |

#### Example

```r
# GEE 분석 후 레이블 적용
library(geepack)
data(dietox)

gee_model <- geeglm(Weight ~ Time + Cu, id = Pig, data = dietox, family = gaussian)
gee_result <- geeglm.display(gee_model)

# 레이블 데이터 생성
dietox_labels <- mk.lev(dietox)

# 테이블에 레이블 적용
labeled_table <- LabeljsTable(gee_result$table, dietox_labels)
```

### Specialized Label Functions

jstable 패키지의 다양한 분석 결과에 특화된 레이블 적용 함수들:

#### `LabeljsRanef(obj.ranef, ref)`
혼합효과모델의 임의효과에 레이블 적용

#### `LabeljsMetric(obj.metric, ref)`
모델 메트릭에 레이블 적용

#### `LabeljsMixed(obj.mixed, ref)`
혼합효과모델 전체 결과에 레이블 적용

#### `LabeljsCox(obj.cox, ref)`
Cox 모델 결과에 레이블 적용

#### `LabeljsGeeglm(obj.geeglm, ref)`
GEE 모델 결과에 레이블 적용

## Usage Notes

### 기본 워크플로

```r
# 1. 데이터 준비
data(mtcars)
mtcars$am <- factor(mtcars$am, labels = c("Automatic", "Manual"))
mtcars$vs <- factor(mtcars$vs, labels = c("V-shaped", "Straight"))

# 2. 레이블 정보 생성
mtcars_labels <- mk.lev(mtcars)

# 3. 분석 수행
model <- glm(mpg ~ am + vs + wt, data = mtcars)
result <- glmshow.display(model)

# 4. 레이블 적용
labeled_result <- LabelepiDisplay(result, label = TRUE, ref = mtcars_labels)
```

### 다양한 분석 유형과 레이블 적용

```r
# 1. Cox 회귀분석
library(survival)
data(lung)

# 레이블 생성
lung_labels <- mk.lev(lung)

# Cox 모델
cox_model <- coxph(Surv(time, status) ~ age + sex + ph.ecog, 
                   data = lung, model = TRUE)
cox_result <- cox2.display(cox_model)

# 레이블 적용
cox_labeled <- LabeljsCox(cox_result, lung_labels)

# 2. GEE 분석
library(geepack)
data(dietox)

# 레이블 생성
dietox_labels <- mk.lev(dietox)

# GEE 모델
gee_model <- geeglm(Weight ~ Time + Cu, id = Pig, data = dietox)
gee_result <- geeglm.display(gee_model)

# 레이블 적용
gee_labeled <- LabeljsGeeglm(gee_result, dietox_labels)

# 3. 혼합효과모델
library(lme4)
lmer_model <- lmer(Weight ~ Time + (1|Pig), data = dietox)
lmer_result <- lmer.display(lmer_model)

# 레이블 적용
lmer_labeled <- LabeljsMixed(lmer_result, dietox_labels)
```

### 사용자 정의 레이블

```r
# 1. 변수 속성으로 레이블 설정
attr(mtcars$mpg, "label") <- "Miles per Gallon"
attr(mtcars$wt, "label") <- "Weight (1000 lbs)"
attr(mtcars$hp, "label") <- "Horsepower"

# 2. 팩터 수준 설정
mtcars$cyl <- factor(mtcars$cyl, 
                     levels = c(4, 6, 8),
                     labels = c("4 cylinders", "6 cylinders", "8 cylinders"))

# 3. 레이블 정보 추출
custom_labels <- mk.lev(mtcars)

# 4. 분석 및 레이블 적용
model <- glm(mpg ~ wt + hp + cyl, data = mtcars)
result <- glmshow.display(model)
labeled_result <- LabelepiDisplay(result, label = TRUE, ref = custom_labels)
```

## Label Data Structure

### mk.lev() 함수의 출력 구조

```r
# 예시 레이블 데이터 구조
iris_labels <- mk.lev(iris)
str(iris_labels)

# 연속형 변수의 경우
# $Sepal.Length
# [1] "Sepal.Length" "Sepal.Length"

# 팩터 변수의 경우  
# $Species
# [1] "Species" "setosa" "versicolor" "virginica"
```

### 레이블 데이터 커스터마이징

```r
# 1. 기본 레이블 생성
labels <- mk.lev(mtcars)

# 2. 수동으로 레이블 수정
labels$mpg <- c("Miles per Gallon", "Miles per Gallon")
labels$wt <- c("Weight", "Weight (1000 lbs)")

# 3. 팩터 레벨 수정
labels$am <- c("Transmission", "Automatic", "Manual")
labels$vs <- c("Engine Shape", "V-shaped", "Straight")

# 4. 수정된 레이블 적용
model <- glm(mpg ~ wt + am + vs, data = mtcars)
result <- glmshow.display(model)
custom_labeled <- LabelepiDisplay(result, label = TRUE, ref = labels)
```

## Integration with Other Functions

### CreateTableOneJS와 연동

```r
# 기술통계 테이블에 레이블 적용
table1 <- CreateTableOneJS(vars = names(mtcars), data = mtcars)
labels <- mk.lev(mtcars)

# 레이블이 적용된 Table 1 생성 (내부적으로 처리)
labeled_table1 <- CreateTableOneJS(
  vars = names(mtcars), 
  data = mtcars,
  labeldata = labels
)
```

### DT 테이블과 연동

```r
library(DT)

# 분석 결과에 레이블 적용 후 DT 테이블로 표시
model <- glm(mpg ~ wt + am, data = mtcars)
result <- glmshow.display(model)
labels <- mk.lev(mtcars)
labeled_result <- LabelepiDisplay(result, label = TRUE, ref = labels)

datatable(
  labeled_result$table,
  options = opt.tbreg("labeled_regression"),
  caption = "Labeled Regression Results"
)
```

## Best Practices

### 레이블 관리 전략

```r
# 1. 분석 시작 전 레이블 설정
prepare_labels <- function(data) {
  # 변수 속성 설정
  attr(data$age, "label") <- "Age (years)"
  attr(data$weight, "label") <- "Weight (kg)"
  attr(data$height, "label") <- "Height (cm)"
  
  # 팩터 레벨 설정
  data$sex <- factor(data$sex, 
                     levels = c(1, 2), 
                     labels = c("Male", "Female"))
  
  return(data)
}

# 2. 일관된 레이블 사용
standardized_data <- prepare_labels(raw_data)
labels <- mk.lev(standardized_data)

# 3. 모든 분석에 동일한 레이블 적용
analyses <- list(
  glm = glmshow.display(glm_model),
  cox = cox2.display(cox_model),
  gee = geeglm.display(gee_model)
)

labeled_analyses <- list(
  glm = LabelepiDisplay(analyses$glm, label = TRUE, ref = labels),
  cox = LabeljsCox(analyses$cox, labels),
  gee = LabeljsGeeglm(analyses$gee, labels)
)
```

### 다국어 지원

```r
# 한국어 레이블 설정
korean_labels <- mk.lev(mtcars)
korean_labels$mpg <- c("연비", "갤런당 마일")
korean_labels$wt <- c("무게", "무게 (1000파운드)")
korean_labels$am <- c("변속기", "자동", "수동")

# 영어 레이블 설정
english_labels <- mk.lev(mtcars)
english_labels$mpg <- c("Fuel Efficiency", "Miles per Gallon")
english_labels$wt <- c("Weight", "Weight (1000 lbs)")
english_labels$am <- c("Transmission", "Automatic", "Manual")
```

## Dependencies

- 기본 R 함수들
- jstable 패키지의 다른 분석 함수들

## Common Issues and Solutions

### 레이블 적용 문제

```r
# 문제: 레이블이 적용되지 않음
# 해결: 올바른 레이블 함수 사용 확인

# GLM 결과 → LabelepiDisplay
glm_result <- LabelepiDisplay(glm_output, label = TRUE, ref = labels)

# GEE 결과 → LabeljsGeeglm  
gee_result <- LabeljsGeeglm(gee_output, labels)

# Cox 결과 → LabeljsCox
cox_result <- LabeljsCox(cox_output, labels)
```

### 레이블 데이터 구조 문제

```r
# 문제: 레이블 데이터 구조가 맞지 않음
# 해결: mk.lev() 함수로 올바른 구조 생성

correct_labels <- mk.lev(data)
str(correct_labels)  # 구조 확인
```

## See Also

- `CreateTableOneJS()` - 기술통계 테이블 생성
- `glmshow.display()` - GLM 결과 표시
- `geeglm.display()` - GEE 결과 표시
- `cox2.display()` - Cox 모델 결과 표시
- `lmer.display()` - 혼합효과모델 결과 표시