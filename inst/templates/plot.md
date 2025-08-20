# LLM 지시어: R PowerPoint 플롯 생성 및 삽입

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
df <- readRDS("<path/to/your/labeled_data.rds>")

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
    text = element_text(size = 12, color = "black"),
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
    axis.title = element_text(size = 12, face = "bold"),
    axis.text = element_text(size = 10, color = "black"),
    legend.title = element_text(size = 11, face = "bold"),
    legend.text = element_text(size = 10),
    
    # 배경 및 격자선
    panel.background = element_rect(fill = "white", color = NA),
    plot.background = element_rect(fill = "white", color = NA),
    panel.grid.major = element_line(color = "grey90", size = 0.3),
    panel.grid.minor = element_line(color = "grey95", size = 0.2),
    
    # 축선 설정
    axis.line = element_line(color = "black", size = 0.5),
    axis.ticks = element_line(color = "black", size = 0.3),
    
    # 범례 설정
    legend.position = "bottom",
    legend.box = "horizontal",
    legend.margin = margin(t = 10),
    
    # 여백 설정
    plot.margin = margin(t = 20, r = 20, b = 20, l = 20)
  )

# 의료/바이오 분야에 적합한 색상 팔레트
medical_colors <- c("#2E86AB", "#A23B72", "#F18F01", "#C73E1D", "#592941")
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
    title = "그룹별 <변수명> 비교",
    x = "<그룹_라벨>",
    y = "<변수_라벨> (Mean ± SE)",
    fill = "<그룹_라벨>"
  ) +
  publication_theme +
  theme(legend.position = "none") # 범례 제거 (x축에 이미 정보 있음)

print(p_barplot)
```

#### 4.2. 산점도 및 상관관계 (Scatter Plot)
```R
# 두 연속형 변수 간 상관관계 시각화
p_scatter <- ggplot(df, aes(x = `<x축_변수>`, y = `<y축_변수>`, color = `<그룹_변수>`)) +
  geom_point(alpha = 0.7, size = 2.5) +
  geom_smooth(method = "lm", se = TRUE, size = 1.2) +
  scale_color_manual(values = medical_colors) +
  labs(
    title = "<x축_변수>와 <y축_변수>의 상관관계",
    x = "<x축_라벨>",
    y = "<y축_라벨>",
    color = "<그룹_라벨>"
  ) +
  publication_theme

# 상관계수 추가 (선택사항)
correlation <- cor(df$`<x축_변수>`, df$`<y축_변수>`, use = "complete.obs")
p_scatter <- p_scatter +
  annotate("text", x = Inf, y = Inf, 
           label = paste("r =", round(correlation, 3)),
           hjust = 1.1, vjust = 1.5, size = 4, fontface = "bold")

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
    title = "그룹별 <변수명> 분포 비교",
    x = "<그룹_라벨>",
    y = "<변수_라벨>",
    fill = "<그룹_라벨>"
  ) +
  publication_theme +
  theme(legend.position = "none")

# 통계적 유의성 표시 (ggpubr 사용)
if(requireNamespace("ggpubr", quietly = TRUE)) {
  p_boxplot <- p_boxplot + 
    ggpubr::stat_compare_means(method = "t.test", 
                               label = "p.format", 
                               size = 4)
}

print(p_boxplot)
```

#### 4.4. Kaplan-Meier 생존곡선 (jskm 패키지 활용)
```R
# 생존 분석이 필요한 경우
if(requireNamespace("survival", quietly = TRUE) && 
   requireNamespace("jskm", quietly = TRUE)) {
  
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
    ystrataname = "<그룹_라벨>",
    timeby = 365, # 1년 단위
    xlims = c(0, max(df$`<시간_변수>`, na.rm = TRUE)),
    ylims = c(0, 1),
    xlab = "Time (days)",
    ylab = "Survival Probability",
    main = "Kaplan-Meier Survival Curve"
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
ppt <- add_slide(ppt, layout = "Title Slide", master = "Office Theme")
ppt <- ph_with(ppt, value = "의료 데이터 분석 결과", location = ph_location_label(ph_label = "Title 1"))
ppt <- ph_with(ppt, value = "통계 분석 및 시각화 보고서", location = ph_location_label(ph_label = "Subtitle 2"))
```

#### 5.2. 플롯을 슬라이드에 삽입
```R
# 플롯별로 새 슬라이드 생성하고 삽입

# 1. Bar Plot 슬라이드
ppt <- add_slide(ppt, layout = "Title and Content", master = "Office Theme")
ppt <- ph_with(ppt, value = "그룹별 변수 비교 분석", location = ph_location_label(ph_label = "Title 1"))
ppt <- ph_with(ppt, value = dml(ggobj = p_barplot), location = ph_location_label(ph_label = "Content Placeholder 2"))

# 2. Scatter Plot 슬라이드
ppt <- add_slide(ppt, layout = "Title and Content", master = "Office Theme")
ppt <- ph_with(ppt, value = "변수 간 상관관계 분석", location = ph_location_label(ph_label = "Title 1"))
ppt <- ph_with(ppt, value = dml(ggobj = p_scatter), location = ph_location_label(ph_label = "Content Placeholder 2"))

# 3. Box Plot 슬라이드
ppt <- add_slide(ppt, layout = "Title and Content", master = "Office Theme")
ppt <- ph_with(ppt, value = "그룹별 분포 비교", location = ph_location_label(ph_label = "Title 1"))
ppt <- ph_with(ppt, value = dml(ggobj = p_boxplot), location = ph_location_label(ph_label = "Content Placeholder 2"))

# 4. 생존곡선 슬라이드 (해당하는 경우)
if(exists("p_survival")) {
  ppt <- add_slide(ppt, layout = "Title and Content", master = "Office Theme")
  ppt <- ph_with(ppt, value = "Kaplan-Meier 생존 분석", location = ph_location_label(ph_label = "Title 1"))
  ppt <- ph_with(ppt, value = dml(ggobj = p_survival), location = ph_location_label(ph_label = "Content Placeholder 2"))
}
```

#### 5.3. 통계 결과 테이블 슬라이드 (선택사항)
```R
# gtsummary나 jstable 결과를 이미지로 변환하여 삽입
if(requireNamespace("gtsummary", quietly = TRUE)) {
  # Table 1 생성
  table1 <- df %>%
    select(`<변수1>`, `<변수2>`, `<그룹_변수>`) %>%
    gtsummary::tbl_summary(by = `<그룹_변수>`) %>%
    gtsummary::add_p() %>%
    gtsummary::bold_labels()
  
  # 테이블을 이미지로 저장 (webshot2 패키지 필요)
  if(requireNamespace("webshot2", quietly = TRUE)) {
    gtsummary::as_gt(table1) %>%
      gt::gtsave("table1_temp.png", vwidth = 800, vheight = 600)
    
    # 테이블 슬라이드 추가
    ppt <- add_slide(ppt, layout = "Title and Content", master = "Office Theme")
    ppt <- ph_with(ppt, value = "기술통계표 (Table 1)", location = ph_location_label(ph_label = "Title 1"))
    ppt <- ph_with(ppt, value = external_img("table1_temp.png"), 
                   location = ph_location_label(ph_label = "Content Placeholder 2"))
    
    # 임시 파일 삭제
    file.remove("table1_temp.png")
  }
}
```

### 6. PowerPoint 파일 저장
```R
# PowerPoint 파일 저장
output_file <- "<path/to/save/medical_analysis_plots.pptx>"
print(ppt, target = output_file)

message("PowerPoint 파일이 생성되었습니다: ", output_file)
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
- **일관성**: 모든 플롯에서 동일한 스타일 및 테마 적용
