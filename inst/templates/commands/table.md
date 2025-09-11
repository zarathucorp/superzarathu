# LLM 지시어: 통계 테이블 생성 (jstable 통합)

## 사용자 요청
`{{USER_ARGUMENTS}}`

## AI Assistant Helper
웹검색이 가능한 경우, jstable 패키지의 최신 함수 사용법을 확인하세요:
- GitHub 소스코드: https://github.com/jinseob2kim/jstable/tree/master/R
- 패키지 문서: https://jinseob2kim.github.io/jstable/
- CRAN: https://cran.r-project.org/package=jstable

## 프로젝트 구조
- 입력: `data/processed/` 폴더의 최신 RDS 파일 자동 사용
- 출력: `output/tables/` 폴더에 자동 저장
- 형식: HTML (기본), Word, Excel, LaTeX 자동 선택

## ⚠️ 보안 및 성능 주의사항
- **테이블만 생성**: 원본 데이터 전체를 출력하지 마세요
- **summary() 사용**: 통계 요약만 생성
- **table() 사용**: 빈도표만 생성
- **개인정보 제외**: 환자 ID, 이름 등은 테이블에서 제외
- **집계 데이터만**: 개별 관측치가 아닌 집계된 통계만 표시

## 주요 기능
- Table 1 (기초 통계표) 생성
- 그룹 비교 테이블
- 회귀분석 결과표
- 생존분석 테이블
- jstable 패키지 완전 통합
- 다양한 출력 형식 (HTML, Word, Excel, LaTeX)

## 테이블 타입 자동 선택
```r
# 사용자 요청 AI 분석
detect_table_type <- function(request, data) {
  request_lower <- tolower(request)
  
  # 자연어 이해
  if (grepl("table 1|기초|baseline|특성|기본|환자", request_lower)) {
    return("table1")
  } else if (grepl("회귀|regression|lm|glm|예측|관련", request_lower)) {
    return("regression")
  } else if (grepl("생존|survival|cox|kaplan|위험", request_lower)) {
    return("survival")
  } else if (grepl("비교|차이|그룹|compare", request_lower)) {
    return("comparison")
  } else {
    # 데이터 구조 기반 추천
    return(suggest_table_by_data(data))
  }
}
```

## 패키지 정보
- **jstable**: 의학통계 테이블 생성 패키지
  - GitHub: https://github.com/jinseob2kim/jstable
  - 주요 함수: CreateTableOneJS(), glmshow.rds(), coxshow.rds()
  - 문서: https://jinseob2kim.github.io/jstable/

## 구현 지침

### 📍 스크립트 위치
- **함수 정의**: `scripts/tables/table_basic.R`에 추가
- **출력 함수**: `scripts/tables/table_export.R`에 추가
- **실행 스크립트**: `scripts/analysis/02_statistical.R` 또는 `run_analysis.R`에서 호출

### 1. Table 1 생성 (jstable 사용)
```r
library(jstable)
# 최신 함수 사용법은 https://github.com/jinseob2kim/jstable/tree/master/R 참고

create_table1 <- function(data, group_var = NULL, vars = NULL) {
  if (is.null(vars)) {
    # 자동으로 주요 변수 선택
    vars <- select_key_variables(data)
  }
  
  if (!is.null(group_var)) {
    # 그룹 비교 테이블
    tb1 <- CreateTableOneJS(
      vars = vars,
      strata = group_var,
      data = data,
      includeNA = FALSE,
      test = TRUE,  # p-value 계산
      smd = TRUE    # SMD 계산
    )
  } else {
    # 단일 그룹 테이블
    tb1 <- CreateTableOneJS(
      vars = vars,
      data = data
    )
  }
  
  return(tb1)
}
```

### 2. 회귀분석 테이블
```r
# 선형/로지스틱 회귀
create_regression_table <- function(model) {
  if (class(model)[1] == "lm") {
    tb <- lmshow.rds(model)
  } else if (class(model)[1] == "glm") {
    tb <- glmshow.rds(model)
  }
  
  # 깔끔한 형식으로 변환
  clean_tb <- tb %>%
    mutate(
      Estimate = round(Estimate, 3),
      `95% CI` = paste0("(", round(CI.lower, 3), ", ", round(CI.upper, 3), ")"),
      `P-value` = format.pval(p.value, digits = 3)
    )
  
  return(clean_tb)
}
```

### 3. 생존분석 테이블
```r
# Cox 회귀 테이블
create_survival_table <- function(cox_model) {
  tb <- coxshow.rds(
    cox_model,
    decimal = 2,
    dec.p = 3
  )
  
  # HR과 95% CI 포맷팅
  tb <- tb %>%
    mutate(
      `HR (95% CI)` = paste0(HR, " (", CI, ")"),
      `P-value` = format.pval(p.value)
    )
  
  return(tb)
}
```

### 4. 커스텀 요약 테이블
```r
create_custom_table <- function(data, row_vars, col_vars = NULL, fun = mean) {
  if (is.null(col_vars)) {
    # 단순 요약
    tb <- data %>%
      summarise(across(all_of(row_vars), 
                      list(mean = mean, sd = sd, median = median),
                      na.rm = TRUE))
  } else {
    # 크로스 테이블
    tb <- data %>%
      group_by(!!!syms(col_vars)) %>%
      summarise(across(all_of(row_vars), fun, na.rm = TRUE))
  }
  
  return(tb)
}
```

### 5. 테이블 포맷팅 및 출력
```r
# 출력 형식별 저장
export_table <- function(table, filename, format = "html") {
  switch(format,
    "html" = {
      htmlTable::htmlTable(table) %>%
        writeLines(paste0(filename, ".html"))
    },
    "word" = {
      flextable::flextable(table) %>%
        flextable::save_as_docx(path = paste0(filename, ".docx"))
    },
    "excel" = {
      openxlsx::write.xlsx(table, paste0(filename, ".xlsx"))
    },
    "latex" = {
      knitr::kable(table, format = "latex") %>%
        writeLines(paste0(filename, ".tex"))
    },
    "markdown" = {
      knitr::kable(table, format = "markdown") %>%
        writeLines(paste0(filename, ".md"))
    }
  )
}
```

### 6. 스마트 기능
```r
# 자동 변수 선택
select_key_variables <- function(data) {
  # 숫자형과 범주형 균형있게 선택
  numeric_vars <- names(data)[sapply(data, is.numeric)][1:5]
  factor_vars <- names(data)[sapply(data, is.factor)][1:5]
  return(c(numeric_vars, factor_vars))
}

# p-value 자동 조정
adjust_pvalues <- function(table, method = "bonferroni") {
  if ("p.value" %in% names(table)) {
    table$p.adjusted <- p.adjust(table$p.value, method = method)
  }
  return(table)
}
```

## 사용 예시
```r
# 기본: Table 1 자동 생성
"기초 특성표 만들어줘"

# 그룹 비교
"치료군별로 특성 비교표 만들어줘"

# 회귀분석 결과
"나이와 BMI가 혈압에 미치는 영향 분석표"

# 생존분석 테이블  
"생존분석 결과 테이블로 정리해줘"

# 커스텀 요청
"연령대별 평균 혈압 테이블로 보여줘"
"성별과 흡연 상태별 당뇨 유병률"
```

## 자동 기능
- 데이터에서 최적 변수 자동 선택
- 그룹 변수 자동 탐지
- p-value 자동 계산 및 표시
- 적절한 통계 방법 자동 선택
- Word/PPT용 테이블 자동 포맷팅
