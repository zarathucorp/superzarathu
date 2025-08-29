# LLM 지시어: R 데이터 헬스 체크 및 진단 (Doctor)

## 사용자 요청
`{{USER_ARGUMENTS}}`

## 🩺 AI 작업 방식
**3단계 접근법을 사용하세요:**

### 1단계: 데이터 스캔 (직접 실행)
```bash
# CLI 명령어로 즉시 실행하여 데이터 파악
ls data/raw/
Rscript -e "files <- list.files('data/raw', pattern='\\.(csv|xlsx?)$', full.names=TRUE); for(f in files) {info <- file.info(f); cat(basename(f), ':', round(info$size/1024/1024, 2), 'MB,', format(info$mtime, '%Y-%m-%d'), '\n')}"
```

### 2단계: 심층 분석 (스크립트 생성)
```r
# data_doctor.R 파일 생성하여 전체 진단 로직 작성
# 데이터 건강도 평가, 문제점 발견, 질문 목록 생성
```

### 3단계: 리포트 생성
- CLI 콘솔 출력 (컬러, 이모지, 테이블)
- Markdown 리포트 파일 생성
- 데이터 생산자용 질문 목록

## 🎯 핵심 진단 항목

### 1. 개요 (Overview)
```r
# 파일 정보 수집
file_info <- list(
  name = basename(file_path),
  size = paste0(round(file.info(file_path)$size/1024/1024, 2), " MB"),
  modified = format(file.info(file_path)$mtime, "%Y-%m-%d %H:%M"),
  rows = nrow(data),
  cols = ncol(data)
)
```

### 2. 데이터 품질 점수 (Data Health Score)
```r
calculate_health_score <- function(data) {
  scores <- list()
  
  # 결측치 점수 (40점)
  missing_rate <- sum(is.na(data)) / (nrow(data) * ncol(data))
  scores$missing <- (1 - missing_rate) * 40
  
  # 중복 행 점수 (20점)
  dup_rate <- sum(duplicated(data)) / nrow(data)
  scores$duplicate <- (1 - dup_rate) * 20
  
  # 데이터 타입 일관성 (20점)
  type_consistency <- check_type_consistency(data)
  scores$types <- type_consistency * 20
  
  # 이상치 점수 (20점)
  outlier_rate <- calculate_outlier_rate(data)
  scores$outliers <- (1 - outlier_rate) * 20
  
  total_score <- sum(unlist(scores))
  grade <- case_when(
    total_score >= 95 ~ "A+",
    total_score >= 90 ~ "A",
    total_score >= 85 ~ "B+",
    total_score >= 80 ~ "B",
    total_score >= 75 ~ "C+",
    total_score >= 70 ~ "C",
    total_score >= 60 ~ "D",
    TRUE ~ "F"
  )
  
  return(list(score = round(total_score, 1), grade = grade, details = scores))
}
```

### 3. 컬럼별 상세 분석
```r
analyze_columns <- function(data) {
  col_analysis <- data.frame(
    Column = names(data),
    Type_Inferred = sapply(data, function(x) {
      if(all(is.na(x))) return("Unknown")
      x_clean <- x[!is.na(x)]
      
      # 날짜 패턴 확인
      if(any(grepl("\\d{4}-\\d{2}-\\d{2}", x_clean))) return("Date")
      
      # 숫자 변환 가능 확인
      if(suppressWarnings(!any(is.na(as.numeric(x_clean))))) return("Numeric")
      
      # 카테고리형 확인
      if(length(unique(x_clean)) < length(x_clean) * 0.1) return("Category")
      
      return("Text")
    }),
    Missing_Count = sapply(data, function(x) sum(is.na(x))),
    Missing_Pct = sapply(data, function(x) round(sum(is.na(x))/length(x)*100, 1)),
    Unique_Values = sapply(data, function(x) length(unique(x[!is.na(x)]))),
    stringsAsFactors = FALSE
  )
  
  # 문제점 찾기
  col_analysis$Issues <- apply(col_analysis, 1, function(row) {
    issues <- c()
    
    # 높은 결측치
    if(as.numeric(row["Missing_Pct"]) > 50) {
      issues <- c(issues, "⚠️ 높은 결측률")
    }
    
    # 혼합된 타입 확인
    col_name <- row["Column"]
    col_data <- data[[col_name]]
    if(!all(is.na(col_data))) {
      numeric_test <- suppressWarnings(as.numeric(col_data))
      if(sum(!is.na(numeric_test)) > 0 && sum(is.na(numeric_test)) > 0) {
        if(sum(is.na(numeric_test)) != sum(is.na(col_data))) {
          issues <- c(issues, "⚠️ 혼합된 데이터 타입")
        }
      }
    }
    
    # 공백 포함
    if(is.character(col_data) && any(grepl("^\\s+|\\s+$", col_data[!is.na(col_data)]))) {
      issues <- c(issues, "⚠️ 앞뒤 공백")
    }
    
    # 날짜 형식 문제
    if(row["Type_Inferred"] == "Date") {
      date_formats <- unique(gsub("[0-9]", "X", col_data[!is.na(col_data)]))
      if(length(date_formats) > 1) {
        issues <- c(issues, "⚠️ 일관되지 않은 날짜 형식")
      }
    }
    
    return(paste(issues, collapse = ", "))
  })
  
  return(col_analysis)
}
```

### 4. 데이터 패턴 감지
```r
detect_data_patterns <- function(data) {
  patterns <- list()
  
  # 반복 측정 패턴
  repeated_patterns <- c("\\.\\d+$", "_V\\d+", "Visit\\d+", "Week\\d+", "_T\\d+")
  for(pattern in repeated_patterns) {
    if(any(grepl(pattern, names(data)))) {
      patterns$repeated_measures <- TRUE
      patterns$repeated_pattern <- pattern
      break
    }
  }
  
  # 임상시험 데이터 패턴
  clinical_keywords <- c("patient", "subject", "visit", "treatment", "dose", "adverse")
  if(sum(tolower(names(data)) %in% clinical_keywords) >= 2) {
    patterns$clinical_trial <- TRUE
  }
  
  # 설문조사 데이터 패턴
  survey_patterns <- c("Q\\d+", "문항\\d+", "item\\d+")
  for(pattern in survey_patterns) {
    if(sum(grepl(pattern, names(data))) > 5) {
      patterns$survey_data <- TRUE
      break
    }
  }
  
  # Wide format 데이터
  if(ncol(data) > 50 && patterns$repeated_measures) {
    patterns$wide_format <- TRUE
  }
  
  return(patterns)
}
```

### 5. 데이터 생산자 질문 목록 생성
```r
generate_questions <- function(data, col_analysis, patterns) {
  questions <- list()
  lang <- getOption("sz.language", "ko")  # 언어 설정
  
  # 결측치 관련 질문
  high_missing <- col_analysis[col_analysis$Missing_Pct > 30, ]
  if(nrow(high_missing) > 0) {
    if(lang == "ko") {
      questions$missing <- sprintf(
        "다음 변수들의 결측치가 많습니다 (%s). 의도된 것인가요? 아니면 데이터 수집 문제인가요?",
        paste(high_missing$Column[1:min(3, nrow(high_missing))], collapse = ", ")
      )
    } else {
      questions$missing <- sprintf(
        "High missing rate in columns: %s. Is this intentional or a data collection issue?",
        paste(high_missing$Column[1:min(3, nrow(high_missing))], collapse = ", ")
      )
    }
  }
  
  # 혼합된 데이터 타입
  mixed_type <- col_analysis[grepl("혼합된 데이터 타입", col_analysis$Issues), ]
  if(nrow(mixed_type) > 0) {
    if(lang == "ko") {
      questions$mixed_type <- sprintf(
        "%s 변수에 숫자와 문자가 섞여 있습니다. 올바른 데이터 타입은 무엇인가요?",
        mixed_type$Column[1]
      )
    } else {
      questions$mixed_type <- sprintf(
        "Column '%s' contains mixed numeric and text values. What is the correct data type?",
        mixed_type$Column[1]
      )
    }
  }
  
  # 카테고리 값 확인
  category_cols <- col_analysis[col_analysis$Type_Inferred == "Category" & col_analysis$Unique_Values < 10, ]
  if(nrow(category_cols) > 0) {
    sample_col <- category_cols$Column[1]
    unique_vals <- unique(data[[sample_col]][!is.na(data[[sample_col]])])
    
    if(lang == "ko") {
      questions$categories <- sprintf(
        "%s 변수의 값들(%s)이 무엇을 의미하나요? 코드북이 있나요?",
        sample_col,
        paste(head(unique_vals, 5), collapse = ", ")
      )
    } else {
      questions$categories <- sprintf(
        "What do the values in '%s' (%s) represent? Is there a codebook?",
        sample_col,
        paste(head(unique_vals, 5), collapse = ", ")
      )
    }
  }
  
  # 반복 측정 관련
  if(!is.null(patterns$repeated_measures)) {
    if(lang == "ko") {
      questions$repeated <- "반복 측정 데이터로 보입니다. 각 시점(Visit)의 의미와 간격을 알려주세요."
    } else {
      questions$repeated <- "This appears to be repeated measures data. Please explain the meaning and intervals of each timepoint."
    }
  }
  
  # 날짜 형식 확인
  date_cols <- col_analysis[col_analysis$Type_Inferred == "Date", ]
  if(nrow(date_cols) > 0) {
    if(lang == "ko") {
      questions$dates <- "날짜 형식이 일관되지 않을 수 있습니다. 표준 형식(YYYY-MM-DD)으로 통일해도 되나요?"
    } else {
      questions$dates <- "Date formats may be inconsistent. Can we standardize to YYYY-MM-DD format?"
    }
  }
  
  # 중복 행 관련
  dup_count <- sum(duplicated(data))
  if(dup_count > 0) {
    if(lang == "ko") {
      questions$duplicates <- sprintf(
        "%d개의 중복된 행이 있습니다. 제거해도 되나요? 아니면 의도된 반복인가요?",
        dup_count
      )
    } else {
      questions$duplicates <- sprintf(
        "Found %d duplicate rows. Should they be removed or are they intentional?",
        dup_count
      )
    }
  }
  
  return(questions)
}
```

## 📊 출력 포맷

### CLI 콘솔 출력
```r
print_doctor_report <- function(file_info, health_score, col_analysis, patterns, questions) {
  # 컬러 출력을 위한 crayon 패키지 사용
  if(require(crayon, quietly = TRUE)) {
    cat(cyan$bold("\n╔════════════════════════════════════════════════════════╗\n"))
    cat(cyan$bold("║          🩺 DATA HEALTH CHECK REPORT (DOCTOR)         ║\n"))
    cat(cyan$bold("╚════════════════════════════════════════════════════════╝\n\n"))
  } else {
    cat("\n========== DATA HEALTH CHECK REPORT (DOCTOR) ==========\n\n")
  }
  
  # 1. 개요
  cat(bold("📋 개요 (Overview)\n"))
  cat(sprintf("  • File Name: %s\n", file_info$name))
  cat(sprintf("  • File Size: %s\n", file_info$size))
  cat(sprintf("  • Total Rows: %s\n", format(file_info$rows, big.mark=",")))
  cat(sprintf("  • Total Columns: %d\n", file_info$cols))
  cat(sprintf("  • Last Modified: %s\n\n", file_info$modified))
  
  # 2. 핵심 진단
  cat(bold("🎯 핵심 진단 결과 (Key Diagnostics)\n"))
  
  # 건강 점수 색상 표시
  score_color <- if(health_score$score >= 90) green else if(health_score$score >= 70) yellow else red
  cat(sprintf("  • Data Health Score: %s%s (%s)%s\n", 
              score_color$bold(),
              health_score$grade,
              health_score$score,
              reset()))
  
  # 세부 점수
  cat("  • 세부 점수:\n")
  cat(sprintf("    - 결측치 관리: %.1f/40\n", health_score$details$missing))
  cat(sprintf("    - 중복 데이터: %.1f/20\n", health_score$details$duplicate))
  cat(sprintf("    - 타입 일관성: %.1f/20\n", health_score$details$types))
  cat(sprintf("    - 이상치 관리: %.1f/20\n\n", health_score$details$outliers))
  
  # 3. 문제가 있는 컬럼 하이라이트
  problem_cols <- col_analysis[col_analysis$Issues != "", ]
  if(nrow(problem_cols) > 0) {
    cat(bold(red("⚠️ 주의가 필요한 컬럼\n")))
    for(i in 1:min(5, nrow(problem_cols))) {
      cat(sprintf("  • %s: %s\n", 
                  problem_cols$Column[i], 
                  problem_cols$Issues[i]))
    }
    cat("\n")
  }
  
  # 4. 데이터 패턴
  if(length(patterns) > 0) {
    cat(bold("🔍 감지된 데이터 패턴\n"))
    if(patterns$repeated_measures) cat("  ✓ 반복 측정 데이터\n")
    if(patterns$clinical_trial) cat("  ✓ 임상시험 데이터\n")
    if(patterns$survey_data) cat("  ✓ 설문조사 데이터\n")
    if(patterns$wide_format) cat("  ✓ Wide format 구조\n")
    cat("\n")
  }
  
  # 5. 질문 목록
  if(length(questions) > 0) {
    cat(bold(yellow("❓ 데이터 생산자에게 확인이 필요한 사항\n")))
    q_num <- 1
    for(q in questions) {
      cat(sprintf("  %d. %s\n", q_num, q))
      q_num <- q_num + 1
    }
  }
  
  cat("\n")
}
```

### Markdown 리포트 생성
```r
generate_markdown_report <- function(file_info, health_score, col_analysis, patterns, questions) {
  report <- c()
  
  # 헤더
  report <- c(report, "# 🩺 데이터 건강 진단 리포트 (Data Doctor Report)")
  report <- c(report, paste0("\n**생성일시:** ", Sys.time()))
  report <- c(report, paste0("**파일:** ", file_info$name))
  report <- c(report, "\n---\n")
  
  # 1. 개요
  report <- c(report, "## 1. 개요 (Overview)")
  report <- c(report, "")
  report <- c(report, "| 항목 | 값 |")
  report <- c(report, "|------|-----|")
  report <- c(report, sprintf("| File Name | %s |", file_info$name))
  report <- c(report, sprintf("| File Size | %s |", file_info$size))
  report <- c(report, sprintf("| Total Rows | %s |", format(file_info$rows, big.mark=",")))
  report <- c(report, sprintf("| Total Columns | %d |", file_info$cols))
  report <- c(report, sprintf("| Last Modified | %s |", file_info$modified))
  report <- c(report, "")
  
  # 2. 핵심 진단 결과
  report <- c(report, "## 2. 핵심 진단 결과 (Key Diagnostics)")
  report <- c(report, "")
  report <- c(report, sprintf("### 🎯 데이터 건강 점수: **%s** (%.1f/100)", 
                               health_score$grade, health_score$score))
  report <- c(report, "")
  report <- c(report, "| 평가 항목 | 점수 | 만점 |")
  report <- c(report, "|-----------|------|------|")
  report <- c(report, sprintf("| 결측치 관리 | %.1f | 40 |", health_score$details$missing))
  report <- c(report, sprintf("| 중복 데이터 | %.1f | 20 |", health_score$details$duplicate))
  report <- c(report, sprintf("| 타입 일관성 | %.1f | 20 |", health_score$details$types))
  report <- c(report, sprintf("| 이상치 관리 | %.1f | 20 |", health_score$details$outliers))
  report <- c(report, sprintf("| **합계** | **%.1f** | **100** |", health_score$score))
  report <- c(report, "")
  
  # 3. 컬럼별 상세 분석
  report <- c(report, "## 3. 컬럼별 상세 분석 (Column Analysis)")
  report <- c(report, "")
  
  # 문제가 있는 컬럼만 표시
  problem_cols <- col_analysis[col_analysis$Issues != "" | col_analysis$Missing_Pct > 10, ]
  if(nrow(problem_cols) > 0) {
    report <- c(report, "### ⚠️ 주의가 필요한 컬럼")
    report <- c(report, "")
    report <- c(report, "| 컬럼명 | 추정 타입 | 결측률 | 고유값 | 발견된 문제 |")
    report <- c(report, "|--------|-----------|--------|--------|-------------|")
    
    for(i in 1:nrow(problem_cols)) {
      report <- c(report, sprintf("| %s | %s | %s%% | %d | %s |",
                                  problem_cols$Column[i],
                                  problem_cols$Type_Inferred[i],
                                  problem_cols$Missing_Pct[i],
                                  problem_cols$Unique_Values[i],
                                  problem_cols$Issues[i]))
    }
    report <- c(report, "")
  }
  
  # 4. 감지된 패턴
  if(length(patterns) > 0) {
    report <- c(report, "## 4. 감지된 데이터 패턴")
    report <- c(report, "")
    if(patterns$repeated_measures) {
      report <- c(report, "- ✅ **반복 측정 데이터**: 같은 대상을 여러 시점에서 측정한 구조")
    }
    if(patterns$clinical_trial) {
      report <- c(report, "- ✅ **임상시험 데이터**: 환자, 치료, 방문 등의 임상 관련 변수 포함")
    }
    if(patterns$survey_data) {
      report <- c(report, "- ✅ **설문조사 데이터**: 문항 형태의 변수명 패턴")
    }
    if(patterns$wide_format) {
      report <- c(report, "- ✅ **Wide Format**: 시점별 변수가 옆으로 나열된 구조")
    }
    report <- c(report, "")
  }
  
  # 5. 데이터 생산자 확인 사항
  if(length(questions) > 0) {
    report <- c(report, "## 5. 📋 데이터 생산자 확인 사항")
    report <- c(report, "")
    report <- c(report, "다음 사항들을 데이터 생산자에게 확인해주세요:")
    report <- c(report, "")
    
    q_num <- 1
    for(q in questions) {
      report <- c(report, sprintf("%d. %s", q_num, q))
      q_num <- q_num + 1
    }
    report <- c(report, "")
  }
  
  # 6. 권장 조치사항
  report <- c(report, "## 6. 🔧 권장 조치사항")
  report <- c(report, "")
  
  recommendations <- c()
  
  if(health_score$score < 70) {
    recommendations <- c(recommendations, "- ⚠️ **데이터 품질이 낮습니다.** 전처리가 필수적입니다.")
  }
  
  if(sum(col_analysis$Missing_Pct > 30) > 0) {
    recommendations <- c(recommendations, "- 결측치가 많은 변수들의 처리 방법을 결정하세요 (제거, 대체, 유지)")
  }
  
  if(any(grepl("혼합된 데이터 타입", col_analysis$Issues))) {
    recommendations <- c(recommendations, "- 데이터 타입을 일관되게 정리하세요")
  }
  
  if(!is.null(patterns$repeated_measures)) {
    recommendations <- c(recommendations, "- 반복 측정 구조를 고려한 분석 방법을 사용하세요")
  }
  
  if(length(recommendations) == 0) {
    recommendations <- c("- ✅ 데이터 품질이 양호합니다. 기본적인 전처리 후 분석 가능합니다.")
  }
  
  for(rec in recommendations) {
    report <- c(report, rec)
  }
  
  report <- c(report, "")
  report <- c(report, "---")
  report <- c(report, sprintf("*Generated by sz:doctor at %s*", Sys.time()))
  
  # 파일로 저장
  output_file <- sprintf("data_doctor_report_%s.md", format(Sys.Date(), "%Y%m%d"))
  writeLines(report, output_file)
  message(sprintf("\n📄 Markdown 리포트가 생성되었습니다: %s", output_file))
  
  return(output_file)
}
```

## 🚀 실행 흐름

### AI 작업 예시
사용자: "데이터 진단해줘"

**AI 작업 순서:**

1. **파일 탐색**
   ```bash
   ls data/raw/
   # 가장 최근 수정된 파일 찾기
   ```

2. **빠른 스캔**
   ```bash
   # 파일 크기와 형식 확인
   Rscript -e "file.info('data/raw/data.xlsx')"
   
   # 데이터 구조 미리보기
   Rscript -e "dim(read.xlsx('data/raw/data.xlsx', rows=1:100))"
   ```

3. **심층 분석 스크립트 생성** (`scripts/data_doctor.R`)
   ```r
   # 전체 데이터 로드 및 분석
   # 건강 점수 계산
   # 문제점 감지
   # 질문 목록 생성
   ```

4. **실행 및 리포트**
   ```bash
   Rscript scripts/data_doctor.R
   ```

5. **결과 표시**
   - CLI에 컬러풀한 리포트 출력
   - Markdown 파일 생성
   - 데이터 생산자용 질문 목록 제공

## 💡 주요 기능

### 지능형 감지
- 데이터 타입 자동 추론
- 반복 측정 패턴 자동 감지
- 임상시험/설문조사 데이터 식별
- 날짜 형식 불일치 감지

### 품질 평가
- 100점 만점 건강 점수
- A+ ~ F 등급 시스템
- 세부 항목별 점수 제공
- 시각적 표시 (컬러, 이모지)

### 실용적 질문 생성
- 데이터 생산자가 답할 수 있는 구체적 질문
- 우선순위에 따른 질문 정렬
- 한국어/영어 지원

## 사용 예시

### 🤖 AI 주도형 (권장)
```
"데이터 상태 진단해줘"
→ AI가 자동으로 파일 찾고, 분석하고, 리포트 생성

"엑셀 파일 건강 체크해줘"
→ 엑셀 파일의 모든 시트 분석 및 종합 리포트

"데이터 문제점 찾아줘"
→ 문제점 위주로 상세 분석
```

### 📝 구체적 요청
```
"survey_2024.csv 진단해줘"
"raw 폴더 전체 데이터 건강 체크"
"영어로 리포트 만들어줘"
```

### 🌍 언어 설정
```r
# 한국어 (기본값)
options(sz.language = "ko")

# 영어
options(sz.language = "en")
```

## ⚠️ 보안 및 성능 주의사항
- **데이터 전체를 출력하지 않음** (개인정보 보호)
- **요약 통계만 표시** (토큰 절약)
- **민감 정보 자동 마스킹**
- **대용량 파일은 샘플링하여 분석**

## 출력 예시

```
╔════════════════════════════════════════════════════════╗
║          🩺 DATA HEALTH CHECK REPORT (DOCTOR)         ║
╚════════════════════════════════════════════════════════╝

📋 개요 (Overview)
  • File Name: clinical_trial_2024.xlsx
  • File Size: 2.5 MB
  • Total Rows: 1,234
  • Total Columns: 78
  • Last Modified: 2024-01-15 14:30

🎯 핵심 진단 결과 (Key Diagnostics)
  • Data Health Score: B+ (85.3)
  • 세부 점수:
    - 결측치 관리: 32.5/40
    - 중복 데이터: 19.8/20
    - 타입 일관성: 18.0/20
    - 이상치 관리: 15.0/20

⚠️ 주의가 필요한 컬럼
  • Age: ⚠️ 혼합된 데이터 타입
  • Visit_Date_V2: ⚠️ 높은 결측률, ⚠️ 일관되지 않은 날짜 형식
  • Treatment_Code: ⚠️ 앞뒤 공백

🔍 감지된 데이터 패턴
  ✓ 반복 측정 데이터
  ✓ 임상시험 데이터
  ✓ Wide format 구조

❓ 데이터 생산자에게 확인이 필요한 사항
  1. Visit_Date_V2 변수의 결측치가 많습니다 (45.2%). 의도된 것인가요?
  2. Age 변수에 숫자와 문자가 섞여 있습니다. 올바른 데이터 타입은 무엇인가요?
  3. Treatment_Code 변수의 값들(A, B, C, 9)이 무엇을 의미하나요? 코드북이 있나요?
  4. 반복 측정 데이터로 보입니다. 각 시점(Visit)의 의미와 간격을 알려주세요.
  5. 24개의 중복된 행이 있습니다. 제거해도 되나요?

📄 Markdown 리포트가 생성되었습니다: data_doctor_report_20240115.md
```