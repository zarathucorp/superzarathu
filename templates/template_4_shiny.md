# LLM 지시어: R Shiny 앱 제작

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
final_data <- readRDS("<path/to/save/labeled_data.rds>")

# 3. UI 정의 (사용자가 보는 화면)
ui <- fluidPage(
  # 앱 제목
  titlePanel("<앱_제목: 예: 환자 데이터 탐색 대시보드>"),
  
  # 사이드바 레이아웃
  sidebarLayout(
    # 입력 컨트롤이 위치하는 사이드바
    sidebarPanel(
      width = 3, # 사이드바 너비 조절
      h4("데이터 필터"),
      
      # 입력 1: 범주형 변수 필터
      selectInput(
        inputId = "cat_var_filter", # server에서 input$cat_var_filter 로 접근
        label = "<범주형_변수_이름> 선택:", # 예: "성별"
        choices = c("전체", unique(final_data$`<범주형_변수_컬럼명>`)),
        selected = "전체"
      ),
      
      # 입력 2: 연속형 변수 필터
      sliderInput(
        inputId = "num_var_filter", # server에서 input$num_var_filter 로 접근
        label = "<연속형_변수_이름> 범위:", # 예: "나이"
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
        type = "tabs",
        tabPanel("플롯", plotOutput(outputId = "main_plot")),
        tabPanel("데이터 테이블", DTOutput(outputId = "main_table"))
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
    if (input$cat_var_filter != "전체") {
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
        title = "필터링된 데이터 시각화",
        x = "<x축_라벨>",
        y = "<y축_라벨>"
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
- 스크립트 내의 모든 `<...>` 플레이스홀더는 실제 데이터의 변수명과 라벨로 채워져야 한다.