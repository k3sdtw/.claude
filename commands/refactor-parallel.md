---
description: 여러 리팩토링 전략을 병렬 에이전트로 동시 탐색. 테스트 통과를 gate로 검증된 최적 전략만 제안.
---

# Parallel Architecture Refactoring

여러 리팩토링 전략을 병렬로 탐색하고, 빌드/테스트 통과를 gate로 사용하여 검증된 전략만 제안합니다.

## Context

- NestJS + Hexagonal Architecture
- Turborepo build system
- Biome linter (ESLint 아님)
- Build: `pnpm build`, Test: `pnpm test:e2e:gifca`

## Process

### Step 1: 코드베이스 분석

TypeScript 소스 파일을 분석하여 다음을 식별하세요:
- 순환 import
- God module (>500 lines)
- 패키지 간 tight coupling
- Layer violation (domain이 infrastructure에 의존)

### Step 2: 전략 제안

3개의 리팩토링 전략을 제안하세요. 각 전략은 Hexagonal Architecture 원칙을 유지해야 합니다.

### Step 3: 병렬 구현

각 전략마다 병렬 Task agent를 생성하여:
1. `refactor/strategy-{n}` 브랜치 생성
2. 리팩토링 구현
3. `pnpm build` 실행 (실패 시 수정 후 재시도, 최대 5회)
4. `pnpm test:e2e:gifca` 최종 gate 실행
5. 의사결정과 trade-off 기록

### Step 4: 비교 보고

| Metric | Strategy 1 | Strategy 2 | Strategy 3 |
|--------|-----------|-----------|-----------|
| Circular imports | | | |
| Build pass | | | |
| Test pass rate | | | |
| Lines changed | | | |

최적 전략을 PR-ready 브랜치로 추천하세요.

## Safety

- main 브랜치에 직접 push 금지
- 기존 테스트가 깨지는 전략은 자동 탈락
- 각 브랜치는 `refactor/strategy-{n}` 네이밍
