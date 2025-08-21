# LLM 지시어: R 데이터 전처리 및 정제 (통합 버전)

## 목표
원시 데이터를 분석 가능한 형태로 전처리하고, 데이터 품질 문제를 체계적으로 해결한다. 사용자의 자연어 요청을 해석하여 적절한 전처리를 수행한다.

## 사용자 요청 해석
$ARGUMENTS를 분석하여:
- "데이터 정제해줘" → 기본 정제 수행
- "결측치 처리해줘" → NA 값 처리 중점
- "이상치 제거해줘" → Outlier 탐지 및 제거
- "중복 제거해줘" → 중복 행/열 제거

## 핵심 처리 단계

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

### 2. 지능형 데이터 로드
```R
# 자동 파일 형식 및 인코딩 감지
input_file <- "$INPUT_FILE"
file_ext <- tools::file_ext(input_file)

# 인코딩 자동 감지
if(file_ext == "csv") {
  encoding_guess <- guess_encoding(input_file)$encoding[1]
  cat("감지된 인코딩:", encoding_guess, "\n")
  
  df <- read_csv(input_file,
                 locale = locale(encoding = encoding_guess),
                 na = c("", "NA", "NULL", "-", ".", "N/A", "n/a"))
} else if(file_ext %in% c("xlsx", "xls")) {
  df <- read_excel(input_file,
                   sheet = 1,
                   na = c("", "NA", "NULL", "-", "."))
} else {
  stop("지원하지 않는 파일 형식: ", file_ext)
}

cat("데이터 로드 성공:", nrow(df), "rows,", ncol(df), "columns\n")
```

### 3. 데이터 품질 초기 진단
불러온 데이터의 품질 문제를 사전에 파악한다.
```R
cat("=== 데이터 품질 진단 ===\n")
cat("차원:", dim(df), "\n")
cat("변수 개수:", ncol(df), "\n")
cat("관측치 개수:", nrow(df), "\n\n")

# 변수명 문제 진단
cat("변수명 문제 확인:\n")
problematic_names <- names(df)[grepl(" |\\t|\\n|[^a-zA-Z0-9_가-힣]", names(df))]
if(length(problematic_names) > 0) {
  cat("문제 변수명:", paste(problematic_names, collapse = ", "), "\n")
}

# 중복 열 확인
duplicated_cols <- names(df)[duplicated(names(df))]
if(length(duplicated_cols) > 0) {
  cat("중복된 열 이름:", paste(duplicated_cols, collapse = ", "), "\n")
}

# 완전 중복 행 확인
duplicate_rows <- sum(duplicated(df))
cat("완전 중복 행 수:", duplicate_rows, "\n\n")
```

### 4. 통합 데이터 정제
```R
# 사용자 요청 파싱
request <- tolower("$ARGUMENTS")
remove_outliers <- str_detect(request, "outlier|이상치")
handle_na <- str_detect(request, "missing|결측|비어있")
remove_duplicates <- str_detect(request, "duplicate|중복")

# 기본 정제
df_clean <- df %>%
  clean_names() %>%
  remove_empty(c("rows", "cols"))

# 중복 제거 (요청 시 또는 기본)
if(remove_duplicates | TRUE) {
  before_rows <- nrow(df_clean)
  df_clean <- df_clean %>% distinct()
  cat("중복 제거:", before_rows - nrow(df_clean), "행\n")
}

# 결측치 처리
if(handle_na) {
  # NA 처리 전략
  na_cols <- names(df_clean)[colSums(is.na(df_clean)) > 0]
  
  if(!is.null("$NA_COLS")) {
    na_cols <- str_split("$NA_COLS", ",")[[1]]
  }
  
  for(col in na_cols) {
    if(col %in% names(df_clean)) {
      if(is.numeric(df_clean[[col]])) {
        # 수치형: 평균 대체
        df_clean[[col]][is.na(df_clean[[col]])] <- mean(df_clean[[col]], na.rm = TRUE)
      } else {
        # 문자형: 'Missing' 대체
        df_clean[[col]][is.na(df_clean[[col]])] <- "Missing"
      }
    }
  }
  cat("결측치 처리 완료:", length(na_cols), "개 열\n")
}

# 이상치 처리
if(remove_outliers) {
  numeric_cols <- names(df_clean)[sapply(df_clean, is.numeric)]
  
  for(col in numeric_cols) {
    Q1 <- quantile(df_clean[[col]], 0.25, na.rm = TRUE)
    Q3 <- quantile(df_clean[[col]], 0.75, na.rm = TRUE)
    IQR <- Q3 - Q1
    lower <- Q1 - 1.5 * IQR
    upper <- Q3 + 1.5 * IQR
    
    outliers <- df_clean[[col]] < lower | df_clean[[col]] > upper
    df_clean[[col]][outliers] <- NA
    
    cat(col, ": ", sum(outliers, na.rm = TRUE), " 이상치 처리\n")
  }
}
```

### 5. 의료/바이오 데이터 특화 처리
의료 데이터에서 자주 발생하는 문제들을 해결한다.
```R
df_medical <- df_clean %>%
  mutate(
    # === 날짜 변수 표준화 ===
    across(contains(c("date", "시간", "일자")), 
           ~ case_when(
             str_detect(as.character(.), "^\\d{4}-\\d{2}-\\d{2}") ~ ymd(.),
             str_detect(as.character(.), "^\\d{2}/\\d{2}/\\d{4}") ~ mdy(.),
             str_detect(as.character(.), "^\\d{4}\\d{2}\\d{2}") ~ ymd(.),
             TRUE ~ as.Date(NA)
           )),
    
    # === 검사값 이상치 플래그 (예시: 혈압, BMI) ===
    across(contains(c("sbp", "수축기")), 
           ~ ifelse(. < 70 | . > 250, NA, .), 
           .names = "{.col}_cleaned"),
    across(contains(c("dbp", "이완기")), 
           ~ ifelse(. < 40 | . > 150, NA, .), 
           .names = "{.col}_cleaned"),
    across(contains(c("bmi", "체질량")), 
           ~ ifelse(. < 10 | . > 60, NA, .), 
           .names = "{.col}_cleaned"),
    
    # === 성별 표준화 ===
    across(contains(c("sex", "gender", "성별")), 
           ~ case_when(
             str_detect(toupper(as.character(.)), "^[MF1]|남|^MALE") ~ "Male",
             str_detect(toupper(as.character(.)), "^[F2]|여|^FEMALE") ~ "Female",
             TRUE ~ NA_character_
           ))
  )

# 메모리 관리: 대용량 데이터 처리 시
if(nrow(df_medical) > 50000) {
  cat("대용량 데이터 감지 - 청크 단위 처리 권장\n")
  cat("AI 에이전트에게 데이터를 분할해서 처리하도록 안내\n")
}
```

### 6. 데이터 품질 검증 및 요약
처리 결과를 검증하고 요약한다.
```R
cat("=== 처리 후 데이터 요약 ===\n")
# 기본 통계
print(summary(df_medical))

# 결측치 패턴 시각화 (작은 데이터셋만)
if(nrow(df_medical) <= 1000 & ncol(df_medical) <= 20) {
  VIM::aggr(df_medical, col = c('navyblue','red'), 
            numbers = TRUE, sortVars = TRUE)
}

# 처리 전후 비교
cat("처리 전 차원:", dim(df), "\n")
cat("처리 후 차원:", dim(df_medical), "\n")
cat("제거된 행 수:", nrow(df) - nrow(df_medical), "\n")
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
      age < 18 ~ "Under 18",
      age >= 18 & age < 40 ~ "Young Adult",
      age >= 40 & age < 65 ~ "Middle-aged",
      age >= 65 ~ "Senior",
      TRUE ~ "Unknown"
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
      bmi < 18.5 ~ "Underweight",
      bmi >= 18.5 & bmi < 25 ~ "Normal",
      bmi >= 25 & bmi < 30 ~ "Overweight",
      bmi >= 30 ~ "Obese",
      TRUE ~ "Unknown"
    )
  ) %>%
  
  # 최종 필터링 (신중하게)
  filter(
    # 나이 범위 체크
    !is.na(age) & age >= 0 & age <= 120,
    # 추가 조건들...
  )

# 최종 검증
cat("최종 데이터셋 차원:", dim(processed_df), "\n")
cat("주요 변수 결측률:\n")
processed_df %>% 
  summarise(across(everything(), ~ round(sum(is.na(.)) / length(.) * 100, 1))) %>%
  pivot_longer(everything(), names_to = "Variable", values_to = "Missing_Percent") %>%
  filter(Missing_Percent > 0) %>%
  arrange(desc(Missing_Percent)) %>%
  print()
```

### 8. 안전한 저장
처리된 데이터를 안전하게 저장한다.
```R
# 저장 전 최종 확인
cat("저장 전 확인:\n")
cat("- 행 수:", nrow(processed_df), "\n")
cat("- 열 수:", ncol(processed_df), "\n")
cat("- 주요 ID 변수 확인 완료\n")

# 백업과 함께 저장
tryCatch({
  # 기존 파일이 있으면 백업
  output_path <- "<path/to/save/processed_data.rds>"
  if(file.exists(output_path)) {
    backup_path <- paste0(tools::file_path_sans_ext(output_path), 
                         "_backup_", Sys.Date(), ".rds")
    file.copy(output_path, backup_path)
    cat("기존 파일 백업:", backup_path, "\n")
  }
  
  # 새 파일 저장
  saveRDS(processed_df, file = output_path)
  cat("데이터 저장 완료:", output_path, "\n")
  
  # 메타데이터도 함께 저장
  metadata <- list(
    processed_date = Sys.time(),
    original_rows = nrow(df),
    final_rows = nrow(processed_df),
    variables = ncol(processed_df),
    processing_notes = "Enhanced preprocessing with medical data considerations"
  )
  saveRDS(metadata, file = gsub("\\.rds$", "_metadata.rds", output_path))
  
}, error = function(e) {
  cat("저장 실패:", e$message, "\n")
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
4. **메모리 사용량**: 처리 중 시스템 리소스 모니터링
