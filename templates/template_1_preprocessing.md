# LLM 지시어: R 데이터 전처리 수행

## 목표 (Objective)
Raw data(csv, excel 등)를 불러와 분석에 적합한 형태로 정제하고 가공(Clean & Tidy)하여, 다음 분석 단계에 사용할 수 있는 `.rds` 파일을 생성한다.

## 프로세스 (Process)

### 1. 라이브러리 로드
데이터 전처리에 필수적인 라이브러리를 로드한다.
```R
# 데이터 핸들링 및 시각화를 위한 핵심 라이브러리
library(tidyverse) 
# Excel 파일을 불러오기 위한 라이브러리
library(readxl) 
```

### 2. 데이터 불러오기
제공된 `<path/to/your/data>`에서 데이터를 불러온다. 데이터 형식(csv, xlsx, rds 등)을 확인하고 적절한 함수를 사용한다.
```R
# CSV 파일 불러오기
raw_data <- read_csv("<path/to/your/data.csv>")

# Excel 파일 불러오기 (시트 이름 또는 번호 지정)
# raw_data <- read_excel("<path/to/your/data.xlsx>", sheet = "<sheet_name>")

# 작업할 데이터셋을 `df`로 명명한다.
df <- raw_data 
```

### 3. 데이터 구조 및 요약 확인 (EDA)
데이터의 구조, 변수 타입, 결측치 등을 파악하여 전처리 방향을 결정한다.
```R
# 데이터의 첫 6개 행 확인
head(df)
# 데이터의 전체적인 구조 확인 (변수명, 타입, 일부 데이터)
str(df)
# 데이터의 기술 통계량 요약
summary(df)
# 데이터의 차원 확인 (행과 열의 수)
dim(df)
```

### 4. 데이터 정제 및 가공 (dplyr)
`dplyr` 패키지를 중심으로 데이터를 정제하고 새로운 파생 변수를 생성한다.
```R
processed_df <- df %>%
  # 1. 변수명 변경 (새이름 = 구이름)
  rename(
    id = `<환자번호_변수명>`,
    age = `<나이_변수명>`
  ) %>%
  
  # 2. 특정 조건에 맞는 행 필터링
  filter(`<필터링_조건식>`) %>% # 예: age >= 18
  
  # 3. 필요한 변수만 선택
  select(id, age, `<분석에_필요한_변수들>`) %>%
  
  # 4. 새로운 변수 생성
  mutate(
    bmi = `<몸무게_변수>` / (`<키_변수>` / 100)^2,
    age_group = case_when(
      age < 40 ~ "Young",
      age >= 40 & age < 60 ~ "Middle-aged",
      age >= 60 ~ "Senior"
    )
  ) %>%
  
  # 5. 결측치 처리
  filter(!is.na(`<주요_변수명>`)) %>%
  
  # 6. 데이터 정렬
  arrange(age) # 나이 오름차순으로 정렬
```

### 5. 데이터 병합 (선택 사항)
필요시, 다른 데이터 소스와 결합한다.
```R
# df2 <- read_csv("<path/to/another/data.csv>")
# merged_df <- left_join(processed_df, df2, by = "<공통_ID_변수>")
```

## 최종 산출물 (Final Deliverable)
전처리가 완료된 데이터프레임 `processed_df`를 지정된 경로 `<path/to/save/processed_data.rds>`에 `.rds` 파일로 저장한다.
```R
saveRDS(processed_df, file = "<path/to/save/processed_data.rds>")
```