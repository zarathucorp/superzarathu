# jskm Documentation

## Overview

`jskm.R`은 jskm 패키지의 핵심 함수로, Kaplan-Meier 생존곡선을 시각화하는 고급 플롯 생성 함수를 제공합니다. 이 함수는 survival 패키지의 survfit 객체를 기반으로 하여 출판 품질의 생존곡선 플롯을 생성하며, 다양한 커스터마이징 옵션과 통계적 정보를 제공합니다.

## Functions

### `jskm()`

Kaplan-Meier 생존곡선 플롯을 생성하는 주요 함수입니다.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `sfit` | survfit | - | survival::survfit 객체 |
| `table` | logical | FALSE | 위험대상자 수 테이블 표시 여부 |
| `xlabs` | character | "Time-to-event" | X축 레이블 |
| `ylabs` | character | "Survival probability" | Y축 레이블 |
| `xlims` | numeric | NULL | X축 범위 |
| `ylims` | numeric | c(0,1) | Y축 범위 |
| `surv.scale` | character | "default" | 생존곡선 스케일 변환 |
| `pval` | logical | FALSE | p-value 표시 여부 |
| `pval.coord` | numeric | NULL | p-value 표시 위치 |
| `pval.testname` | logical | FALSE | 검정 방법명 표시 여부 |
| `marks` | logical | TRUE | 중도절단 표시 여부 |
| `shape` | numeric | 3 | 중도절단 마커 모양 |
| `legend` | logical | TRUE | 범례 표시 여부 |
| `legend.labs` | character | NULL | 범례 레이블 |
| `timeby` | numeric | NULL | X축 눈금 간격 |
| `cumhaz` | logical | FALSE | 누적위험함수 플롯 |
| `cluster` | character | NULL | 클러스터 변수 |
| `data` | data.frame | NULL | 원본 데이터 |
| `cut.landmark` | numeric | NULL | 랜드마크 분석 시점 |
| `showpercent` | logical | FALSE | 백분율 표시 |
| `ci` | logical | NULL | 신뢰구간 표시 |
| `subs` | character | NULL | 하위집단 |
| `linecols` | character | "Set1" | 선 색상 팔레트 |
| `dashed` | logical | FALSE | 점선 사용 여부 |
| `theme` | character | NULL | 플롯 테마 |
| `nejm.infigure.ratiow` | numeric | 0.6 | NEJM 스타일 테이블 너비 비율 |
| `nejm.infigure.ratioh` | numeric | 0.5 | NEJM 스타일 테이블 높이 비율 |
| `nejm.infigure.height` | numeric | 4.5 | NEJM 스타일 전체 높이 |

#### Example

```r
library(survival)
library(jskm)

# 기본 사용법
data(colon)
fit <- survfit(Surv(time, status) ~ rx, data = colon)

# 기본 플롯
jskm(fit)

# 고급 옵션을 사용한 플롯
jskm(fit,
     table = TRUE,           # 위험대상자 테이블 추가
     pval = TRUE,            # p-value 표시
     marks = FALSE,          # 중도절단 마커 제거
     timeby = 500,           # X축 눈금 간격
     xlims = c(0, 3000),     # X축 범위
     legend.labs = c("Obs", "Lev", "Lev+5FU"),  # 범례 레이블
     linecols = c("#E7B800", "#2E9FDF", "#FC4E07"),  # 선 색상
     theme = "nejm"          # NEJM 저널 스타일
)

# 누적위험함수 플롯
jskm(fit,
     cumhaz = TRUE,
     ylabs = "Cumulative hazard",
     pval = TRUE
)

# 랜드마크 분석
jskm(fit,
     cut.landmark = 365,     # 1년 랜드마크
     table = TRUE,
     pval = TRUE
)
```

## Plot Customization Options

### 테마 (Themes)

#### NEJM 스타일
```r
# New England Journal of Medicine 스타일
jskm(fit, theme = "nejm", table = TRUE)

# NEJM 스타일 세부 조정
jskm(fit, 
     theme = "nejm",
     nejm.infigure.ratiow = 0.7,    # 테이블 너비 비율
     nejm.infigure.ratioh = 0.6,    # 테이블 높이 비율  
     nejm.infigure.height = 5       # 전체 플롯 높이
)
```

#### JAMA 스타일
```r
# Journal of the American Medical Association 스타일
jskm(fit, theme = "jama", table = TRUE)
```

#### 사용자 정의 테마
```r
# 사용자 정의 색상과 스타일
jskm(fit,
     linecols = c("#1B9E77", "#D95F02", "#7570B3"),
     dashed = TRUE,          # 점선 사용
     ci = TRUE,              # 신뢰구간 표시
     marks = TRUE,           # 중도절단 표시
     shape = 4               # 다이아몬드 모양 마커
)
```

### 색상 팔레트 (Color Palettes)

```r
# 사전 정의된 팔레트
jskm(fit, linecols = "Set1")      # RColorBrewer Set1
jskm(fit, linecols = "Dark2")     # RColorBrewer Dark2  
jskm(fit, linecols = "jco")       # Journal of Clinical Oncology
jskm(fit, linecols = "npg")       # Nature Publishing Group
jskm(fit, linecols = "aaas")      # Science/AAAS
jskm(fit, linecols = "nejm")      # NEJM
jskm(fit, linecols = "jama")      # JAMA

# 사용자 정의 색상
custom_colors <- c("#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4")
jskm(fit, linecols = custom_colors)
```

## Advanced Features

### 위험대상자 테이블 (Risk Table)

```r
# 기본 위험대상자 테이블
jskm(fit, table = TRUE)

# 테이블 포맷 조정
jskm(fit, 
     table = TRUE,
     timeby = 365,           # 연간 간격
     showpercent = TRUE      # 백분율 표시
)
```

### 통계적 정보 표시

```r
# p-value 추가
jskm(fit, 
     pval = TRUE,
     pval.coord = c(100, 0.8),      # p-value 위치
     pval.testname = TRUE           # 검정명 표시
)

# 위험비 추가 (이변량 분석인 경우)
binary_fit <- survfit(Surv(time, status) ~ I(rx == "Lev+5FU"), data = colon)
jskm(binary_fit, 
     pval = TRUE,
     hr = TRUE              # 위험비 표시
)
```

### 랜드마크 분석 (Landmark Analysis)

```r
# 특정 시점 이후 생존율 분석
jskm(fit,
     cut.landmark = 500,    # 500일 랜드마크
     table = TRUE,
     pval = TRUE,
     xlabs = "Time since landmark (days)"
)

# 다중 랜드마크 분석
landmarks <- c(365, 730, 1095)  # 1, 2, 3년
for(lm in landmarks) {
  p <- jskm(fit, 
           cut.landmark = lm,
           table = TRUE,
           main = paste("Landmark at", lm, "days"))
  print(p)
}
```

### 하위집단 분석

```r
# 특정 하위집단만 플롯
jskm(fit,
     subs = "rx == 'Lev+5FU'",     # 특정 치료군만
     table = TRUE
)

# 클러스터 고려
jskm(fit,
     cluster = "id",               # 클러스터 변수
     data = colon_with_clusters    # 클러스터 정보가 있는 데이터
)
```

## Statistical Details

### 지원하는 분석 유형

#### 1. 기본 Kaplan-Meier 분석
```r
# 단일군 생존분석
single_fit <- survfit(Surv(time, status) ~ 1, data = colon)
jskm(single_fit)

# 다중군 비교
multi_fit <- survfit(Surv(time, status) ~ rx, data = colon)
jskm(multi_fit, pval = TRUE)
```

#### 2. 누적위험함수
```r
# 누적위험함수 플롯
jskm(fit,
     cumhaz = TRUE,
     ylabs = "Cumulative hazard",
     ylims = c(0, 2)
)
```

#### 3. 경쟁위험 분석
```r
library(cmprsk)

# 경쟁위험 데이터 준비
colon$comp_event <- with(colon, 
  ifelse(status == 1 & etype == 1, 1,  # 재발
         ifelse(status == 1 & etype == 2, 2,  # 사망
                0)))  # 중도절단

# 경쟁위험 누적발생함수
cif_fit <- cuminc(colon$time, colon$comp_event, colon$rx)
# Note: jskm은 survfit 객체를 사용하므로 직접 지원하지 않음
```

### 검정 방법

```r
# 로그-순위 검정 (기본)
jskm(fit, pval = TRUE, pval.testname = TRUE)

# 가중 로그-순위 검정 (가중치가 있는 경우)
weighted_fit <- survfit(Surv(time, status) ~ rx, 
                       data = colon, 
                       weights = weights)
jskm(weighted_fit, pval = TRUE)
```

## Output Customization

### 축 설정

```r
# 축 범위 및 레이블 조정
jskm(fit,
     xlims = c(0, 2000),           # X축 범위
     ylims = c(0.4, 1),           # Y축 범위  
     xlabs = "Follow-up time (days)",
     ylabs = "Overall survival",
     timeby = 200                  # X축 눈금 간격
)

# 백분율 표시
jskm(fit,
     showpercent = TRUE,          # Y축을 백분율로
     ylabs = "Survival (%)"
)
```

### 범례 설정

```r
# 범례 커스터마이징
jskm(fit,
     legend = TRUE,
     legend.labs = c("Control", "Treatment A", "Treatment B"),
     legend.position = c(0.8, 0.8)  # 범례 위치
)

# 범례 제거
jskm(fit, legend = FALSE)
```

### 마커 설정

```r
# 중도절단 마커 조정
jskm(fit,
     marks = TRUE,
     shape = 3,                   # 십자 모양
     mark.size = 2                # 마커 크기
)

# 마커 제거
jskm(fit, marks = FALSE)
```

## Integration with Other Packages

### ggplot2 확장

```r
library(ggplot2)

# jskm은 ggplot 객체를 반환하므로 추가 수정 가능
p <- jskm(fit, table = TRUE)

# ggplot 레이어 추가
p + 
  ggtitle("Kaplan-Meier Survival Curves") +
  theme(plot.title = element_text(hjust = 0.5)) +
  annotate("text", x = 1000, y = 0.2, 
           label = "Follow-up: median 5.2 years")
```

### 다중 플롯 조합

```r
library(gridExtra)

# 여러 하위집단의 생존곡선
subgroups <- c("sex", "age_group", "stage")
plots <- list()

for(i in 1:length(subgroups)) {
  formula_str <- paste("Surv(time, status) ~", subgroups[i])
  sub_fit <- survfit(as.formula(formula_str), data = colon)
  plots[[i]] <- jskm(sub_fit, 
                     pval = TRUE, 
                     main = subgroups[i])
}

# 2x2 배열로 표시
grid.arrange(plots[[1]], plots[[2]], 
             plots[[3]], plots[[4]], 
             ncol = 2)
```

## Performance Considerations

### 대용량 데이터 처리

```r
# 큰 데이터셋에서의 최적화
large_fit <- survfit(Surv(time, status) ~ treatment, 
                    data = large_dataset)

# 플롯 옵션 최적화
jskm(large_fit,
     marks = FALSE,              # 마커 제거로 성능 향상
     ci = FALSE,                 # 신뢰구간 제거
     table = FALSE               # 테이블 제거
)
```

### 메모리 효율성

```r
# 메모리 사용량 최소화
jskm(fit,
     xlims = c(0, 1000),         # 관심 구간만 표시
     timeby = 100,               # 적절한 눈금 간격
     theme = NULL                # 기본 테마 사용
)
```

## Dependencies

- `survival` package - survfit 객체 처리
- `ggplot2` package - 플롯 생성
- `gridExtra` package - 테이블 레이아웃
- `RColorBrewer` package - 색상 팔레트
- `scales` package - 축 포매팅

## Troubleshooting

### 일반적인 오류

```r
# 1. survfit 객체가 아닌 경우
# Error: 올바른 해결법
fit <- survfit(Surv(time, status) ~ group, data = data)
jskm(fit)  # coxph가 아닌 survfit 사용

# 2. 시간 변수에 음수값이 있는 경우
data$time[data$time < 0] <- 0.1  # 작은 양수로 대체

# 3. 범례 레이블 수 불일치
group_levels <- length(unique(data$group))
legend_labels <- paste("Group", 1:group_levels)
jskm(fit, legend.labs = legend_labels)
```

### 성능 최적화

```r
# 큰 데이터셋을 위한 최적화
jskm(fit,
     # 불필요한 요소 제거
     marks = FALSE,
     ci = FALSE,
     # 해상도 조정
     dpi = 72,
     # 단순한 테마 사용
     theme = NULL
)
```

## See Also

- `survival::survfit()` - Kaplan-Meier 추정
- `survival::survdiff()` - 로그-순위 검정
- `svyjskm()` - Survey 가중 생존곡선
- `ggplot2::ggplot()` - 기본 플롯 시스템
- `gridExtra::grid.arrange()` - 다중 플롯 배열