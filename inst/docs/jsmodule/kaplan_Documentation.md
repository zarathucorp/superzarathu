# kaplan Documentation

## Overview

`kaplan.R`은 jsmodule 패키지의 생존분석 시각화 모듈로, Shiny 애플리케이션에서 Kaplan-Meier 생존곡선을 생성하고 커스터마이징하는 기능을 제공합니다. 이 모듈은 표준 생존분석과 설문조사 가중 생존분석을 모두 지원하며, 경쟁위험 분석과 다양한 시각화 옵션을 포함합니다.

## Module Components

### `kaplanUI(id)`

Kaplan-Meier 플롯 설정을 위한 Shiny 모듈 UI를 생성합니다.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `id` | character | - | 모듈의 네임스페이스 식별자 |

#### Returns

Shiny UI 객체 (생존분석 플롯 설정 요소들)

#### UI Components

- 이벤트/시간 변수 선택
- 독립변수 선택
- 경쟁위험 분석 옵션
- 시각화 옵션 (스케일, p-value, 테이블 표시)

### `ggplotdownUI(id)`

생성된 플롯의 다운로드 옵션 UI를 생성합니다.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `id` | character | - | 모듈의 네임스페이스 식별자 |

#### Returns

Shiny UI 객체 (다운로드 버튼 및 플롯 내보내기 컨트롤)

### `optionUI(id)`

추가적인 플롯 설정 옵션을 위한 드롭다운 버튼 UI를 생성합니다.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `id` | character | - | 모듈의 네임스페이스 식별자 |

#### Returns

Shiny UI 객체 (추가 플롯 커스터마이징 옵션이 포함된 드롭다운 버튼)

### `kaplanModule(input, output, session, data, data_label, data_varStruct = NULL, nfactor.limit = 20, design.survey = NULL)`

Kaplan-Meier 생존곡선 생성을 위한 서버 사이드 로직을 제공합니다.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `input` | - | - | Shiny 입력 객체 |
| `output` | - | - | Shiny 출력 객체 |
| `session` | - | - | Shiny 세션 객체 |
| `data` | data.frame/reactive | - | 생존분석 데이터셋 |
| `data_label` | data.frame/reactive | - | 변수 레이블 정보 |
| `data_varStruct` | list | NULL | 변수 구조 정보 |
| `nfactor.limit` | integer | 20 | 범주형 변수 레벨 제한 |
| `design.survey` | survey.design | NULL | 설문조사 설계 객체 |

#### Returns

다음을 포함하는 반응형 객체:
- 커스터마이징된 Kaplan-Meier 플롯
- 생존분석 통계량
- 다운로드 가능한 플롯 객체

## Usage Examples

### 기본 사용법

```r
library(shiny)
library(jsmodule)
library(survival)
library(jskm)

# UI 정의
ui <- fluidPage(
  titlePanel("Kaplan-Meier Survival Analysis"),
  sidebarLayout(
    sidebarPanel(
      kaplanUI("survival_analysis"),
      hr(),
      optionUI("survival_analysis"),
      hr(),
      ggplotdownUI("survival_analysis")
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Survival Plot", 
                 plotOutput("kaplan_plot", height = "600px")),
        tabPanel("Summary Table", 
                 DT::DTOutput("survival_summary")),
        tabPanel("Risk Table", 
                 verbatimTextOutput("risk_table"))
      )
    )
  )
)

server <- function(input, output, session) {
  # 예시 생존분석 데이터
  survival_data <- reactive({
    data(colon, package = "survival")
    colon
  })
  
  data_label <- reactive({
    data.frame(
      variable = names(colon),
      label = c("ID", "Study", "Treatment", "Sex", "Age", "Obstruction",
               "Perforated", "Adherence", "Nodes", "Time", "Status", 
               "Differentiation", "Extent", "Surgery time", "Time to recurrence",
               "Recurrence status", "Time to death", "Death status"),
      stringsAsFactors = FALSE
    )
  })
  
  # Kaplan-Meier 모듈 서버
  kaplan_result <- callModule(kaplanModule, "survival_analysis",
                             data = survival_data,
                             data_label = data_label,
                             nfactor.limit = 30)
  
  # 메인 생존곡선 플롯
  output$kaplan_plot <- renderPlot({
    req(kaplan_result()$plot)
    kaplan_result()$plot
  })
  
  # 생존분석 요약 테이블
  output$survival_summary <- DT::renderDT({
    req(kaplan_result()$summary)
    kaplan_result()$summary
  }, options = list(scrollX = TRUE))
  
  # 위험 테이블
  output$risk_table <- renderPrint({
    req(kaplan_result()$risk_table)
    kaplan_result()$risk_table
  })
}

shinyApp(ui = ui, server = server)
```

### 고급 사용법

```r
# 복잡한 생존분석 워크플로
server <- function(input, output, session) {
  # 데이터 입력 모듈 연동
  data_input <- callModule(csvFile, "datafile")
  
  # 생존분석 모듈
  survival_analysis <- callModule(kaplanModule, "kaplan_viz",
                                 data = reactive(data_input()$data),
                                 data_label = reactive(data_input()$label))
  
  # 다중 생존곡선 비교
  comparative_survival <- reactive({
    req(data_input()$data)
    
    df <- data_input()$data
    
    # 주요 예후 인자별 생존곡선 생성
    prognostic_factors <- df %>%
      select_if(function(x) is.factor(x) && length(levels(x)) <= 5) %>%
      names()
    
    survival_plots <- list()
    
    for(factor in prognostic_factors[1:min(3, length(prognostic_factors))]) {
      if(!is.null(df$time) && !is.null(df$status)) {
        fit <- survfit(Surv(time, status) ~ get(factor), data = df)
        
        survival_plots[[factor]] <- jskm(fit,
                                        table = TRUE,
                                        pval = TRUE,
                                        main = paste("Survival by", factor))
      }
    }
    
    return(survival_plots)
  })
  
  # 경쟁위험 분석
  competing_risk_analysis <- reactive({
    req(data_input()$data)
    
    df <- data_input()$data
    
    if(!is.null(df$time) && !is.null(df$event_type)) {
      # 경쟁위험 모델 적합
      library(cmprsk)
      
      cif_result <- cuminc(df$time, df$event_type, df$group)
      
      return(list(
        cumulative_incidence = cif_result,
        summary = summary(cif_result)
      ))
    }
  })
  
  # 다중 플롯 출력
  output$comparative_plots <- renderUI({
    plots <- comparative_survival()
    req(plots)
    
    plot_outputs <- lapply(names(plots), function(name) {
      plotOutput(paste0("plot_", name), height = "400px")
    })
    
    do.call(tagList, plot_outputs)
  })
}
```

## Survival Analysis Features

### 지원하는 분석 유형

#### 표준 Kaplan-Meier 분석
```r
# 단일군 생존분석
survfit(Surv(time, status) ~ 1, data = data)

# 다중군 비교
survfit(Surv(time, status) ~ group, data = data)

# 층화 분석
survfit(Surv(time, status) ~ group + strata(strata_var), data = data)
```

#### 설문조사 가중 생존분석
```r
# 가중 생존분석 (survey 패키지 사용)
if(!is.null(design.survey)) {
  svykm(Surv(time, status) ~ group, design = design.survey)
}
```

#### 경쟁위험 분석
```r
# 경쟁위험을 고려한 누적발생함수
library(cmprsk)
cuminc(time, event_type, group)
```

### 플롯 커스터마이징 옵션

#### 기본 시각화 설정
```r
# 생존곡선 스타일
survival_plot_options <- list(
  show_confidence_interval = TRUE,
  show_censoring_marks = TRUE,
  show_pvalue = TRUE,
  show_risk_table = TRUE,
  color_palette = "jco",  # 또는 "npg", "aaas", "nejm"
  theme = "classic"       # 또는 "minimal", "bw"
)
```

#### 시간 축 설정
```r
# 시간 단위 및 범위
time_axis_options <- list(
  time_scale = "default",  # "default", "percent", "log"
  time_breaks = "auto",    # 또는 특정 간격 지정
  time_limits = NULL,      # 또는 c(min, max)
  time_labels = "auto"     # 또는 커스텀 레이블
)
```

#### 고급 시각화 옵션
```r
# 생존곡선 고급 설정
advanced_options <- list(
  risk_table_position = "bottom",  # "bottom", "right", "none"
  confidence_interval_alpha = 0.3,
  censoring_shape = "|",
  line_size = 1.2,
  point_size = 2,
  legend_position = "top"          # "top", "bottom", "left", "right", "none"
)
```

## Statistical Output

### 생존분석 통계량

```r
# 모듈에서 제공하는 통계 정보:
survival_statistics <- list(
  median_survival = "중앙생존시간",
  survival_rates = "특정 시점 생존율",
  confidence_intervals = "신뢰구간",
  logrank_test = "로그순위 검정",
  hazard_ratios = "위험비 (이변량 분석 시)"
)
```

### 위험 테이블 (Risk Table)

```r
# 시간별 위험대상자 수 테이블
risk_table_info <- data.frame(
  time = "시간 구간",
  n_risk = "위험대상자 수",
  n_event = "이벤트 발생 수",
  n_censor = "중도절단 수",
  survival = "생존율",
  std_err = "표준오차",
  lower_ci = "신뢰구간 하한",
  upper_ci = "신뢰구간 상한"
)
```

## Integration with Other Modules

### 데이터 입력 모듈과의 연동

```r
# 생존분석 전용 데이터 입력
server <- function(input, output, session) {
  # 생존분석 데이터 입력
  survival_input <- callModule(csvFile, "survival_data")
  
  # 데이터 전처리
  processed_survival_data <- reactive({
    req(survival_input()$data)
    
    df <- survival_input()$data
    
    # 생존분석 필수 변수 확인
    time_vars <- df %>% select_if(is.numeric) %>% names()
    status_vars <- df %>% 
      select_if(function(x) is.factor(x) || (is.numeric(x) && all(x %in% c(0,1)))) %>%
      names()
    
    return(list(
      data = df,
      time_candidates = time_vars,
      status_candidates = status_vars
    ))
  })
  
  # Kaplan-Meier 분석
  kaplan_analysis <- callModule(kaplanModule, "km_analysis",
                               data = reactive(processed_survival_data()$data),
                               data_label = reactive(survival_input()$label))
}
```

### Cox 회귀분석과의 연동

```r
# 생존곡선과 Cox 모델 결합 분석
combined_survival_analysis <- reactive({
  req(kaplan_analysis(), cox_analysis())
  
  # Kaplan-Meier 결과
  km_plot <- kaplan_analysis()$plot
  
  # Cox 모델 결과
  cox_summary <- cox_analysis()$summary
  
  # 결합 시각화
  combined_plot <- km_plot +
    labs(caption = paste("Cox model p-value:", 
                        round(cox_summary$coefficients[1,5], 4)))
  
  return(list(
    plot = combined_plot,
    km_summary = kaplan_analysis()$summary,
    cox_summary = cox_summary
  ))
})
```

## Export and Download Features

### 플롯 다운로드 옵션

```r
# 다양한 형식으로 플롯 저장
download_options <- list(
  formats = c("png", "pdf", "svg", "eps"),
  resolutions = c(300, 600, 1200),  # DPI
  dimensions = list(
    width = c(6, 8, 10, 12),        # inches
    height = c(4, 6, 8, 10)         # inches
  )
)

# 다운로드 핸들러
output$download_survival_plot <- downloadHandler(
  filename = function() {
    paste("kaplan_meier_", Sys.Date(), ".", input$file_format, sep = "")
  },
  content = function(file) {
    ggsave(file, plot = kaplan_result()$plot,
           width = input$plot_width, 
           height = input$plot_height,
           dpi = input$plot_dpi,
           device = input$file_format)
  }
)
```

### 데이터 내보내기

```r
# 생존분석 결과 데이터 다운로드
output$download_survival_data <- downloadHandler(
  filename = function() {
    paste("survival_analysis_", Sys.Date(), ".csv", sep = "")
  },
  content = function(file) {
    survival_summary <- kaplan_result()$summary
    write.csv(survival_summary, file, row.names = FALSE)
  }
)
```

## Performance Considerations

### 대용량 생존 데이터

```r
# 큰 생존분석 데이터 처리 최적화
optimized_survival <- reactive({
  req(data_input()$data)
  
  df <- data_input()$data
  
  # 표본 추출 (필요한 경우)
  if(nrow(df) > 50000) {
    df_sample <- df[sample(nrow(df), 20000), ]
    showNotification("Large dataset: Using random sample for visualization", 
                    type = "warning")
  } else {
    df_sample <- df
  }
  
  # 필수 변수만 선택
  essential_vars <- c(input$time_var, input$status_var, input$group_var)
  df_minimal <- df_sample[, essential_vars, drop = FALSE]
  
  return(df_minimal)
})
```

## Dependencies

### 필수 패키지

- `shiny` - 기본 Shiny 기능
- `survival` - 생존분석 함수
- `jskm` - Kaplan-Meier 플롯 생성
- `ggplot2` - 그래픽 시스템

### 선택적 패키지

- `survminer` - 생존곡선 고급 시각화
- `cmprsk` - 경쟁위험 분석
- `survey` - 가중 생존분석
- `DT` - 결과 테이블 표시

## Troubleshooting

### 일반적인 오류

```r
# 1. 시간 변수가 음수인 경우
# 해결: 시간 변수 검증 및 변환

# 2. 상태 변수가 0/1이 아닌 경우
# 해결: 이벤트 인코딩 확인 및 변환

# 3. 모든 관측치가 중도절단인 경우
# 해결: 데이터 확인 및 이벤트 정의 재검토

# 4. 생존곡선이 그려지지 않는 경우
# 해결: 변수 타입 및 결측치 확인
```

## See Also

- `survival::survfit()` - Kaplan-Meier 추정
- `jskm::jskm()` - 한국형 생존곡선 플롯
- `survminer::ggsurvplot()` - ggplot2 기반 생존곡선
- `cox.R` - Cox 회귀분석 모듈