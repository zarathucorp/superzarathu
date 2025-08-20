# SuperZarathu Commands Usage Guide

## Overview
SuperZarathu R 패키지는 Claude Code와 Gemini CLI에서 사용할 수 있는 R 데이터 분석 명령어를 제공합니다. 모든 명령어는 `sz:` 접두사를 사용합니다.

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

### 1. `/sz:preprocess` - 데이터 전처리
**목적:** Raw 데이터를 분석 가능한 형태로 정제

**Arguments:**
- `--input <file>` (필수): 입력 데이터 파일 (CSV/Excel)
- `--output <file>`: 출력 RDS 파일 (기본값: processed_data.rds)
- `--encoding <type>`: 파일 인코딩 (UTF-8 또는 CP949)
- `--chunk-size <number>`: 대용량 데이터 처리 시 청크 크기

**예시:**
```bash
/sz:preprocess --input raw_data.csv --output clean.rds --encoding UTF-8
/sz:preprocess data.xlsx  # 첫 번째 인수는 자동으로 --input으로 해석
```

### 2. `/sz:label` - 데이터 라벨링
**목적:** 코드 값을 사람이 읽을 수 있는 라벨로 변환

**Arguments:**
- `--data <file>` (필수): 전처리된 RDS 데이터 파일
- `--codebook <file>`: 코드북 Excel 파일 (선택)
- `--output <file>`: 출력 파일 (기본값: labeled_data.rds)

**예시:**
```bash
/sz:label --data processed.rds --codebook codebook.xlsx
/sz:label processed.rds --output labeled.rds
```

### 3. `/sz:analysis` - 통계 분석
**목적:** 기술통계 및 추론통계 분석 수행

**Arguments:**
- `--data <file>` (필수): 라벨링된 RDS 데이터
- `--outcome <var>` (필수): 결과 변수명 (종속변수)
- `--group <var>`: 그룹 비교 변수
- `--covariates <var1,var2>`: 공변량 (쉼표로 구분)
- `--method <type>`: 분석 방법 (linear, logistic, cox)

**예시:**
```bash
/sz:analysis --data labeled.rds --outcome mortality --group treatment --method logistic
/sz:analysis labeled.rds --outcome bmi --covariates age,sex --method linear
```

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

### 6. `/sz:plot` - PowerPoint 플롯 생성
**목적:** 출판 품질의 그래프 생성 및 PPT 삽입

**Arguments:**
- `--data <file>` (필수): RDS 데이터 파일
- `--type <plot>` (필수): 플롯 유형 (bar, scatter, box, survival)
- `--x <var>`: X축 변수명
- `--y <var>`: Y축 변수명
- `--group <var>`: 그룹 변수명
- `--output <file>`: PowerPoint 파일명 (기본값: plots.pptx)

**예시:**
```bash
/sz:plot --data results.rds --type scatter --x age --y cholesterol --group gender
/sz:plot mydata.rds --type box --y bmi --group treatment --output figures.pptx
```

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
일반적인 분석 워크플로우:
```bash
1. /sz:preprocess raw_data.csv --output clean.rds
2. /sz:label clean.rds --codebook codes.xlsx --output labeled.rds
3. /sz:analysis labeled.rds --outcome disease --group treatment
4. /sz:jstable labeled.rds --strata treatment --output word
5. /sz:plot labeled.rds --type box --y biomarker --group treatment
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