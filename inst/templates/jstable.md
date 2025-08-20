# LLM 지시어: `jstable` 패키지 활용법

## 목표 (Objective)
`jstable` 패키지를 사용하여 논문 형식의 기술 통계 표(Table 1) 및 회귀 분석 표를 생성한다. 이 리포지토리의 핵심 패턴인 `mk.lev`를 활용한 라벨링을 적용하는 방법을 포함한다.

## 프로세스 (Process)

### 1. 라이브러리 및 데이터 로드
```R
library(tidyverse)
library(jstable)

# 라벨링이 완료된 데이터 또는 라벨링할 데이터 로드
df <- readRDS("<path/to/your/data.rds>")
```

### 2. 라벨 정보 생성 (`mk.lev`)
`jstable`의 모든 기능에 일관되게 적용될 라벨 정보를 생성한다. 이 객체(`out.label`)는 다른 함수에서 참조로 사용된다.
```R
# 데이터프레임의 모든 변수에 대해 라벨 정보를 담은 리스트 생성
out.label <- jstable::mk.lev(df)
```

### 3. 기술 통계 표 (Table 1) 생성
`CreateTableOneJS` 함수를 사용하여 기본적인 기술 통계 표를 만든다.

```R
# Table 1에 포함할 변수 목록 정의
vars_to_include <- c("<변수1>", "<변수2>", "<변수3>")

# 기본 Table 1 생성
table1 <- CreateTableOneJS(
  data = df,
  vars = vars_to_include,
  showAllLevels = TRUE # 모든 범주 수준을 보여줌
)

# 그룹 간 비교 Table 1 생성 (strata 사용)
grouped_table1 <- CreateTableOneJS(
  data = df,
  vars = vars_to_include,
  strata = "<그룹_비교_변수>", # 예: "disease_status"
  showAllLevels = TRUE
)

# Shiny 앱에서는 `jstableOutput()`(UI)과 `renderJstable()`(서버)을 통해 테이블을 출력할 수 있다.
# print(table1) 또는 print(grouped_table1) 로 콘솔에서 확인
```

### 4. 회귀 분석 표 생성
`glm`, `coxph` 등 모델링 결과를 `display` 함수와 `Labeljs` 함수를 통해 표로 변환한다.

```R
# 로지스틱 회귀 모델 생성
model_logistic <- glm(disease_status ~ age + sex + bmi, data = df, family = "binomial")

# 1. 모델 결과를 display 객체로 변환
res_display <- jstable::glm.display(model_logistic, decimal = 2)

# 2. 라벨 정보를 적용하여 최종 테이블 생성
regression_table <- jstable::Labeljs(res_display, ref = out.label)

# Cox 회귀 분석의 경우 `cox.display`와 `LabeljsCox` 사용
# library(survival)
# model_cox <- coxph(Surv(time, event) ~ age + sex, data = df)
# res_cox_display <- jstable::cox.display(model_cox)
# cox_table <- jstable::LabeljsCox(res_cox_display, ref = out.label)

# print(regression_table)
```

## 최종 산출물 (Final Deliverable)
- `CreateTableOneJS`로 생성된 Table 1 객체 (`table1`, `grouped_table1`)
- 회귀 분석 결과와 라벨이 결합된 표 객체 (`regression_table`)
