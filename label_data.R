# LLM 지시어: R 데이터 라벨링 수행
# 템플릿에 따른 실제 구현

# 1. 라이브러리 로드
# 기본 R만 사용 (tidyverse, readxl 대신)

# 2. 데이터 불러오기
processed_df <- readRDS("processed_data.rds")

cat("=== 원본 데이터 구조 확인 ===\n")
str(processed_df)
cat("\n=== 원본 데이터 요약 ===\n")
summary(processed_df)
cat("\n=== 원본 데이터 첫 6행 ===\n")
head(processed_df)

# 3. 코드북 불러오기 (CSV 형태)
value_labels <- read.csv("codebook_value_labels.csv", stringsAsFactors = FALSE, fileEncoding = "UTF-8")
variable_labels <- read.csv("codebook_variable_labels.csv", stringsAsFactors = FALSE, fileEncoding = "UTF-8")

cat("\n=== 코드북 value_labels 확인 ===\n")
print(value_labels)

cat("\n=== 코드북 variable_labels 확인 ===\n")
print(variable_labels)

# 4. 라벨링 수행

#### 방법 1: 코드북(Codebook)을 활용한 자동 라벨링 (권장)
# 작업할 데이터프레임 복사
labeled_df <- processed_df

# 값 라벨링 자동화
# 코드북에 정의된 모든 변수에 대해 루프 실행
cat("\n=== 자동 라벨링 시작 ===\n")

for (var_name in unique(value_labels$variable)) {
  # 해당 변수가 데이터프레임에 존재하는지 확인
  if (var_name %in% names(labeled_df)) {
    # 해당 변수에 대한 라벨 정보 필터링
    labels_for_var <- value_labels[value_labels$variable == var_name, ]
    
    cat(sprintf("라벨링 중: %s 변수\n", var_name))
    cat(sprintf("  - 기존 값: %s\n", paste(unique(labeled_df[[var_name]]), collapse = ", ")))
    cat(sprintf("  - 새 라벨: %s\n", paste(labels_for_var$label, collapse = ", ")))
    
    # factor로 변환
    labeled_df[[var_name]] <- factor(
      labeled_df[[var_name]],
      levels = labels_for_var$value,
      labels = labels_for_var$label
    )
  }
}

#### 방법 3: case_when()을 이용한 조건부 라벨링 (추가 예제)
# BMI를 범주형으로 변환
labeled_df$bmi_category <- ifelse(labeled_df$bmi < 18.5, "Underweight",
                         ifelse(labeled_df$bmi < 25, "Normal",
                         ifelse(labeled_df$bmi < 30, "Overweight", "Obese")))

# 나이 그룹 생성
labeled_df$age_group <- ifelse(labeled_df$age < 40, "Young",
                      ifelse(labeled_df$age < 60, "Middle-aged", "Senior"))

cat("\n=== 라벨링 완료 후 데이터 구조 ===\n")
str(labeled_df)

cat("\n=== 라벨링된 데이터 첫 10행 ===\n")
head(labeled_df, 10)

# 5. 라벨링 결과 확인
cat("\n=== 범주형 변수별 빈도표 ===\n")

# 성별 분포
cat("성별 분포:\n")
print(table(labeled_df$sex, useNA = "ifany"))

# 질병 상태 분포
cat("\n질병 상태 분포:\n")
print(table(labeled_df$disease_status, useNA = "ifany"))

# 흡연 상태 분포
cat("\n흡연 상태 분포:\n")
print(table(labeled_df$smoking, useNA = "ifany"))

# 중증도 분포
cat("\n중증도 분포:\n")
print(table(labeled_df$severity, useNA = "ifany"))

# 치료 반응 분포
cat("\n치료 반응 분포:\n")
print(table(labeled_df$treatment_response, useNA = "ifany"))

# 병원 유형 분포
cat("\n병원 유형 분포:\n")
print(table(labeled_df$hospital_type, useNA = "ifany"))

# 새로 생성된 범주형 변수들
cat("\nBMI 범주 분포:\n")
print(table(labeled_df$bmi_category, useNA = "ifany"))

cat("\n연령 그룹 분포:\n")
print(table(labeled_df$age_group, useNA = "ifany"))

# 6. 교차표 분석 예제
cat("\n=== 교차표 분석 예제 ===\n")
cat("성별 × 질병 상태:\n")
print(table(labeled_df$sex, labeled_df$disease_status))

cat("\n흡연 상태 × 질병 상태:\n")
print(table(labeled_df$smoking, labeled_df$disease_status))

# 7. 데이터 품질 체크
cat("\n=== 데이터 품질 체크 ===\n")
cat("결측치 개수:\n")
sapply(labeled_df, function(x) sum(is.na(x)))

cat("\n라벨링된 변수들의 레벨 확인:\n")
categorical_vars <- sapply(labeled_df, is.factor)
for(var in names(labeled_df)[categorical_vars]) {
  cat(sprintf("%s: %s\n", var, paste(levels(labeled_df[[var]]), collapse = ", ")))
}

# 최종 산출물 저장
saveRDS(labeled_df, file = "labeled_data.rds")
cat("\n=== 최종 결과 ===\n")
cat("라벨링이 완료된 데이터가 'labeled_data.rds' 파일로 저장되었습니다.\n")
cat(sprintf("총 %d명의 환자 데이터, %d개 변수\n", nrow(labeled_df), ncol(labeled_df)))
cat("범주형 변수들이 사람이 이해하기 쉬운 텍스트 라벨로 변환되었습니다.\n")