# LLM 지시어: 데이터 시각화 (jskm 통합)

## 사용자 요청
`{{USER_ARGUMENTS}}`

## AI Assistant Helper
웹검색이 가능한 경우, jskm 패키지의 최신 함수 사용법을 확인하세요:
- GitHub 소스코드: https://github.com/jinseob2kim/jskm/tree/master/R
- 패키지 문서: https://jinseob2kim.github.io/jskm/
- CRAN: https://cran.r-project.org/package=jskm
- 예제: https://github.com/jinseob2kim/jskm/tree/master/vignettes

## 프로젝트 구조
- 입력: `data/processed/` 폴더의 최신 RDS 파일 자동 사용
- 출력: `output/plots/` 폴더에 자동 저장
- 형식: PNG (기본), PDF, PPT 자동 선택

## ⚠️ 보안 및 성능 주의사항
- **그래프만 생성**: 원본 데이터를 텍스트로 출력하지 마세요
- **집계 시각화**: 개별 데이터포인트보다 집계된 패턴 표시
- **개인정보 제외**: 환자 ID 등을 축 레이블에 사용 금지
- **적절한 샘플링**: 대용량 데이터는 샘플링 후 시각화
- **plot() 직접 사용**: 데이터 전체를 print() 하지 마세요

## 주요 기능
- 기본 플롯: 막대, 선, 산점도, 박스플롯, 히스토그램
- 생존분석 플롯 (Kaplan-Meier, jskm)
- 상관관계 히트맵
- 인터랙티브 플롯 (plotly)
- 의학 통계 특화 시각화
- PowerPoint/PDF 자동 생성

## 플롯 타입 자동 선택
```r
detect_plot_type <- function(request, data) {
  request_lower <- tolower(request)
  
  # 키워드 기반 탐지
  if (grepl("생존|survival|kaplan|meier|km", request_lower)) {
    return("survival")
  } else if (grepl("상관|correlation|heatmap", request_lower)) {
    return("correlation")
  } else if (grepl("분포|distribution|histogram", request_lower)) {
    return("histogram")
  } else if (grepl("비교|compare|box", request_lower)) {
    return("boxplot")
  } else if (grepl("관계|relationship|scatter", request_lower)) {
    return("scatter")
  } else if (grepl("추세|trend|line|시간", request_lower)) {
    return("line")
  } else if (grepl("비율|proportion|bar|막대", request_lower)) {
    return("bar")
  }
  
  # 데이터 타입 기반 추천
  return(suggest_by_data(data))
}
```

## 패키지 정보
- **jskm**: Kaplan-Meier 생존곡선 시각화 패키지
  - GitHub: https://github.com/jinseob2kim/jskm
  - 주요 함수: jskm(), svyjskm()
  - 문서: https://jinseob2kim.github.io/jskm/
  - 예제: https://github.com/jinseob2kim/jskm/tree/master/vignettes

## 구현 지침

### 📍 스크립트 위치
- **기본 플롯 함수**: `scripts/plots/plot_basic.R`에 추가
- **정적 플롯 함수**: `scripts/plots/plot_static.R`에 추가
- **인터랙티브 플롯**: `scripts/plots/plot_interactive.R`에 추가
- **실행 스크립트**: `scripts/analysis/02_statistical.R` 또는 `run_analysis.R`에서 호출

### 1. 생존분석 플롯 (jskm)
```r
library(jskm)
library(survival)
# 최신 함수 사용법은 https://github.com/jinseob2kim/jskm/blob/master/R/jskm.R 참고

create_km_plot <- function(data, time_var, event_var, group_var = NULL) {
  # Survival object 생성
  surv_formula <- as.formula(paste0("Surv(", time_var, ", ", event_var, ") ~ ", 
                                    ifelse(is.null(group_var), "1", group_var)))
  
  fit <- survfit(surv_formula, data = data)
  
  # jskm으로 아름다운 KM curve 생성
  p <- jskm(
    fit,
    main = "Kaplan-Meier Survival Curve",
    ylab = "Survival Probability",
    xlab = "Time",
    table = TRUE,           # Risk table 표시
    pval = TRUE,           # P-value 표시
    pval.size = 5,
    pval.coord = c(0.1, 0.1),
    marks = TRUE,          # Censoring marks
    linecols = "Set1",     # 색상 팔레트
    legendposition = c(0.85, 0.8),
    ci = TRUE,             # 신뢰구간
    cumhaz = FALSE,        # 누적 위험 대신 생존확률
    cluster.option = "cluster",
    cluster.var = NULL,
    data = data
  )
  
  return(p)
}

# Cox regression forest plot
create_forest_plot <- function(cox_model) {
  library(survminer)
  ggforest(
    cox_model,
    data = model.frame(cox_model),
    main = "Hazard Ratios",
    fontsize = 0.8
  )
}
```

### 2. 분포 시각화
```r
create_distribution_plot <- function(data, var, group = NULL, type = "histogram") {
  p <- ggplot(data, aes(x = .data[[var]]))
  
  if (type == "histogram") {
    p <- p + geom_histogram(aes(fill = .data[[group]]), 
                           bins = 30, alpha = 0.7, position = "identity")
  } else if (type == "density") {
    p <- p + geom_density(aes(color = .data[[group]], fill = .data[[group]]), 
                         alpha = 0.3)
  } else if (type == "violin") {
    p <- p + geom_violin(aes(x = .data[[group]], fill = .data[[group]]))
  }
  
  p <- p + 
    theme_minimal() +
    labs(title = paste("Distribution of", var))
  
  return(p)
}
```

### 3. 그룹 비교 플롯
```r
create_comparison_plot <- function(data, x_var, y_var, type = "box") {
  p <- ggplot(data, aes(x = .data[[x_var]], y = .data[[y_var]]))
  
  if (type == "box") {
    p <- p + 
      geom_boxplot(aes(fill = .data[[x_var]]), alpha = 0.7) +
      geom_jitter(width = 0.2, alpha = 0.3) +
      stat_compare_means()  # p-value 추가
  } else if (type == "violin") {
    p <- p + 
      geom_violin(aes(fill = .data[[x_var]]), alpha = 0.7) +
      geom_boxplot(width = 0.1, fill = "white")
  } else if (type == "bar") {
    p <- p + 
      stat_summary(fun = mean, geom = "bar", aes(fill = .data[[x_var]])) +
      stat_summary(fun.data = mean_se, geom = "errorbar", width = 0.2)
  }
  
  p <- p + 
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  
  return(p)
}
```

### 4. 상관관계 히트맵
```r
create_correlation_heatmap <- function(data, method = "pearson", cluster = TRUE) {
  # 숫자형 변수만 선택
  numeric_data <- data[sapply(data, is.numeric)]
  
  # 상관계수 계산
  cor_matrix <- cor(numeric_data, use = "complete.obs", method = method)
  
  # 클러스터링 (선택)
  if (cluster) {
    library(pheatmap)
    p <- pheatmap(
      cor_matrix,
      display_numbers = TRUE,
      number_format = "%.2f",
      color = colorRampPalette(c("blue", "white", "red"))(100),
      cluster_rows = TRUE,
      cluster_cols = TRUE,
      main = "Correlation Heatmap"
    )
  } else {
    # ggplot2 버전
    library(reshape2)
    melted <- melt(cor_matrix)
    p <- ggplot(melted, aes(Var1, Var2, fill = value)) +
      geom_tile() +
      geom_text(aes(label = round(value, 2)), size = 3) +
      scale_fill_gradient2(low = "blue", high = "red", mid = "white", 
                          midpoint = 0, limit = c(-1, 1)) +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
  }
  
  return(p)
}
```

### 5. 인터랙티브 플롯
```r
create_interactive_plot <- function(static_plot) {
  library(plotly)
  ggplotly(static_plot, tooltip = "all")
}
```

### 6. 플롯 저장 및 내보내기
```r
save_plots <- function(plots, filename = "plots", format = "pptx") {
  if (format == "pptx") {
    library(officer)
    library(rvg)
    
    ppt <- read_pptx()
    
    for (i in seq_along(plots)) {
      ppt <- ppt %>%
        add_slide(layout = "Title and Content", master = "Office Theme") %>%
        ph_with(dml(ggobj = plots[[i]]), location = ph_location_type(type = "body"))
    }
    
    print(ppt, target = paste0(filename, ".pptx"))
    
  } else if (format == "pdf") {
    pdf(paste0(filename, ".pdf"), width = 10, height = 8)
    for (p in plots) print(p)
    dev.off()
    
  } else if (format == "png") {
    for (i in seq_along(plots)) {
      ggsave(paste0(filename, "_", i, ".png"), plots[[i]], 
             width = 10, height = 8, dpi = 300)
    }
  }
}
```

### 7. 테마 및 스타일
```r
# 의학 논문 스타일
apply_medical_theme <- function(plot) {
  plot + 
    theme_classic() +
    theme(
      text = element_text(size = 12, family = "Arial"),
      axis.line = element_line(size = 0.5),
      axis.text = element_text(color = "black"),
      legend.position = "bottom",
      panel.grid.major = element_line(color = "gray90", size = 0.25)
    )
}
```

## 사용 예시
```r
# 기본: 데이터 탐색 플롯
"데이터 시각화해줘"

# 생존분석 플롯
"생존곡선 그려줘"
"Kaplan-Meier 플롯 만들어줘"

# 분포 시각화
"연령별 혈압 분포를 박스플롯으로 보여줘"
"BMI 분포 히스토그램 그려줘"

# 그룹 비교
"치료군별 결과 비교 그래프"
"성별에 따른 콜레스테롤 수치 차이"

# 상관관계
"변수들 간의 상관관계 히트맵 보여줘"

# PPT 생성
"모든 주요 그래프를 PPT로 만들어줘"
```

## 스마트 기능
- AI 기반 플롯 타입 자동 선택
- 최적 시각화 방법 제안
- 자동 레이아웃 및 스타일링
- 의학 논문용 포맷 자동 적용
- 다중 플롯 일괄 생성