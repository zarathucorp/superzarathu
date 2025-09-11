# forestcox Documentation

## Overview

`forestcox.R`은 jsmodule 패키지의 Cox 회귀분석 결과를 시각화하는 Forest Plot 모듈로, Shiny 애플리케이션에서 생존분석의 하위집단 분석 결과를 직관적인 forest plot으로 표현하는 기능을 제공합니다. 이 모듈은 다양한 하위집단별 위험비(Hazard Ratio)와 신뢰구간을 시각적으로 비교할 수 있게 하며, 경쟁위험 분석과 클러스터 분석도 지원합니다.

## Module Components

### `forestcoxUI(id, label = "forestplot")`

Forest plot 생성을 위한 Shiny 모듈 UI를 생성합니다.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `id` | character | - | 모듈의 고유 식별자 |
| `label` | character | "forestplot" | Forest plot 모듈 레이블 |

#### Returns

Shiny UI 객체 (forest plot 설정을 위한 다양한 입력 컨트롤들)

#### UI Components

- 클러스터 선택
- 그룹 및 하위집단 변수 선택
- 종속변수 및 시간변수 선택
- 공변량 선택
- 경쟁위험 분석 옵션
- 커스텀 forest plot 설정

### `forestcoxServer(id, data, data_label, data_varStruct = NULL, nfactor.limit = 10, design.survey = NULL, cluster_id = NULL, vec.event = NULL, vec.time = NULL)`

Forest plot 생성 및 관련 분석을 위한 서버 사이드 로직을 제공합니다.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `id` | character | - | 모듈의 고유 식별자 |
| `data` | reactive | - | 반응형 데이터 소스 |
| `data_label` | reactive | - | 반응형 데이터 레이블 |
| `data_varStruct` | list | NULL | 변수 구조 정보 |
| `nfactor.limit` | integer | 10 | 범주형 변수 레벨 최대 개수 |
| `design.survey` | reactive | NULL | 반응형 설문조사 설계 |
| `cluster_id` | character | NULL | 마진 Cox 모델용 클러스터 변수 |
| `vec.event` | character | NULL | 생존분석용 이벤트 변수들 |
| `vec.time` | character | NULL | 생존분석용 시간 변수들 |

#### Returns

다음을 포함하는 반응형 리스트:
1. 하위집단 분석 데이터 테이블
2. Forest plot 시각화

#### Key Features

- 표준 및 경쟁위험 생존분석 지원
- 유연한 하위집단 및 공변량 선택
- 커스터마이징 가능한 forest plot 외관
- Forest plot 내보내기 옵션

## Usage Examples

### 기본 사용법

```r
library(shiny)
library(jsmodule)
library(survival)
library(forestplot)
library(DT)

# UI 정의
ui <- fluidPage(
  titlePanel("Cox Regression Forest Plot Analysis"),
  sidebarLayout(
    sidebarPanel(
      forestcoxUI("forest_analysis", label = "Forest Plot 분석"),
      hr(),
      downloadButton("download_plot", "Forest Plot 다운로드")
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Forest Plot", 
                 plotOutput("forest_plot", height = "800px")),
        tabPanel("Subgroup Table", 
                 DT::DTOutput("subgroup_table")),
        tabPanel("Overall Model", 
                 verbatimTextOutput("overall_model")),
        tabPanel("Summary Statistics", 
                 verbatimTextOutput("summary_stats"))
      )
    )
  )
)

server <- function(input, output, session) {
  # 예시 생존분석 데이터
  data_input <- reactive({
    data(colon, package = "survival")
    
    # 데이터 전처리
    colon_processed <- colon %>%
      mutate(
        rx = factor(rx, labels = c("Observation", "Levamisole", "Lev+5FU")),
        sex = factor(sex, labels = c("Female", "Male")),
        age_group = factor(ifelse(age > median(age, na.rm = TRUE), "Older", "Younger")),
        obstruct = factor(obstruct, labels = c("No", "Yes")),
        perfor = factor(perfor, labels = c("No", "Yes")),
        differ = factor(differ, labels = c("Well", "Moderate", "Poor")),
        nodes_group = factor(ifelse(nodes > median(nodes, na.rm = TRUE), "High", "Low"))
      ) %>%
      filter(!is.na(time) & !is.na(status) & time > 0)
    
    colon_processed
  })
  
  data_label <- reactive({
    data.frame(
      variable = names(data_input()),
      label = c("ID", "Study", "Treatment", "Sex", "Age", "Obstruction",
               "Perforated", "Adherence", "Nodes", "Time", "Status", 
               "Differentiation", "Extent", "Surgery time", "Age Group",
               "Time to recurrence", "Recurrence status", "Time to death", 
               "Death status", "Nodes Group"),
      stringsAsFactors = FALSE
    )
  })
  
  # Forest plot 모듈 서버
  forest_result <- callModule(forestcoxServer, "forest_analysis",
                             data = data_input,
                             data_label = data_label,
                             nfactor.limit = 20)
  
  # Forest plot 출력
  output$forest_plot <- renderPlot({
    req(forest_result())
    if(!is.null(forest_result()$plot)) {
      forest_result()$plot
    }
  })
  
  # 하위집단 분석 테이블 출력
  output$subgroup_table <- DT::renderDT({
    req(forest_result())
    if(!is.null(forest_result()$table)) {
      DT::datatable(forest_result()$table,
                    options = list(scrollX = TRUE, pageLength = 15),
                    rownames = FALSE) %>%
        DT::formatRound(columns = c("HR", "Lower", "Upper"), digits = 3) %>%
        DT::formatRound(columns = "P value", digits = 4)
    }
  })
  
  # 전체 모델 요약
  output$overall_model <- renderPrint({
    req(data_input())
    
    df <- data_input()
    
    if(all(c("time", "status", "rx") %in% names(df))) {
      cat("Overall Cox Regression Model\n")
      cat("============================\n\n")
      
      # 전체 모델
      overall_cox <- coxph(Surv(time, status) ~ rx + sex + age + obstruct, 
                          data = df)
      
      print(summary(overall_cox))
      
      cat("\nModel Statistics:\n")
      cat("Sample size:", overall_cox$n, "\n")
      cat("Number of events:", overall_cox$nevent, "\n")
      cat("Concordance:", round(overall_cox$concordance[1], 4), "\n")
    }
  })
  
  # 요약 통계
  output$summary_stats <- renderPrint({
    req(data_input())
    
    df <- data_input()
    
    cat("Dataset Summary\n")
    cat("===============\n\n")
    
    cat("Total observations:", nrow(df), "\n")
    
    if("status" %in% names(df)) {
      events <- sum(df$status, na.rm = TRUE)
      cat("Total events:", events, "\n")
      cat("Event rate:", round(events/nrow(df)*100, 1), "%\n\n")
    }
    
    if("time" %in% names(df)) {
      cat("Follow-up time:\n")
      cat("  Median:", round(median(df$time, na.rm = TRUE), 1), "\n")
      cat("  Range:", round(min(df$time, na.rm = TRUE), 1), "-", 
          round(max(df$time, na.rm = TRUE), 1), "\n\n")
    }
    
    # 범주형 변수 요약
    categorical_vars <- df %>% select_if(is.factor) %>% names()
    
    if(length(categorical_vars) > 0) {
      cat("Categorical Variables Summary:\n")
      for(var in categorical_vars[1:min(5, length(categorical_vars))]) {
        cat("\n", var, ":\n")
        print(table(df[[var]], useNA = "ifany"))
      }
    }
  })
}

shinyApp(ui = ui, server = server)
```

### 고급 사용법

```r
# 복잡한 하위집단 분석 워크플로
server <- function(input, output, session) {
  # 데이터 입력 모듈 연동
  data_input <- callModule(csvFile, "datafile")
  
  # Forest plot 분석
  forest_analysis <- callModule(forestcoxServer, "forest_viz",
                               data = reactive(data_input()$data),
                               data_label = reactive(data_input()$label))
  
  # 다중 변수별 하위집단 분석
  multiple_subgroup_analysis <- reactive({
    req(data_input()$data)
    
    df <- data_input()$data
    
    # 생존분석에 필요한 변수 확인
    if(all(c("time", "status") %in% names(df))) {
      # 하위집단 변수 후보들
      categorical_vars <- df %>% select_if(is.factor) %>% names()
      
      if(length(categorical_vars) >= 2) {
        subgroup_results <- list()
        
        for(subgroup_var in categorical_vars[1:min(3, length(categorical_vars))]) {
          # 각 하위집단별 Cox 모델
          subgroup_levels <- unique(df[[subgroup_var]])
          
          level_results <- data.frame()
          
          for(level in subgroup_levels) {
            subset_data <- df[df[[subgroup_var]] == level, ]
            
            if(nrow(subset_data) >= 10) {  # 최소 표본 크기
              tryCatch({
                # 주요 치료 변수로 Cox 모델 적합
                treatment_vars <- names(df)[grepl("treat|rx|group", tolower(names(df)))]
                
                if(length(treatment_vars) >= 1) {
                  formula_str <- paste("Surv(time, status) ~", treatment_vars[1])
                  cox_model <- coxph(as.formula(formula_str), data = subset_data)
                  
                  summary_cox <- summary(cox_model)
                  
                  level_results <- rbind(level_results, data.frame(
                    Subgroup = paste(subgroup_var, "=", level),
                    N = nrow(subset_data),
                    Events = sum(subset_data$status, na.rm = TRUE),
                    HR = round(summary_cox$coefficients[1, "exp(coef)"], 3),
                    Lower_CI = round(summary_cox$conf.int[1, "lower .95"], 3),
                    Upper_CI = round(summary_cox$conf.int[1, "upper .95"], 3),
                    P_value = round(summary_cox$coefficients[1, "Pr(>|z|)"], 4)
                  ))
                }
              }, error = function(e) NULL)
            }
          }
          
          if(nrow(level_results) > 0) {
            subgroup_results[[subgroup_var]] <- level_results
          }
        }
        
        return(subgroup_results)
      }
    }
  })
  
  # 상호작용 분석
  interaction_analysis <- reactive({
    req(data_input()$data)
    
    df <- data_input()$data
    
    if(all(c("time", "status") %in% names(df))) {
      categorical_vars <- df %>% select_if(is.factor) %>% names()
      treatment_vars <- names(df)[grepl("treat|rx|group", tolower(names(df)))]
      
      if(length(categorical_vars) >= 2 && length(treatment_vars) >= 1) {
        interaction_results <- data.frame()
        
        treatment_var <- treatment_vars[1]
        
        for(interact_var in categorical_vars[1:min(3, length(categorical_vars))]) {
          if(interact_var != treatment_var) {
            tryCatch({
              # 상호작용 모델
              formula_str <- paste("Surv(time, status) ~", treatment_var, "*", interact_var)
              interaction_model <- coxph(as.formula(formula_str), data = df)
              
              # 상호작용 항의 유의성 검정
              anova_result <- anova(interaction_model)
              
              # 상호작용 항 p-value 추출
              interaction_p <- anova_result[nrow(anova_result), "P(>|Chi|)"]
              
              interaction_results <- rbind(interaction_results, data.frame(
                Treatment = treatment_var,
                Interaction_Variable = interact_var,
                Interaction_P_value = round(interaction_p, 4),
                Significant_Interaction = ifelse(interaction_p < 0.05, "Yes", "No")
              ))
            }, error = function(e) NULL)
          }
        }
        
        return(interaction_results)
      }
    }
  })
  
  # 사용자 정의 Forest Plot
  custom_forest_plot <- reactive({
    req(multiple_subgroup_analysis())
    
    # 모든 하위집단 결과를 하나로 합치기
    all_results <- do.call(rbind, multiple_subgroup_analysis())
    
    if(nrow(all_results) > 0) {
      # Forest plot 데이터 준비
      plot_data <- all_results %>%
        mutate(
          ci_text = paste0(HR, " (", Lower_CI, "-", Upper_CI, ")"),
          significant = ifelse(P_value < 0.05, "Significant", "Not Significant")
        )
      
      # Forest plot 생성
      p <- ggplot(plot_data, aes(x = HR, y = reorder(Subgroup, HR))) +
        geom_vline(xintercept = 1, linetype = "dashed", color = "red", alpha = 0.7) +
        geom_errorbarh(aes(xmin = Lower_CI, xmax = Upper_CI, color = significant),
                      height = 0.2, size = 1) +
        geom_point(aes(color = significant, size = N), alpha = 0.8) +
        scale_color_manual(values = c("Significant" = "red", "Not Significant" = "blue")) +
        scale_size_continuous(range = c(2, 5), name = "Sample Size") +
        scale_x_log10(breaks = c(0.25, 0.5, 1, 2, 4, 8)) +
        labs(
          title = "Forest Plot: Subgroup Analysis",
          x = "Hazard Ratio (95% CI)",
          y = "Subgroups",
          color = "Statistical Significance"
        ) +
        theme_minimal() +
        theme(
          plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
          axis.text.y = element_text(size = 10),
          legend.position = "bottom"
        )
      
      # CI 텍스트 추가
      p <- p + 
        geom_text(aes(label = ci_text), 
                 hjust = -0.1, size = 3.5, 
                 color = "black")
      
      return(p)
    }
  })
  
  # 다중 하위집단 분석 결과 출력
  output$multiple_subgroup <- renderUI({
    results <- multiple_subgroup_analysis()
    req(results)
    
    output_list <- list()
    
    for(var_name in names(results)) {
      output_list[[var_name]] <- div(
        h4(paste("Subgroup Analysis:", var_name)),
        renderDT({
          DT::datatable(results[[var_name]],
                       options = list(dom = 't', pageLength = -1),
                       rownames = FALSE) %>%
            DT::formatRound(columns = c("HR", "Lower_CI", "Upper_CI"), digits = 3) %>%
            DT::formatRound(columns = "P_value", digits = 4)
        }),
        br()
      )
    }
    
    do.call(tagList, output_list)
  })
  
  # 사용자 정의 Forest Plot 출력
  output$custom_forest <- renderPlot({
    req(custom_forest_plot())
    custom_forest_plot()
  }, height = 600)
  
  # 상호작용 분석 결과
  output$interaction_analysis <- DT::renderDT({
    req(interaction_analysis())
    
    DT::datatable(interaction_analysis(),
                 options = list(dom = 't', pageLength = -1),
                 rownames = FALSE) %>%
      DT::formatRound(columns = "Interaction_P_value", digits = 4)
  })
}
```

## Forest Plot Visualization Features

### 지원하는 플롯 유형

#### 기본 Forest Plot
```r
# 표준 forest plot with hazard ratios
basic_forest_plot <- function(results_data) {
  forestplot::forestplot(
    labeltext = results_data$labels,
    mean = results_data$HR,
    lower = results_data$Lower_CI,
    upper = results_data$Upper_CI,
    title = "Forest Plot: Cox Regression Results",
    xlab = "Hazard Ratio (95% CI)"
  )
}
```

#### 하위집단별 Forest Plot
```r
# 하위집단별 분석 결과 시각화
subgroup_forest_plot <- function(subgroup_data) {
  # 하위집단별 결과를 색상으로 구분
  ggplot(subgroup_data, aes(x = HR, y = reorder(Subgroup, HR))) +
    geom_vline(xintercept = 1, linetype = "dashed", color = "gray") +
    geom_errorbarh(aes(xmin = Lower_CI, xmax = Upper_CI, color = Subgroup_Category),
                  height = 0.3) +
    geom_point(aes(color = Subgroup_Category, size = Sample_Size)) +
    scale_x_log10() +
    theme_minimal()
}
```

#### 상호작용 Forest Plot
```r
# 상호작용 효과를 보여주는 forest plot
interaction_forest_plot <- function(interaction_data) {
  # 상호작용 유무에 따른 시각적 구분
  ggplot(interaction_data, aes(x = HR, y = Subgroup)) +
    geom_vline(xintercept = 1, linetype = "dashed") +
    geom_errorbarh(aes(xmin = Lower_CI, xmax = Upper_CI, 
                      color = Significant_Interaction),
                  height = 0.2) +
    geom_point(aes(color = Significant_Interaction), size = 3) +
    facet_wrap(~Interaction_Variable, scales = "free_y") +
    scale_color_manual(values = c("Yes" = "red", "No" = "blue"))
}
```

### 통계적 분석 기능

#### 이질성 검정
```r
# 하위집단 간 이질성 검정
heterogeneity_test <- function(subgroup_results) {
  # Cochran's Q test for heterogeneity
  q_statistic <- sum((log(subgroup_results$HR) - 
                     weighted.mean(log(subgroup_results$HR), 
                                  1/subgroup_results$SE^2))^2 / 
                    subgroup_results$SE^2)
  
  df <- length(subgroup_results$HR) - 1
  p_value <- pchisq(q_statistic, df, lower.tail = FALSE)
  
  # I² statistic
  i_squared <- max(0, (q_statistic - df) / q_statistic * 100)
  
  return(list(
    Q = q_statistic,
    df = df,
    p_value = p_value,
    I_squared = i_squared
  ))
}
```

#### 메타분석 결합 추정치
```r
# 고정효과 메타분석 결합 추정치
fixed_effect_meta <- function(subgroup_results) {
  weights <- 1 / subgroup_results$SE^2
  
  combined_log_hr <- weighted.mean(log(subgroup_results$HR), weights)
  combined_se <- sqrt(1 / sum(weights))
  
  combined_hr <- exp(combined_log_hr)
  lower_ci <- exp(combined_log_hr - 1.96 * combined_se)
  upper_ci <- exp(combined_log_hr + 1.96 * combined_se)
  
  return(list(
    HR = combined_hr,
    Lower_CI = lower_ci,
    Upper_CI = upper_ci,
    SE = combined_se
  ))
}
```

## Advanced Features

### 경쟁위험 분석 Forest Plot

```r
# 경쟁위험을 고려한 forest plot
competing_risks_forest <- function(data, event_var, time_var, treatment_var, competing_event) {
  # Fine-Gray 모델을 이용한 경쟁위험 분석
  if(requireNamespace("cmprsk", quietly = TRUE)) {
    
    # 각 하위집단별 경쟁위험 분석
    subgroups <- unique(data$subgroup_var)
    cr_results <- data.frame()
    
    for(subgroup in subgroups) {
      subset_data <- data[data$subgroup_var == subgroup, ]
      
      # 경쟁위험 분석
      cr_fit <- cmprsk::crr(subset_data[[time_var]], 
                           subset_data[[event_var]],
                           subset_data[[treatment_var]])
      
      cr_results <- rbind(cr_results, data.frame(
        Subgroup = subgroup,
        SHR = exp(cr_fit$coef),
        Lower_CI = exp(cr_fit$coef - 1.96 * sqrt(diag(cr_fit$var))),
        Upper_CI = exp(cr_fit$coef + 1.96 * sqrt(diag(cr_fit$var))),
        P_value = 2 * (1 - pnorm(abs(cr_fit$coef / sqrt(diag(cr_fit$var)))))
      ))
    }
    
    return(cr_results)
  }
}
```

### 동적 Forest Plot 업데이트

```r
# 사용자 선택에 따른 동적 forest plot 업데이트
dynamic_forest_update <- reactive({
  req(input$selected_subgroups, input$confidence_level)
  
  # 선택된 하위집단만 필터링
  filtered_data <- forest_data() %>%
    filter(Subgroup %in% input$selected_subgroups)
  
  # 신뢰수준 조정
  z_value <- qnorm(1 - (1 - input$confidence_level/100) / 2)
  
  updated_data <- filtered_data %>%
    mutate(
      Lower_CI = HR * exp(-z_value * SE),
      Upper_CI = HR * exp(z_value * SE)
    )
  
  return(updated_data)
})
```

### 개별 환자 예측

```r
# 개별 환자의 예측 위험도를 forest plot에 표시
individual_risk_prediction <- function(patient_data, model_results) {
  # 환자의 특성에 따른 예측 위험비 계산
  predicted_hr <- exp(sum(coef(cox_model) * patient_data[names(coef(cox_model))]))
  
  # 예측 구간 계산
  vcov_matrix <- vcov(cox_model)
  se_pred <- sqrt(t(patient_data[names(coef(cox_model))]) %*% 
                  vcov_matrix %*% 
                  patient_data[names(coef(cox_model))])
  
  pred_lower <- exp(log(predicted_hr) - 1.96 * se_pred)
  pred_upper <- exp(log(predicted_hr) + 1.96 * se_pred)
  
  return(list(
    Predicted_HR = predicted_hr,
    Lower_CI = pred_lower,
    Upper_CI = pred_upper
  ))
}
```

## Export and Download Features

### 고품질 Forest Plot 내보내기

```r
# 출판 품질 forest plot 생성
publication_forest_plot <- reactive({
  req(forest_result())
  
  # 고해상도 설정
  if(!is.null(forest_result()$plot)) {
    forest_result()$plot +
      theme_classic() +
      theme(
        text = element_text(size = 12, family = "Arial"),
        axis.title = element_text(size = 14, face = "bold"),
        axis.text = element_text(size = 11),
        plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
        legend.title = element_text(size = 12, face = "bold"),
        legend.text = element_text(size = 11),
        panel.grid.major.y = element_line(color = "gray90", size = 0.3),
        panel.grid.minor = element_blank()
      )
  }
})

# Forest plot 다운로드
output$download_forest_plot <- downloadHandler(
  filename = function() {
    paste("forest_plot_", Sys.Date(), ".", input$file_format, sep = "")
  },
  content = function(file) {
    ggsave(file, plot = publication_forest_plot(),
           width = input$plot_width, height = input$plot_height,
           dpi = 300, device = input$file_format)
  }
)
```

### 분석 결과 보고서

```r
# Forest plot 분석 보고서 생성
forest_analysis_report <- reactive({
  req(forest_result()$table)
  
  results_table <- forest_result()$table
  
  report_text <- paste0(
    "Forest Plot Analysis Report\n",
    "===========================\n\n",
    "Analysis Date: ", Sys.Date(), "\n",
    "Number of Subgroups: ", nrow(results_table), "\n\n",
    
    "Subgroup Analysis Results:\n"
  )
  
  for(i in 1:nrow(results_table)) {
    subgroup_name <- rownames(results_table)[i]
    hr <- results_table[i, "HR"]
    lower_ci <- results_table[i, "Lower"]
    upper_ci <- results_table[i, "Upper"]
    p_val <- results_table[i, "P value"]
    
    report_text <- paste0(report_text,
      sprintf("- %s: HR = %.3f (95%% CI: %.3f-%.3f), p = %.4f\n",
              subgroup_name, hr, lower_ci, upper_ci, p_val)
    )
  }
  
  return(report_text)
})
```

## Performance Optimization

### 대용량 데이터 처리

```r
# 효율적인 하위집단 분석
efficient_subgroup_analysis <- reactive({
  req(data_input()$data)
  
  df <- data_input()$data
  
  # 하위집단 크기 확인
  min_subgroup_size <- 20
  
  filtered_subgroups <- df %>%
    group_by(subgroup_var) %>%
    summarise(n = n(), .groups = "drop") %>%
    filter(n >= min_subgroup_size) %>%
    pull(subgroup_var)
  
  df_filtered <- df %>%
    filter(subgroup_var %in% filtered_subgroups)
  
  if(nrow(df_filtered) != nrow(df)) {
    showNotification(
      paste("Small subgroups (<", min_subgroup_size, "subjects) excluded from analysis"),
      type = "warning"
    )
  }
  
  return(df_filtered)
})
```

## Dependencies

### 필수 패키지

- `shiny` - 기본 Shiny 기능
- `survival` - 생존분석 함수
- `forestplot` - Forest plot 생성
- `ggplot2` - 그래픽 시각화

### 선택적 패키지

- `cmprsk` - 경쟁위험 분석
- `meta` - 메타분석 기능
- `survminer` - 생존분석 시각화

## Troubleshooting

### 일반적인 오류

```r
# 1. 하위집단 크기가 너무 작은 경우
# 해결: 최소 표본 크기 확인 및 그룹 결합

# 2. 수렴하지 않는 Cox 모델
# 해결: 변수 단순화 또는 정규화

# 3. Forest plot 범위 문제
# 해결: 축 범위 수동 설정 또는 이상치 제거

# 4. 너무 많은 하위집단
# 해결: 주요 하위집단 선택 또는 계층적 표시
```

## See Also

- `survival::coxph()` - Cox 회귀분석
- `forestplot::forestplot()` - Forest plot 생성
- `meta::metagen()` - 메타분석
- `coxph.R` - Cox 회귀분석 모듈