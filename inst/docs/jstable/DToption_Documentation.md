# DToption Documentation

## Overview

`DToption.R`은 jstable 패키지에서 DT::datatable의 다양한 옵션을 제공하는 함수들을 포함합니다. 이 함수들은 데이터 테이블의 표시, 다운로드, 페이징 등의 옵션을 사용자 친화적으로 설정할 수 있도록 도와줍니다.

## Functions

### `opt.data(fname)`

일반 데이터용 DT::datatable 옵션을 제공합니다.

#### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `fname` | character | 다운로드할 파일명 |

#### Features

- **다운로드 옵션**: Copy, Print, CSV, Excel, PDF
- **페이지 설정**: 기본 10개 행 표시
- **페이지 선택**: 10, 25, All 옵션 제공
- **검색 및 정렬**: 활성화

#### Example

```r
# 기본 사용법
opt.data("mtcars")

# DT::datatable과 함께 사용
library(DT)
datatable(mtcars, options = opt.data("mtcars_data"))
```

### `opt.tb1(fname)`

Table 1 (기술통계 테이블)용 DT::datatable 옵션을 제공합니다.

#### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `fname` | character | 다운로드할 파일명 |

#### Features

- **페이지 설정**: 기본 25개 행 표시
- **정렬 비활성화**: 테이블 구조 유지
- **다운로드 옵션**: Copy, Print, CSV, Excel, PDF
- **검색**: 활성화

#### Example

```r
# CreateTableOneJS 결과와 함께 사용
result <- CreateTableOneJS(vars = names(mtcars), data = mtcars)
datatable(result, options = opt.tb1("table1_results"))
```

### `opt.tbreg(fname)`

회귀분석 결과 테이블용 DT::datatable 옵션을 제공합니다.

#### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `fname` | character | 다운로드할 파일명 |

#### Features

- **무제한 페이징**: 모든 결과를 한 번에 표시
- **정렬 비활성화**: 회귀결과 순서 유지
- **다운로드 옵션**: Copy, Print, CSV, Excel, PDF
- **최적화**: GLM, GEE, lmer/glmer 결과에 특화

#### Example

```r
# 회귀분석 결과와 함께 사용
fit <- glm(mpg ~ wt + hp, data = mtcars)
result <- glmshow.display(fit)
datatable(result, options = opt.tbreg("regression_results"))
```

### `opt.roc(fname)`

ROC 분석 결과용 DT::datatable 옵션을 제공합니다.

#### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `fname` | character | 다운로드할 파일명 |

#### Features

- **정렬 비활성화**: ROC 결과 순서 유지
- **간소화된 다운로드**: 필수 옵션만 제공
- **최적화**: ROC 분석 결과 표시에 특화

#### Example

```r
# ROC 분석 결과와 함께 사용
roc_results <- # ROC 분석 결과
datatable(roc_results, options = opt.roc("roc_analysis"))
```

### `opt.simpledown(fname)`

간단한 다운로드 전용 DT::datatable 옵션을 제공합니다.

#### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `fname` | character | 다운로드할 파일명 |

#### Features

- **필터 없음**: 검색 기능 비활성화
- **페이징 없음**: 모든 데이터를 한 번에 표시
- **정렬 비활성화**: 원본 데이터 순서 유지
- **최소 다운로드 옵션**: 필수 기능만 제공

#### Example

```r
# 단순 데이터 표시 및 다운로드
simple_data <- data.frame(x = 1:5, y = letters[1:5])
datatable(simple_data, options = opt.simpledown("simple_data"))
```

## Usage Notes

### 기본 사용 패턴

```r
library(DT)

# 1. 데이터 탐색용
datatable(iris, options = opt.data("iris_data"))

# 2. 기술통계 테이블용
table1 <- CreateTableOneJS(vars = names(iris), data = iris)
datatable(table1, options = opt.tb1("iris_table1"))

# 3. 회귀분석 결과용
model <- glm(Species == "setosa" ~ ., data = iris, family = "binomial")
result <- glmshow.display(model)
datatable(result, options = opt.tbreg("iris_regression"))
```

### 고급 사용법

```r
# 옵션 커스터마이징
custom_options <- opt.data("my_data")
custom_options$pageLength <- 50  # 페이지 크기 변경
datatable(mtcars, options = custom_options)

# 여러 옵션 조합
combined_options <- c(
  opt.tb1("combined_table"),
  list(scrollX = TRUE, scrollY = "400px")
)
```

## Common Options Included

모든 함수에서 공통으로 포함되는 옵션들:

### Download Buttons
- **Copy**: 클립보드로 복사
- **Print**: 인쇄용 페이지
- **CSV**: CSV 파일 다운로드
- **Excel**: Excel 파일 다운로드
- **PDF**: PDF 파일 다운로드

### DOM Configuration
최적화된 레이아웃으로 버튼과 테이블이 적절히 배치됩니다.

### Language Settings
한국어 환경에 최적화된 텍스트 설정이 포함됩니다.

## Dependencies

- `DT` package
- 해당 분석 함수들 (CreateTableOneJS, glmshow.display 등)

## See Also

- `DT::datatable()` - 기본 데이터테이블 함수
- `CreateTableOneJS()` - 기술통계 테이블 생성
- `glmshow.display()` - 회귀분석 결과 표시
- `geeglm.display()` - GEE 결과 표시
- `lmer.display()` - 혼합효과모델 결과 표시