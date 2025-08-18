
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

df <- readRDS("<path/to/your/data.rds>")
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
  ystrataname = "<그룹_변수_이름>", # 범례 제목 (예: "Treatment Group")
  timeby = 365, # x축 눈금 간격 (예: 365일 = 1년)
  xlab = "Time in days",
  ylab = "Survival Probability",
  main = "Kaplan-Meier Survival Curve"
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
# doc <- add_slide(doc, layout = "Title and Content", master = "Office Theme")
# doc <- ph_with(doc, value = dml(ggobj = jskm_plot), location = ph_location_fullsize())
# print(doc, target = "jskm_plot.pptx")
```

## 최종 산출물 (Final Deliverable)
- `jskm()` 함수로 생성된 Kaplan-Meier 플롯 객체 (`jskm_plot`)
