# LLM 지시어: R PowerPoint 플롯 생성 (지능형 통합 버전)

## 목표
데이터를 시각화하여 PowerPoint에 삽입한다. 사용자가 플롯 유형을 지정하거나, 자연어로 요청하면 적절한 시각화를 자동 선택한다.

## 사용자 요청 해석
$ARGUMENTS를 분석하여 적절한 시각화를 선택한다:
- "막대 그래프 그려줘" → Bar plot with error bars
- "산점도 그려줘" → Scatter plot with regression
- "박스플롯 그려줘" → Box plot with p-values
- "생존 곡선 그려줘" → Kaplan-Meier curve
- "히트맵 그려줘" → Heatmap

## 핵심 처리 단계

### 1. 환경 설정 및 데이터 로드
```R
library(tidyverse)
library(ggplot2)
library(ggpubr)      # 출판 품질 플롯
library(officer)     # PowerPoint 출력
library(rvg)         # 벡터 그래픽
library(scales)      # 축 포맷팅
library(RColorBrewer) # 색상 팔레트

# 데이터 로드
data <- readRDS("$DATA_FILE")

# 요청 파싱
request <- tolower("$ARGUMENTS")
```

### 2. 출판 품질 테마 자동 설정
```R
# 지능형 테마 선택
theme_selection <- case_when(
  str_detect(request, "nature|lancet") ~ "nature",
  str_detect(request, "nejm|jama") ~ "nejm",
  str_detect(request, "presentation|프레젠테이션") ~ "presentation",
  TRUE ~ "publication"  # 기본값
)

# 선택된 테마 적용
publication_theme <- switch(theme_selection,
  "nature" = theme_classic() + theme(
    text = element_text(size = 10, family = "Arial"),
    axis.title = element_text(size = 11, face = "bold"),
    legend.position = "top"
  ),
  "nejm" = theme_minimal() + theme(
    text = element_text(size = 11, family = "Helvetica"),
    panel.grid.minor = element_blank(),
    legend.position = "bottom"
  ),
  "presentation" = theme_minimal() + theme(
    text = element_text(size = 14, face = "bold"),
    plot.title = element_text(size = 18, hjust = 0.5),
    axis.title = element_text(size = 14),
    legend.text = element_text(size = 12)
  ),
  # 기본 publication 테마
  theme_minimal() + theme(
    text = element_text(size = 12),
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
    axis.title = element_text(size = 12, face = "bold"),
    panel.grid.major = element_line(color = "grey90", size = 0.3),
    legend.position = "bottom"
  )
)

# 색상 팔레트 자동 선택
color_palette <- if(str_detect(request, "colorblind|색맹")) {
  c("#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2")
} else {
  c("#2E86AB", "#A23B72", "#F18F01", "#C73E1D", "#592941")
}
```

### 3. 지능형 플롯 생성

#### 3.1. 자동 플롯 유형 선택
```R
# 플롯 유형 자동 결정
plot_type <- case_when(
  str_detect(request, "bar|막대") ~ "bar",
  str_detect(request, "scatter|산점") ~ "scatter",
  str_detect(request, "box|박스") ~ "box",
  str_detect(request, "survival|생존") ~ "survival",
  str_detect(request, "heat|히트") ~ "heatmap",
  str_detect(request, "violin|바이올린") ~ "violin",
  str_detect(request, "histogram|히스토") ~ "histogram",
  TRUE ~ "auto"  # 데이터 구조에 따라 자동 결정
)

# 자동 플롯 선택
if(plot_type == "auto") {
  # 데이터 구조 분석
  numeric_vars <- data %>% select(where(is.numeric)) %>% names()
  factor_vars <- data %>% select(where(is.factor)) %>% names()
  
  plot_type <- case_when(
    length(factor_vars) > 0 & length(numeric_vars) > 0 ~ "box",
    length(numeric_vars) >= 2 ~ "scatter",
    length(factor_vars) >= 2 ~ "bar",
    TRUE ~ "histogram"
  )
}

cat("선택된 플롯 유형:", plot_type, "\n")
```

#### 3.2. 플롯 생성 함수
```R
# Bar Plot
if(plot_type == "bar") {
  # 범주형 변수 자동 선택
  cat_var <- data %>% select(where(is.factor)) %>% names() %>% first()
  num_var <- data %>% select(where(is.numeric)) %>% names() %>% first()
  
  if(!is.null(cat_var) & !is.null(num_var)) {
    summary_stats <- data %>%
      group_by(!!sym(cat_var)) %>%
      summarise(
        mean_val = mean(!!sym(num_var), na.rm = TRUE),
        se_val = sd(!!sym(num_var), na.rm = TRUE) / sqrt(n()),
        .groups = 'drop'
      )
    
    p <- ggplot(summary_stats, aes(x = !!sym(cat_var), y = mean_val, fill = !!sym(cat_var))) +
      geom_col(alpha = 0.8, width = 0.7) +
      geom_errorbar(aes(ymin = mean_val - se_val, ymax = mean_val + se_val),
                    width = 0.2, size = 0.8) +
      scale_fill_manual(values = color_palette) +
      labs(
        title = paste("그룹별", num_var, "비교"),
        x = cat_var,
        y = paste(num_var, "(Mean ± SE)")
      ) +
      publication_theme +
      theme(legend.position = "none")
  }
}

# Scatter Plot  
if(plot_type == "scatter") {
  numeric_vars <- data %>% select(where(is.numeric)) %>% names()
  
  if(length(numeric_vars) >= 2) {
    x_var <- numeric_vars[1]
    y_var <- numeric_vars[2]
    color_var <- data %>% select(where(is.factor)) %>% names() %>% first()
    
    p <- ggplot(data, aes(x = !!sym(x_var), y = !!sym(y_var))) +
      geom_point(alpha = 0.7, size = 2.5) +
      geom_smooth(method = "lm", se = TRUE, color = "blue") +
      labs(
        title = paste(x_var, "vs", y_var),
        x = x_var,
        y = y_var
      ) +
      publication_theme
    
    # 상관계수 추가
    correlation <- cor(data[[x_var]], data[[y_var]], use = "complete.obs")
    p <- p + annotate("text", x = Inf, y = Inf,
                      label = paste("r =", round(correlation, 3)),
                      hjust = 1.1, vjust = 1.5, size = 4)
    
    if(!is.null(color_var)) {
      p <- p + aes(color = !!sym(color_var)) +
        scale_color_manual(values = color_palette)
    }
  }
}

# Box Plot
if(plot_type == "box") {
  cat_var <- data %>% select(where(is.factor)) %>% names() %>% first()
  num_var <- data %>% select(where(is.numeric)) %>% names() %>% first()
  
  if(!is.null(cat_var) & !is.null(num_var)) {
    p <- ggplot(data, aes(x = !!sym(cat_var), y = !!sym(num_var), fill = !!sym(cat_var))) +
      geom_boxplot(alpha = 0.8, outlier.shape = 21) +
      geom_jitter(width = 0.2, alpha = 0.3, size = 1) +
      scale_fill_manual(values = color_palette) +
      labs(
        title = paste("그룹별", num_var, "분포"),
        x = cat_var,
        y = num_var
      ) +
      publication_theme +
      theme(legend.position = "none")
    
    # p-value 추가
    if(n_distinct(data[[cat_var]]) == 2) {
      p <- p + stat_compare_means(method = "t.test", label = "p.format")
    } else {
      p <- p + stat_compare_means(method = "anova", label = "p.format")
    }
  }
}

print(p)
```

### 4. 특수 플롯 자동 생성

```R
# 생존 분석
if(plot_type == "survival") {
  library(survival)
  library(survminer)
  
  # 시간/이벤트 변수 자동 감지
  time_vars <- names(data)[str_detect(names(data), "time|day|month|year")]
  event_vars <- names(data)[str_detect(names(data), "event|status|death")]
  
  if(length(time_vars) > 0 & length(event_vars) > 0) {
    group_var <- data %>% select(where(is.factor)) %>% names() %>% first()
    
    if(!is.null(group_var)) {
      formula_str <- paste0("Surv(", time_vars[1], ", ", event_vars[1], ") ~ ", group_var)
    } else {
      formula_str <- paste0("Surv(", time_vars[1], ", ", event_vars[1], ") ~ 1")
    }
    
    fit <- survfit(as.formula(formula_str), data = data)
    
    p <- ggsurvplot(
      fit,
      data = data,
      pval = TRUE,
      conf.int = TRUE,
      risk.table = TRUE,
      palette = color_palette,
      ggtheme = publication_theme,
      title = "Kaplan-Meier Survival Curve"
    )$plot
  }
}

# 히트맵
if(plot_type == "heatmap") {
  library(pheatmap)
  
  # 수치형 변수만 선택
  numeric_data <- data %>% select(where(is.numeric))
  
  if(ncol(numeric_data) > 1) {
    # 상관 행렬 계산
    cor_matrix <- cor(numeric_data, use = "complete.obs")
    
    # 히트맵 생성 (기본 ggplot 객체가 아니므로 별도 처리)
    pheatmap(
      cor_matrix,
      color = colorRampPalette(c("blue", "white", "red"))(100),
      display_numbers = TRUE,
      number_format = "%.2f",
      main = "Correlation Heatmap"
    )
  }
}
```

### 5. PowerPoint 자동 생성

```R
# PowerPoint 출력이 요청된 경우
if(!is.null("$OUTPUT_FILE") & str_ends("$OUTPUT_FILE", ".pptx")) {
  
  # 새 PowerPoint 문서 생성
  ppt <- read_pptx()
  
  # 제목 슬라이드
  ppt <- add_slide(ppt, layout = "Title Slide")
  ppt <- ph_with(ppt, value = "데이터 분석 결과", 
                 location = ph_location_type(type = "title"))
  ppt <- ph_with(ppt, value = paste("생성 시간:", Sys.Date()), 
                 location = ph_location_type(type = "subTitle"))
  
  # 플롯 슬라이드 추가
  if(exists("p")) {
    ppt <- add_slide(ppt, layout = "Title and Content")
    
    # 제목 자동 생성
    plot_title <- switch(plot_type,
      "bar" = "그룹별 비교 분석",
      "scatter" = "상관관계 분석",
      "box" = "분포 비교 분석",
      "survival" = "생존 분석",
      "heatmap" = "상관 히트맵",
      "데이터 시각화"
    )
    
    ppt <- ph_with(ppt, value = plot_title, 
                   location = ph_location_type(type = "title"))
    ppt <- ph_with(ppt, value = dml(ggobj = p), 
                   location = ph_location_type(type = "body"))
  }
  
  # 통계 요약 슬라이드 추가
  if(plot_type %in% c("bar", "box")) {
    ppt <- add_slide(ppt, layout = "Title and Content")
    ppt <- ph_with(ppt, value = "통계 요약", 
                   location = ph_location_type(type = "title"))
    
    # 통계 요약 텍스트 생성
    stats_text <- paste(
      "플롯 유형:", plot_type, "\n",
      "데이터 크기:", nrow(data), "rows ×", ncol(data), "columns\n",
      "결측치:", sum(is.na(data)), "\n",
      "생성 시간:", Sys.time()
    )
    
    ppt <- ph_with(ppt, value = stats_text, 
                   location = ph_location_type(type = "body"))
  }
  
  # PowerPoint 파일 저장
  print(ppt, target = "$OUTPUT_FILE")
  cat("PowerPoint 파일 생성 완료:", "$OUTPUT_FILE", "\n")
  
} else {
  # 화면에만 표시
  if(exists("p")) {
    print(p)
  }
  cat("\n플롯 생성 완료\n")
  cat("PowerPoint로 내보내려면 --output 옵션으로 .pptx 파일을 지정하세요.\n")
}
```

## 사용자 입력 처리
$ARGUMENTS를 파싱하여:
- --data 또는 첫 번째 인수: RDS 데이터 파일
- --type: 플롯 유형 (bar, scatter, box, survival, heatmap)
- --x: X축 변수명 (자동 선택)
- --y: Y축 변수명 (자동 선택)
- --group: 그룹 변수명 (자동 선택)
- --output: PowerPoint 파일명 (.pptx)
- --theme: 테마 선택 (nature, nejm, lancet, presentation)
- --colorblind: 색맹 친화적 색상 사용

또는 자연어 요청: "막대 그래프 그려줘", "생존 곡선 그려줘" 등
