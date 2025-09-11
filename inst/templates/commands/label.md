# LLM 지시어: 데이터 라벨링 및 메타데이터 관리

## 사용자 요청
`{{USER_ARGUMENTS}}`

## 🤖 AI 작업 방식
**2단계 접근법을 사용하세요:**

### 1단계: 탐색과 판단 (직접 실행)
```bash
# CLI 명령어로 즉시 실행하여 데이터 파악
ls data/processed/*.rds
Rscript -e "str(readRDS('data/processed/data.rds'), list.len=5)"
Rscript -e "library(openxlsx); getSheetNames('data/raw/data.xlsx')"
```
- 데이터 변수 타입 확인
- 코드북 존재 여부 파악  
- 0/1 변수, 범주형 변수 탐지

### 2단계: 라벨링 스크립트 생성 및 실행
```r
# label_data.R 파일 생성하여 전체 라벨링 로직 작성
# 사용자가 재실행 가능하도록 완전한 스크립트로
```
- 탐색 결과를 바탕으로 라벨링 스크립트 작성
- jstable 활용 또는 custom 라벨링
- `Rscript label_data.R`로 실행

## 프로젝트 구조
- 입력: `data/processed/` 폴더의 RDS 파일 자동 탐지
- 코드북 위치 (우선순위 순):
  1. `data/raw/` 폴더의 Excel 파일 내 "codebook" 시트
  2. `data/raw/codebook.xlsx` 별도 파일
  3. 원본 데이터 Excel의 2번째 시트
- 출력: `data/processed/` 폴더에 라벨된 RDS 파일 저장

## ⚠️ 보안 및 성능 주의사항
- **데이터 전체를 출력하지 마세요** (개인정보 보호, 토큰 절약)
- **names(), colnames() 사용**: 변수명만 확인
- **attr() 사용**: 라벨 정보만 확인
- **str() 사용**: 구조만 확인 (데이터 값 X)
- **코드북만 처리**: 실제 데이터는 읽지 말고 메타데이터만 작업

## 주요 기능
- 변수명 한글/영문 라벨링
- 범주형 변수 값 라벨링
- 코드북 적용 및 생성
- 메타데이터 관리
- 자동 라벨 추천

## 구현 지침

### 🎯 AI 작업 흐름 예시

#### 1️⃣ 탐색 단계 (직접 실행)
```bash
# 데이터 파일 확인
ls -la data/processed/*.rds

# 데이터 구조와 변수 타입 확인
Rscript -e "data <- readRDS('data/processed/data.rds'); str(data, list.len=10)"

# 0/1 변수 탐지
Rscript -e "data <- readRDS('data/processed/data.rds'); vars01 <- names(data)[sapply(data, function(x) all(x %in% c(0,1,NA)))]; print(vars01)"

# 코드북 확인
Rscript -e "library(openxlsx); sheets <- getSheetNames('data/raw/data.xlsx'); if('codebook' %in% tolower(sheets)) print('Codebook found!')"
```

#### 2️⃣ 스크립트 생성 단계
```r
# scripts/label_data.R 생성
library(jstable)
library(data.table)

# 데이터 읽기
data <- readRDS("data/processed/data.rds")

# [탐색 결과를 바탕으로 한 라벨링 로직]
# - jstable::mk.lev() 실행
# - 0/1 변수 → No/Yes
# - factor/continuous 분류
# - 코드북 적용

# 결과 저장  
saveRDS(data, "data/processed/data_labeled.rds")
```

#### 3️⃣ 실행
```bash
Rscript scripts/label_data.R
```

### 📍 스크립트 위치
- **탐색용 one-liner**: 직접 CLI에서 실행
- **라벨링 스크립트**: `scripts/label_data.R` 생성
- **재사용 함수**: `scripts/utils/label_functions.R`에 추가

### 1. 데이터 자동 로드
```r
# data/processed 폴더에서 최신 RDS 파일 자동 탐지
processed_files <- list.files("data/processed", pattern = "\\.rds$", full.names = TRUE)
if (length(processed_files) == 0) {
  stop("No processed data files found in data/processed/")
}

# 최신 파일 또는 사용자 요청 기반 선택
input_file <- processed_files[order(file.info(processed_files)$mtime, decreasing = TRUE)][1]
data <- readRDS(input_file)
message("Labeling: ", basename(input_file))
```

### 2. 코드북 탐지 및 라벨링
```r
# 코드북 자동 탐지 (여러 위치 확인)
codebook <- NULL

# 1. Excel 파일 내 "codebook" 시트 확인
excel_files <- list.files("data/raw", pattern = "\\.xlsx?$", full.names = TRUE)
for (file in excel_files) {
  sheets <- getSheetNames(file)
  if ("codebook" %in% tolower(sheets)) {
    message("Found codebook sheet in: ", basename(file))
    codebook <- read.xlsx(file, sheet = "codebook")
    break
  }
}

# 2. 별도 codebook.xlsx 파일 확인
if (is.null(codebook) && file.exists("data/raw/codebook.xlsx")) {
  message("Found codebook file: codebook.xlsx")
  codebook <- read.xlsx("data/raw/codebook.xlsx")
}

# 3. 원본 데이터 Excel의 2번째 시트 확인
if (is.null(codebook)) {
  original_excel <- list.files("data/raw", pattern = "\\.xlsx?$")[1]
  if (!is.na(original_excel)) {
    sheets <- getSheetNames(file.path("data/raw", original_excel))
    if (length(sheets) >= 2) {
      message("Using 2nd sheet as codebook from: ", original_excel)
      codebook <- read.xlsx(file.path("data/raw", original_excel), sheet = 2)
    }
  }
}

# 라벨 적용 (데이터 값은 건드리지 않음)
if (!is.null(codebook)) {
  message("Applying labels from codebook...")
  # 변수명만 확인 (데이터 전체 X)
  var_names <- names(data)
  message(sprintf("Variables to label: %d", length(var_names)))
  
  # 라벨 적용
  for (var in var_names) {
    if (var %in% codebook$variable) {
      attr(data[[var]], "label") <- codebook$label[codebook$variable == var]
    }
  }
} else {
  message("No codebook found. Generating labels automatically...")
  # AI 기반 자동 라벨 생성
}
```

### 3. jstable 패키지 활용 (유연한 라벨링)
```r
# jstable::mk.lev() 사용하여 자동 레벨 생성
if (require(jstable, quietly = TRUE)) {
  message("jstable 패키지로 라벨 테이블을 생성합니다...")
  out.label <- jstable::mk.lev(data)
  
  # 0/1 변수 자동 감지 및 라벨링
  vars.01 <- names(data)[sapply(lapply(data, levels), function(x){
    identical(x, c("0", "1"))
  })]
  
  for (v in vars.01) {
    out.label[variable == v, val_label := c("No", "Yes")]
    message(sprintf("✅ %s: 0→No, 1→Yes로 라벨링", v))
  }
  
  # 특정 변수 커스텀 라벨링 예시
  # Group 변수
  if ("Group" %in% names(data)) {
    out.label[variable == "Group", ":="(
      var_label = "Treatment Group",
      val_label = c("Control", "Treatment")
    )]
    message("✅ Group 변수 라벨링 완료")
  }
  
  # Age_group 변수
  if ("Age_group" %in% names(data)) {
    out.label[variable == "Age_group", ":="(
      var_label = "Age Group", 
      val_label = c("<65", "≥65")
    )]
    message("✅ Age_group 변수 라벨링 완료")
  }
  
  message("\n라벨 테이블이 생성되었습니다.")
  message("필요시 out.label 테이블을 직접 수정하여 커스터마이징 가능합니다.")
}
```

### 4. 데이터 타입 자동 분류 및 변환
```r
# 변수를 factor와 continuous로 자동 분류
# 레벨 수나 데이터 특성에 따라 분류
factor_vars <- names(data)[sapply(data, function(x) {
  length(unique(x[!is.na(x)])) <= 10 ||  # 고유값 10개 이하
  is.character(x) ||                      # 문자형
  is.logical(x)                           # 논리형
})]

conti_vars <- setdiff(names(data), factor_vars)

# 타입 변환 수행
message("\n데이터 타입 변환을 시작합니다...")
data[, (factor_vars) := lapply(.SD, factor), .SDcols = factor_vars]
data[, (conti_vars) := lapply(.SD, as.numeric), .SDcols = conti_vars]

message(sprintf("✅ Factor 변수: %d개", length(factor_vars)))
message(sprintf("✅ Continuous 변수: %d개", length(conti_vars)))
message("\n변환된 변수 목록을 확인하세요:")
message("Factor: ", paste(head(factor_vars, 5), collapse = ", "), 
        ifelse(length(factor_vars) > 5, "...", ""))
message("Continuous: ", paste(head(conti_vars, 5), collapse = ", "),
        ifelse(length(conti_vars) > 5, "...", ""))
```

### 5. 값 라벨링 (범주형 변수)
```r
# 팩터 레벨 라벨링
label_values <- function(x, value_labels) {
  if (is.factor(x) || is.character(x)) {
    factor(x, levels = names(value_labels), labels = value_labels)
  }
}

# 예시: 성별
if ("sex" %in% names(data)) {
  data$sex <- label_values(data$sex, c("1" = "남성", "2" = "여성"))
  message("✅ sex 변수 라벨링: 1→남성, 2→여성")
}
```

### 6. 코드북 생성
```r
# 자동 코드북 생성
generate_codebook <- function(data) {
  codebook <- data.frame(
    variable = names(data),
    type = sapply(data, class),
    label = sapply(data, function(x) attr(x, "label") %||% NA),
    values = sapply(data, function(x) {
      if (is.factor(x)) paste(levels(x), collapse = ", ")
      else if (is.numeric(x)) paste(range(x, na.rm = TRUE), collapse = " - ")
      else "text"
    })
  )
  return(codebook)
}
```

### 7. 라벨 검증 및 보고 (데이터 값 출력 금지)
```r
# 라벨 완성도 체크 (변수명과 라벨만 확인)
check_labels <- function(data) {
  # 변수명만 확인
  var_names <- names(data)
  unlabeled <- var_names[sapply(var_names, function(x) is.null(attr(data[[x]], "label")))]
  
  if (length(unlabeled) > 0) {
    message("라벨이 없는 변수: ", paste(unlabeled, collapse = ", "))
  }
  
  # 라벨 현황 요약 (데이터 값 없이)
  label_summary <- data.frame(
    variable = var_names,
    label = sapply(var_names, function(x) attr(data[[x]], "label") %||% NA),
    type = sapply(data, class)
  )
  
  message("\n라벨링 완료:")
  message(sprintf("- 전체 변수: %d개", length(var_names)))
  message(sprintf("- 라벨된 변수: %d개", sum(!is.na(label_summary$label))))
  
  # 라벨 정보만 출력 (데이터 값 X)
  print(head(label_summary, 10))
}
```

### 8. 자동 저장 및 최종 보고
```r
# 라벨된 데이터 저장
output_name <- paste0(
  tools::file_path_sans_ext(basename(input_file)),
  "_labeled_",
  format(Sys.Date(), "%Y%m%d"),
  ".rds"
)
output_file <- file.path("data/processed", output_name)
saveRDS(data, output_file)
message("Saved labeled data to: ", output_file)

# 코드북 자동 생성 및 저장
codebook <- generate_codebook(data)
write.xlsx(codebook, file.path("output/tables", "codebook_auto.xlsx"))
message("Generated codebook: output/tables/codebook_auto.xlsx")
```

## 스마트 기능
- jstable 패키지와 완벽 호환
- 0/1 변수 자동 No/Yes 변환
- 변수 타입 자동 분류 (factor/continuous)
- 의료 데이터 자동 인식 (ICD 코드, 검사명)
- 통계청 표준 코드 적용
- 다국어 라벨 지원 (한글, 영문)
- 라벨 일관성 검사
- AI 기반 변수명 해석
- 작업 내용 상세 보고 (사용자가 확인 가능)

## 사용 예시

### 🤖 AI 주도형 (권장)
```
"데이터 라벨링해줘"
→ AI가 데이터 찾고, 코드북 찾고, 자동 적용

"라벨 테이블 만들어줘"
→ AI가 jstable 사용하여 자동 생성

"변수 타입 정리해줘"
→ AI가 factor/continuous 자동 분류 및 변환
```

### 📝 구체적 요청
```
"코드북 적용해서 라벨링해줘"
"변수명 보고 자동으로 한글 라벨 만들어줘"
"0/1 변수 모두 No/Yes로 바꿔줘"
```

### 💡 AI 작업 예시
사용자: "라벨링해줘"

**AI 작업 순서:**

1. **탐색 (직접 실행)**
   ```bash
   ls data/processed/  # 최신 데이터 확인
   
   # 변수 타입 확인
   Rscript -e "data <- readRDS('data/processed/data.rds'); table(sapply(data, class))"
   
   # 0/1 변수 찾기
   Rscript -e "data <- readRDS('data/processed/data.rds'); sum(sapply(data, function(x) all(x %in% c(0,1,NA))))"
   
   # 코드북 탐색
   Rscript -e "file.exists('data/raw/codebook.xlsx')"
   ```

2. **판단**
   - "15개 0/1 변수 발견 → No/Yes 변환 필요"
   - "codebook 시트 있음 → 적용 가능"
   - "Group, Age_group 변수 있음 → 커스텀 라벨 필요"

3. **스크립트 생성** (`scripts/label_data.R`)
   ```r
   # 탐색 결과를 반영한 완전한 라벨링 스크립트
   library(jstable)
   data <- readRDS("data/processed/data.rds")
   
   # jstable로 라벨 테이블 생성
   out.label <- mk.lev(data)
   
   # 0/1 변수 처리
   vars.01 <- c("var1", "var2", ...)  # 탐색에서 찾은 변수들
   for(v in vars.01) {
     out.label[variable == v, val_label := c("No", "Yes")]
   }
   # ... 추가 라벨링 ...
   
   saveRDS(data, "data/processed/data_labeled.rds")
   ```

4. **실행**
   ```bash
   Rscript scripts/label_data.R
   ```

5. **결과 보고**
   - "✅ 15개 0/1 변수 → No/Yes 변환"
   - "✅ factor 30개, continuous 25개로 분류"
   - "✅ data/processed/data_labeled.rds 저장"
```
