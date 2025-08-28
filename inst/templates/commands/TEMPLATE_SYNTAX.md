# 템플릿 문법 가이드

## 플레이스홀더 변경 사항

### 이전 문법 (문제점)
- `$ARGUMENTS` - 마크다운에서 $ 기호가 수식으로 해석될 수 있음
- 일부 마크다운 렌더러에서 깨질 가능성

### 새로운 문법 옵션들

#### 옵션 1: 중괄호 사용 (권장)
```
{{USER_ARGUMENTS}}
{{args}}
{{input}}
```
- 장점: Handlebars/Mustache 스타일로 친숙함
- 단점: 없음

#### 옵션 2: 백틱으로 감싸기
```
`{{USER_ARGUMENTS}}`
```
- 장점: 마크다운에서 코드로 표시되어 안전
- 단점: 없음

#### 옵션 3: HTML 주석 스타일
```
<!-- USER_ARGUMENTS -->
```
- 장점: 마크다운 렌더링시 보이지 않음
- 단점: LLM이 놓칠 가능성

#### 옵션 4: 대괄호 사용
```
[[USER_ARGUMENTS]]
```
- 장점: 위키 스타일
- 단점: 일부 위키 시스템과 충돌 가능

## Claude Code와 Gemini 호환성

### Claude Code
- `$ARGUMENTS` 지원 (레거시)
- `{{args}}` 권장
- 백틱으로 감싼 형태도 인식

### Gemini CLI
- `{{args}}` 기본 지원
- 중괄호 문법이 표준

## 권장 사항

### 통합 명령어 v2에서는:
```markdown
## 사용자 입력
`{{USER_ARGUMENTS}}`
```

이렇게 사용하면:
1. 마크다운 렌더링 안전
2. Claude Code/Gemini 모두 호환
3. 코드블록으로 표시되어 명확함

## 변환 함수

```r
# setup_commands.R에서 자동 변환
convert_placeholder <- function(content, ai_type) {
  if (ai_type == "claude") {
    # Claude Code용
    content <- gsub("\\{\\{USER_ARGUMENTS\\}\\}", "$ARGUMENTS", content)
  } else if (ai_type == "gemini") {
    # Gemini용
    content <- gsub("\\{\\{USER_ARGUMENTS\\}\\}", "{{args}}", content)
  }
  return(content)
}
```

## 기타 플레이스홀더

### 추가 변수들
- `{{DATA_PATH}}` - 데이터 파일 경로
- `{{OUTPUT_PATH}}` - 출력 경로
- `{{OPTIONS}}` - 추가 옵션들
- `{{REQUEST}}` - 자연어 요청

### 조건부 섹션
```markdown
{{#if table_type}}
  테이블 타입: {{table_type}}
{{/if}}
```

## 마이그레이션 스크립트

기존 템플릿을 새 형식으로 변환:

```r
migrate_templates <- function(dir) {
  files <- list.files(dir, pattern = "\\.md$", full.names = TRUE)
  
  for (file in files) {
    content <- readLines(file, encoding = "UTF-8")
    
    # $ARGUMENTS를 {{USER_ARGUMENTS}}로 변경
    content <- gsub("\\$ARGUMENTS", "`{{USER_ARGUMENTS}}`", content)
    
    # 파일 다시 쓰기
    writeLines(content, file, useBytes = TRUE)
    
    message("Updated: ", basename(file))
  }
}
```