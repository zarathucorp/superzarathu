# SuperZarathu Commands Usage Guide

## Overview
SuperZarathu R 패키지는 Claude Code와 Gemini CLI에서 사용할 수 있는 R 데이터 분석 명령어를 제공합니다. 모든 명령어는 `sz:` 접두사를 사용하며, 자연어 요청과 구체적인 옵션을 모두 지원합니다.

## Command Arguments System

### Claude Code
Claude Code에서는 `$ARGUMENTS` 플레이스홀더를 통해 사용자 인수를 받습니다.

**사용 예시:**
```bash
/sz:preprocess --input data.csv --output processed.rds --encoding UTF-8
/sz:analysis --data mydata.rds --outcome survival --group treatment --method logistic
```

### Gemini CLI
Gemini CLI에서는 `{{args}}` 플레이스홀더를 통해 사용자 인수를 받습니다.

**사용 예시:**
```bash
gemini /sz:preprocess --input data.csv --output processed.rds
gemini /sz:plot --data results.rds --type scatter --x age --y bmi
```

## Available Commands  

### 1. `/sz:preprocess` - 데이터 전처리 및 정제 (강화됨)
**목적:** Raw 데이터를 분석 가능한 형태로 전처리하고 데이터 품질 문제를 해결

**Arguments:**
- `--input <file>` (필수): 입력 데이터 파일 (CSV/Excel, 인코딩 자동 감지)
- `--output <file>`: 출력 RDS 파일 (기본값: processed_data.rds)
- `--na_cols <col1,col2>`: 결측치 처리할 열 지정
- `--encoding <type>`: 파일 인코딩 강제 지정 (UTF-8/CP949)
- `--chunk-size <number>`: 대용량 데이터 처리 시 청크 크기

**자연어 요청 지원:**
```bash
/sz:preprocess data.csv "데이터 정제해줘"
/sz:preprocess data.xlsx "결측치 처리하고 이상치 제거해줘"
/sz:preprocess raw.csv "중복 제거해줘" --output clean.rds
```

### 2. `/sz:label` - 데이터 라벨링 (강화됨)
**목적:** 코드 값을 의미있는 라벨로 변환 (코드북 없이도 자동 추론)

**Arguments:**
- `--data <file>` (필수): 전처리된 RDS 데이터 파일
- `--codebook <file>`: 코드북 Excel/CSV 파일 (선택, 형식 자동 감지)
- `--output <file>`: 출력 파일 (기본값: labeled_data.rds)
- `--auto`: 코드북 없이 자동 라벨 추론

**지능형 기능:**
- 이진 변수 자동 감지 (0/1 → No/Yes, 1/2 → Male/Female)
- Likert 척도 자동 인식 (1-5, 1-7 등)
- 연속 변수 자동 범주화 (나이, BMI 등)

**예시:**
```bash
/sz:label processed.rds --codebook codebook.xlsx
/sz:label processed.rds --auto  # 코드북 없이 자동 라벨링
```

### 3. `/sz:analysis` - 통계 분석 (강화됨)
**목적:** 통계 분석 수행 (구체적 지정 또는 자연어 요청)

**Arguments (기존 방식):**
- `--data <file>` (필수): 라벨링된 RDS 데이터
- `--outcome <var>`: 결과 변수명 (종속변수)
- `--group <var>`: 그룹 비교 변수
- `--covariates <var1,var2>`: 공변량 (쉼표로 구분)
- `--method <type>`: 분석 방법 (linear, logistic, cox)
- `--output <file>`: 결과 파일 (PowerPoint/Excel)

**자연어 요청 지원:**
```bash
/sz:analysis labeled.rds "그룹 간 차이를 분석해줘"
/sz:analysis data.rds "회귀 분석 수행해줘"
/sz:analysis survival.rds "생존 분석 해줘"
/sz:analysis data.rds "Table 1 만들어줘" --output table1.xlsx
```

**자동 선택되는 분석:**
- Table 1 (기술통계 + p-values)
- 회귀 분석 (선형/로지스틱 자동 선택)
- 생존 분석 (Kaplan-Meier, Cox regression)
- 상관 분석

### 4. `/sz:jstable` - 논문용 테이블 생성
**목적:** 출판 가능한 Table 1 및 회귀분석 테이블 생성

**Arguments:**
- `--data <file>` (필수): RDS 데이터 파일
- `--strata <var>`: 층화 변수 (그룹 비교용)
- `--vars <var1,var2>`: 포함할 변수들 (쉼표로 구분)
- `--output <format>`: 출력 형식 (html, word, excel)

**예시:**
```bash
/sz:jstable --data mydata.rds --strata disease_status --vars age,sex,bmi
/sz:jstable mydata.rds --vars age,sex,lab_results --output word
```

### 5. `/sz:jskm` - Kaplan-Meier 생존분석
**목적:** 생존곡선 생성 및 분석

**Arguments:**
- `--data <file>` (필수): RDS 데이터 파일
- `--time <var>` (필수): 시간 변수명
- `--event <var>` (필수): 이벤트 변수명
- `--group <var>`: 그룹 변수명
- `--timeby <number>`: X축 시간 간격 (기본값: 365)

**예시:**
```bash
/sz:jskm --data survival.rds --time os_days --event death --group treatment
/sz:jskm survival.rds --time time_to_event --event status --timeby 30
```

### 6. `/sz:plot` - PowerPoint 플롯 생성 (강화됨)
**목적:** 데이터 시각화 및 PPT 삽입 (자동 플롯 선택 및 저널 스타일 테마)

**Arguments (기존 방식):**
- `--data <file>` (필수): RDS 데이터 파일
- `--type <plot>`: 플롯 유형 (bar, scatter, box, survival, heatmap)
- `--x <var>`: X축 변수명 (자동 선택 가능)
- `--y <var>`: Y축 변수명 (자동 선택 가능)
- `--group <var>`: 그룹 변수명 (자동 선택 가능)
- `--theme <style>`: 테마 선택 (nature, nejm, lancet, presentation)
- `--colorblind`: 색맹 친화적 색상
- `--output <file>`: PowerPoint 파일명 (기본값: plots.pptx)

**자연어 요청 지원:**
```bash
/sz:plot data.rds "막대 그래프 그려줘"
/sz:plot results.rds "산점도 그려줘" --output scatter.pptx
/sz:plot survival.rds "생존 곡선 그려줘" --theme nejm
/sz:plot data.rds "상관 히트맵 만들어줘" --colorblind
```

**지능형 기능:**
- 데이터 구조 분석하여 최적 플롯 자동 선택
- 저널별 테마 자동 적용 (Nature, NEJM, Lancet 등)
- 통계적 유의성 자동 표시 (p-values, 신뢰구간)

### 7. `/sz:shiny` - Shiny 앱 생성
**목적:** 인터랙티브 데이터 탐색 앱 생성

**Arguments:**
- `--data <file>` (필수): RDS 데이터 파일
- `--title <text>`: 앱 제목 (기본값: Data Explorer)
- `--port <number>`: 실행 포트
- `--theme <name>`: UI 테마

**예시:**
```bash
/sz:shiny --data mydata.rds --title "Clinical Trial Dashboard" --port 3838
/sz:shiny analysis.rds --theme cerulean
```

### 8. `/sz:jsmodule` - 모듈식 Shiny 앱
**목적:** jsmodule 기반 확장 가능한 분석 앱 생성

**Arguments:**
- `--data <file>` (필수): RDS 데이터 파일
- `--modules <module1,module2>`: 포함할 모듈 (data, table1, km, cox)
- `--title <text>`: 앱 제목

**예시:**
```bash
/sz:jsmodule --data clinical.rds --modules data,table1,km,cox --title "Clinical Analysis"
/sz:jsmodule mydata.rds --modules data,table1
```

## Argument Patterns

### 필수 vs 선택적 인수
- **필수 인수**: 명령어 설명에서 `(필수)` 표시
- **선택적 인수**: 대괄호 `[--option]`로 표시

### 첫 번째 위치 인수
대부분의 명령어는 첫 번째 인수를 자동으로 주요 입력으로 해석합니다:
- `preprocess`, `label`: `--input` 또는 `--data`
- 다른 명령어들: `--data`

**예시:**
```bash
/sz:preprocess data.csv  # --input data.csv와 동일
/sz:analysis mydata.rds --outcome survival  # --data mydata.rds와 동일
```

### 다중 값 인수
쉼표로 구분하여 여러 값을 전달:
```bash
--vars age,sex,bmi,lab_result
--covariates age,sex,smoking_status
--modules data,table1,km
```

### 불린 플래그
일부 옵션은 값 없이 플래그만으로 활성화:
```bash
/sz:analysis --data mydata.rds --outcome death --verbose
/sz:plot --data results.rds --type bar --interactive
```

## Tips & Best Practices

### 1. 워크플로우 순서
일반적인 분석 워크플로우 (강화된 자연어 지원):
```bash
# 구체적 옵션 방식 (기존)
1. /sz:preprocess raw_data.csv --output clean.rds
2. /sz:label clean.rds --codebook codes.xlsx --output labeled.rds
3. /sz:analysis labeled.rds --outcome disease --group treatment
4. /sz:jstable labeled.rds --strata treatment --output word
5. /sz:plot labeled.rds --type box --y biomarker --group treatment

# 자연어 방식 (새로운 기능)
1. /sz:preprocess raw_data.csv "데이터 정제하고 이상치 제거해줘"
2. /sz:label clean.rds --auto  # 코드북 없이 자동 라벨링
3. /sz:analysis labeled.rds "그룹 간 차이 분석해줘"
4. /sz:plot labeled.rds "주요 변수들 시각화해줘" --theme nature
```

### 2. 파일 명명 규칙
- 전처리: `*_processed.rds`
- 라벨링: `*_labeled.rds`
- 분석 결과: `*_results.rds`

### 3. 인코딩 문제 해결
한글 데이터에서 인코딩 문제 발생 시:
```bash
/sz:preprocess --input data.csv --encoding CP949  # Windows 한글
/sz:preprocess --input data.csv --encoding UTF-8  # Mac/Linux
```

### 4. 대용량 데이터 처리
50,000행 이상의 데이터:
```bash
/sz:preprocess --input bigdata.csv --chunk-size 10000
```

## Error Handling

### 일반적인 오류와 해결방법

**1. 파일을 찾을 수 없음:**
```
Error: cannot open file 'data.csv'
```
→ 파일 경로를 절대 경로로 지정하거나 작업 디렉토리 확인

**2. 변수명 오류:**
```
Error: Variable 'age' not found in data
```
→ 데이터의 실제 변수명 확인 (대소문자 구분)

**3. 인코딩 오류:**
```
Error: invalid multibyte string
```
→ `--encoding CP949` 또는 `--encoding UTF-8` 옵션 사용

## Integration with IDEs

### RStudio
RStudio 터미널에서 직접 사용:
```bash
# Terminal 탭에서
/sz:preprocess data.csv
```

### VS Code
Claude Code 또는 Gemini 확장 설치 후 명령 팔레트에서 사용

## Further Resources

- Package Documentation: `?superzarathu`
- Template Details: `get_templates()`
- GitHub: https://github.com/zarathucorp/superzarathu

## Support

문제 발생 시:
1. 패키지 재설치: `devtools::install()`
2. 명령어 재생성: `setup_claude_commands()` 또는 `setup_gemini_commands()`
3. Issue 등록: GitHub Issues