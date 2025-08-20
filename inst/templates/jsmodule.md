# LLM 지시어: `jsmodule`을 활용한 모듈식 Shiny 앱 제작

## 목표 (Objective)
`jsmodule` 패키지에서 제공하는 사전 정의된 모듈(UI/Server)을 활용하여, 데이터 탐색, 기술 통계 분석, 생존 분석 기능을 갖춘 확장 가능한 Shiny 앱을 신속하게 구축한다.

## 핵심 개념 (Core Concept)
`jsmodule`은 특정 기능을 수행하는 UI와 서버 로직을 하나의 쌍(예: `data_ui`/`data_server`)으로 묶어 제공한다. 개발자는 각 모듈을 레고 블록처럼 조립하여 전체 앱을 구성한다.

- **`global.R`**: 앱 전역에서 사용할 데이터와 객체(특히, `jstable::mk.lev`로 만든 라벨 정보)를 준비한다.
- **`ui.R` (또는 `app.R`의 `ui`):** 각 모듈의 UI 함수(예: `data_ui("data")`)를 호출하여 화면을 구성한다.
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
data_for_app <- readRDS("<path/to/your/data.rds>")

# jstable을 위한 라벨 정보 생성 (매우 중요)
out.label <- jstable::mk.lev(data_for_app)
# --------------------------------


# 2. UI 정의
ui <- fluidPage(
  navbarPage(
    "jsmodule 기반 분석 앱",
    # 첫 번째 탭: 데이터 확인
    tabPanel("Data",
             data_ui("data") # "data"라는 ID로 데이터 모듈 UI 호출
    ),
    # 두 번째 탭: Table 1
    tabPanel("Table 1",
             jstable_ui("tb1") # "tb1"이라는 ID로 jstable 모듈 UI 호출
    ),
    # 세 번째 탭: Kaplan-Meier Plot
    tabPanel("Kaplan-Meier",
             jskm_ui("km") # "km"이라는 ID로 jskm 모듈 UI 호출
    ),
    # 네 번째 탭: Cox Regression
    tabPanel("Cox model",
             cox_ui("cox") # "cox"라는 ID로 Cox 모듈 UI 호출
    )
  )
)


# 3. Server 정의
server <- function(input, output, session) {

  # [핵심] 각 모듈에 데이터와 라벨 정보를 전달하고 서버 로직을 실행
  # callModule(모듈서버함수, "UI에서_사용한_ID", data = 데이터, data.label = 라벨정보)

  # 데이터 모듈 서버
  # reactive()를 사용하여 데이터가 동적으로 변경될 수 있도록 전달
  data_server("data", data = reactive({data_for_app}), data.label = reactive({out.label}))

  # Table 1 모듈 서버
  # data_server 모듈에서 필터링된 데이터를 받아올 수 있음 (get_data())
  # 여기서는 간단하게 전체 데이터를 사용
  jstable_server("tb1", data = reactive({data_for_app}), data.label = reactive({out.label}))

  # Kaplan-Meier 모듈 서버
  jskm_server("km", data = reactive({data_for_app}), data.label = reactive({out.label}))

  # Cox 모듈 서버
  cox_server("cox", data = reactive({data_for_app}), data.label = reactive({out.label}))

}


# 4. 앱 실행
shinyApp(ui, server)

```

## 최종 산출물 (Final Deliverable)
- `jsmodule`의 모듈들을 활용하여 구성된 완전한 Shiny 앱 `app.R` 스크립트.
- `global.R` (또는 상단)에 데이터 및 라벨 정보(`mk.lev`)가 정의되어 있어야 한다.
- `ui`와 `server`의 모듈 ID가 정확히 일치해야 한다.
