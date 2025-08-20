#' Get Hardcoded Templates
#'
#' Returns a list of all hardcoded templates for command generation.
#' Each template is a character string containing the full markdown content.
#'
#' @return A named list where names are command names and values are template content
#' @export
get_templates <- function() {
  list(
    preprocess = "# LLM 지시어: R 데이터 전처리 수행

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
raw_data <- read_csv(\"<path/to/your/data.csv>\")

# Excel 파일 불러오기 (시트 이름 또는 번호 지정)
# raw_data <- read_excel(\"<path/to/your/data.xlsx>\", sheet = \"<sheet_name>\")

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
      age < 40 ~ \"Young\",
      age >= 40 & age < 60 ~ \"Middle-aged\",
      age >= 60 ~ \"Senior\"
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
# df2 <- read_csv(\"<path/to/another/data.csv>\")
# merged_df <- left_join(processed_df, df2, by = \"<공통_ID_변수>\")
```

## 최종 산출물 (Final Deliverable)
전처리가 완료된 데이터프레임 `processed_df`를 지정된 경로 `<path/to/save/processed_data.rds>`에 `.rds` 파일로 저장한다.
```R
saveRDS(processed_df, file = \"<path/to/save/processed_data.rds>\")
```",
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
- `ui`와 `server`의 모듈 ID가 정확히 일치해야 한다.",
    plot = "# LLM 지시어: R PowerPoint 플롯 생성 및 삽입

## 목표 (Objective)
의료/바이오 데이터 분석 결과를 출판 품질의 그래프로 시각화하고, `officer` 패키지를 사용하여 PowerPoint 프레젠테이션에 삽입할 수 있는 형태로 제작한다. 임상연구 발표 및 논문 투고에 적합한 수준의 플롯을 생성한다.

## 입력 (Input)
- 분석이 완료된 데이터프레임 (`labeled_df` 또는 `processed_df`)
- 시각화할 변수 및 그룹 정보

## 프로세스 (Process)

### 1. 라이브러리 로드
```R
# 데이터 처리 및 시각화를 위한 핵심 라이브러리
library(tidyverse)
library(ggplot2)

# PowerPoint 작업을 위한 라이브러리
library(officer)   # PowerPoint 파일 생성 및 편집
library(rvg)      # ggplot을 벡터 그래픽으로 변환

# 추가적인 시각화 라이브러리 (필요시)
library(ggpubr)   # 통계적 비교와 publication-ready 플롯
library(cowplot)  # 여러 플롯 조합
library(scales)   # 축 스케일링
library(RColorBrewer) # 색상 팔레트
```

### 2. 데이터 불러오기
```R
# 라벨링이 완료된 데이터 또는 분석용 데이터 로드
df <- readRDS(\"<path/to/your/labeled_data.rds>\")

# 데이터 구조 확인
str(df)
summary(df)
```

### 3. 출판 품질 플롯 테마 설정
임상연구 및 의학 저널 투고에 적합한 깔끔한 테마를 정의한다.
```R
# 출판용 테마 정의
publication_theme <- theme_minimal() +
  theme(
    # 텍스트 설정
    text = element_text(size = 12, color = \"black\"),
    plot.title = element_text(size = 14, face = \"bold\", hjust = 0.5),
    axis.title = element_text(size = 12, face = \"bold\"),
    axis.text = element_text(size = 10, color = \"black\"),
    legend.title = element_text(size = 11, face = \"bold\"),
    legend.text = element_text(size = 10),
    
    # 배경 및 격자선
    panel.background = element_rect(fill = \"white\", color = NA),
    plot.background = element_rect(fill = \"white\", color = NA),
    panel.grid.major = element_line(color = \"grey90\", size = 0.3),
    panel.grid.minor = element_line(color = \"grey95\", size = 0.2),
    
    # 축선 설정
    axis.line = element_line(color = \"black\", size = 0.5),
    axis.ticks = element_line(color = \"black\", size = 0.3),
    
    # 범례 설정
    legend.position = \"bottom\",
    legend.box = \"horizontal\",
    legend.margin = margin(t = 10),
    
    # 여백 설정
    plot.margin = margin(t = 20, r = 20, b = 20, l = 20)
  )

# 의료/바이오 분야에 적합한 색상 팔레트
medical_colors <- c(\"#2E86AB\", \"#A23B72\", \"#F18F01\", \"#C73E1D\", \"#592941\")
```

### 4. 플롯 유형별 생성

#### 4.1. 기술통계 시각화 (Bar Plot + Error Bar)
```R
# 그룹별 연속형 변수의 평균과 표준오차 계산
summary_stats <- df %>%
  group_by(`<그룹_변수>`) %>%
  summarise(
    mean_value = mean(`<연속형_변수>`, na.rm = TRUE),
    se_value = sd(`<연속형_변수>`, na.rm = TRUE) / sqrt(n()),
    .groups = 'drop'
  )

# Bar plot with error bars
p_barplot <- ggplot(summary_stats, aes(x = `<그룹_변수>`, y = mean_value, fill = `<그룹_변수>`)) +
  geom_col(alpha = 0.8, width = 0.7) +
  geom_errorbar(aes(ymin = mean_value - se_value, ymax = mean_value + se_value),
                width = 0.2, size = 0.8) +
  scale_fill_manual(values = medical_colors) +
  labs(
    title = \"그룹별 <변수명> 비교\",
    x = \"<그룹_라벨>\",
    y = \"<변수_라벨> (Mean ± SE)\",
    fill = \"<그룹_라벨>\"
  ) +
  publication_theme +
  theme(legend.position = \"none\") # 범례 제거 (x축에 이미 정보 있음)

print(p_barplot)
```

#### 4.2. 산점도 및 상관관계 (Scatter Plot)
```R
# 두 연속형 변수 간 상관관계 시각화
p_scatter <- ggplot(df, aes(x = `<x축_변수>`, y = `<y축_변수>`, color = `<그룹_변수>`)) +
  geom_point(alpha = 0.7, size = 2.5) +
  geom_smooth(method = \"lm\", se = TRUE, size = 1.2) +
  scale_color_manual(values = medical_colors) +
  labs(
    title = \"<x축_변수>와 <y축_변수>의 상관관계\",
    x = \"<x축_라벨>\",
    y = \"<y축_라벨>\",
    color = \"<그룹_라벨>\"
  ) +
  publication_theme

# 상관계수 추가 (선택사항)
correlation <- cor(df$`<x축_변수>`, df$`<y축_변수>`, use = \"complete.obs\")
p_scatter <- p_scatter +
  annotate(\"text\", x = Inf, y = Inf, 
           label = paste(\"r =\", round(correlation, 3)),
           hjust = 1.1, vjust = 1.5, size = 4, fontface = \"bold\")

print(p_scatter)
```

#### 4.3. 박스플롯 (Box Plot)
```R
# 그룹별 분포 비교
p_boxplot <- ggplot(df, aes(x = `<그룹_변수>`, y = `<연속형_변수>`, fill = `<그룹_변수>`)) +
  geom_boxplot(alpha = 0.8, outlier.shape = 21, outlier.size = 2) +
  geom_jitter(width = 0.2, alpha = 0.4, size = 1) +
  scale_fill_manual(values = medical_colors) +
  labs(
    title = \"그룹별 <변수명> 분포 비교\",
    x = \"<그룹_라벨>\",
    y = \"<변수_라벨>\",
    fill = \"<그룹_라벨>\"
  ) +
  publication_theme +
  theme(legend.position = \"none\")

# 통계적 유의성 표시 (ggpubr 사용)
if(requireNamespace(\"ggpubr\", quietly = TRUE)) {
  p_boxplot <- p_boxplot + 
    ggpubr::stat_compare_means(method = \"t.test\", 
                               label = \"p.format\", 
                               size = 4)
}

print(p_boxplot)
```

#### 4.4. Kaplan-Meier 생존곡선 (jskm 패키지 활용)
```R
# 생존 분석이 필요한 경우
if(requireNamespace(\"survival\", quietly = TRUE) && 
   requireNamespace(\"jskm\", quietly = TRUE)) {
  
  library(survival)
  library(jskm)
  
  # 생존 객체 생성
  surv_obj <- Surv(time = df$`<시간_변수>`, event = df$`<이벤트_변수>`)
  
  # 그룹별 생존곡선 적합
  fit_km <- survfit(surv_obj ~ `<그룹_변수>`, data = df)
  
  # jskm으로 출판 품질 생존곡선 생성
  p_survival <- jskm(
    sfit = fit_km,
    data = df,
    table = TRUE,
    pval = TRUE,
    ystrataname = \"<그룹_라벨>\",
    timeby = 365, # 1년 단위
    xlims = c(0, max(df$`<시간_변수>`, na.rm = TRUE)),
    ylims = c(0, 1),
    xlab = \"Time (days)\",
    ylab = \"Survival Probability\",
    main = \"Kaplan-Meier Survival Curve\"
  )
  
  print(p_survival)
}
```

### 5. PowerPoint에 플롯 삽입

#### 5.1. 새로운 PowerPoint 프레젠테이션 생성
```R
# 새 PowerPoint 문서 생성
ppt <- read_pptx()

# 사용 가능한 레이아웃 확인
# layout_summary(ppt)

# 제목 슬라이드 추가
ppt <- add_slide(ppt, layout = \"Title Slide\", master = \"Office Theme\")
ppt <- ph_with(ppt, value = \"의료 데이터 분석 결과\", location = ph_location_label(ph_label = \"Title 1\"))
ppt <- ph_with(ppt, value = \"통계 분석 및 시각화 보고서\", location = ph_location_label(ph_label = \"Subtitle 2\"))
```

#### 5.2. 플롯을 슬라이드에 삽입
```R
# 플롯별로 새 슬라이드 생성하고 삽입

# 1. Bar Plot 슬라이드
ppt <- add_slide(ppt, layout = \"Title and Content\", master = \"Office Theme\")
ppt <- ph_with(ppt, value = \"그룹별 변수 비교 분석\", location = ph_location_label(ph_label = \"Title 1\"))
ppt <- ph_with(ppt, value = dml(ggobj = p_barplot), location = ph_location_label(ph_label = \"Content Placeholder 2\"))

# 2. Scatter Plot 슬라이드
ppt <- add_slide(ppt, layout = \"Title and Content\", master = \"Office Theme\")
ppt <- ph_with(ppt, value = \"변수 간 상관관계 분석\", location = ph_location_label(ph_label = \"Title 1\"))
ppt <- ph_with(ppt, value = dml(ggobj = p_scatter), location = ph_location_label(ph_label = \"Content Placeholder 2\"))

# 3. Box Plot 슬라이드
ppt <- add_slide(ppt, layout = \"Title and Content\", master = \"Office Theme\")
ppt <- ph_with(ppt, value = \"그룹별 분포 비교\", location = ph_location_label(ph_label = \"Title 1\"))
ppt <- ph_with(ppt, value = dml(ggobj = p_boxplot), location = ph_location_label(ph_label = \"Content Placeholder 2\"))

# 4. 생존곡선 슬라이드 (해당하는 경우)
if(exists(\"p_survival\")) {
  ppt <- add_slide(ppt, layout = \"Title and Content\", master = \"Office Theme\")
  ppt <- ph_with(ppt, value = \"Kaplan-Meier 생존 분석\", location = ph_location_label(ph_label = \"Title 1\"))
  ppt <- ph_with(ppt, value = dml(ggobj = p_survival), location = ph_location_label(ph_label = \"Content Placeholder 2\"))
}
```

#### 5.3. 통계 결과 테이블 슬라이드 (선택사항)
```R
# gtsummary나 jstable 결과를 이미지로 변환하여 삽입
if(requireNamespace(\"gtsummary\", quietly = TRUE)) {
  # Table 1 생성
  table1 <- df %>%
    select(`<변수1>`, `<변수2>`, `<그룹_변수>`) %>%
    gtsummary::tbl_summary(by = `<그룹_변수>`) %>%
    gtsummary::add_p() %>%
    gtsummary::bold_labels()
  
  # 테이블을 이미지로 저장 (webshot2 패키지 필요)
  if(requireNamespace(\"webshot2\", quietly = TRUE)) {
    gtsummary::as_gt(table1) %>%
      gt::gtsave(\"table1_temp.png\", vwidth = 800, vheight = 600)
    
    # 테이블 슬라이드 추가
    ppt <- add_slide(ppt, layout = \"Title and Content\", master = \"Office Theme\")
    ppt <- ph_with(ppt, value = \"기술통계표 (Table 1)\", location = ph_location_label(ph_label = \"Title 1\"))
    ppt <- ph_with(ppt, value = external_img(\"table1_temp.png\"), 
                   location = ph_location_label(ph_label = \"Content Placeholder 2\"))
    
    # 임시 파일 삭제
    file.remove(\"table1_temp.png\")
  }
}
```

### 6. PowerPoint 파일 저장
```R
# PowerPoint 파일 저장
output_file <- \"<path/to/save/medical_analysis_plots.pptx>\"
print(ppt, target = output_file)

message(\"PowerPoint 파일이 생성되었습니다: \", output_file)
```

## 최종 산출물 (Final Deliverable)

### 주요 산출물
1. **출판 품질의 ggplot2 시각화**
   - 의료/임상 데이터에 최적화된 테마 적용
   - 논문 투고 및 학회 발표에 적합한 해상도와 스타일
   - 통계적 유의성 및 효과 크기 표시

2. **PowerPoint 프레젠테이션 파일** (`.pptx`)
   - 각 플롯이 개별 슬라이드로 구성
   - 제목 슬라이드 및 설명 텍스트 포함
   - 벡터 그래픽 형태로 확대 시에도 선명함 유지

3. **재사용 가능한 R 스크립트**
   - 출판용 테마 및 색상 팔레트 정의
   - 다양한 플롯 유형별 템플릿 코드
   - PowerPoint 자동 생성 워크플로우

### 품질 기준
- **해상도**: 300 DPI 이상의 출판 품질
- **색상**: 의료/과학 출판물에 적합한 색상 팔레트
- **타이포그래피**: 명확하고 읽기 쉬운 폰트 및 크기
- **통계 표시**: p-value, 신뢰구간, 효과크기 등 통계 정보 포함
- **일관성**: 모든 플롯에서 동일한 스타일 및 테마 적용"
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
