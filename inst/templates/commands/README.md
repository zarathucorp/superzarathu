# SuperZarathu 통합 명령어 v2

> **AI Assistant를 위한 안내**: 이 명령어들은 jstable, jskm, jsmodule 패키지를 사용합니다. 웹검색이 가능하다면 GitHub 링크를 통해 최신 함수 사용법을 확인하세요.

## ⚠️ 중요: 보안 및 토큰 절약 가이드라인

### 절대 하지 말아야 할 것들:
- ❌ **print(data)** - 전체 데이터 출력 금지
- ❌ **View(data)** - 데이터 뷰어 사용 금지
- ❌ **data** - 콘솔에 데이터 객체 직접 출력 금지
- ❌ 개인정보(주민번호, 환자명, ID) 노출

### 반드시 사용해야 할 것들:
- ✅ **head(data, 5)** - 상위 5행만 확인
- ✅ **str(data)** - 구조만 확인
- ✅ **summary(data)** - 통계 요약만
- ✅ **dim(data)** - 크기만 확인
- ✅ **names(data)** - 변수명만 확인

## 📋 명령어 개요 (5개로 통합)

### 1. `/sz:preprocess` - 데이터 전처리
- `data/raw/` 폴더에서 자동으로 파일 탐지
- CSV/Excel 파일 읽기 및 정제
- 인코딩 문제 해결 (UTF-8, CP949)
- 데이터 타입 최적화
- 결측치 및 이상치 처리
- `data/processed/`에 RDS 형식으로 자동 저장

### 2. `/sz:label` - 데이터 라벨링
- `data/processed/` 폴더의 최신 RDS 자동 사용
- 변수명 한글/영문 라벨링
- 범주형 변수 값 라벨링
- 코드북 자동 탐지:
  - Excel 파일 내 "codebook" 시트
  - `data/raw/codebook.xlsx` 별도 파일
  - 원본 데이터의 2번째 시트
- 의료 데이터 자동 인식
- 메타데이터 관리

### 3. `/sz:table` - 테이블 생성 (jstable 통합)
- `data/processed/` 폴더의 최신 RDS 자동 사용
- **Table 1** (기초 통계표)
- **회귀분석 테이블** (lm, glm, cox)
- **생존분석 테이블**
- **jstable 완전 통합**
- `output/tables/`에 자동 저장 (HTML, Word, Excel, LaTeX)

### 4. `/sz:plot` - 시각화 (jskm 통합)
- `data/processed/` 폴더의 최신 RDS 자동 사용
- **기본 플롯**: 막대, 선, 산점도, 박스플롯
- **생존분석**: Kaplan-Meier curves (jskm)
- **상관관계**: 히트맵
- **의학통계 특화 시각화**
- `output/plots/`에 자동 저장 (PNG, PDF, PPT)

### 5. `/sz:rshiny` - Shiny 앱 생성 (jsmodule 통합)
- `data/processed/` 폴더의 최신 RDS 자동 로드
- **대시보드** 자동 생성
- **jsmodule 통계 앱** (Table1, 회귀, 생존, ROC)
- **데이터 탐색기**
- **보고서 생성 모듈**
- 반응형 UI/UX

## 🎯 주요 개선사항

### 통합된 기능
- `jstable` → `/sz:table`에 통합
- `jskm` → `/sz:plot`에 통합  
- `jsmodule` → `/sz:rshiny`에 통합
- `analysis` → 각 명령어에 분산 통합

### 스마트 기능
- **프로젝트 구조 활용**: `data/`, `output/` 폴더 자동 사용
- **자연어 이해**: "연령별 혈압 분포 보여줘"
- **자동 타입 감지**: 데이터에 맞는 최적 분석 선택
- **의료 데이터 특화**: ICD 코드, 검사명 자동 인식
- **일괄 처리**: 여러 작업을 한 번에 수행

## 📝 사용 예시

```r
# 1. 데이터 전처리
/sz:preprocess "최신 데이터 전처리해줘"
/sz:preprocess "survey_2024.csv 파일 정제해줘"

# 2. 라벨링
/sz:label "데이터에 라벨 붙여줘"
/sz:label "코드북 적용해서 라벨링해줘"

# 3. Table 1 생성 (jstable 사용)
/sz:table "기초 특성표 만들어줘"
/sz:table "치료군별로 특성 비교표 만들어줘"

# 4. 생존분석 플롯 (jskm 사용)
/sz:plot "생존곡선 그려줘"
/sz:plot "Kaplan-Meier 플롯 만들어줘"

# 5. 통계 분석 Shiny 앱 (jsmodule 사용)
/sz:rshiny "데이터 분석 앱 만들어줘"
/sz:rshiny "의학통계 분석 앱 만들어줘"
```

## 🚀 다양한 자연어 요청 예시

```r
# 테이블
/sz:table "치료군별 기초 특성표 만들어줘"
/sz:table "연령대별 평균 혈압 테이블로 보여줘"
/sz:table "Cox 회귀분석 결과표 생성"
/sz:table "성별과 흡연 상태별 당뇨 유병률"

# 플롯
/sz:plot "생존 곡선 그려줘"
/sz:plot "연령대별 혈압 박스플롯"
/sz:plot "변수들 간의 상관관계 히트맵 보여줘"
/sz:plot "BMI 분포 히스토그램 그려줘"

# Shiny
/sz:rshiny "통계 분석 대시보드 만들어줘"
/sz:rshiny "생존분석 전용 앱 만들어줘"
/sz:rshiny "데이터 업로드하고 분석하는 앱"
```

## 📦 필요 패키지

### 핵심 패키지
- `data.table`, `tidyverse`, `openxlsx`

### 통계 패키지 (GitHub 링크)
- **jstable**: 의학통계 테이블 생성
  - GitHub: https://github.com/jinseob2kim/jstable
  - 문서: https://jinseob2kim.github.io/jstable/
- **jskm**: Kaplan-Meier 생존곡선
  - GitHub: https://github.com/jinseob2kim/jskm
  - 문서: https://jinseob2kim.github.io/jskm/
- **jsmodule**: Shiny 의학통계 모듈
  - GitHub: https://github.com/jinseob2kim/jsmodule
  - 문서: https://jinseob2kim.github.io/jsmodule/
- `survival`, `survminer`

### 시각화 패키지
- `ggplot2`, `plotly`, `pheatmap`

### Shiny 패키지
- `shiny`, `shinydashboard`, `DT`

## 🔄 마이그레이션 가이드

| 기존 명령어 | 새 명령어 | 변경사항 |
|------------|----------|----------|
| `/sz:jstable` | `/sz:table` | table 명령어에 통합 |
| `/sz:jskm` | `/sz:plot` | plot 명령어에 통합 |
| `/sz:jsmodule` | `/sz:rshiny` | rshiny 명령어에 통합 |
| `/sz:analysis` | 각 명령어 | 테이블/플롯에 분산 |

## ✅ 장점

1. **명령어 단순화**: 8개 → 5개로 감소
2. **기능 강화**: 각 명령어가 더 강력해짐
3. **일관성**: 통일된 인터페이스
4. **유연성**: 자연어 요청 지원
5. **호환성**: 기존 jstable/jskm/jsmodule 완전 지원