---
name: learn
description: 현재 세션에서 발견한 패턴, 규칙, 학습 사항을 검토하여 CLAUDE.md에 추가합니다.
allowed_tools: ["Read", "Write", "Edit", "Glob", "Grep", "Bash"]
---

# /learn - 세션 학습 및 CLAUDE.md 업데이트

현재 세션의 대화 내용을 분석하여 유용한 패턴, 규칙, 학습 사항을 추출하고 CLAUDE.md에 기록합니다.

## 분석 대상

세션에서 다음 항목들을 검토합니다:

### 1. 코딩 패턴 (Coding Patterns)
- 새로 발견된 아키텍처 패턴
- 반복적으로 사용된 코드 구조
- 프로젝트 특화 컨벤션

### 2. 에러 해결 (Error Solutions)
- 빌드/타입 에러 해결 방법
- 자주 발생하는 문제와 해결책
- 트러블슈팅 팁

### 3. 워크플로우 (Workflows)
- 효과적이었던 작업 순서
- 도구 사용 패턴
- 테스트/배포 프로세스

### 4. 프로젝트 규칙 (Project Rules)
- 코드 스타일 규칙
- 네이밍 컨벤션
- 금지 사항 (anti-patterns)

### 5. 의존성/설정 (Dependencies/Config)
- 새로 추가된 라이브러리
- 설정 변경 사항
- 환경 변수

## 실행 단계

### Step 1: 현재 CLAUDE.md 확인

```bash
# 프로젝트 루트의 CLAUDE.md 확인
cat ./CLAUDE.md 2>/dev/null || echo "CLAUDE.md not found"
```

### Step 2: 세션 분석

현재 세션에서 다음을 추출합니다:

| 카테고리 | 추출 대상 |
|---------|----------|
| **패턴** | 새로운 코드 패턴, 아키텍처 결정 |
| **규칙** | 명시적/암묵적 코딩 규칙 |
| **에러** | 해결된 에러와 해결 방법 |
| **팁** | 생산성 향상 팁, 단축키 |
| **금지** | 피해야 할 패턴, anti-patterns |

### Step 3: CLAUDE.md 업데이트

기존 내용과 중복되지 않는 새로운 항목만 추가합니다.

## CLAUDE.md 형식

```markdown
# Project Instructions

## Patterns
- [패턴 설명]

## Rules
- [규칙 설명]

## Error Solutions
### [에러 유형]
- 원인: [원인 설명]
- 해결: [해결 방법]

## Workflows
### [워크플로우 이름]
1. [단계 1]
2. [단계 2]

## Anti-patterns
- [피해야 할 패턴]

## Session Log
- [YYYY-MM-DD] [학습 내용 요약]
```

## 출력 예시

```
## 세션 분석 결과

### 새로 발견된 패턴
1. **Entity Factory Pattern** - LuxProduct.create() / reconstitute() 패턴
2. **Symbol Token DI** - Repository 인터페이스에 Symbol 토큰 사용

### 해결된 에러
1. **TypeScript strict mode 에러** - private 필드에 definite assignment assertion 필요

### 추가된 규칙
1. 날짜는 dayjs 사용, 'YYYY-MM-DD HH:mm:ss' 형식 통일

### CLAUDE.md 업데이트 완료
- 3개 패턴 추가
- 1개 에러 해결책 추가
- 1개 규칙 추가
```

## 사용법

```bash
/learn                    # 현재 세션 분석 및 CLAUDE.md 업데이트
/learn --dry-run          # 업데이트 미리보기 (실제 쓰기 없음)
/learn --category patterns # 특정 카테고리만 분석
```

## 주의사항

- 민감한 정보(API 키, 비밀번호)는 절대 기록하지 않습니다
- 프로젝트 특화 내용만 기록합니다 (일반적인 지식 제외)
- 기존 내용과 중복되는 항목은 건너뜁니다
- 불확실한 패턴은 `[검토 필요]` 태그를 붙입니다

## 관련 명령어

- `/skill-create` - Git 히스토리에서 패턴 추출
- `/code-review` - 코드 품질 검토
- `/plan` - 구현 계획 수립
