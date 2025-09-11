# adjustedLR Documentation

## Overview

`adjustedLR.R`은 jskm 패키지에서 가중치를 고려한 조정된 로그-순위 검정(adjusted log-rank test)을 수행하는 내부 함수를 제공합니다. 이 함수는 생존분석에서 두 그룹 간의 생존곡선 차이를 검정할 때, 표본가중치나 다른 조정 요인을 고려하여 보다 정확한 통계적 추론을 가능하게 합니다.

## Functions

### `adjusted.LR(times, failures, variable, weights = NULL)`

가중치를 고려한 조정된 로그-순위 검정을 수행합니다.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `times` | numeric | - | 생존시간을 나타내는 수치형 벡터 |
| `failures` | binary | - | 사건 발생 여부를 나타내는 이진 벡터 |
| `variable` | binary | - | 그룹 멤버십을 나타내는 이진 변수 (0과 1) |
| `weights` | numeric | NULL | 각 관측치의 가중치 벡터 (기본값: 모든 관측치에 1) |

#### Returns

다음을 포함하는 리스트:
- **statistic**: 검정 통계량
- **p.value**: 정규분포를 사용하여 계산된 p-value

#### Example

```r
# 기본 사용법 (내부 함수이므로 직접 호출은 권장되지 않음)
# 예시 데이터 생성
set.seed(123)
n <- 100
times <- rexp(n, rate = 0.1)
failures <- rbinom(n, 1, 0.7)
group <- rbinom(n, 1, 0.5)
weights <- runif(n, 0.5, 2)

# 조정된 로그-순위 검정
result <- jskm:::adjusted.LR(
  times = times,
  failures = failures,
  variable = group,
  weights = weights
)

print(result)
# $statistic
# [1] -0.123
# 
# $p.value
# [1] 0.902
```

### `crosssum(y, ind)`

특정 지점에서의 누적합을 계산하는 헬퍼 함수입니다.

#### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `y` | numeric | 누적합을 계산할 수치형 벡터 |
| `ind` | logical | 누적합을 계산할 지점을 나타내는 논리형 벡터 |

#### Returns

지정된 지점에서의 누적합 값

## Statistical Background

### 조정된 로그-순위 검정

로그-순위 검정은 두 개 이상의 그룹 간 생존곡선을 비교하는 표준적인 비모수 검정법입니다. 조정된 로그-순위 검정은 다음과 같은 상황에서 필요합니다:

1. **표본 가중치**: 복잡한 표본설계에서 추출된 데이터
2. **역확률 가중치**: 선택 편향을 보정하기 위한 가중치
3. **성향점수 가중치**: 관찰연구에서 혼동변수 조정

### 검정 통계량

조정된 로그-순위 검정 통계량은 다음과 같이 계산됩니다:

```
U = Σ w_i * (O_i - E_i)
V = Σ w_i^2 * V_i

Z = U / √V
```

여기서:
- `w_i`: 각 관측치의 가중치
- `O_i`: 관찰된 사건 수
- `E_i`: 기대되는 사건 수
- `V_i`: 분산 성분

## Usage Notes

### 내부 함수로서의 사용

`adjusted.LR`은 주로 다른 jskm 함수들에서 내부적으로 사용됩니다:

```r
# svyjskm에서 p-value 계산 시 사용
# jskm에서 가중치가 있는 경우 p-value 계산 시 사용

# 직접 사용은 권장되지 않으며, 대신 다음과 같이 사용:
library(survival)
library(jskm)

# 표준 생존 분석
fit <- survfit(Surv(time, status) ~ group, data = data)
jskm(fit, pval = TRUE)  # 내부적으로 조정된 검정 사용 가능
```

### 입력 데이터 검증

함수는 다음과 같은 입력 검증을 수행합니다:

```r
# 1. 생존시간은 양수여야 함
if(any(times <= 0)) {
  stop("모든 생존시간은 양수여야 합니다")
}

# 2. 사건 지시자는 0 또는 1
if(!all(failures %in% c(0, 1))) {
  stop("failures는 0 또는 1의 값만 가져야 합니다")
}

# 3. 그룹 변수는 이진 변수
if(!all(variable %in% c(0, 1))) {
  stop("variable은 0 또는 1의 값만 가져야 합니다")
}

# 4. 가중치는 양수
if(!is.null(weights) && any(weights <= 0)) {
  stop("모든 가중치는 양수여야 합니다")
}
```

## Mathematical Details

### 로그-순위 검정의 원리

두 그룹의 생존함수가 동일하다는 귀무가설을 검정:

- **H₀**: S₁(t) = S₂(t) for all t
- **H₁**: S₁(t) ≠ S₂(t) for some t

### 가중치 적용

각 사건 시점 t에서:

1. **위험집합 (Risk Set)**: R(t) = {i : T_i ≥ t}
2. **가중 사건 수**: d₁(t) = Σ w_i * δ_i * I(T_i = t, X_i = 1)
3. **가중 기대값**: e₁(t) = n₁(t) * d(t) / n(t)

여기서 가중치는 각 단계에서 적절히 적용됩니다.

### 점근적 분포

표본 크기가 클 때, 검정 통계량 Z는 근사적으로 표준정규분포를 따릅니다:

```
Z ~ N(0, 1) under H₀
```

## Integration with Other Functions

### jskm 함수와의 연동

```r
# jskm에서 가중치가 있는 경우 자동으로 사용
library(jskm)
library(survival)

# 가중치가 있는 데이터
weighted_data <- data.frame(
  time = rexp(100),
  status = rbinom(100, 1, 0.7),
  group = factor(rbinom(100, 1, 0.5)),
  weight = runif(100, 0.5, 2)
)

# survfit 객체 생성 (가중치 적용)
fit <- survfit(Surv(time, status) ~ group, 
               data = weighted_data, 
               weights = weight)

# jskm 플롯 (내부적으로 adjusted.LR 사용 가능)
jskm(fit, pval = TRUE)
```

### svyjskm 함수와의 연동

```r
library(survey)

# Survey design 객체
design <- svydesign(ids = ~1, weights = ~weight, data = survey_data)

# Survey Kaplan-Meier
svy_fit <- svykm(Surv(time, status) ~ group, design = design)

# svyjskm 플롯 (내부적으로 adjusted.LR 사용)
svyjskm(svy_fit, pval = TRUE)
```

## Computational Considerations

### 효율적인 계산

1. **벡터화 연산**: R의 벡터화된 연산을 활용하여 계산 속도 최적화
2. **메모리 관리**: 대용량 데이터에서도 효율적으로 동작
3. **수치적 안정성**: 극단적인 가중치 값에 대한 안정적인 계산

### 계산 복잡도

- **시간 복잡도**: O(n log n) (정렬 때문)
- **공간 복잡도**: O(n)

여기서 n은 관측치의 수입니다.

## Limitations and Considerations

### 사용상 주의사항

1. **가중치의 해석**: 가중치의 의미를 명확히 이해하고 사용
2. **표본 크기**: 작은 표본에서는 점근적 근사가 부정확할 수 있음
3. **비례위험 가정**: 로그-순위 검정은 비례위험을 가정하지 않음

### 대안적 접근법

```r
# 1. 가중 Cox 회귀
library(survival)
cox_weighted <- coxph(Surv(time, status) ~ group, 
                      data = data, 
                      weights = weight)

# 2. Survey 생존분석
library(survey)
design <- svydesign(ids = ~1, weights = ~weight, data = data)
svy_cox <- svycoxph(Surv(time, status) ~ group, design = design)
```

## Dependencies

- 기본 R 함수들 (`cumsum`, `sum`, `pnorm` 등)
- `survival` package (생존분석 객체와의 호환성)

## See Also

- `jskm()` - Kaplan-Meier 플롯 생성
- `svyjskm()` - Survey 가중 Kaplan-Meier 플롯
- `survival::survdiff()` - 표준 로그-순위 검정
- `survey::svylogrank()` - Survey 로그-순위 검정

## References

1. Fleming, T. R., & Harrington, D. P. (2011). *Counting Processes and Survival Analysis*. Wiley.
2. Kalbfleisch, J. D., & Prentice, R. L. (2002). *The Statistical Analysis of Failure Time Data*. Wiley.
3. Lumley, T. (2010). *Complex Surveys: A Guide to Analysis Using R*. Wiley.