#' Get Hardcoded Templates
#'
#' Returns a list of all hardcoded templates for command generation.
#' Each template is a character string containing the full markdown content.
#'
#' @return A named list where names are command names and values are template content
#' @export
get_templates <- function() {
  list(
    preprocess = "# LLM 지시어: R 데이터 전처리 수행 (강화 버전)

## 목표 (Objective)
Raw data(csv, excel 등)를 불러와 분석에 적합한 형태로 정제하고 가공(Clean & Tidy)하여, 다음 분석 단계에 사용할 수 있는 `.rds` 파일을 생성한다. 특히 임상/의료 데이터에서 자주 발생하는 문제점들을 체계적으로 해결한다.

## 프로세스 (Process)

### 1. 라이브러리 로드
데이터 전처리에 필수적인 라이브러리를 로드한다.
```R
# 핵심 데이터 처리 라이브러리
library(tidyverse)
library(readxl)
library(janitor) # 변수명 정리 및 중복 제거
library(lubridate) # 날짜 처리
library(VIM) # 결측치 패턴 분석
library(pins) # AWS S3 연동 (필요시)
```

### 2. 안전한 데이터 불러오기
데이터 불러오기 시 발생할 수 있는 인코딩, 형식 문제를 예방한다.
```R
# === 방법 1: 로컬 파일 불러오기 ===
tryCatch({
  # CSV: 인코딩 자동 감지 또는 명시
  raw_data <- read_csv(\"<path/to/your/data.csv>\", 
                       locale = locale(encoding = \"UTF-8\"), # 또는 \"CP949\"
                       na = c(\"\", \"NA\", \"NULL\", \"-\", \".\"))
  
  # Excel: 첫 번째 시트 및 헤더 확인
  # raw_data <- read_excel(\"<path/to/your/data.xlsx>\", 
  #                        sheet = 1, 
  #                        skip = 0, # 헤더가 몇 번째 행에 있는지 확인
  #                        na = c(\"\", \"NA\", \"NULL\"))
}, error = function(e) {
  cat(\"데이터 로드 오류:\", e$message, \"\\n\")
  cat(\"인코딩을 CP949로 재시도\\n\")
  raw_data <- read_csv(\"<path/to/your/data.csv>\", 
                       locale = locale(encoding = \"CP949\"))
})

# === 방법 2: AWS S3에서 불러오기 (pins 패키지) ===
# board_s3 <- board_s3(bucket = \"<bucket-name>\", region = \"<region>\")
# raw_data <- pin_read(board_s3, \"<data-name>\")

df <- raw_data
```

### 3. 데이터 품질 초기 진단
불러온 데이터의 품질 문제를 사전에 파악한다.
```R
cat(\"=== 데이터 품질 진단 ===\\n\")
cat(\"차원:\", dim(df), \"\\n\")
cat(\"변수 개수:\", ncol(df), \"\\n\")
cat(\"관측치 개수:\", nrow(df), \"\\n\\n\")

# 변수명 문제 진단
cat(\"변수명 문제 확인:\\n\")
problematic_names <- names(df)[grepl(\" |\\\\t|\\\\n|[^a-zA-Z0-9_가-힣]\", names(df))]
if(length(problematic_names) > 0) {
  cat(\"문제 변수명:\", paste(problematic_names, collapse = \", \"), \"\\n\")
}

# 중복 열 확인
duplicated_cols <- names(df)[duplicated(names(df))]
if(length(duplicated_cols) > 0) {
  cat(\"중복된 열 이름:\", paste(duplicated_cols, collapse = \", \"), \"\\n\")
}

# 완전 중복 행 확인
duplicate_rows <- sum(duplicated(df))
cat(\"완전 중복 행 수:\", duplicate_rows, \"\\n\\n\")
```

### 4. 변수명 및 기본 정제
변수명을 정리하고 기본적인 데이터 정제를 수행한다.
```R
df_clean <- df %>%
  # 변수명 정리 (공백, 특수문자 제거)
  clean_names() %>%
  
  # 완전 중복 행 제거
  distinct() %>%
  
  # 빈 행/열 제거
  remove_empty(c(\"rows\", \"cols\")) %>%
  
  # 환자 ID 중복 확인 및 처리 (임상 데이터 특화)
  {
    if(\"patient_id\" %in% names(.) | \"id\" %in% names(.)) {
      id_col <- ifelse(\"patient_id\" %in% names(.), \"patient_id\", \"id\")
      dup_ids <- sum(duplicated(.[[id_col]], incomparables = NA))
      if(dup_ids > 0) {
        cat(\"경고: 환자 ID 중복\", dup_ids, \"건 발견\\n\")
        cat(\"중복 처리 방법을 확인하세요\\n\")
      }
    }
    .
  }
```

### 5. 의료/바이오 데이터 특화 처리
의료 데이터에서 자주 발생하는 문제들을 해결한다.
```R
df_medical <- df_clean %>%
  mutate(
    # === 날짜 변수 표준화 ===
    across(contains(c(\"date\", \"시간\", \"일자\")), 
           ~ case_when(
             str_detect(as.character(.), \"^\\\\d{4}-\\\\d{2}-\\\\d{2}\") ~ ymd(.),
             str_detect(as.character(.), \"^\\\\d{2}/\\\\d{2}/\\\\d{4}\") ~ mdy(.),
             str_detect(as.character(.), \"^\\\\d{4}\\\\d{2}\\\\d{2}\") ~ ymd(.),
             TRUE ~ as.Date(NA)
           )),
    
    # === 검사값 이상치 플래그 (예시: 혈압, BMI) ===
    across(contains(c(\"sbp\", \"수축기\")), 
           ~ ifelse(. < 70 | . > 250, NA, .), 
           .names = \"{.col}_cleaned\"),
    across(contains(c(\"dbp\", \"이완기\")), 
           ~ ifelse(. < 40 | . > 150, NA, .), 
           .names = \"{.col}_cleaned\"),
    across(contains(c(\"bmi\", \"체질량\")), 
           ~ ifelse(. < 10 | . > 60, NA, .), 
           .names = \"{.col}_cleaned\"),
    
    # === 성별 표준화 ===
    across(contains(c(\"sex\", \"gender\", \"성별\")), 
           ~ case_when(
             str_detect(toupper(as.character(.)), \"^[MF1]|남|^MALE\") ~ \"Male\",
             str_detect(toupper(as.character(.)), \"^[F2]|여|^FEMALE\") ~ \"Female\",
             TRUE ~ NA_character_
           ))
  )

# 메모리 관리: 대용량 데이터 처리 시
if(nrow(df_medical) > 50000) {
  cat(\"대용량 데이터 감지 - 청크 단위 처리 권장\\n\")
  cat(\"AI 에이전트에게 데이터를 분할해서 처리하도록 안내\\n\")
}
```

### 6. 데이터 품질 검증 및 요약
처리 결과를 검증하고 요약한다.
```R
cat(\"=== 처리 후 데이터 요약 ===\\n\")
# 기본 통계
print(summary(df_medical))

# 결측치 패턴 시각화 (작은 데이터셋만)
if(nrow(df_medical) <= 1000 & ncol(df_medical) <= 20) {
  VIM::aggr(df_medical, col = c('navyblue','red'), 
            numbers = TRUE, sortVars = TRUE)
}

# 처리 전후 비교
cat(\"처리 전 차원:\", dim(df), \"\\n\")
cat(\"처리 후 차원:\", dim(df_medical), \"\\n\")
cat(\"제거된 행 수:\", nrow(df) - nrow(df_medical), \"\\n\")
```

### 7. 분석 맞춤 변수 생성 및 최종 정제
분석 목적에 맞는 변수를 생성하고 최종 정제한다.
```R
processed_df <- df_medical %>%
  # 기존 로직 유지하되 안전한 처리 추가
  mutate(
    # 나이 그룹 (안전한 처리)
    age_group = case_when(
      is.na(age) ~ NA_character_,
      age < 18 ~ \"Under 18\",
      age >= 18 & age < 40 ~ \"Young Adult\",
      age >= 40 & age < 65 ~ \"Middle-aged\",
      age >= 65 ~ \"Senior\",
      TRUE ~ \"Unknown\"
    ),
    
    # BMI 계산 (안전한 처리)
    bmi = case_when(
      is.na(weight) | is.na(height) ~ NA_real_,
      height <= 0 | weight <= 0 ~ NA_real_,
      TRUE ~ weight / (height/100)^2
    ),
    
    # BMI 카테고리
    bmi_category = case_when(
      is.na(bmi) ~ NA_character_,
      bmi < 18.5 ~ \"Underweight\",
      bmi >= 18.5 & bmi < 25 ~ \"Normal\",
      bmi >= 25 & bmi < 30 ~ \"Overweight\",
      bmi >= 30 ~ \"Obese\",
      TRUE ~ \"Unknown\"
    )
  ) %>%
  
  # 최종 필터링 (신중하게)
  filter(
    # 나이 범위 체크
    !is.na(age) & age >= 0 & age <= 120,
    # 추가 조건들...
  )

# 최종 검증
cat(\"최종 데이터셋 차원:\", dim(processed_df), \"\\n\")
cat(\"주요 변수 결측률:\\n\")
processed_df %>% 
  summarise(across(everything(), ~ round(sum(is.na(.)) / length(.) * 100, 1))) %>%
  pivot_longer(everything(), names_to = \"Variable\", values_to = \"Missing_Percent\") %>%
  filter(Missing_Percent > 0) %>%
  arrange(desc(Missing_Percent)) %>%
  print()
```

### 8. 안전한 저장
처리된 데이터를 안전하게 저장한다.
```R
# 저장 전 최종 확인
cat(\"저장 전 확인:\\n\")
cat(\"- 행 수:\", nrow(processed_df), \"\\n\")
cat(\"- 열 수:\", ncol(processed_df), \"\\n\")
cat(\"- 주요 ID 변수 확인 완료\\n\")

# 백업과 함께 저장
tryCatch({
  # 기존 파일이 있으면 백업
  output_path <- \"<path/to/save/processed_data.rds>\"
  if(file.exists(output_path)) {
    backup_path <- paste0(tools::file_path_sans_ext(output_path), 
                         \"_backup_\", Sys.Date(), \".rds\")
    file.copy(output_path, backup_path)
    cat(\"기존 파일 백업:\", backup_path, \"\\n\")
  }
  
  # 새 파일 저장
  saveRDS(processed_df, file = output_path)
  cat(\"데이터 저장 완료:\", output_path, \"\\n\")
  
  # 메타데이터도 함께 저장
  metadata <- list(
    processed_date = Sys.time(),
    original_rows = nrow(df),
    final_rows = nrow(processed_df),
    variables = ncol(processed_df),
    processing_notes = \"Enhanced preprocessing with medical data considerations\"
  )
  saveRDS(metadata, file = gsub(\"\\\\\\\\.rds$\", \"_metadata.rds\", output_path))
  
}, error = function(e) {
  cat(\"저장 실패:\", e$message, \"\\n\")
})
```

## 최종 산출물 (Final Deliverable)
- 정제된 데이터: `processed_data.rds`
- 메타데이터: `processed_data_metadata.rds`
- 처리 로그: 콘솔 출력된 모든 검증 결과
- 백업 파일: 기존 파일이 있었다면 날짜별 백업

## 주의사항
1. **큰 데이터셋 (>50,000행)**: 청크 단위로 나눠서 처리 요청
2. **복잡한 의료 코드**: 별도 코드북 확인 필요
3. **개인정보**: 민감 정보 마스킹 여부 확인
4. **메모리 사용량**: 처리 중 시스템 리소스 모니터링",
    label = "# LLM 지시어: R 데이터 라벨링 수행

## 목표 (Objective)
전처리된 데이터에 포함된 변수들의 코드 값을 사람이 이해할 수 있는 텍스트 라벨로 변환한다. 코드북(Codebook)을 우선적으로 활용하여 자동화하고, 코드북이 없는 경우 수동으로 라벨링한다.

## 입력 (Input)
- 전처리된 데이터프레임 (`processed_df`)
- (선택) 코드북 파일 (`<path/to/codebook.xlsx>`)

## 프로세스 (Process)

### 1. 라이브러리 로드
```R
library(tidyverse)
library(readxl)
# library(labelled) # 변수 라벨 속성 부여 시 사용
```

### 2. 데이터 불러오기
전처리 단계에서 생성된 `.rds` 파일을 불러온다.
```R
processed_df <- readRDS(\"<path/to/save/processed_data.rds>\")
```

### 3. 라벨링 수행

#### 방법 1: 코드북(Codebook)을 활용한 자동 라벨링 (권장)
코드북 Excel 파일을 읽어와서, 정의된 값(value)과 라벨(label)에 따라 자동으로 `factor` 변환을 수행한다.

**코드북 구조 예시 (`codebook.xlsx`):**
- **value_labels (시트):** `variable` (변수명), `value` (코드값), `label` (설명) 컬럼을 포함
  - 예: 'sex', 1, 'Male'
  - 예: 'sex', 2, 'Female'
- **variable_labels (시트):** `variable` (변수명), `description` (변수 설명) 컬럼을 포함
  - 예: 'sbp', 'Systolic Blood Pressure (mmHg)'

```R
# 코드북 파일 경로
codebook_path <- \"<path/to/codebook.xlsx>\"

# 코드북에서 값 라벨과 변수 라벨 시트 불러오기
value_labels <- read_excel(codebook_path, sheet = \"value_labels\")
# variable_labels <- read_excel(codebook_path, sheet = \"variable_labels\") # 필요한 경우

# 작업할 데이터프레임 복사
labeled_df <- processed_df

# 값 라벨링 자동화
# 코드북에 정의된 모든 변수에 대해 루프 실행
for (var_name in unique(value_labels$variable)) {
  # 해당 변수가 데이터프레임에 존재하는지 확인
  if (var_name %in% names(labeled_df)) {
    # 해당 변수에 대한 라벨 정보 필터링
    labels_for_var <- value_labels %>% filter(variable == var_name)

    # factor로 변환
    labeled_df[[var_name]] <- factor(
      labeled_df[[var_name]],
      levels = labels_for_var$value,
      labels = labels_for_var$label
    )
  }
}
```

#### 방법 2: `factor()` 함수를 이용한 수동 라벨링
코드북이 없을 경우, 코드에 직접 라벨을 명시한다.
```R
# 이 방법은 코드북이 없을 때만 사용
labeled_df <- processed_df %>%
  mutate(
    # 예: 성별 변수 (1: 남성, 2: 여성)
    sex = factor(sex,
                 levels = c(1, 2),
                 labels = c(\"Male\", \"Female\")),

    # 예: 질병 유무 변수 (0: 없음, 1: 있음)
    disease_status = factor(has_disease,
                              levels = c(0, 1),
                              labels = c(\"Control\", \"Case\"))
  )
```

#### 방법 3: `case_when()`을 이용한 조건부 라벨링
연속형 변수를 범주형으로 만들거나 복잡한 조건으로 라벨링할 때 사용한다.
```R
labeled_df <- labeled_df %>% # 이미 다른 라벨링이 적용된 데이터에 추가
  mutate(
    bp_stage = case_when(
      sbp < 120 & dbp < 80 ~ \"Normal\",
      sbp >= 140 | dbp >= 90 ~ \"Hypertension\",
      TRUE ~ \"Pre-hypertension\"
    )
  )
```

## 최종 산출물 (Final Deliverable)
라벨링이 완료된 데이터프레임 `labeled_df`를 지정된 경로 `<path/to/save/labeled_data.rds>`에 `.rds` 파일로 저장한다.
```R
saveRDS(labeled_df, file = \"<path/to/save/labeled_data.rds>\")
```",
    analysis = "# LLM 지시어: R 통계 분석 수행

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
labeled_df <- readRDS(\"<path/to/save/labeled_data.rds>\")
```

### 3. 기술 통계 분석 (Descriptive Statistics)
`gtsummary` 패키지를 사용하여 \"Table 1\"을 생성한다.

#### 3.1. 전체 그룹 요약 테이블
```R
table1_overall <- labeled_df %>%
  # Table 1에 포함할 변수 선택
  select(`<변수1>`, `<변수2>`, `<변수3>`) %>%
  tbl_summary(
    statistic = list(
      all_continuous() ~ \"{mean} ({sd})\", # 연속형 변수: 평균 (표준편차)
      all_categorical() ~ \"{n} ({p}%)\"   # 범주형 변수: N (%)
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
      all_continuous() ~ \"{mean} ({sd})\",
      all_categorical() ~ \"{n} ({p}%)\"
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
                        family = \"binomial\")

# 결과 요약
summary(logistic_model)

# gtsummary로 표 생성 (지수 변환하여 Odds Ratio 표시)
tbl_regression(logistic_model, exponentiate = TRUE)
```

## 최종 산출물 (Final Deliverable)
- 기술 통계 테이블 (`table1_overall`, `table1_grouped`)
- 회귀 분석 결과 테이블 (`tbl_regression` 결과)
- 각 분석 결과에 대한 간단한 해석 (예: p-value < 0.05로 통계적으로 유의함)",
    shiny = "# LLM 지시어: R Shiny 앱 제작

## 목표 (Objective)
분석용 데이터셋을 사용자가 직접 탐색할 수 있는 인터랙티브 웹 대시보드를 제작한다. 사용자는 입력 컨트롤(필터 등)을 통해 데이터를 동적으로 변경하고, 시각화된 결과(플롯, 테이블)를 확인할 수 있다.

## 기본 구조 (`app.R`)
Shiny 앱은 `ui` (User Interface)와 `server` (Server Logic) 두 개의 핵심 컴포넌트로 구성된 단일 스크립트 `app.R`로 작성한다.

```R
# 1. 라이브러리 로드
library(shiny)
library(tidyverse)
library(ggplot2)
library(DT) # 인터랙티브 테이블

# 2. 데이터 로드
# 앱 실행 시 한 번만 로드되도록 server 함수 외부에 위치시킨다.
# 이는 성능 최적화에 매우 중요하다.
final_data <- readRDS(\"<path/to/save/labeled_data.rds>\")

# 3. UI 정의 (사용자가 보는 화면)
ui <- fluidPage(
  # 앱 제목
  titlePanel(\"<앱_제목: 예: 환자 데이터 탐색 대시보드>\"),

  # 사이드바 레이아웃
  sidebarLayout(
    # 입력 컨트롤이 위치하는 사이드바
    sidebarPanel(
      width = 3, # 사이드바 너비 조절
      h4(\"데이터 필터\"),

      # 입력 1: 범주형 변수 필터
      selectInput(
        inputId = \"cat_var_filter\", # server에서 input$cat_var_filter 로 접근
        label = \"<범주형_변수_이름> 선택:\", # 예: \"성별\"
        choices = c(\"전체\", unique(final_data$`<범주형_변수_컬럼명>`)),
        selected = \"전체\"
      ),

      # 입력 2: 연속형 변수 필터
      sliderInput(
        inputId = \"num_var_filter\", # server에서 input$num_var_filter 로 접근
        label = \"<연속형_변수_이름> 범위:\", # 예: \"나이\"
        min = min(final_data$`<연속형_변수_컬럼명>`, na.rm = TRUE),
        max = max(final_data$`<연속형_변수_컬럼명>`, na.rm = TRUE),
        value = c(min, max) # 초기 선택값
      )
    ),

    # 출력 결과가 표시되는 메인 패널
    mainPanel(
      width = 9,
      # 결과를 탭으로 구분하여 표시
      tabsetPanel(
        type = \"tabs\",
        tabPanel(\"플롯\", plotOutput(outputId = \"main_plot\")),
        tabPanel(\"데이터 테이블\", DTOutput(outputId = \"main_table\"))
      )
    )
  )
)

# 4. Server 정의 (앱의 로직)
server <- function(input, output, session) {

  # [핵심] reactive(): 입력값(input)이 바뀔 때마다 이 블록이 자동으로 재실행되어
  # 그 결과를 다른 출력에서 사용할 수 있게 한다.
  filtered_data <- reactive({
    # 필터링할 원본 데이터
    data <- final_data

    # 범주형 변수 필터 로직
    if (input$cat_var_filter != \"전체\") {
      data <- data %>% filter(`<범주형_변수_컬럼명>` == input$cat_var_filter)
    }

    # 연속형 변수 필터 로직
    data <- data %>%
      filter(
        `<연속형_변수_컬럼명>` >= input$num_var_filter[1] &
        `<연속형_변수_컬럼명>` <= input$num_var_filter[2]
      )

    # 필터링된 데이터 반환
    return(data)
  })

  # 출력 1: 플롯 생성
  output$main_plot <- renderPlot({
    # reactive 데이터는 함수처럼 ()를 붙여 호출해야 한다.
    ggplot(filtered_data(), aes(x = `<x축_변수>`, y = `<y축_변수>`, color = `<색상_구분_변수>`)) +
      geom_point(alpha = 0.7) +
      labs(
        title = \"필터링된 데이터 시각화\",
        x = \"<x축_라벨>\",
        y = \"<y축_라벨>\"
      ) +
      theme_minimal(base_size = 14)
  })

  # 출력 2: 데이터 테이블 생성
  output$main_table <- renderDT({
    datatable(
      filtered_data(),
      options = list(pageLength = 10, scrollX = TRUE), # 가로 스크롤 추가
      rownames = FALSE,
      filter = 'top' # 컬럼별 필터 기능 추가
    )
  })
}

# 5. 앱 실행
shinyApp(ui = ui, server = server)
```

## 최종 산출물 (Final Deliverable)
- 위 구조를 따르는 완전한 `app.R` 스크립트 파일.
- 스크립트 내의 모든 `<...>` 플레이스홀더는 실제 데이터의 변수명과 라벨로 채워져야 한다.",
    jstable = "
# LLM 지시어: `jstable` 패키지 활용법

## 목표 (Objective)
`jstable` 패키지를 사용하여 논문 형식의 기술 통계 표(Table 1) 및 회귀 분석 표를 생성한다. 이 리포지토리의 핵심 패턴인 `mk.lev`를 활용한 라벨링을 적용하는 방법을 포함한다.

## 프로세스 (Process)

### 1. 라이브러리 및 데이터 로드
```R
library(tidyverse)
library(jstable)

# 라벨링이 완료된 데이터 또는 라벨링할 데이터 로드
df <- readRDS(\"<path/to/your/data.rds>\")
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
vars_to_include <- c(\"<변수1>\", \"<변수2>\", \"<변수3>\")

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
  strata = \"<그룹_비교_변수>\", # 예: \"disease_status\"
  showAllLevels = TRUE
)

# Shiny 앱에서는 `jstableOutput()`(UI)과 `renderJstable()`(서버)을 통해 테이블을 출력할 수 있다.
# print(table1) 또는 print(grouped_table1) 로 콘솔에서 확인
```

### 4. 회귀 분석 표 생성
`glm`, `coxph` 등 모델링 결과를 `display` 함수와 `Labeljs` 함수를 통해 표로 변환한다.

```R
# 로지스틱 회귀 모델 생성
model_logistic <- glm(disease_status ~ age + sex + bmi, data = df, family = \"binomial\")

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
- 회귀 분석 결과와 라벨이 결합된 표 객체 (`regression_table`)",
    jskm = "
# LLM 지시어: `jskm` 패키지 활용법

## 목표 (Objective)
`survival` 패키지와 `jskm` 패키지를 연동하여 출판 가능한 수준의 Kaplan-Meier 생존 곡선 플롯을 생성한다.

## 프로세스 (Process)

### 1. 라이브러리 및 데이터 로드
`jskm`은 `survival` 패키지에 의존하므로 함께 로드한다.
```R
library(tidyverse)
library(survival)
library(jskm)

df <- readRDS(\"<path/to/your/data.rds>\")
```

### 2. 생존 객체 생성 (`Surv`)
Kaplan-Meier 분석의 핵심인 생존 객체를 `Surv()` 함수로 생성한다. 이 객체는 생존 시간과 이벤트 발생 여부 정보를 담고 있다.
```R
# 생존 객체 생성
# time: 이벤트 발생까지의 시간, event: 이벤트 발생 여부 (1=발생, 0=중도절단)
surv_obj <- Surv(time = df$`<시간_변수>`, event = df$`<이벤트_변수>`)
```

### 3. 생존 곡선 모델 적합 (`survfit`)
생존 객체를 사용하여 Kaplan-Meier 모델을 적합시킨다. 그룹별로 비교하려면 `~` 뒤에 그룹 변수를 지정한다.
```R
# 전체 그룹에 대한 모델
fit_overall <- survfit(surv_obj ~ 1, data = df)

# 특정 그룹(예: 치료법)에 따른 모델
fit_grouped <- survfit(surv_obj ~ `<그룹_변수>`, data = df)
```

### 4. `jskm`으로 플롯 생성
적합된 모델(`fit`)을 `jskm()` 함수에 전달하여 플롯을 생성한다. 다양한 옵션으로 모양을 커스터마이징할 수 있다.

```R
# 기본 Kaplan-Meier 플롯
jskm_plot <- jskm(
  sfit = fit_grouped, # survfit 모델 객체
  data = df,
  table = TRUE, # 플롯 하단에 위험표(at-risk table) 표시
  pval = TRUE, # 그룹 간 p-value (log-rank test) 표시
  ystrataname = \"<그룹_변수_이름>\", # 범례 제목 (예: \"Treatment Group\")
  timeby = 365, # x축 눈금 간격 (예: 365일 = 1년)
  xlab = \"Time in days\",
  ylab = \"Survival Probability\",
  main = \"Kaplan-Meier Survival Curve\"
)

# 플롯 출력
print(jskm_plot)
```

### 5. 플롯 저장 (선택 사항)
`officer`와 `rvg` 패키지를 사용하여 결과를 pptx 파일로 저장할 수 있다.
```R
# library(officer)
# library(rvg)
#
# doc <- read_pptx()
# doc <- add_slide(doc, layout = \"Title and Content\", master = \"Office Theme\")
# doc <- ph_with(doc, value = dml(ggobj = jskm_plot), location = ph_location_fullsize())
# print(doc, target = \"jskm_plot.pptx\")
```

## 최종 산출물 (Final Deliverable)
- `jskm()` 함수로 생성된 Kaplan-Meier 플롯 객체 (`jskm_plot`)",
    jsmodule = "
# LLM 지시어: `jsmodule`을 활용한 모듈식 Shiny 앱 제작

## 목표 (Objective)
`jsmodule` 패키지에서 제공하는 사전 정의된 모듈(UI/Server)을 활용하여, 데이터 탐색, 기술 통계 분석, 생존 분석 기능을 갖춘 확장 가능한 Shiny 앱을 신속하게 구축한다.

## 핵심 개념 (Core Concept)
`jsmodule`은 특정 기능을 수행하는 UI와 서버 로직을 하나의 쌍(예: `data_ui`/`data_server`)으로 묶어 제공한다. 개발자는 각 모듈을 레고 블록처럼 조립하여 전체 앱을 구성한다.

- **`global.R`**: 앱 전역에서 사용할 데이터와 객체(특히, `jstable::mk.lev`로 만든 라벨 정보)를 준비한다.
- **`ui.R` (또는 `app.R`의 `ui`):** 각 모듈의 UI 함수(예: `data_ui(\"data\")`)를 호출하여 화면을 구성한다.
- **`server.R` (또는 `app.R`의 `server`):** `callModule`을 사용하여 각 UI에 해당하는 서버 로직을 실행하고, 데이터와 라벨 정보를 전달한다.

## 전체 앱 구조 예시 (`app.R`)

```R
# 1. 라이브러리 로드
library(shiny)
library(tidyverse)
library(jstable)
library(jskm)
library(jsmodule)
library(DT)

# --- global.R 에 해당하는 부분 ---
# 앱 전역에서 사용할 데이터와 라벨 객체를 미리 로드한다.
# 데이터 로드
data_for_app <- readRDS(\"<path/to/your/data.rds>\")

# jstable을 위한 라벨 정보 생성 (매우 중요)
out.label <- jstable::mk.lev(data_for_app)
# --------------------------------


# 2. UI 정의
ui <- fluidPage(
  navbarPage(
    \"jsmodule 기반 분석 앱\",
    # 첫 번째 탭: 데이터 확인
    tabPanel(\"Data\",
             data_ui(\"data\") # \"data\"라는 ID로 데이터 모듈 UI 호출
    ),
    # 두 번째 탭: Table 1
    tabPanel(\"Table 1\",
             jstable_ui(\"tb1\") # \"tb1\"이라는 ID로 jstable 모듈 UI 호출
    ),
    # 세 번째 탭: Kaplan-Meier Plot
    tabPanel(\"Kaplan-Meier\",
             jskm_ui(\"km\") # \"km\"이라는 ID로 jskm 모듈 UI 호출
    ),
    # 네 번째 탭: Cox Regression
    tabPanel(\"Cox model\",
             cox_ui(\"cox\") # \"cox\"라는 ID로 Cox 모듈 UI 호출
    )
  )
)


# 3. Server 정의
server <- function(input, output, session) {

  # [핵심] 각 모듈에 데이터와 라벨 정보를 전달하고 서버 로직을 실행
  # callModule(모듈서버함수, \"UI에서_사용한_ID\", data = 데이터, data.label = 라벨정보)

  # 데이터 모듈 서버
  # reactive()를 사용하여 데이터가 동적으로 변경될 수 있도록 전달
  data_server(\"data\", data = reactive({data_for_app}), data.label = reactive({out.label}))

  # Table 1 모듈 서버
  # data_server 모듈에서 필터링된 데이터를 받아올 수 있음 (get_data())
  # 여기서는 간단하게 전체 데이터를 사용
  jstable_server(\"tb1\", data = reactive({data_for_app}), data.label = reactive({out.label}))

  # Kaplan-Meier 모듈 서버
  jskm_server(\"km\", data = reactive({data_for_app}), data.label = reactive({out.label}))

  # Cox 모듈 서버
  cox_server(\"cox\", data = reactive({data_for_app}), data.label = reactive({out.label}))

}


# 4. 앱 실행
shinyApp(ui, server)

```

## 최종 산출물 (Final Deliverable)
- `jsmodule`의 모듈들을 활용하여 구성된 완전한 Shiny 앱 `app.R` 스크립트.
- `global.R` (또는 상단)에 데이터 및 라벨 정보(`mk.lev`)가 정의되어 있어야 한다.
- `ui`와 `server`의 모듈 ID가 정확히 일치해야 한다."
  )
}

#' Setup Custom Gemini Commands from Template Files
#'
#' This function creates Gemini command TOML files in the ".gemini/commands"
#' directory using hardcoded templates for data analysis workflows.
#'
#' @details
#' This function uses hardcoded templates from \code{get_templates()} to generate
#' corresponding TOML files for Gemini CLI. Available templates include:
#' preprocess, label, analysis, shiny, jstable, jskm, and jsmodule.
#'
#' @export
#' @examples
#' \dontrun{
#' # This will create .toml files in the .gemini/commands/ directory
#' setup_gemini_commands()
#' }
setup_gemini_commands <- function() {
  # 1. Define directory
  gemini_dir <- file.path(getwd(), ".gemini", "commands")

  # Create .gemini/commands directory if it doesn't exist
  if (!dir.exists(gemini_dir)) {
    dir.create(gemini_dir, recursive = TRUE)
    message("Created directory: ", gemini_dir)
  }

  # 2. Get hardcoded templates
  templates <- get_templates()

  # 3. Create .toml files for each template
  for (command_name in names(templates)) {
    prompt_content <- templates[[command_name]]

    # Extract description from the first line
    first_line <- strsplit(prompt_content, "\n")[[1]][1]
    description <- gsub("# LLM 지시어: ", "", first_line)

    # Construct TOML content
    toml_content <- sprintf(
      'name = "%s"\ndescription = "%s"\nprompt = """\n%s\n"""',
      command_name,
      description,
      prompt_content
    )

    # Write .toml file
    toml_file_path <- file.path(gemini_dir, paste0(command_name, ".toml"))
    con <- file(toml_file_path, "w", encoding = "UTF-8")
    writeLines(toml_content, con)
    close(con)

    message("Created command file: ", toml_file_path)
  }

  message("\nGemini command setup complete from templates.")
}

#' Setup Custom Claude Code Commands from Template Files
#'
#' This function creates Claude Code slash command markdown files in the
#' ".claude/commands" directory using hardcoded templates for data analysis workflows.
#'
#' @details
#' This function uses hardcoded templates from \code{get_templates()} to generate
#' corresponding markdown files for Claude Code slash commands. Available templates
#' include: preprocess, label, analysis, shiny, jstable, jskm, and jsmodule.
#' Claude Code slash commands use markdown format with YAML frontmatter.
#'
#' @export
#' @examples
#' \dontrun{
#' # This will create .md files in the .claude/commands/ directory
#' setup_claude_commands()
#' }
setup_claude_commands <- function() {
  # 1. Define directory
  claude_dir <- file.path(getwd(), ".claude", "commands")

  # Create .claude/commands directory if it doesn't exist
  if (!dir.exists(claude_dir)) {
    dir.create(claude_dir, recursive = TRUE)
    message("Created directory: ", claude_dir)
  }

  # 2. Get hardcoded templates
  templates <- get_templates()

  # 3. Create .md files for each template
  for (command_name in names(templates)) {
    prompt_content <- templates[[command_name]]

    # Extract description from the first line
    first_line <- strsplit(prompt_content, "\n")[[1]][1]
    description <- gsub("# LLM 지시어: ", "", first_line)

    # Construct Claude Code markdown content with frontmatter
    claude_content <- sprintf(
      "---\ndescription: %s\nargument-hint: [options]\n---\n\n%s",
      description,
      prompt_content
    )

    # Write .md file
    claude_file_path <- file.path(claude_dir, paste0(command_name, ".md"))
    con <- file(claude_file_path, "w", encoding = "UTF-8")
    writeLines(claude_content, con)
    close(con)

    message("Created Claude Code command file: ", claude_file_path)
  }

  message("\nClaude Code command setup complete from templates.")
}
