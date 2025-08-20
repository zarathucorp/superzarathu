# 샘플 의료 데이터 및 코드북 생성 스크립트
# 라벨링 예제를 위한 준비

# 기본 R 함수만 사용하여 패키지 의존성 제거

# 1. 샘플 전처리된 의료 데이터 생성 (processed_data.rds 시뮬레이션)
set.seed(123)
n_patients <- 500

processed_df <- data.frame(
  patient_id = 1:n_patients,
  age = sample(20:80, n_patients, replace = TRUE),
  sex = sample(c(1, 2), n_patients, replace = TRUE, prob = c(0.45, 0.55)),
  bmi = round(rnorm(n_patients, 25, 4), 1),
  smoking = sample(c(0, 1, 2), n_patients, replace = TRUE, prob = c(0.6, 0.3, 0.1)),
  disease_status = sample(c(0, 1), n_patients, replace = TRUE, prob = c(0.7, 0.3)),
  severity = sample(c(1, 2, 3), n_patients, replace = TRUE, prob = c(0.5, 0.3, 0.2)),
  treatment_response = sample(c(0, 1, 2), n_patients, replace = TRUE, prob = c(0.2, 0.5, 0.3)),
  hospital_type = sample(c(1, 2, 3), n_patients, replace = TRUE, prob = c(0.4, 0.4, 0.2)),
  follow_up_months = sample(1:60, n_patients, replace = TRUE)
)

# 2. 코드북 생성 - value_labels 시트
value_labels <- data.frame(
  variable = c(
    # 성별
    "sex", "sex",
    # 흡연 상태
    "smoking", "smoking", "smoking",
    # 질병 상태
    "disease_status", "disease_status",
    # 중증도
    "severity", "severity", "severity",
    # 치료 반응
    "treatment_response", "treatment_response", "treatment_response",
    # 병원 유형
    "hospital_type", "hospital_type", "hospital_type"
  ),
  value = c(
    # 성별 코드
    1, 2,
    # 흡연 상태 코드
    0, 1, 2,
    # 질병 상태 코드
    0, 1,
    # 중증도 코드
    1, 2, 3,
    # 치료 반응 코드
    0, 1, 2,
    # 병원 유형 코드
    1, 2, 3
  ),
  label = c(
    # 성별 라벨
    "Male", "Female",
    # 흡연 상태 라벨
    "Never smoker", "Former smoker", "Current smoker",
    # 질병 상태 라벨
    "Control", "Case",
    # 중증도 라벨
    "Mild", "Moderate", "Severe",
    # 치료 반응 라벨
    "No response", "Partial response", "Complete response",
    # 병원 유형 라벨
    "General hospital", "University hospital", "Specialty clinic"
  )
)

# 3. 코드북 생성 - variable_labels 시트
variable_labels <- data.frame(
  variable = c(
    "patient_id", "age", "sex", "bmi", "smoking", 
    "disease_status", "severity", "treatment_response", 
    "hospital_type", "follow_up_months"
  ),
  description = c(
    "Patient identification number",
    "Age in years", 
    "Sex (1=Male, 2=Female)",
    "Body Mass Index (kg/m²)",
    "Smoking status (0=Never, 1=Former, 2=Current)",
    "Disease status (0=Control, 1=Case)",
    "Disease severity (1=Mild, 2=Moderate, 3=Severe)",
    "Treatment response (0=No, 1=Partial, 2=Complete)",
    "Hospital type (1=General, 2=University, 3=Specialty)",
    "Follow-up period in months"
  )
)

# 4. 파일 저장
# 전처리된 데이터 저장
saveRDS(processed_df, file = "processed_data.rds")

# 코드북을 CSV 파일로 저장 (Excel 패키지 없이)
write.csv(value_labels, "codebook_value_labels.csv", row.names = FALSE, fileEncoding = "UTF-8")
write.csv(variable_labels, "codebook_variable_labels.csv", row.names = FALSE, fileEncoding = "UTF-8")

# 5. 생성된 파일 확인 및 미리보기
cat("=== 생성된 파일들 ===\n")
cat("1. processed_data.rds - 전처리된 샘플 의료 데이터\n")
cat("2. codebook_value_labels.csv - 코드북 값 라벨\n")
cat("3. codebook_variable_labels.csv - 코드북 변수 라벨\n\n")

cat("=== 샘플 데이터 미리보기 ===\n")
head(processed_df)

cat("\n=== 코드북 value_labels 미리보기 ===\n")
head(value_labels, 10)

cat("\n=== 코드북 variable_labels 미리보기 ===\n")
head(variable_labels)