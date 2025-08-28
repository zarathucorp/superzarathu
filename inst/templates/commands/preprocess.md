# LLM 지시어: R 데이터 전처리 및 정제

## 사용자 요청
`{{USER_ARGUMENTS}}`

## 🤖 AI 작업 방식
**2단계 접근법을 사용하세요:**

### 1단계: 탐색과 판단 (직접 실행)
```bash
# CLI 명령어로 즉시 실행하여 데이터 파악
ls data/raw/
Rscript -e "library(openxlsx); getSheetNames('data.xlsx')"
Rscript -e "dim(read.csv('data.csv', nrows=5))"
```
- 파일 구조 파악
- 데이터 특성 확인
- 문제점 감지 (반복 측정, 헤더 문제, NA 등)

### 2단계: 처리 스크립트 생성 및 실행
```r
# preprocess.R 파일 생성하여 전체 처리 로직 작성
# 사용자가 재실행 가능하도록 완전한 스크립트로
```
- 탐색 결과를 바탕으로 처리 스크립트 작성
- `Rscript preprocess.R`로 실행
- 결과 저장 및 보고

## 프로젝트 구조
- 입력: `data/raw/` 폴더의 CSV/Excel 파일 자동 탐지
- 출력: `data/processed/` 폴더에 RDS 파일 저장  
- 로그: 처리 과정을 사용자에게 실시간 보고

## 주요 기능
- CSV/Excel 파일 읽기 및 처리
- 데이터 타입 자동 변환 및 최적화
- 결측치 처리 및 이상치 탐지
- 인코딩 문제 해결 (UTF-8, CP949)
- 대용량 데이터 청크 처리

## ⚠️ 보안 및 성능 주의사항
- **데이터 전체를 출력하지 마세요** (개인정보 보호, 토큰 절약)
- **head(), glimpse(), str() 사용**: 데이터 구조만 확인
- **summary() 사용**: 통계 요약만 표시
- **dim() 사용**: 데이터 크기만 확인
- **민감 정보 마스킹**: 주민번호, 환자명 등 자동 제거

## 구현 지침

### 🎯 AI 작업 흐름 예시

#### 1️⃣ 탐색 단계 (직접 실행)
```bash
# 파일 확인
ls -la data/raw/

# Excel 시트 구조 파악
Rscript -e "library(openxlsx); sheets <- getSheetNames('data/raw/data.xlsx'); print(sheets)"

# 데이터 크기와 헤더 확인
Rscript -e "df <- read.xlsx('data/raw/data.xlsx', rows=1:5); print(dim(df)); print(names(df)[1:10])"

# 반복 측정 패턴 확인
Rscript -e "names <- names(read.xlsx('data/raw/data.xlsx', rows=1)); sum(grepl('\\\\.1$|\\\\.2$|_V[0-9]', names))"
```

#### 2️⃣ 스크립트 생성 단계
```r
# scripts/preprocess_data.R 생성
library(openxlsx)
library(data.table)

# 데이터 읽기
data <- read.xlsx("data/raw/data.xlsx", skip = 1)

# [탐색 결과를 바탕으로 한 처리 로직]
# - 반복 측정 변수명 정리
# - 날짜 변환
# - NA 처리 등

# 결과 저장
saveRDS(data, "data/processed/data_processed.rds")
```

#### 3️⃣ 실행
```bash
Rscript scripts/preprocess_data.R
```

### 📍 스크립트 위치
- **탐색용 one-liner**: 직접 CLI에서 실행
- **처리 스크립트**: `scripts/preprocess_data.R` 생성
- **재사용 함수**: `scripts/utils/preprocess_functions.R`에 추가

### 1. 데이터 구조 사전 검증 (필수)
```r
# ⚠️ 데이터를 읽기 전에 반드시 구조를 먼저 파악하세요!

# 1. Excel 파일 전체 구조 파악
if (grepl("\\.xlsx?$", input_file)) {
  sheets <- getSheetNames(input_file)
  message("\n📋 Excel 시트 목록:")
  for (i in seq_along(sheets)) {
    # 각 시트의 크기 확인 (헤더 skip 없이)
    temp_data <- read.xlsx(input_file, sheet = i, rows = 1:10)
    message(sprintf("  [%d] %s: %d열 감지", i, sheets[i], ncol(temp_data)))
  }
  
  # 다중 헤더 확인 (첫 5개 행 살펴보기)
  message("\n🔍 헤더 구조 확인 중...")
  header_check <- read.xlsx(input_file, sheet = 1, rows = 1:5, colNames = FALSE)
  
  # skip 파라미터 자동 결정
  skip_rows <- 0
  if (sum(is.na(header_check[1,])) > ncol(header_check)/2) {
    message("⚠️ 첫 행에 빈 셀이 많음. skip = 1 권장")
    skip_rows <- 1
  }
  
  # 실제 데이터 행 찾기
  for (i in 1:nrow(header_check)) {
    if (sum(!is.na(header_check[i,])) > ncol(header_check) * 0.7) {
      message(sprintf("✅ 실제 데이터는 %d행부터 시작하는 것으로 추정", i))
      break
    }
  }
}

# 2. 코드북과 실제 데이터 컬럼 수 비교
codebook_sheet <- which(tolower(sheets) %in% c("codebook", "label", "dictionary"))
if (length(codebook_sheet) > 0) {
  codebook <- read.xlsx(input_file, sheet = codebook_sheet[1])
  actual_data <- read.xlsx(input_file, sheet = 1, rows = 1:2, skip = skip_rows)
  
  col_ratio <- ncol(actual_data) / nrow(codebook)
  if (col_ratio > 1.5) {
    message(sprintf("\n⚠️ 컬럼 수 불일치 경고!"))
    message(sprintf("   코드북 변수: %d개", nrow(codebook)))
    message(sprintf("   실제 컬럼: %d개 (%.1f배)", ncol(actual_data), col_ratio))
    message("   → 반복 측정 구조일 가능성 높음!")
  }
}
```

### 2. 데이터 읽기 및 반복 측정 탐지
```r
# 파일 읽기 (구조 파악 후)
if (grepl("\\.csv$", input_file)) {
  data <- fread(input_file, encoding = "UTF-8")
} else if (grepl("\\.xlsx?$", input_file)) {
  # skip 파라미터 적용하여 읽기
  data <- read.xlsx(input_file, skip = skip_rows)
  
  # 첫 행이 여전히 헤더인지 확인
  if (all(grepl("^X\\d+$", names(data)[1:5]))) {
    message("⚠️ 컬럼명이 X1, X2... 형태. 헤더를 제대로 읽지 못했을 수 있음")
    # 첫 행을 컬럼명으로 사용
    names(data) <- as.character(data[1,])
    data <- data[-1,]
  }
}

# 반복 측정 패턴 자동 탐지
detect_repeated_measures <- function(data) {
  patterns <- list(
    점_숫자 = "\\.\\d+$",           # score.1, score.2
    V_숫자 = "_V\\d+",               # item_V1, item_V2
    Visit = "Visit\\d+",             # Visit1, Visit2
    Week = "Week\\d+",               # Week1, Week2
    Time = "_T\\d+",                 # _T1, _T2
    괄호 = "\\(\\d+\\)"              # item(1), item(2)
  )
  
  detected <- character()
  for (pattern_name in names(patterns)) {
    if (any(grepl(patterns[[pattern_name]], names(data)))) {
      detected <- c(detected, pattern_name)
    }
  }
  
  if (length(detected) > 0) {
    message("\n✅ 반복 측정 패턴 감지:", paste(detected, collapse = ", "))
    
    # 임상시험 데이터 확인 질문
    message("\n❓ 다음 사항을 확인해주세요:")
    message("  □ 임상시험 데이터입니까?")
    message("  □ 같은 환자를 여러 시점에서 측정했습니까?")
    message("  □ Wide format (옆으로 늘어선) 구조입니까?")
    message("\n하나라도 '예'라면 변수명 재구조화가 필요합니다.")
    
    return(TRUE)
  }
  return(FALSE)
}

# 패턴 탐지 실행
has_repeated <- detect_repeated_measures(data)

# 데이터 크기 정보
message(sprintf("\n📊 데이터 크기: %d행 × %d열", nrow(data), ncol(data)))
if (ncol(data) > 50) {
  message("   → 컬럼이 많음. 반복 측정 구조 확인 필요!")
}
```

### 3. 임상시험 데이터 특수 처리
```r
# 🏥 임상시험/반복 측정 데이터 구조화
if (has_repeated) {
  message("\n📊 반복 측정 구조 처리 중...")
  
  # Wide format 변수명 패턴화 예시
  # 원본: score, score.1, score.2 또는 변수명 반복
  # 목표: score_V1, score_V2, score_V3
  
  # 컬럼명 분석
  col_analysis <- data.frame(
    index = 1:ncol(data),
    original = names(data),
    stringsAsFactors = FALSE
  )
  
  # 기본 변수명 추출 (숫자/패턴 제거)
  col_analysis$base_name <- gsub("\\.\\d+$", "", col_analysis$original)
  col_analysis$base_name <- gsub("_V\\d+$", "", col_analysis$base_name)
  col_analysis$base_name <- gsub("\\(\\d+\\)$", "", col_analysis$base_name)
  
  # 중복 변수명 찾기
  duplicated_vars <- names(table(col_analysis$base_name)[table(col_analysis$base_name) > 1])
  
  if (length(duplicated_vars) > 0) {
    message(sprintf("✅ %d개 반복 변수 발견", length(duplicated_vars)))
    message("   예시:", paste(head(duplicated_vars, 5), collapse = ", "))
    
    # Visit 번호 자동 할당
    for (var in duplicated_vars) {
      idx <- which(col_analysis$base_name == var)
      for (i in seq_along(idx)) {
        col_analysis$new_name[idx[i]] <- paste0(var, "_V", i)
      }
    }
    
    # 비반복 변수는 그대로 유지
    single_idx <- which(!col_analysis$base_name %in% duplicated_vars)
    col_analysis$new_name[single_idx] <- col_analysis$original[single_idx]
    
    # 새 이름 적용
    names(data) <- col_analysis$new_name
    message("\n✅ 변수명 재구조화 완료")
    
    # 변경 내역 샘플 출력
    changed <- col_analysis[col_analysis$original != col_analysis$new_name, ]
    if (nrow(changed) > 0) {
      message("\n변경 예시:")
      for (i in 1:min(5, nrow(changed))) {
        message(sprintf("  %s → %s", changed$original[i], changed$new_name[i]))
      }
    }
  }
  
  # 검증: 각 Visit별 변수 개수 확인
  v1_vars <- sum(grepl("_V1", names(data)))
  v2_vars <- sum(grepl("_V2", names(data)))
  v3_vars <- sum(grepl("_V3", names(data)))
  
  if (v1_vars > 0) {
    message(sprintf("\n📊 Visit별 변수 개수:"))
    message(sprintf("  V1: %d개", v1_vars))
    if (v2_vars > 0) message(sprintf("  V2: %d개", v2_vars))
    if (v3_vars > 0) message(sprintf("  V3: %d개", v3_vars))
  }
}

# 샘플 데이터 확인 (첫 번째 행)
if (has_repeated && nrow(data) > 0) {
  message("\n👤 첫 번째 행 데이터 샘플:")
  
  # 반복 측정 변수 예시 출력
  repeated_cols <- grep("_V[1-3]", names(data), value = TRUE)
  if (length(repeated_cols) > 0) {
    # 각 Visit별로 하나씩만 예시 출력
    for (v in c("_V1", "_V2", "_V3")) {
      v_sample <- head(grep(v, repeated_cols, value = TRUE), 2)
      if (length(v_sample) > 0) {
        for (col in v_sample) {
          message(sprintf("  %s = %s", col, data[[col]][1]))
        }
      }
    }
  }
}
```

### 4. 날짜 변환 처리
```r
# Excel 숫자 형식 날짜 변환 (5자리 숫자)
data$date_column <- ifelse(
  grepl("^\\d{5}$", data$date_column),  # 5자리 숫자이면
  as.character(as.Date(as.numeric(data$date_column), origin = "1899-12-30")),
  data$date_column  # 이미 날짜 문자열로 되어 있는 경우
)

# 잘못된 날짜 수정 예시 (사용자에게 확인)
if (any(grepl("^16\\d{2}", data$date_column))) {
  message("⚠️ 16XX년대 날짜 발견. 19XX년대로 수정이 필요할 수 있습니다.")
  message("예: 1646-12-02 → 1946-12-02")
  # 사용자 확인 후 수정
}
```

### 5. 변수명 일괄 변경 (수동 지정)
```r
# 반복 측정 데이터 패턴화 예시
# Visit 1, 2, 3에 대한 변수명 정리
# 사용자의 데이터 구조에 맞게 수정하세요
names(data)[10:20] <- c("score_V1", paste0("item", 1:10, "_V1"))
names(data)[21:31] <- c("score_V2", paste0("item", 1:10, "_V2"))
names(data)[32:42] <- c("score_V3", paste0("item", 1:10, "_V3"))

message("변수명이 패턴화되었습니다:")
message("- Visit별 구분: _V1, _V2, _V3")
message("- 측정 항목들이 일관된 패턴으로 정리됨")
```

### 6. NA 처리 방법
```r
# NA 처리 옵션들 (사용자가 선택)
message("\n다음과 같은 NA 처리 방법이 있습니다:")
message("1. 문자열 'NA', '미기재', 'N/A' → 실제 NA로 변환")
message("2. 특정 값(999, -1 등) → NA로 변환")
message("3. NA → 특정 값으로 대체 (0, 평균값, 중앙값)")
message("4. 완전 결측 행/열 제거")

# 예시: 문자열 NA 처리
data[data == "NA" | data == "미기재" | data == "N/A"] <- NA

# 숫자 변환 시 주의사항 알림
message("\n⚠️ 주의: 숫자 값을 임의로 변경하지 않습니다")
message("예: 3.5, 1.5 같은 중간값은 원본 유지")
message("필요 시 사용자가 직접 지정해주세요")
```

### 7. 데이터 타입 최적화
- 문자열 → 팩터 변환 (고유값 < 50%)
- 날짜 형식 자동 감지 및 변환
- 숫자형 데이터 정제

### 8. 결측치 패턴 분석
- 결측치 패턴 분석
- 변수별 결측률 계산
- 적절한 처리 방법 제안 (제거, 대체, 유지)

### 9. 파생 변수 생성 (사용자 확인)
```r
# 나이 계산 (자주 필요)
# 주의: 반드시 데이터 내의 기준일을 사용 (오늘 날짜 X)

# 유연한 컬럼명 검색 함수
find_date_column <- function(col_names, patterns) {
  for (pattern in patterns) {
    # 대소문자 구분 없이, 부분 매칭으로 검색
    matches <- grep(pattern, col_names, ignore.case = TRUE, value = TRUE)
    if (length(matches) > 0) {
      return(matches[1])
    }
  }
  return(NA)
}

# 기준일 관련 패턴들 (우선순위 순)
date_patterns <- c("기준일", "동의.*일", "방문일", "등록일", "visit.*date", 
                   "enrollment", "screening", "baseline", "date$")
birth_patterns <- c("생년월일", "생일", "birth", "DOB", "출생")

# 컬럼 찾기
ref_date <- find_date_column(names(data), date_patterns)
birth_date <- find_date_column(names(data), birth_patterns)

if (!is.na(ref_date) && !is.na(birth_date)) {
  # 날짜 형식 확인 및 변환
  data$Age <- as.numeric(as.Date(data[[ref_date]]) - as.Date(data[[birth_date]]))/365.25
  data$Age_group <- cut(data$Age, breaks = c(0, 65, Inf), labels = c("<65", "≥65"))
  message(sprintf("✅ 나이 계산 완료: '%s' - '%s'", ref_date, birth_date))
  message("   Age, Age_group 변수가 생성되었습니다")
} else {
  message("⚠️ 나이 계산에 필요한 날짜 컬럼을 찾을 수 없습니다")
  if (is.na(ref_date)) {
    message("   기준일 찾을 수 없음 (찾은 패턴: 기준일, 동의일, 방문일 등)")
  }
  if (is.na(birth_date)) {
    message("   생년월일 찾을 수 없음 (찾은 패턴: 생년월일, birth, DOB 등)")
  }
  message("   수동으로 지정해주세요")
}

# 점수 합계나 다중 응답 처리는 사용자에게 확인
message("\n다음과 같은 파생 변수가 필요할 수 있습니다:")
message("- 측정 항목 점수 합계 (여러 문항의 총점)")
message("- 다중 응답 분해 (하나의 변수 → 여러 개별 변수)")
message("- 범주화 (연속형 변수 → 범주형 변수)")
message("\n필요한 파생 변수를 알려주세요.")
```

### 10. pins 패키지 연동 (S3, 로컬)
```r
# pins board 사용 시
if (require(pins, quietly = TRUE)) {
  message("\npins 패키지를 사용하시나요? (S3, 로컬 board 등)")
  
  # S3 board 예시
  # board <- pins::board_s3("bucket-name", prefix = "path/to/data")
  # data_list <- pins::pin_read(board, "dataset_name")
  # data <- data_list$data
  # metadata <- data_list$label
  
  # 처리 후 저장
  # board %>% pins::pin_write(
  #   list(data = processed_data, label = metadata), 
  #   name = "processed_dataset"
  # )
}
```

### 11. 데이터 품질 보고서 (보안 주의)
```r
# 요약 통계만 생성 (데이터 전체 출력 금지)
summary_stats <- list(
  n_rows = nrow(data),
  n_cols = ncol(data),
  missing_rate = sum(is.na(data)) / (nrow(data) * ncol(data)),
  data_types = sapply(data, class)
)

# 데이터 미리보기 (상위 5행만)
message("Data preview:")
print(head(data, 5))  # 절대 전체 데이터 print(data) 금지!

# 민감 정보 확인 및 마스킹
sensitive_cols <- detect_sensitive_columns(names(data))
if (length(sensitive_cols) > 0) {
  message("⚠️ 민감 정보 감지: ", paste(sensitive_cols, collapse = ", "))
  message("자동 마스킹 처리됨")
}
```

### 12. 최종 검증 및 자동 저장
```r
# ✅ 처리 전후 비교
message("\n📊 최종 검증:")
message(sprintf("  처리 전: %d행 × %d열", nrow(data_original), ncol(data_original)))
message(sprintf("  처리 후: %d행 × %d열", nrow(data), ncol(data)))

if (ncol(data) != ncol(data_original)) {
  message("  ⚠️ 컬럼 수가 변경되었습니다. 반복 측정 구조 재확인 필요!")
}

# 데이터 손실 확인
if (nrow(data) < nrow(data_original)) {
  lost_rows <- nrow(data_original) - nrow(data)
  message(sprintf("  ⚠️ %d개 행이 제거되었습니다 (결측치 또는 중복)", lost_rows))
}

# 반복 측정 데이터인 경우 Visit별 완전성 확인
if (has_repeated) {
  for (v in c("V1", "V2", "V3")) {
    v_cols <- grep(paste0("_", v), names(data), value = TRUE)
    if (length(v_cols) > 0) {
      completeness <- sum(!is.na(data[[v_cols[1]]])) / nrow(data) * 100
      message(sprintf("  %s 완전성: %.1f%%", v, completeness))
    }
  }
}
```

### 13. 자동 저장
```r
# data/processed에 타임스탬프와 함께 저장
output_name <- paste0(
  tools::file_path_sans_ext(basename(input_file)),
  "_processed_",
  format(Sys.Date(), "%Y%m%d"),
  ".rds"
)
output_file <- file.path("data/processed", output_name)
saveRDS(data, output_file, compress = TRUE)
message("Saved to: ", output_file)

# 처리 이력 로그
log_processing(input_file, output_file, nrow(data), ncol(data))
```

## 스마트 기능
- 자동 파일 탐지: 가장 최근 파일 우선
- 인코딩 자동 감지 (UTF-8, CP949)
- 데이터 타입 최적화
- 결측치 패턴 분석 및 보고
- 처리 이력 추적

## 사용 예시

### 🤖 AI 주도형 (권장)
```
"데이터 전처리해줘"
→ AI가 알아서 파일 찾고, 구조 파악하고, 처리하고, 보고

"임상시험 데이터 정리해줘"
→ AI가 반복 측정 구조 자동 감지하고 처리

"엑셀 파일 정리해서 분석 준비해줘"
→ AI가 다중 헤더, 시트 구조 파악 후 최적 처리
```

### 📝 구체적 요청
```
"survey_2024.csv 파일 정제해줘"
"raw 폴더의 모든 CSV 파일 처리해줘"
"한글 깨진 파일 처리해줘"
```

### 💡 AI 작업 예시
사용자: "데이터 전처리해줘"

**AI 작업 순서:**

1. **탐색 (직접 실행)**
   ```bash
   ls data/raw/  # 파일 목록 확인
   
   # Excel 구조 파악
   Rscript -e "library(openxlsx); getSheetNames('data/raw/data.xlsx')"
   
   # 데이터 샘플 확인
   Rscript -e "head(read.xlsx('data/raw/data.xlsx', rows=1:3))"
   ```

2. **판단**
   - "77개 컬럼 발견, 코드북은 33개 → 반복 측정 구조"
   - "첫 행이 비어있음 → skip=1 필요"
   - "생년월일, 기준일 컬럼 있음 → 나이 계산 가능"

3. **스크립트 생성** (`scripts/preprocess_data.R`)
   ```r
   # 탐색 결과를 반영한 완전한 처리 스크립트
   library(openxlsx)
   data <- read.xlsx("data/raw/data.xlsx", skip=1)
   # ... 처리 로직 ...
   saveRDS(data, "data/processed/data_clean.rds")
   ```

4. **실행**
   ```bash
   Rscript scripts/preprocess_data.R
   ```

5. **결과 보고**
   - "✅ 77개 컬럼 → V1/V2/V3 구조로 정리"
   - "✅ 나이 변수 생성 완료"
   - "✅ data/processed/data_clean.rds 저장"
```