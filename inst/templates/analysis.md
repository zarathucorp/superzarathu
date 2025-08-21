# LLM 지시어: R 통계 분석 (지능형 통합 버전)

## 목표
데이터를 분석하여 통계 결과를 생성한다. 사용자가 구체적인 분석 방법을 지정하거나, 자연어로 요청하면 적절한 분석을 자동 선택한다.

## 사용자 요청 해석
$ARGUMENTS를 분석하여 적절한 분석 방법을 선택한다:
- "그룹 간 차이를 분석해줘" → Table 1 + p-values
- "회귀 분석 해줘" → Linear/Logistic regression
- "생존 분석 해줘" → Kaplan-Meier + Cox regression
- "연관성 분석" → Correlation matrix

## 핵심 처리 단계

### 1. 환경 설정 및 데이터 로드
```R
library(tidyverse)
library(gtsummary)  # 출판 수준 테이블
library(jstable)    # 임상 통계 테이블
library(survival)   # 생존 분석
library(officer)    # PowerPoint 출력

# 데이터 로드
data <- readRDS("$DATA_FILE")
```

### 2. 지능형 분석 선택
사용자 요청을 해석하여 적절한 분석을 자동 수행한다.

```R
# 요청 파싱 및 분석 유형 결정
request <- tolower("$ARGUMENTS")

# 키워드 기반 분석 유형 자동 감지
analysis_type <- case_when(
  str_detect(request, "table 1|기술통계|요약|그룹 비교") ~ "table1",
  str_detect(request, "회귀|regression|lm|glm") ~ "regression",
  str_detect(request, "생존|survival|kaplan|cox") ~ "survival",
  str_detect(request, "상관|연관|correlation") ~ "correlation",
  str_detect(request, "t-test|t 검정") ~ "ttest",
  str_detect(request, "anova|분산분석") ~ "anova",
  TRUE ~ "table1"  # 기본값
)

cat("선택된 분석:", analysis_type, "\n")
```

### 3. Table 1 자동 생성
```R
if(analysis_type == "table1") {
  # 변수 자동 선택 (수치형 + 범주형 혼합)
  vars_to_include <- data %>%
    select(where(~ is.numeric(.) | is.factor(.))) %>%
    names()
  
  # 그룹 변수 자동 감지 (2-3개 값만 가진 factor)
  group_var <- data %>%
    select(where(~ is.factor(.) & n_distinct(.) %in% c(2,3))) %>%
    names() %>%
    first()
  
  if(!is.null(group_var)) {
    # 그룹 비교 Table 1
    table1 <- data %>%
      select(all_of(vars_to_include)) %>%
      tbl_summary(
        by = all_of(group_var),
        statistic = list(
          all_continuous() ~ "{mean} ± {sd}",
          all_categorical() ~ "{n} ({p}%)"
        ),
        digits = all_continuous() ~ 1
      ) %>%
      add_p(test = list(
        all_continuous() ~ "t.test",
        all_categorical() ~ "chisq.test"
      )) %>%
      add_overall() %>%
      modify_header(label ~ "**Variable**") %>%
      bold_labels()
  } else {
    # 전체 요약 Table 1
    table1 <- data %>%
      tbl_summary(
        statistic = list(
          all_continuous() ~ "{mean} ± {sd}",
          all_categorical() ~ "{n} ({p}%)"
        )
      )
  }
  
  print(table1)
}
```

### 4. 회귀 분석 자동 수행
```R
if(analysis_type == "regression") {
  # 결과 변수 자동 감지 (연속형 vs 이분형)
  outcome_vars <- data %>%
    select(where(is.numeric)) %>%
    names()
  
  binary_vars <- data %>%
    select(where(~ is.factor(.) & n_distinct(.) == 2)) %>%
    names()
  
  # 자동으로 모델 선택
  if(length(outcome_vars) > 0) {
    # 연속형 결과: 선형 회귀
    outcome <- outcome_vars[1]
    predictors <- setdiff(names(data), outcome)
    
    formula_str <- paste(outcome, "~", paste(predictors[1:min(5, length(predictors))], collapse = " + "))
    model <- lm(as.formula(formula_str), data = data)
    
    # 결과 테이블
    reg_table <- model %>%
      tbl_regression() %>%
      add_glance_table(include = c(r.squared, AIC, nobs))
    
  } else if(length(binary_vars) > 0) {
    # 이분형 결과: 로지스틱 회귀
    outcome <- binary_vars[1]
    predictors <- setdiff(names(data), outcome)
    
    formula_str <- paste(outcome, "~", paste(predictors[1:min(5, length(predictors))], collapse = " + "))
    model <- glm(as.formula(formula_str), data = data, family = binomial)
    
    # 결과 테이블 (Odds Ratio)
    reg_table <- model %>%
      tbl_regression(exponentiate = TRUE) %>%
      add_glance_table(include = c(AIC, nobs))
  }
  
  print(reg_table)
}
```

### 5. 생존 분석 자동 수행
```R
if(analysis_type == "survival") {
  library(survival)
  library(survminer)
  
  # 시간 및 이벤트 변수 자동 감지
  time_vars <- names(data)[str_detect(names(data), "time|day|month|year")]
  event_vars <- names(data)[str_detect(names(data), "event|status|death|recur")]
  
  if(length(time_vars) > 0 & length(event_vars) > 0) {
    # Kaplan-Meier 분석
    surv_formula <- as.formula(paste0("Surv(", time_vars[1], ", ", event_vars[1], ") ~ 1"))
    km_fit <- survfit(surv_formula, data = data)
    
    # 생존 곡선 플롯
    ggsurvplot(km_fit, 
               data = data,
               pval = TRUE,
               conf.int = TRUE,
               risk.table = TRUE,
               title = "Kaplan-Meier Survival Curve")
    
    # Cox 회귀 모델
    cox_model <- coxph(surv_formula, data = data)
    cox_table <- tbl_regression(cox_model, exponentiate = TRUE)
    print(cox_table)
  }
}
```

### 6. 결과 저장 및 보고
```R
# PowerPoint로 결과 저장
if(!is.null("$OUTPUT_FILE") & str_ends("$OUTPUT_FILE", ".pptx")) {
  library(officer)
  library(flextable)
  
  # PowerPoint 객체 생성
  ppt <- read_pptx()
  
  # Table 1 슬라이드 추가
  if(exists("table1")) {
    ppt <- ppt %>%
      add_slide(layout = "Title and Content") %>%
      ph_with(value = "Table 1: Baseline Characteristics", location = ph_location_type(type = "title")) %>%
      ph_with(value = as_flex_table(table1), location = ph_location_type(type = "body"))
  }
  
  # 회귀 분석 결과 슬라이드
  if(exists("reg_table")) {
    ppt <- ppt %>%
      add_slide(layout = "Title and Content") %>%
      ph_with(value = "Regression Analysis Results", location = ph_location_type(type = "title")) %>%
      ph_with(value = as_flex_table(reg_table), location = ph_location_type(type = "body"))
  }
  
  print(ppt, target = "$OUTPUT_FILE")
  cat("결과 저장 완료:", "$OUTPUT_FILE", "\n")
}

# 결과 해석
cat("\n=== 분석 완료 ===\n")
cat("수행된 분석:", analysis_type, "\n")
if(exists("model")) {
  cat("p < 0.05인 유의한 변수를 확인하세요.\n")
}
```
