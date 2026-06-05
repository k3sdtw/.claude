---
description: Full orchestrated workflow. Requirements → workspace → plan → expert review → implement → verify → ship (commit/PR).
---

# Orchestrate Workflow

E2E pipeline: requirements → workspace → plan → expert review → implement → verify → ship.

## Project Context (MUST be first)

프로젝트별 `.claude/` 디렉토리는 `/bootstrap` 명령으로 이미 구축되어 있다. orchestrate는 프로젝트의 기존 설정을 그대로 활용한다.

**컨텍스트 소스 (자동 로드됨):**
- **프로젝트 CLAUDE.md** — 기술 스택, 명령어(dev/build/test/lint), 아키텍처, 디렉토리 구조
- **per-package CLAUDE.md** — 모노레포인 경우 패키지별 상세
- **`.claude/rules/`** — 코드 스타일, git workflow, 테스팅, 보안 규칙

> Claude Code가 CLAUDE.md를 자동 로드하므로 별도 Read 없이 컨텍스트에서 참조 가능. 단, **sub-agent(Task)에는 전달되지 않으므로** state JSON에 핵심 값을 저장한다.

**Start phase에서 추출하여 state JSON에 저장할 값:**
1. `projectType` — CLAUDE.md의 Tech Stack 또는 파일 감지로 판별 (backend / frontend / fullstack)
2. `techStack` — 프레임워크 + 언어 요약 (예: "NestJS / TypeScript")
3. `commands.lint` / `commands.build` / `commands.test` — CLAUDE.md의 ## Commands 섹션에서 추출
4. 위 값을 찾을 수 없으면 → AskUserQuestion으로 사용자에게 직접 질문

## Workspace Mode

| Input | Mode |
|-------|------|
| (기본 — 플래그 없음) | **main** — 현재 체크아웃(main 브랜치)에서 직접 개발. 워크스페이스를 만들지 않는다 |
| `--worktree` flag | **worktree** — gtr로 격리된 worktree를 만들고 그 안에서 개발 |

| | main 모드 | worktree 모드 |
|---|----------|---------------|
| 개발 위치 | repo 루트 (현재 체크아웃) | gtr worktree |
| 브랜치 | 현재 브랜치 그대로 (보통 main) | `{identifier}` feature 브랜치 |
| 마무리 | **commit까지만** — push는 사용자가 직접 | commit → push → **PR 생성** |
| gtr 미설치 시 | 무관 | **STOP** — 설치 안내 |

## State Management

모든 orchestrate 워크플로우는 workPath의 `plans/` 디렉토리에 **두 파일**을 생성·관리한다:

| File | Purpose |
|------|---------|
| `plans/{identifier}.md` | 사람이 읽는 플랜 (요구사항, phase, 에이전트 배정) |
| `plans/{identifier}.state.json` | 에이전트가 읽는 머신 상태 |

> 두 파일은 워크플로우 메타데이터다. **커밋에 포함하지 않는다** (done phase에서 스테이징 제외).

### State JSON Schema

```jsonc
{
  "identifier": "add-dashboard",       // feature slug (kebab-case)
  "workspace": "main",                 // "main" 또는 "worktree"
  "branchName": null,                  // worktree 모드의 feature 브랜치. main 모드면 null
  "baseBranch": "main",                // PR 대상 브랜치 (worktree 모드에서 사용)

  "workPath": "/absolute/path",        // 모든 phase가 실행되는 디렉토리 (main 모드: repo 루트, worktree 모드: worktree 경로)
  "planFile": "/absolute/path/plans/add-dashboard.md",

  "projectType": "backend",            // "backend" / "frontend" / "fullstack"
  "techStack": "NestJS / TypeScript",  // CLAUDE.md에서 추출한 기술 스택 요약
  "commands": {                        // CLAUDE.md ## Commands에서 추출
    "lint": "pnpm lint",
    "build": "pnpm build",
    "test": "pnpm test:e2e"
  },

  "currentPhase": "start",             // "start" → "review" → "impl" → "done" → "completed"
  "gates": {
    "plan": false,                     // Gate 1: 플랜 승인
    "review": false,                   // Gate 2: expert review 승인
    "finish": false                    // Gate 3: commit/PR 승인
  },

  "expertReviews": {},                 // review phase에서 채워짐

  "attempts": {                        // 실패 루프 카운터 — state에 영속되어 세션이 끊겨도 한도 유지
    "planFix": 0,                      // review: 플랜 수정 순환 (최대 2)
    "implVerify": 0,                   // impl: verification 시도 (최대 3)
    "codeFix": 0,                      // done: 코드 리뷰 수정 순환 (최대 2)
    "doneVerify": 0                    // done: verification 시도 (최대 3)
  },

  "testDatabase": {
    "name": null,                      // 테스트 전용 DB 이름 (impl/done에서 생성)
    "url": null,                       // 치환된 DATABASE_URL
    "type": null                       // postgresql | mysql | sqlite | mongodb
  },

  "verification": {
    "lint": null,                      // null → "pass" 또는 "fail"
    "build": null,
    "test": null,
    "lastRunAt": null                  // ISO 8601 timestamp
  },

  "pullRequest": {                     // worktree 모드만 채워짐
    "url": null,
    "number": null
  },

  "createdAt": "2026-02-11T10:00:00Z",
  "updatedAt": "2026-02-11T10:30:00Z"
}
```

### State Read/Write Rules

1. **Start phase**가 state JSON을 생성 (모든 필드 초기화)
2. **모든 phase**는 시작 시 state를 Read로 읽고, 종료 시 Write로 갱신
3. 경로 등 메타데이터는 **반드시 state JSON에서 읽는다** — plan markdown을 파싱하지 않는다
4. Plan markdown은 사람용, state JSON은 에이전트용
5. timestamp는 `date -u +%Y-%m-%dT%H:%M:%SZ`로 생성한다

## State Guard Pattern (review/impl/done 공통)

모든 sub-command(start 제외)는 시작 시 아래 절차를 **순서대로** 수행한다. 어느 단계에서든 실패하면 **즉시 중단**하고 사용자에게 상황을 알린다.

1. **State 파일 탐색**: Glob으로 `plans/*.state.json` 검색
   - 파일 없음 → STOP: "state 파일이 없습니다. `/orchestrate:start`를 먼저 실행하세요"
   - 파일 1개 → 해당 파일 사용
   - 파일 여러 개 → 파일 목록과 각 identifier를 보여주고 AskUserQuestion으로 선택 요청
2. **State 읽기**: Read 도구로 state.json 파일을 읽고 JSON 파싱
3. **작업 디렉토리 전환**: `workPath` 디렉토리 존재를 확인하고 Bash로 `cd {workPath}` 실행 → 없으면 STOP. 이후 모든 Bash 명령은 이 디렉토리에서 실행된다
4. **브랜치 확인** (worktree 모드만): `git branch --show-current`가 state의 `branchName`과 일치하는지 확인 → 불일치 시 STOP. main 모드는 검증 생략
5. **필드 추출**: state에서 이번 phase에 필요한 값을 변수로 보관 (workspace, projectType, techStack, commands, planFile, branchName, baseBranch 등)
6. **Phase 진입**: state의 `currentPhase`를 현재 phase로, `updatedAt`을 현재 시각으로 갱신 → Write로 저장

## gtr 명령어 (CRITICAL — worktree 모드 전용)

gtr은 Git subcommand다. **반드시 `git gtr`로 실행한다.**

```
CORRECT:  git gtr new <branch>
WRONG:    gtr new <branch>        ← command not found
```

상세 레퍼런스: `~/.claude/rules/common/gtr-reference.md`
main 모드에서는 gtr을 사용하지 않는다.

## Mandatory Rules

1. 반드시 프로젝트 컨텍스트를 먼저 파악한다 (CLAUDE.md 기반)
2. **기본은 main 모드** — 현재 체크아웃에서 직접 개발하고, 워크스페이스를 만들지 않는다
3. `--worktree` 플래그가 있을 때만 worktree를 생성한다. gtr 미설치면 STOP하고 설치를 안내한다
4. **gtr 실행 형식** — 항상 `git gtr ...` 형태로 호출. `gtr ...`로 직접 호출 금지
5. 모든 phase는 state의 `workPath` 안에서 실행한다
6. Gate를 사용자 승인 없이 건너뛰지 않는다
7. Expert review·impl 에이전트는 반드시 병렬 실행한다 — **Workflow 도구 우선**, 미지원 시 Task 병렬 (각 sub-command 파일 참조)
8. **State JSON이 권위적 소스** — 에이전트는 state JSON에서 읽되, plan markdown을 파싱하지 않는다
9. **main 모드에서는 push·PR을 자동 실행하지 않는다** — commit까지만 하고 push는 사용자에게 안내한다

## Idempotency (재진입 처리)

- `/orchestrate:start` 재실행 시: 동일 identifier의 state.json이 이미 존재하면 → "기존 워크플로우를 이어서 진행할지, 새로 시작할지" AskUserQuestion으로 확인
- 이미 완료된 phase를 다시 실행하면: state의 currentPhase를 확인하고 → "이미 {phase}가 완료되었습니다. 다시 실행할까요?" 확인

## Pipeline Flow (자동 연속 실행)

`/orchestrate` 실행 시 4개 phase를 **하나의 세션에서 자동으로 연속 실행**한다.
사용자가 개별 sub-command를 입력할 필요 없다. Gate 확인만 하면 자동으로 다음 phase로 진행한다.

```
[Project Context] → automatic (CLAUDE.md 기반)
     ↓
[Phase 1: Start]   → workspace 설정 → context 추출 → state.json + plan.md 작성 → GATE 1
     ↓ (Gate 1 통과 시 자동 진행)
[Phase 2: Review]  → State Guard → parallel expert review → GATE 2
     ↓ (Gate 2 통과 시 자동 진행)
[Phase 3: Impl]    → State Guard → parallel agent implementation → verification
     ↓ (verification 통과 시 자동 진행)
[Phase 4: Done]    → State Guard → verify → code review → GATE 3 → ship (main: commit / worktree: commit+push+PR)
```

### Phase 실행 방법

각 phase의 상세 지침은 sub-command 파일에 정의되어 있다.
**Read 도구로 해당 파일을 읽고, 그 안의 지침을 그대로 수행한다.**

| 순서 | 파일 | 진입 조건 |
|------|------|-----------|
| 1 | `~/.claude/commands/orchestrate/start.md` | 즉시 시작 |
| 2 | `~/.claude/commands/orchestrate/review.md` | Gate 1 통과 (gates.plan = true) |
| 3 | `~/.claude/commands/orchestrate/impl.md` | Gate 2 통과 (gates.review = true) |
| 4 | `~/.claude/commands/orchestrate/done.md` | impl verification 통과 |

### 자동 진행 규칙

1. 각 phase 파일의 지침을 **끝까지** 수행한다
2. Gate에서 사용자 확인을 받으면 **즉시 다음 phase 파일을 Read하여 실행**한다
3. sub-command 파일 끝의 `→ 다음: /orchestrate:xxx` 안내는 **무시**한다 — 자동으로 진행한다
4. 어떤 phase에서든 STOP이 발생하면 전체 워크플로우를 중단하고 사용자에게 보고한다
5. **Gate 통과 직후**(다음 phase 파일을 Read하기 전)는 컨텍스트 압축의 최적 시점이다 — 컨텍스트가 길어졌다면 사용자에게 `/compact`를 제안한다. 재개 컨텍스트는 모두 state JSON에 있으므로 압축해도 안전하다

## Resuming Mid-Workflow (개별 sub-command)

세션이 끊기거나 중간부터 재개할 때는 개별 sub-command를 직접 실행한다:

```
/orchestrate:start   → Phase 1부터 시작
/orchestrate:review  → Phase 2부터 재개
/orchestrate:impl    → Phase 3부터 재개
/orchestrate:done    → Phase 4부터 재개
```

개별 sub-command 실행 시에는 해당 phase만 수행하고 종료한다 (자동 연속 실행 아님).
모든 재개 컨텍스트는 state JSON에서 로드한다.

## Output Language

사용자 facing 출력은 **한국어**를 기본으로 한다.

## Examples

```
/orchestrate add dashboard page                       # main 모드 (기본) — main에서 직접 개발, commit까지
/orchestrate --worktree add voucher notification      # worktree 모드 — 격리 개발 + PR 생성
```
