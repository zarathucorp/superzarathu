# LLM 지시어: R 데이터 라벨링 수행

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
processed_df <- readRDS("<path/to/save/processed_data.rds>")
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
codebook_path <- "<path/to/codebook.xlsx>"

# 코드북에서 값 라벨과 변수 라벨 시트 불러오기
value_labels <- read_excel(codebook_path, sheet = "value_labels")
# variable_labels <- read_excel(codebook_path, sheet = "variable_labels") # 필요한 경우

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
                 labels = c("Male", "Female")),

    # 예: 질병 유무 변수 (0: 없음, 1: 있음)
    disease_status = factor(has_disease,
                              levels = c(0, 1),
                              labels = c("Control", "Case"))
  )
```

#### 방법 3: `case_when()`을 이용한 조건부 라벨링
연속형 변수를 범주형으로 만들거나 복잡한 조건으로 라벨링할 때 사용한다.
```R
labeled_df <- labeled_df %>% # 이미 다른 라벨링이 적용된 데이터에 추가
  mutate(
    bp_stage = case_when(
      sbp < 120 & dbp < 80 ~ "Normal",
      sbp >= 140 | dbp >= 90 ~ "Hypertension",
      TRUE ~ "Pre-hypertension"
    )
  )
```

## 최종 산출물 (Final Deliverable)
라벨링이 완료된 데이터프레임 `labeled_df`를 지정된 경로 `<path/to/save/labeled_data.rds>`에 `.rds` 파일로 저장한다.
```R
saveRDS(labeled_df, file = "<path/to/save/labeled_data.rds>")
```
