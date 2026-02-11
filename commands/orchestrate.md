---
description: Full orchestrated workflow. Requirements → branch → plan → expert review → implement → verify → PR. Jira optional.
---

# Orchestrate Workflow

E2E pipeline: requirements → branch → plan → expert review → implement → verify → PR.

## Project Context (MUST be first)

프로젝트별 `.claude/` 디렉토리는 `/bootstrap` 명령으로 이미 구축되어 있다. orchestrate는 프로젝트의 기존 설정을 그대로 활용한다.

**컨텍스트 소스 (자동 로드됨):**
- **프로젝트 CLAUDE.md** — 기술 스택, 명령어(dev/build/test/lint), 아키텍처, 디렉토리 구조
- **per-package CLAUDE.md** — 모노레포인 경우 패키지별 상세 (worktree 진입 시 자동 로드)
- **`.claude/rules/`** — 코드 스타일, git workflow, 테스팅, 보안 규칙

> Claude Code가 CLAUDE.md를 자동 로드하므로 별도 Read 없이 컨텍스트에서 참조 가능. 단, **sub-agent(Task)에는 전달되지 않으므로** state JSON에 핵심 값을 저장한다.

**Start phase에서 추출하여 state JSON에 저장할 값:**
1. `projectType` — CLAUDE.md의 Tech Stack 또는 파일 감지로 판별 (backend / frontend / fullstack)
2. `techStack` — 프레임워크 + 언어 요약 (예: "NestJS / TypeScript")
3. `commands.lint` / `commands.build` / `commands.test` — CLAUDE.md의 ## Commands 섹션에서 추출
4. 위 값을 찾을 수 없으면 → AskUserQuestion으로 사용자에게 직접 질문

## Mode Detection

| Input | Mode |
|-------|------|
| Jira key (`[A-Z]+-[0-9]+`) | jira |
| `--no-jira` flag | standalone |
| Feature description only | AskUserQuestion으로 Jira 사용 여부 질문 |

## State Management

모든 orchestrate 워크플로우는 worktree의 `plans/` 디렉토리에 **두 파일**을 생성·관리한다:

| File | Purpose |
|------|---------|
| `plans/{identifier}.md` | 사람이 읽는 플랜 (요구사항, phase, 에이전트 배정) |
| `plans/{identifier}.state.json` | 에이전트가 읽는 머신 상태 |

### State JSON Schema

```jsonc
{
  "identifier": "GIFCA-123",           // Jira key 또는 feature slug (예: "add-dashboard")
  "jiraKey": "GIFCA-123",              // standalone이면 null
  "branchName": "GIFCA-123-voucher-feature",
  "baseBranch": "main",               // PR 대상 브랜치 (main, develop, master 등)

  "worktreePath": "/absolute/path/to/worktree",
  "mainRepoPath": "/absolute/path/to/main-repo",
  "planFile": "/absolute/path/to/plans/GIFCA-123.md",

  "projectType": "backend",            // "backend" / "frontend" / "fullstack"
  "techStack": "NestJS / TypeScript", // CLAUDE.md에서 추출한 기술 스택 요약
  "commands": {                        // CLAUDE.md ## Commands에서 추출
    "lint": "pnpm lint",
    "build": "pnpm build",
    "test": "pnpm test:e2e"
  },
  "workspace": "worktree",            // "worktree" 또는 "branch"

  "currentPhase": "start",            // "start" → "review" → "impl" → "done" → "completed"
  "gates": {
    "planConfirmed": false,
    "expertApproved": false,
    "prConfirmed": false
  },

  "expertReviews": {},                 // review phase에서 채워짐

  "verification": {
    "lint": null,                      // null → "pass" 또는 "fail"
    "build": null,
    "test": null,
    "lastRunAt": null                  // ISO 8601 timestamp
  },

  "pullRequest": {
    "url": null,                       // PR 생성 후 URL
    "number": null                     // PR 번호
  },

  "createdAt": "2026-02-11T10:00:00Z",
  "updatedAt": "2026-02-11T10:30:00Z"
}
```

### State Read/Write Rules

1. **Start phase**가 state JSON을 생성 (모든 필드 초기화)
2. **모든 phase**는 시작 시 state를 Read로 읽고, 종료 시 Write로 갱신
3. 경로·키 등 메타데이터는 **반드시 state JSON에서 읽는다** — plan markdown을 파싱하지 않는다
4. Plan markdown은 사람용, state JSON은 에이전트용

## State Guard Pattern (review/impl/done 공통)

모든 sub-command(start 제외)는 시작 시 아래 절차를 **순서대로** 수행한다. 어느 단계에서든 실패하면 **즉시 중단**하고 사용자에게 상황을 알린다.

1. **State 파일 탐색**: Glob으로 `plans/*.state.json` 검색
   - 파일 없음 → STOP: "state 파일이 없습니다. `/orchestrate:start`를 먼저 실행하세요"
   - 파일 1개 → 해당 파일 사용
   - 파일 여러 개 → 파일 목록과 각 identifier를 보여주고 AskUserQuestion으로 선택 요청
2. **State 읽기**: Read 도구로 state.json 파일을 읽고 JSON 파싱
3. **Worktree 확인**: `worktreePath`의 디렉토리가 존재하는지 Bash `ls {worktreePath}`로 확인
   - 디렉토리 없음 → STOP: "worktree 경로가 존재하지 않습니다"
4. **작업 디렉토리 전환**: Bash로 `cd {worktreePath}` 실행. 이후 모든 Bash 명령은 이 디렉토리에서 실행된다.
   (Claude Code의 Bash 도구는 cd를 통해 working directory가 유지됨)
5. **브랜치 확인**: `git branch --show-current` 실행 → main 또는 master면 STOP
6. **필드 추출**: state에서 이번 phase에 필요한 값을 변수로 보관 (jiraKey, projectType, techStack, commands, planFile, branchName, baseBranch 등)
7. **Phase 진입**: state의 `currentPhase`를 현재 phase로, `updatedAt`을 현재 시각으로 갱신 → Write로 저장

## gtr 명령어 (CRITICAL)

gtr은 Git subcommand다. **반드시 `git gtr`로 실행한다.**

```
CORRECT:  git gtr new <branch>
WRONG:    gtr new <branch>        ← command not found
```

상세 레퍼런스: `~/.claude/rules/common/gtr-reference.md`

## Mandatory Rules

1. 반드시 프로젝트 컨텍스트를 먼저 파악한다 (CLAUDE.md 기반)
2. 반드시 별도 workspace를 생성한다 (main에서 직접 개발 금지)
3. **Worktree 우선** — `git gtr list`가 성공하면 항상 worktree 사용. 실패 시에만 branch fallback
4. **gtr 실행 형식** — 항상 `git gtr ...` 형태로 호출. `gtr ...`로 직접 호출 금지
5. **Worktree 컨텍스트** — 모든 phase는 worktree 디렉토리 안에서 실행
6. Gate를 사용자 승인 없이 건너뛰지 않는다
7. Expert review는 반드시 병렬 실행한다
8. **State JSON이 권위적 소스** — 에이전트는 state JSON에서 읽되, plan markdown을 파싱하지 않는다

## Idempotency (재진입 처리)

- `/orchestrate:start` 재실행 시: 동일 identifier의 state.json이 이미 존재하면 → "기존 워크플로우를 이어서 진행할지, 새로 시작할지" AskUserQuestion으로 확인
- 이미 완료된 phase를 다시 실행하면: state의 currentPhase를 확인하고 → "이미 {phase}가 완료되었습니다. 다시 실행할까요?" 확인

## Pipeline Flow

```
[Project Context] → automatic (CLAUDE.md 기반)
     ↓
[Phase 1: Start]   → create worktree → extract context → write state.json + plan.md → GATE 1
     ↓
[Phase 2: Review]  → State Guard → parallel expert review → GATE 2
     ↓
[Phase 3: Impl]    → State Guard → parallel agent implementation → verification
     ↓
[Phase 4: Done]    → State Guard → verify → code review → commit → PR → GATE 3
```

각 phase는 sub-command에 매핑된다. Gate는 사용자의 명시적 확인이 필요하다.

## Resuming Mid-Workflow

```
/orchestrate:start   → Phase 1 (state.json 생성)
/orchestrate:review  → Phase 2 (state.json 읽기)
/orchestrate:impl    → Phase 3 (state.json 읽기)
/orchestrate:done    → Phase 4 (state.json 읽기)
```

모든 재개 컨텍스트(projectType, techStack, commands, worktree path, Jira key, gate 상태)는 state JSON에서 로드한다.

## Output Language

사용자 facing 출력은 **한국어**를 기본으로 한다.

## Examples

```
/orchestrate GIFCA-123                                    # Jira mode
/orchestrate GIFCA-456                                    # Jira mode
/orchestrate --no-jira add dashboard page                 # Standalone
/orchestrate add voucher expiration notification           # Auto-detect mode
```
