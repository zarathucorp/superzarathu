# LLM 지시어: R 데이터 라벨링 (지능형 통합 버전)

## 목표
데이터의 코드값을 의미있는 라벨로 변환한다. 코드북이 있으면 활용하고, 없으면 데이터 패턴을 분석하여 자동으로 라벨을 생성한다.

## 핵심 처리 단계

### 1. 초기 설정 및 데이터 로드
```R
library(tidyverse)
library(readxl)
library(labelled)  # haven 패키지의 라벨 기능

# 데이터 로드
data <- readRDS("$DATA_FILE")
```

### 2. 코드북 기반 자동 라벨링
코드북이 제공된 경우, 대량의 변수를 효율적으로 처리한다.

**코드북 형식 자동 감지:**
- CSV/Excel 파일 지원
- 다양한 형식(Wide/Long) 자동 인식
- 변수 라벨과 값 라벨 동시 처리

```R
# 코드북 읽기 (형식 자동 감지)
if(!is.null("$CODEBOOK_FILE")) {
  if(str_ends("$CODEBOOK_FILE", ".xlsx")) {
    # Excel: 시트별로 처리
    value_labels <- read_excel("$CODEBOOK_FILE", sheet = "value_labels")
    var_labels <- read_excel("$CODEBOOK_FILE", sheet = "variable_labels")
  } else {
    # CSV: 형식 추론
    codebook <- read_csv("$CODEBOOK_FILE")
    # Wide 형식인지 Long 형식인지 자동 판단
    if("variable" %in% names(codebook) & "value" %in% names(codebook)) {
      value_labels <- codebook
    }
  }
  
  # 효율적인 벡터화 라벨링
  labeled_data <- data %>%
    mutate(across(
      .cols = intersect(names(.), unique(value_labels$variable)),
      .fns = ~ {
        var_labels <- value_labels %>%
          filter(variable == cur_column()) %>%
          select(value, label)
        factor(.x, 
               levels = var_labels$value,
               labels = var_labels$label)
      }
    ))
  
  # 변수 설명 추가 (labelled 패키지)
  if(exists("var_labels")) {
    for(i in seq_len(nrow(var_labels))) {
      var_label(labeled_data[[var_labels$variable[i]]]) <- var_labels$description[i]
    }
  }
}
```

### 3. 지능형 라벨링 (코드북 없는 경우)
코드북이 없어도 데이터 패턴을 분석하여 자동으로 라벨을 제안한다.

```R
# 자동 라벨 추론
auto_label <- function(x, var_name) {
  unique_vals <- sort(unique(x[!is.na(x)]))
  
  # 이진 변수 자동 감지
  if(length(unique_vals) == 2) {
    if(all(unique_vals %in% c(0, 1))) {
      return(factor(x, levels = c(0, 1), labels = c("No", "Yes")))
    }
    if(all(unique_vals %in% c(1, 2))) {
      # 성별 변수 추론
      if(str_detect(tolower(var_name), "sex|gender")) {
        return(factor(x, levels = c(1, 2), labels = c("Male", "Female")))
      }
    }
  }
  
  # Likert 척도 감지 (1-5, 1-7 등)
  if(all(unique_vals %in% 1:7) & length(unique_vals) >= 5) {
    labels <- c("Strongly Disagree", "Disagree", "Neutral", 
                "Agree", "Strongly Agree")[1:length(unique_vals)]
    return(factor(x, levels = unique_vals, labels = labels))
  }
  
  return(x)  # 변환하지 않음
}

# 지능형 라벨링 적용
if(is.null("$CODEBOOK_FILE")) {
  labeled_data <- data %>%
    mutate(across(where(~ n_distinct(.x) <= 10), 
                  ~ auto_label(.x, cur_column())))
}
```

### 4. 연속 변수 구간화 (자동 범주화)
연속형 변수를 의미있는 구간으로 자동 변환한다.

```R
# 의료 데이터 특화 구간화
labeled_data <- labeled_data %>%
  mutate(
    # 나이 그룹 (표준 구간)
    age_group = cut(age, 
                    breaks = c(0, 18, 40, 65, Inf),
                    labels = c("Pediatric", "Young Adult", "Middle-aged", "Senior"),
                    include.lowest = TRUE),
    
    # BMI 카테고리 (WHO 기준)
    bmi_category = cut(bmi,
                       breaks = c(0, 18.5, 25, 30, Inf),
                       labels = c("Underweight", "Normal", "Overweight", "Obese"),
                       include.lowest = TRUE),
    
    # 혈압 단계 (임상 가이드라인)
    bp_stage = case_when(
      is.na(sbp) | is.na(dbp) ~ NA_character_,
      sbp < 120 & dbp < 80 ~ "Normal",
      sbp < 130 & dbp < 80 ~ "Elevated",
      sbp < 140 | dbp < 90 ~ "Stage 1 HTN",
      TRUE ~ "Stage 2 HTN"
    )
  )
```

### 5. 라벨 검증 및 저장
```R
# 라벨링 결과 요약
cat("=== 라벨링 완료 ===\n")
cat("처리된 변수:", sum(sapply(labeled_data, is.factor)), "개\n")

# 라벨 분포 확인 (상위 5개 변수)
labeled_data %>%
  select(where(is.factor)) %>%
  slice_head(n = 5) %>%
  map(table)

# 저장
output_file <- ifelse(!is.null("$OUTPUT_FILE"), 
                      "$OUTPUT_FILE", 
                      "labeled_data.rds")
saveRDS(labeled_data, file = output_file)
cat("저장 완료:", output_file, "\n")
```

## 사용자 입력 처리
$ARGUMENTS를 파싱하여:
- --data 또는 첫 번째 인수: RDS 데이터 파일
- --codebook: 코드북 파일 (Excel/CSV)
- --output: 출력 파일 경로 (기본: labeled_data.rds)
- --auto: 코드북 없이 자동 추론 모드
