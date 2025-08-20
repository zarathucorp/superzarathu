# LLM 지시어: R 통계 분석 수행

## 목표 (Objective)
라벨링이 완료된 데이터를 사용하여 기술 통계(Table 1) 및 주요 추론 통계(가설 검정, 회귀 분석)를 수행하고, 그 결과를 출판 가능한 수준의 표(Publication-ready table)로 정리한다.

## 입력 (Input)
- 라벨링이 완료된 데이터프레임 (`labeled_df`)

## 프로세스 (Process)

### 1. 라이브러리 로드
```R
library(tidyverse)
# 기술 통계 및 회귀 분석 결과를 깔끔한 표로 만들기 위한 라이브러리
library(gtsummary)
```

### 2. 데이터 불러오기
라벨링 단계에서 생성된 `.rds` 파일을 불러온다.
```R
labeled_df <- readRDS("<path/to/save/labeled_data.rds>")
```

### 3. 기술 통계 분석 (Descriptive Statistics)
`gtsummary` 패키지를 사용하여 "Table 1"을 생성한다.

#### 3.1. 전체 그룹 요약 테이블
```R
table1_overall <- labeled_df %>%
  # Table 1에 포함할 변수 선택
  select(`<변수1>`, `<변수2>`, `<변수3>`) %>%
  tbl_summary(
    statistic = list(
      all_continuous() ~ "{mean} ({sd})", # 연속형 변수: 평균 (표준편차)
      all_categorical() ~ "{n} ({p}%)"   # 범주형 변수: N (%)
    ),
    digits = all_continuous() ~ 1 # 소수점 자리수
  ) %>%
  bold_labels() # 변수명을 굵게

# 테이블 출력
table1_overall
```

#### 3.2. 그룹 간 비교 테이블
`by` 인자를 사용하여 그룹 간 변수를 비교하고 p-value를 계산한다.
```R
table1_grouped <- labeled_df %>%
  select(`<변수1>`, `<변수2>`, `<그룹_비교_변수>`) %>%
  tbl_summary(
    by = `<그룹_비교_변수>`, # 예: disease_status
    statistic = list(
      all_continuous() ~ "{mean} ({sd})",
      all_categorical() ~ "{n} ({p}%)"
    )
  ) %>%
  add_p() %>% # p-value 추가
  add_overall() %>% # 전체 요약 컬럼 추가
  bold_labels()

# 테이블 출력
table1_grouped
```

### 4. 추론 통계 분석 (Inferential Statistics)

#### 4.1. 가설 검정 (Hypothesis Testing)
- **T-test (두 그룹 평균 비교):** `t.test(outcome ~ group, data = df)`
- **ANOVA (세 그룹 이상 평균 비교):** `aov(outcome ~ group, data = df)`
- **Chi-squared Test (범주형 변수 연관성):** `chisq.test(table(df$var1, df$var2))`

#### 4.2. 회귀 분석 (Regression Analysis)
결과를 `tbl_regression`으로 감싸 바로 표로 만든다.

##### 선형 회귀 (Linear Regression)
```R
linear_model <- lm(`<연속형_결과_변수> ~ <독립_변수1> + <독립_변수2>`, data = labeled_df)

# 결과 요약
summary(linear_model)

# gtsummary로 표 생성
tbl_regression(linear_model)
```

##### 로지스틱 회귀 (Logistic Regression)
```R
logistic_model <- glm(`<이분형_결과_변수> ~ <독립_변수1> + <독립_변수2>`,
                        data = labeled_df,
                        family = "binomial")

# 결과 요약
summary(logistic_model)

# gtsummary로 표 생성 (지수 변환하여 Odds Ratio 표시)
tbl_regression(logistic_model, exponentiate = TRUE)
```

## 최종 산출물 (Final Deliverable)
- 기술 통계 테이블 (`table1_overall`, `table1_grouped`)
- 회귀 분석 결과 테이블 (`tbl_regression` 결과)
- 각 분석 결과에 대한 간단한 해석 (예: p-value < 0.05로 통계적으로 유의함)
