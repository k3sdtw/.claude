# Bootstrap: .claude 폴더 자동 생성 커맨드

당신은 현재 레포지토리를 면밀히 분석하여 최적화된 `.claude/` 폴더 구조를 생성하는 부트스트랩 에이전트입니다.

아래 단계를 **순서대로, 빠짐없이** 수행하세요.

---

## Phase 1: 레포지토리 심층 분석

아래 항목들을 모두 조사하세요. 충분한 파일을 직접 열어보고 판단하세요.

### 1-1. 프로젝트 메타데이터
- `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `build.gradle`, `pom.xml`, `Gemfile`, `composer.json`, `*.csproj`, `Makefile`, `CMakeLists.txt` 등 빌드/의존성 파일 확인
- README, CONTRIBUTING, LICENSE 확인

### 1-2. 기술 스택 식별
- **언어**: 주 언어, 보조 언어, 언어 버전
- **프레임워크**: (React, Next.js, Django, FastAPI, Spring, Rails, etc.)
- **패키지 매니저**: (npm, pnpm, yarn, pip, poetry, cargo, etc.)
- **빌드 도구**: (webpack, vite, esbuild, tsc, gradle, maven, etc.)
- **테스트 프레임워크**: (jest, pytest, vitest, go test, rspec, etc.)
- **린터/포매터**: (eslint, prettier, ruff, black, clippy, etc.)
- **CI/CD**: (.github/workflows, .gitlab-ci.yml, Jenkinsfile, etc.)
- **인프라**: (Docker, Kubernetes, Terraform, CDK, etc.)
- **DB/ORM**: (Prisma, TypeORM, SQLAlchemy, Diesel, etc.)

### 1-3. 아키텍처 분석
- 디렉토리 구조 파악 (모노레포 여부, src 구조, 레이어 구분)
- 진입점(entry point) 파악
- 핵심 모듈/패키지 식별
- API 라우트 구조 (있다면)
- 상태 관리 패턴 (있다면)
- 에러 처리 패턴

### 1-4. 코드 컨벤션 분석
- 네이밍 컨벤션 (camelCase, snake_case, PascalCase 등)
- import 스타일 및 순서
- 파일/폴더 명명 규칙
- 주석 스타일
- 타입 사용 패턴 (TypeScript strict, Python type hints 등)
- 기존 `.editorconfig`, `tsconfig.json`, `eslintrc` 등에서 컨벤션 추출

### 1-5. 개발 워크플로우 분석
- 브랜치 전략 (git log, branch 목록 참고)
- 커밋 메시지 컨벤션 (conventional commits 여부 등)
- PR 템플릿 존재 여부
- 테스트 커버리지 설정

---

## Phase 2: .claude 폴더 구조 생성

분석 결과를 바탕으로 아래 파일들을 **모두** 생성하세요.

```
.claude/
├── CLAUDE.md                  # 프로젝트 마스터 컨텍스트
├── settings.json              # Claude Code 설정
├── rules/
│   ├── code-style.md          # 코드 스타일 규칙
│   ├── architecture.md        # 아키텍처 규칙
│   ├── testing.md             # 테스트 규칙
│   ├── git-workflow.md        # Git 워크플로우 규칙
│   ├── error-handling.md      # 에러 처리 규칙
│   └── security.md            # 보안 규칙
├── agents/
│   ├── code-reviewer.md       # 코드 리뷰 에이전트
│   ├── refactorer.md          # 리팩토링 에이전트
│   ├── test-writer.md         # 테스트 작성 에이전트
│   ├── doc-writer.md          # 문서 작성 에이전트
│   └── debugger.md            # 디버깅 에이전트
├── skills/
│   ├── feature-implementation.md   # 새 기능 구현 스킬
│   ├── bug-fix.md                  # 버그 수정 스킬
│   ├── migration.md                # 마이그레이션 스킬
│   └── performance-optimization.md # 성능 최적화 스킬
└── commands/
    ├── review.md              # 코드 리뷰 커맨드
    ├── test.md                # 테스트 작성 커맨드
    ├── refactor.md            # 리팩토링 커맨드
    ├── fix.md                 # 버그 수정 커맨드
    └── docs.md                # 문서 생성 커맨드
```

---

## Phase 3: 각 파일 작성 가이드

### 3-1. CLAUDE.md (마스터 컨텍스트)

이 파일은 Claude가 이 프로젝트에서 작업할 때 **가장 먼저 읽는 파일**입니다. 반드시 아래 섹션을 포함하세요:

```markdown
# {프로젝트명}

## Project Overview
- 프로젝트의 목적, 핵심 기능 한 문단 요약
- 대상 사용자 / 유스케이스

## Tech Stack
- 언어, 프레임워크, 주요 라이브러리 목록 (버전 포함)
- 빌드 도구, 패키지 매니저

## Architecture
- 고수준 아키텍처 설명 (레이어, 모듈 구조)
- 핵심 디렉토리와 역할 설명
- 데이터 흐름 요약

## Development Setup
- 의존성 설치 커맨드
- 개발 서버 실행 커맨드
- 환경변수 설정 (.env 구조)

## Key Commands
- build, test, lint, format, deploy 등 주요 커맨드 정리

## Code Conventions
- 네이밍, import, 파일 구조 규칙 요약
- 사용하는 린터/포매터와 설정 위치

## Testing Strategy
- 테스트 프레임워크, 실행 방법
- 테스트 파일 위치 규칙, 네이밍 규칙
- 커버리지 목표 (있다면)

## Important Patterns
- 이 프로젝트에서 반복적으로 사용되는 패턴
- 에러 처리, 로깅, 인증 등의 표준 방식

## Known Constraints & Gotchas
- 주의해야 할 점, 알려진 제약사항
- 피해야 할 안티패턴
```

### 3-2. settings.json

```json
{
  "permissions": {
    "allow": [
      // 프로젝트에서 실제 사용하는 커맨드만 허용
      // 예: "npm test", "npm run lint", "pytest", "cargo test" 등
    ],
    "deny": [
      // 위험한 커맨드 차단
      // 예: "rm -rf /", "DROP TABLE", 프로덕션 배포 커맨드 등
    ]
  }
}
```

프로젝트에서 실제 사용하는 빌드/테스트/린트 커맨드를 `allow`에, 위험 커맨드를 `deny`에 넣으세요.

### 3-3. rules/ (규칙 파일들)

각 규칙 파일은 아래 형식을 따르세요:

```markdown
# {규칙 카테고리}

## 원칙
- 이 프로젝트에서 지켜야 할 핵심 원칙 (구체적이고 실행 가능한 수준)

## DO (반드시 따를 것)
- 프로젝트 코드에서 실제로 관찰된 패턴 기반으로 작성
- 구체적인 코드 예시 포함

## DON'T (절대 하지 말 것)
- 프로젝트에서 피하는 안티패턴
- 구체적인 나쁜 예시와 이유

## Examples
- 프로젝트 코드에서 추출한 실제 좋은 예시 / 나쁜 예시
```

**중요**: 일반적인 프로그래밍 규칙이 아니라 **이 프로젝트 고유의 컨벤션**을 반영하세요. 실제 코드를 분석하여 패턴을 추출하세요.

### 3-4. agents/ (에이전트 정의)

각 에이전트 파일은 아래 형식을 따르세요:

```markdown
# {Agent Name}

## Role
- 이 에이전트의 역할과 책임 한 문단 정의

## Expertise
- 이 에이전트가 전문성을 갖는 영역 (프로젝트 기술 스택 기반)

## Workflow
1. 단계별 작업 절차 (이 프로젝트의 도구/커맨드에 맞춤)
2. ...

## Rules
- 이 에이전트가 반드시 따라야 할 규칙
- 참조할 rules/ 파일 명시

## Output Format
- 이 에이전트의 출력 형식 정의

## Tools & Commands
- 이 에이전트가 사용할 수 있는 커맨드 목록 (프로젝트에 실재하는 것만)
```

### 3-5. skills/ (스킬 정의)

각 스킬 파일은 아래 형식을 따르세요:

```markdown
# {Skill Name}

## Purpose
- 이 스킬이 해결하는 문제

## Prerequisites
- 이 스킬을 사용하기 전 확인해야 할 사항

## Step-by-Step Process
1. 체계적인 실행 절차 (프로젝트 구조에 맞춤)
2. ...

## Checklist
- [ ] 완료 전 확인해야 할 항목들

## Templates
- 이 스킬에서 생성하는 코드/파일의 템플릿 (프로젝트 컨벤션 반영)

## Examples
- 프로젝트 내 실제 사례 참조
```

### 3-6. commands/ (커스텀 커맨드)

각 커맨드 파일은 `/commands/{name}.md` 형식이며, 슬래시 커맨드로 실행됩니다:

```markdown
# {Command}: {간단한 설명}

{이 커맨드가 실행될 때 Claude가 수행할 구체적인 지시사항}

## Input
- $ARGUMENTS (사용자 입력 인자 설명)

## Process
1. 단계별 실행 절차

## Output
- 예상 출력 형식
```

---

## Phase 4: 검증 및 마무리

1. 생성된 모든 파일을 다시 읽어서 **프로젝트 실제 내용과 일치하는지** 검증
2. 존재하지 않는 커맨드, 잘못된 경로, 부정확한 기술 스택 참조가 없는지 확인
3. 모든 규칙과 예시가 **실제 코드 분석 결과**에 기반하는지 확인
4. 최종 요약 출력:
   - 감지된 기술 스택
   - 생성된 파일 목록
   - 주요 컨벤션 요약
   - 추가 커스터마이징 권장 사항

---

## 핵심 원칙

- **구체적일 것**: "클린 코드를 작성하라" 같은 일반론이 아니라 "함수명은 `handle{Event}` 패턴을 따르고, 컴포넌트는 `{Feature}.tsx`로 명명한다" 수준으로 구체적이어야 합니다.
- **실증적일 것**: 반드시 실제 코드를 읽고 패턴을 추출하세요. 추측하지 마세요.
- **실용적일 것**: 생성된 모든 파일이 Claude의 실제 작업에 즉시 도움이 되어야 합니다.
- **프로젝트에 맞출 것**: 이 레포지토리에만 해당하는 고유한 설정을 만드세요. 범용 템플릿을 복사하지 마세요.

지금 바로 현재 레포지토리 분석을 시작하세요.
