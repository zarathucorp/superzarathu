# LLM 지시어: R 데이터 전처리 수행 (강화 버전)

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
  raw_data <- read_csv("<path/to/your/data.csv>", 
                       locale = locale(encoding = "UTF-8"), # 또는 "CP949"
                       na = c("", "NA", "NULL", "-", "."))
  
  # Excel: 첫 번째 시트 및 헤더 확인
  # raw_data <- read_excel("<path/to/your/data.xlsx>", 
  #                        sheet = 1, 
  #                        skip = 0, # 헤더가 몇 번째 행에 있는지 확인
  #                        na = c("", "NA", "NULL"))
}, error = function(e) {
  cat("데이터 로드 오류:", e$message, "\n")
  cat("인코딩을 CP949로 재시도\n")
  raw_data <- read_csv("<path/to/your/data.csv>", 
                       locale = locale(encoding = "CP949"))
})

# === 방법 2: AWS S3에서 불러오기 (pins 패키지) ===
# board_s3 <- board_s3(bucket = "<bucket-name>", region = "<region>")
# raw_data <- pin_read(board_s3, "<data-name>")

df <- raw_data
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

### 4. 변수명 및 기본 정제
변수명을 정리하고 기본적인 데이터 정제를 수행한다.
```R
df_clean <- df %>%
  # 변수명 정리 (공백, 특수문자 제거)
  clean_names() %>%
  
  # 완전 중복 행 제거
  distinct() %>%
  
  # 빈 행/열 제거
  remove_empty(c("rows", "cols")) %>%
  
  # 환자 ID 중복 확인 및 처리 (임상 데이터 특화)
  {
    if("patient_id" %in% names(.) | "id" %in% names(.)) {
      id_col <- ifelse("patient_id" %in% names(.), "patient_id", "id")
      dup_ids <- sum(duplicated(.[[id_col]], incomparables = NA))
      if(dup_ids > 0) {
        cat("경고: 환자 ID 중복", dup_ids, "건 발견\n")
        cat("중복 처리 방법을 확인하세요\n")
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
