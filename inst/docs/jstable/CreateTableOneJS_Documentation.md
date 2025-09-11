# CreateTableOneJS Documentation

## Overview

`CreateTableOneJS`는 jstable 패키지의 핵심 함수로, 기술통계 테이블을 생성하는 향상된 기능을 제공합니다. tableone 패키지의 기능을 확장하여 더 유연한 계층화 및 레이블링 옵션을 지원합니다.

## Functions

### `CreateTableOne2()`

tableone 패키지의 수정된 테이블 생성 함수입니다.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `data` | data.frame | - | 분석할 데이터프레임 |
| `strata` | character | NULL | 그룹화 변수명 |
| `vars` | character | - | 요약할 변수들 |
| `factorVars` | character | NULL | 범주형 변수들 |
| `includeNA` | logical | FALSE | NA를 factor 레벨로 처리 여부 |
| `test` | logical | TRUE | 그룹 간 비교 검정 수행 여부 |
| `testApprox` | character | "chisq" | 근사 검정 방법 |
| `argsApprox` | list | NULL | 근사 검정 인수 |
| `testExact` | character | "fisher" | 정확 검정 방법 |
| `argsExact` | list | NULL | 정확 검정 인수 |
| `testNormal` | character | "oneway.test" | 정규분포 검정 방법 |
| `argsNormal` | list | NULL | 정규분포 검정 인수 |
| `testNonNormal` | character | "kruskal.test" | 비모수 검정 방법 |
| `argsNonNormal` | list | NULL | 비모수 검정 인수 |
| `showAllLevels` | logical | FALSE | 모든 범주형 변수 레벨 표시 |
| `printToggle` | logical | TRUE | 출력 여부 |
| `quote` | logical | FALSE | 따옴표 사용 여부 |
| `smd` | logical | FALSE | 표준화 평균 차이 계산 여부 |
| `Labels` | logical | FALSE | 변수 레이블 사용 여부 |
| `exact` | character | NULL | 정확 검정할 변수들 |
| `nonnormal` | character | NULL | 비모수 검정할 변수들 |
| `catDigits` | integer | 1 | 비율의 소수점 자릿수 |
| `contDigits` | integer | 2 | 연속변수의 소수점 자릿수 |
| `pDigits` | integer | 3 | p-value의 소수점 자릿수 |
| `labeldata` | data.frame | NULL | 레이블 데이터 |
| `psub` | logical | TRUE | 하위 집합 p-value 표시 |

#### Example

```r
library(survival)
CreateTableOne2(vars = names(lung), strata = "sex", data = lung)
```

### `CreateTableOneJS()`

향상된 테이블 생성 함수로, 추가적인 계층화 옵션을 제공합니다.

#### Key Features

- **이중 계층화 지원**: 두 단계의 그룹화 변수 사용 가능
- **유연한 레이블링**: 더 다양한 레이블링 옵션
- **확장된 통계 검정**: 추가적인 정규성 검정 및 쌍별 비교 옵션
- **향상된 포맷팅**: 더 정밀한 출력 제어

#### Example

```r
library(survival)
CreateTableOneJS(vars = names(lung), strata = "sex", data = lung)
```

## Usage Notes

### 기본 사용법

```r
# 단순 기술통계 테이블
CreateTableOneJS(vars = c("age", "ph.ecog", "meal.cal"), 
                 data = lung)

# 그룹별 비교 테이블
CreateTableOneJS(vars = c("age", "ph.ecog", "meal.cal"), 
                 strata = "sex", 
                 data = lung)
```

### 고급 설정

```r
# 범주형 변수 지정 및 검정 옵션
CreateTableOneJS(vars = c("age", "ph.ecog", "meal.cal"), 
                 strata = "sex",
                 factorVars = "ph.ecog",
                 test = TRUE,
                 smd = TRUE,
                 data = lung)
```

## Output

함수는 다음을 포함하는 기술통계 테이블을 생성합니다:

- **연속변수**: 평균 ± 표준편차 또는 중위수 [사분위범위]
- **범주형변수**: 빈도 (백분율)
- **통계검정**: p-values (지정된 경우)
- **효과크기**: 표준화 평균 차이 (smd=TRUE인 경우)

## Dependencies

- `tableone` package
- `survival` package (예제용)

## Additional Notes

### Statistical Tests

#### 범주형 변수
- **기본값**: Chi-square test
- **대안**: Fisher's exact test (소표본)
- **옵션**: `testApprox`, `testExact` 매개변수로 제어

#### 연속변수
- **정규분포**: One-way ANOVA (`oneway.test`)
- **비정규분포**: Kruskal-Wallis test (`kruskal.test`)
- **옵션**: `nonnormal` 매개변수로 비모수 검정 지정

### Formatting Options

```r
# 소수점 자릿수 조정
CreateTableOneJS(vars = c("age", "meal.cal"), 
                 strata = "sex",
                 contDigits = 1,    # 연속변수 1자리
                 catDigits = 2,     # 범주형변수 2자리
                 pDigits = 4,       # p-value 4자리
                 data = lung)
```

### Missing Data Handling

```r
# NA를 별도 범주로 처리
CreateTableOneJS(vars = c("age", "ph.ecog"), 
                 strata = "sex",
                 factorVars = "ph.ecog",
                 includeNA = TRUE,  # NA를 factor level로 포함
                 data = lung)
```

## See Also

- `tableone::CreateTableOne()` - 원본 함수
- `jstable::CreateTableOneJS()` - 향상된 버전
- `survival::lung` - 예제 데이터셋