# SuperZarathu Framework

## 1. 개요 (Overview)

SuperZarathu는 R을 이용한 통계 분석 전 과정을 AI 코드 어시스턴트(예: Gemini, Claude)와 함께 체계적이고 효율적으로 수행하기 위해 설계된 **프롬프트 엔지니어링 프레임워크**입니다.

이 프레임워크는 복잡한 분석 작업을 표준화된 단계로 나누고, 각 단계에 맞는 명확한 "지시서(Instructional Template)"를 제공함으로써 AI 어시스턴트의 작업 일관성과 결과물의 품질을 높이는 것을 목표로 합니다.

## 2. 작동 방식 (How It Works)

SuperZarathu는 사용자와 AI 어시스턴트 간의 특정 상호작용 프로토콜을 정의합니다.

1.  **사용자**: 수행할 분석 단계를 결정하고, 아래의 명령어 목록에서 원하는 작업을 선택합니다.
2.  **사용자**: AI 어시스턴트에게 `/sz:<명령어>` 형식으로 명령을 내립니다. (예: `/sz:preprocess`)
3.  **AI 어시스턴트**: 지정된 명령어에 해당하는 마크다운 지시서를 읽고, 그 안에 정의된 목표, 프로세스, 산출물 형식에 따라 사용자와 상호작용하며 과제를 수행합니다.

## 3. 명령어 (Commands)

| 명령어 | 대응 템플릿 | 설명 |
| --- | --- | --- |
| `/sz:preprocess` | `template_1_preprocessing.md` | 데이터 전처리 및 정제 |
| `/sz:label` | `template_2_labeling.md` | 변수 레이블링 및 데이터 사전 생성 |
| `/sz:analyze` | `template_3_analysis.md` | 기술 통계 및 기본 분석 |
| `/sz:shiny` | `template_4_shiny.md` | R Shiny 애플리케이션 개발 |
| `/sz:table1` | `template_5_jstable.md` | `jstable`을 이용한 Table 1 생성 |
| `/sz:km` | `template_6_jskm.md` | `jskm`을 이용한 생존 분석 |
| `/sz:module` | `template_7_jsmodule.md` | R Shiny 모듈 개발 |

## 4. 핵심 구성요소 (Core Components)

*   **/templates**: 프레임워크의 핵심인 **지시서 템플릿**들이 위치하는 디렉토리입니다.
*   **/docs**: 프레임워크에 대한 상세 문서나 배경 지식을 저장합니다.
*   **/examples**: 프레임워크를 사용하여 생성된 R 코드나 결과물의 예시를 저장합니다.
