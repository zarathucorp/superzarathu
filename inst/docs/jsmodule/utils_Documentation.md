# utils Documentation

## Overview
`utils.R`은 jsmodule 패키지의 핵심 유틸리티 함수 모음입니다. SPSS 파일의 라벨 처리, 데이터 변환, 테이블 생성 등 패키지 전반에서 사용되는 공통 기능들을 제공합니다. 특히 SPSS에서 가져온 .sav 파일의 변수 라벨과 값 라벨을 R 환경에서 적절하게 처리하는 기능이 핵심입니다.

## Main Function

### `mk.lev2(out.old, out.label)`
SPSS .sav 파일의 라벨 정보를 처리하고 업데이트하는 함수입니다.

**Parameters:**
- `out.old`: 원본 데이터의 속성 정보를 포함한 객체
- `out.label`: 업데이트할 라벨 메타데이터 객체

**Returns:**
- 동기화된 라벨 정보가 포함된 업데이트된 `out.label` 객체

**Purpose:**
- SPSS 변수 라벨과 값 라벨 동기화
- R 환경에서 SPSS 데이터의 메타데이터 보존
- jsmodule 분석 모듈에서 사용할 수 있는 형태로 라벨 변환

## Usage Examples

### Basic SPSS Label Processing
```r
library(jsmodule)
library(foreign)

# SPSS 파일 로드
spss_data <- read.spss("survey_data.sav", to.data.frame = TRUE, 
                      use.value.labels = FALSE)

# 라벨 정보 추출
original_labels <- attributes(spss_data)

# 기본 라벨 구조 생성
base_labels <- jstable::mk.lev(spss_data)

# SPSS 라벨 정보로 업데이트
enhanced_labels <- mk.lev2(spss_data, base_labels)

# 결과 확인
str(enhanced_labels)
```

### Integration with jsmodule Analysis
```r
library(jsmodule)

# SPSS 데이터 및 라벨 준비
process_spss_for_analysis <- function(spss_file_path) {
  # SPSS 파일 로드
  raw_data <- read.spss(spss_file_path, to.data.frame = TRUE)
  
  # 기본 라벨 생성
  base_labels <- jstable::mk.lev(raw_data)
  
  # SPSS 라벨로 개선
  enhanced_labels <- mk.lev2(raw_data, base_labels)
  
  return(list(
    data = raw_data,
    labels = enhanced_labels
  ))
}

# 분석에 사용
spss_analysis <- process_spss_for_analysis("clinical_data.sav")

# jsmodule 가젯에서 사용
jsBasicGadget(spss_analysis$data)
```

### Custom Label Enhancement
```r
library(jsmodule)
library(data.table)

# 사용자 정의 라벨 처리
enhance_survey_labels <- function(data, additional_labels = NULL) {
  # 기본 라벨 구조
  base_labels <- jstable::mk.lev(data)
  
  # SPSS 라벨 적용
  if (!is.null(attr(data, "variable.labels"))) {
    enhanced_labels <- mk.lev2(data, base_labels)
  } else {
    enhanced_labels <- base_labels
  }
  
  # 추가 라벨 정보 적용
  if (!is.null(additional_labels)) {
    for (var_name in names(additional_labels)) {
      if (var_name %in% names(enhanced_labels)) {
        enhanced_labels[[var_name]]$label <- additional_labels[[var_name]]
      }
    }
  }
  
  return(enhanced_labels)
}

# 사용 예시
custom_labels <- list(
  age = "환자 연령 (세)",
  gender = "성별",
  diagnosis = "진단명"
)

enhanced_labels <- enhance_survey_labels(clinical_data, custom_labels)
```

## Technical Implementation

### Label Extraction Process
```r
# 내부 라벨 처리 과정 (의사코드)
extract_spss_labels <- function(spss_data) {
  # 1단계: 변수 라벨 추출
  variable_labels <- attr(spss_data, "variable.labels")
  
  # 2단계: 값 라벨 추출  
  value_labels <- attr(spss_data, "label.table")
  
  # 3단계: 각 변수별 속성 처리
  processed_labels <- list()
  
  for (var_name in names(spss_data)) {
    var_attrs <- attributes(spss_data[[var_name]])
    
    processed_labels[[var_name]] <- list(
      variable_label = variable_labels[[var_name]] %||% var_name,
      value_labels = var_attrs$labels %||% NULL,
      class = class(spss_data[[var_name]]),
      levels = levels(spss_data[[var_name]]) %||% NULL
    )
  }
  
  return(processed_labels)
}
```

### Label Synchronization Algorithm
```r
# 라벨 동기화 알고리즘 (의사코드)
synchronize_labels <- function(old_data, label_template) {
  # 기존 라벨 구조 복사
  updated_labels <- label_template
  
  # SPSS 속성 정보 추출
  spss_attrs <- extract_spss_attributes(old_data)
  
  # 각 변수에 대해 라벨 업데이트
  for (var_name in names(updated_labels)) {
    if (var_name %in% names(spss_attrs)) {
      # 변수 라벨 업데이트
      if (!is.null(spss_attrs[[var_name]]$variable_label)) {
        updated_labels[[var_name]]$label <- spss_attrs[[var_name]]$variable_label
      }
      
      # 값 라벨 업데이트
      if (!is.null(spss_attrs[[var_name]]$value_labels)) {
        updated_labels[[var_name]]$levels <- spss_attrs[[var_name]]$value_labels
      }
    }
  }
  
  return(updated_labels)
}
```

### Data Type Handling
```r
# 데이터 타입별 처리
handle_variable_types <- function(variable, spss_attrs) {
  var_class <- class(variable)
  
  if ("factor" %in% var_class) {
    # 요인 변수 처리
    return(list(
      type = "categorical",
      levels = levels(variable),
      labels = spss_attrs$value_labels,
      ordered = is.ordered(variable)
    ))
    
  } else if (is.numeric(variable)) {
    # 수치형 변수 처리
    if (!is.null(spss_attrs$value_labels)) {
      # 라벨이 있는 수치형 (코딩된 범주형)
      return(list(
        type = "coded_categorical", 
        codes = spss_attrs$value_labels,
        range = range(variable, na.rm = TRUE)
      ))
    } else {
      # 순수 연속형
      return(list(
        type = "continuous",
        range = range(variable, na.rm = TRUE),
        mean = mean(variable, na.rm = TRUE),
        sd = sd(variable, na.rm = TRUE)
      ))
    }
    
  } else if (is.character(variable)) {
    # 문자형 변수 처리
    return(list(
      type = "text",
      unique_values = length(unique(variable)),
      max_length = max(nchar(variable), na.rm = TRUE)
    ))
  }
}
```

## Advanced Features

### Unicode and Encoding Support
```r
# 한국어 SPSS 파일 처리
process_korean_spss <- function(file_path) {
  # 인코딩 지정하여 로드
  spss_data <- read.spss(file_path, to.data.frame = TRUE, 
                        reencode = "UTF-8")
  
  # 한글 라벨 처리를 위한 인코딩 변환
  if (Sys.getlocale("LC_CTYPE") != "en_US.UTF-8") {
    # 변수 라벨 인코딩 처리
    var_labels <- attr(spss_data, "variable.labels")
    if (!is.null(var_labels)) {
      var_labels <- iconv(var_labels, from = "CP949", to = "UTF-8")
      attr(spss_data, "variable.labels") <- var_labels
    }
  }
  
  # 라벨 처리
  base_labels <- jstable::mk.lev(spss_data)
  enhanced_labels <- mk.lev2(spss_data, base_labels)
  
  return(list(data = spss_data, labels = enhanced_labels))
}
```

### Missing Data Handling
```r
# 결측값 및 특수값 처리
handle_spss_missing <- function(data, missing_codes = c(-9, -8, -7)) {
  processed_data <- data
  
  for (var_name in names(data)) {
    variable <- data[[var_name]]
    
    # SPSS 결측값 코드를 NA로 변환
    if (is.numeric(variable)) {
      variable[variable %in% missing_codes] <- NA
    }
    
    # 사용자 정의 결측값 라벨 처리
    missing_labels <- attr(variable, "missing.labels")
    if (!is.null(missing_labels)) {
      # 결측값 라벨 정보 보존
      attr(variable, "original.missing") <- missing_labels
    }
    
    processed_data[[var_name]] <- variable
  }
  
  return(processed_data)
}
```

### Label Validation
```r
# 라벨 유효성 검사
validate_labels <- function(data, labels) {
  validation_results <- list()
  
  for (var_name in names(labels)) {
    if (!var_name %in% names(data)) {
      validation_results[[var_name]] <- "Variable not found in data"
      next
    }
    
    var_data <- data[[var_name]]
    var_labels <- labels[[var_name]]
    
    # 값 라벨과 실제 데이터 일치성 검사
    if (!is.null(var_labels$levels) && is.factor(var_data)) {
      expected_levels <- names(var_labels$levels)
      actual_levels <- levels(var_data)
      
      missing_levels <- setdiff(actual_levels, expected_levels)
      extra_levels <- setdiff(expected_levels, actual_levels)
      
      if (length(missing_levels) > 0 || length(extra_levels) > 0) {
        validation_results[[var_name]] <- list(
          missing = missing_levels,
          extra = extra_levels
        )
      }
    }
  }
  
  return(validation_results)
}
```

## Integration with jsmodule Ecosystem

### Table Generation Integration
```r
# jstable과 통합
create_enhanced_table1 <- function(data, labels, group_var = NULL) {
  # mk.lev2로 처리된 라벨 사용
  enhanced_data <- data
  attr(enhanced_data, "enhanced.labels") <- labels
  
  # Table 1 생성
  if (!is.null(group_var)) {
    table1 <- jstable::CreateTableOne(
      vars = names(data)[names(data) != group_var],
      strata = group_var,
      data = enhanced_data,
      factorVars = get_categorical_vars(labels)
    )
  } else {
    table1 <- jstable::CreateTableOne(
      vars = names(data),
      data = enhanced_data,
      factorVars = get_categorical_vars(labels)
    )
  }
  
  return(table1)
}

# 범주형 변수 식별
get_categorical_vars <- function(labels) {
  categorical_vars <- c()
  
  for (var_name in names(labels)) {
    if (!is.null(labels[[var_name]]$levels) || 
        labels[[var_name]]$class %in% c("factor", "character")) {
      categorical_vars <- c(categorical_vars, var_name)
    }
  }
  
  return(categorical_vars)
}
```

### Shiny Module Integration
```r
# Shiny 모듈에서 라벨 활용
use_enhanced_labels <- function(data, labels) {
  # 변수 선택 UI에서 라벨 표시
  var_choices <- sapply(names(labels), function(x) {
    label_text <- labels[[x]]$label %||% x
    setNames(x, label_text)
  })
  
  return(var_choices)
}

# 결과 테이블에서 라벨 표시
format_results_with_labels <- function(results, labels) {
  formatted_results <- results
  
  # 변수명을 라벨로 교체
  if ("Variable" %in% names(formatted_results)) {
    formatted_results$Variable <- sapply(formatted_results$Variable, function(x) {
      labels[[x]]$label %||% x
    })
  }
  
  return(formatted_results)
}
```

## Performance Optimization

### Memory Efficiency
```r
# 메모리 효율적인 라벨 처리
optimize_label_processing <- function(large_data, chunk_size = 1000) {
  data_vars <- names(large_data)
  n_vars <- length(data_vars)
  
  # 청크 단위로 처리
  processed_labels <- list()
  
  for (i in seq(1, n_vars, chunk_size)) {
    end_idx <- min(i + chunk_size - 1, n_vars)
    chunk_vars <- data_vars[i:end_idx]
    
    # 청크별 데이터 추출
    chunk_data <- large_data[, chunk_vars, with = FALSE]
    
    # 라벨 처리
    chunk_base <- jstable::mk.lev(chunk_data)
    chunk_enhanced <- mk.lev2(chunk_data, chunk_base)
    
    # 결과 병합
    processed_labels <- c(processed_labels, chunk_enhanced)
    
    # 메모리 정리
    rm(chunk_data, chunk_base, chunk_enhanced)
    gc()
  }
  
  return(processed_labels)
}
```

### Caching System
```r
# 라벨 처리 결과 캐싱
cache_labels <- function(data_hash, labels) {
  cache_dir <- file.path(tempdir(), "jsmodule_labels")
  if (!dir.exists(cache_dir)) {
    dir.create(cache_dir)
  }
  
  cache_file <- file.path(cache_dir, paste0(data_hash, ".rds"))
  saveRDS(labels, cache_file)
  
  return(cache_file)
}

load_cached_labels <- function(data_hash) {
  cache_dir <- file.path(tempdir(), "jsmodule_labels")
  cache_file <- file.path(cache_dir, paste0(data_hash, ".rds"))
  
  if (file.exists(cache_file)) {
    return(readRDS(cache_file))
  }
  
  return(NULL)
}
```

## Error Handling and Validation

### Robust Error Handling
```r
# 안전한 라벨 처리
safe_mk_lev2 <- function(out.old, out.label) {
  tryCatch({
    # 기본 유효성 검사
    if (is.null(out.old) || is.null(out.label)) {
      stop("Input data or labels cannot be NULL")
    }
    
    if (!is.list(out.label)) {
      stop("out.label must be a list structure")
    }
    
    # mk.lev2 실행
    result <- mk.lev2(out.old, out.label)
    
    # 결과 검증
    if (length(result) != length(out.label)) {
      warning("Label processing may have failed - length mismatch")
    }
    
    return(result)
    
  }, error = function(e) {
    warning(paste("mk.lev2 failed:", e$message))
    return(out.label)  # 원본 라벨 반환
  })
}
```

## Dependencies

### Required Packages
```r
# 필수 의존성
library(data.table)     # 효율적인 데이터 처리
library(DT)             # 파이프 연산자 및 테이블 기능

# SPSS 파일 처리용
library(foreign)        # SPSS .sav 파일 읽기
library(haven)          # 최신 SPSS 파일 형식 지원

# 라벨 처리용
library(jstable)        # 기본 라벨 구조 생성
```

### Optional Enhancements
```r
# 추가 기능용 패키지
library(Hmisc)          # 고급 라벨 처리
library(sjlabelled)     # 라벨 유틸리티
library(labelled)       # 라벨 데이터 조작
```

## Best Practices

### SPSS 데이터 처리 가이드라인
- **인코딩 확인**: 한글 라벨 처리시 UTF-8 확인
- **결측값 처리**: SPSS 특수 결측값 코드 처리
- **메모리 관리**: 대용량 파일시 청크 단위 처리
- **백업**: 원본 속성 정보 보존

### 라벨 품질 관리
- **일관성**: 변수명과 라벨 일관성 확인
- **완성도**: 모든 변수에 적절한 라벨 존재
- **정확성**: 값 라벨과 실제 데이터 일치
- **국제화**: 다국어 지원 고려

## Version Notes
이 문서는 jsmodule 패키지의 유틸리티 함수들을 기반으로 작성되었습니다. SPSS 파일 처리 방식은 `foreign` 및 `haven` 패키지의 업데이트에 따라 변경될 수 있으며, 최신 버전과의 호환성을 정기적으로 확인해야 합니다.