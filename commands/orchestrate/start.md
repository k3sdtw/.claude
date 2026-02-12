---
description: Start orchestrate workflow. Jira check → requirements Q&A → (issue creation) → branch setup → plan writing.
---

# Start Orchestrate

## 0. Idempotency Check

사용자가 제공한 Jira 키 또는 feature slug로 **기존 worktree가 있는지** 확인한다:

1. `git worktree list`를 실행하여 해당 identifier를 포함하는 worktree가 있는지 검색
2. 매칭되는 worktree가 있으면 → 해당 worktree의 `plans/*.state.json`을 Glob으로 검색
3. state가 존재하면:
   - AskUserQuestion: "기존 워크플로우({identifier}, phase: {currentPhase})를 이어서 진행할까요, 새로 시작할까요?"
   - 이어서 진행 → state의 `currentPhase`에 해당하는 sub-command 안내
   - 새로 시작 → 기존 state 파일 삭제 후 계속
4. 매칭되는 worktree가 없으면 → 정상 진행

## 1. Jira Check

AskUserQuestion으로 사용자에게 확인:

| 답변 | 행동 |
|------|------|
| 기존 Jira 키 입력 (예: GIFCA-123) | `mcp__jira__jira_get_issue`로 이슈 조회 → step 3 건너뜀 |
| 새로 만들겠다 | Q&A 후 step 3에서 이슈 생성 |
| Jira 없이 진행 | MODE = standalone, Jira 관련 step 모두 건너뜀 |

## 2. Requirements Q&A

사용자와 인터랙티브 인터뷰를 진행한다. 목표: 구현에 필요한 최소한의 명확한 요구사항 확보.

**AskUserQuestion 도구**로 프로젝트 타입에 따라 관련 항목만 선별하여 질문한다 (1회에 1~3개 질문, 최대 2회):

| 프로젝트 타입 | 필수 확인 항목 |
|---------------|----------------|
| Backend API | endpoint spec (method, path, request/response), validation rules, error scenarios |
| Frontend UI | 컴포넌트 구조, 상태 관리, UX 요구사항 |
| Fullstack | API contract + 화면 흐름 |
| 공통 | 목적과 사용자 가치, 외부 서비스 연동 여부 |

**종료 조건:**
- 사용자가 "진행해", "충분해" 등 명시적으로 종료 의사를 밝히면 즉시 종료
- 필수 항목이 모두 확인되면 종료
- 사용자가 간략한 답변을 해도 추론 가능하면 그대로 진행 (과도한 질문 금지)

**출력:** 구조화된 요구사항 문서 (plan 작성에 사용)

## 3. Create Jira Issue (새 이슈만 — 기존 키 or standalone이면 건너뜀)

AskUserQuestion으로 project key 확인 후:
```
mcp__jira__jira_create_issue({
  project_key: "{확인된 key}",
  summary: "{feature 요약}",
  issue_type: "Task",
  description: "## Background\n## Tasks\n## Done Criteria\n## References"
})
```

## 4. Workspace Detection

> **CRITICAL: gtr은 Git subcommand다. 반드시 `git gtr`로 실행해야 한다. `gtr` 단독 실행은 command not found.**

```bash
# CORRECT — 반드시 이 형태로 실행
git gtr list 2>/dev/null && echo "GTR_AVAILABLE" || echo "GTR_NOT_AVAILABLE"

# WRONG — 절대 이렇게 실행하지 않는다
# gtr list                    ← command not found
# gtr new branch-name         ← command not found
```

| 결과 | 행동 |
|------|------|
| `GTR_AVAILABLE` 출력 | WORKSPACE = worktree (기본, 항상 우선) |
| `GTR_NOT_AVAILABLE` 출력 또는 command not found | WORKSPACE = branch (fallback) |

> 이미 worktree 안에 있어도 (`.git`이 파일인 경우) WORKSPACE = worktree로 설정

## 5. Create Workspace (main에서 직접 개발 금지)

### Worktree (기본)

아래 명령어를 **정확히 이 순서로, 이 형태 그대로** 실행한다:

```bash
# 1. main repo root 저장
MAIN_REPO=$(git rev-parse --show-toplevel)

# 2. 브랜치명 결정
BRANCH_NAME="{JIRA-KEY}-{slug}"  # standalone이면 "{slug}"

# 3. worktree 생성 — 반드시 "git gtr" 형태로 실행
git gtr new "$BRANCH_NAME"
#    ^^^
#    "git gtr new" 이다. "gtr new"가 아니다.

# 4. worktree 경로 획득
WORKTREE_PATH=$(git worktree list | grep "$BRANCH_NAME" | awk '{print $1}')

# 5. worktree 진입 및 검증
cd "$WORKTREE_PATH"
[ "$(git branch --show-current)" = "$BRANCH_NAME" ] || echo "ERROR: worktree 진입 실패"
```

**자동 실행 항목** (수동 실행 불필요):
- `.gtrconfig`의 `[copy]` 패턴에 매칭되는 `.env` 파일 복사
- `[hooks] postCreate` 명령어 실행 (예: `pnpm install --frozen-lockfile`)

**반드시 worktree에 진입하고 브랜치를 검증한 후** 다음 단계로 진행한다.
이후 모든 작업(plan 작성, 파일 편집)은 worktree 안에서 수행한다.

### Branch (gtr 미설치 시 fallback만)

```bash
git checkout -b "{BRANCH_NAME}"
```

### 이미 동일 브랜치의 worktree가 존재하는 경우

`git worktree list`에서 해당 브랜치가 이미 보이면:
- AskUserQuestion: "이미 {BRANCH_NAME} worktree가 존재합니다. 해당 worktree를 사용할까요?"
- 예 → 기존 worktree 경로로 cd
- 아니오 → STOP

## 6. Write Plan + State (worktree 안에서)

**먼저 plans/ 디렉토리 생성:**
```bash
mkdir -p plans/
```

### 6a. Project Context 추출

프로젝트 CLAUDE.md는 Claude Code가 자동 로드하므로 이미 컨텍스트에 있다. 아래 값을 추출하여 state JSON에 저장한다:

1. **projectType**: CLAUDE.md의 Tech Stack / Overview를 보고 판별
   - NestJS, Express, Django, Gin 등 → `"backend"`
   - Next.js, React, Vue 등 → `"frontend"`
   - 양쪽 모두 → `"fullstack"`
   - 판별 불가 → 프로젝트 루트에서 파일 감지 (`nest-cli.json` → backend, `next.config.*` → frontend 등)
   - 그래도 불가 → AskUserQuestion으로 사용자에게 질문

2. **techStack**: CLAUDE.md에서 추출한 프레임워크 / 언어 조합 (예: `"NestJS / TypeScript"`)

3. **commands**: CLAUDE.md의 `## Commands` 섹션에서 lint, build, test 명령어 추출
   - 모노레포인 경우 작업 대상 패키지의 per-package CLAUDE.md에서 추출
   - 명령어를 찾을 수 없으면 → AskUserQuestion으로 사용자에게 직접 질문

### 6b. State JSON — `plans/{identifier}.state.json`

**가장 먼저 생성.** 모든 에이전트가 읽는 single source of truth.

Write 도구로 아래 JSON을 생성한다 (모든 필드를 채울 것):

```jsonc
{
  "identifier": "{jira-key 또는 slug}",
  "jiraKey": "{JIRA-KEY}",              // standalone이면 null
  "branchName": "{branch-name}",
  "baseBranch": "{main 또는 develop 등}", // `git symbolic-ref refs/remotes/origin/HEAD`로 감지. 감지 실패 시 "main"

  "worktreePath": "{worktree 절대 경로}",  // step 5에서 획득한 값
  "mainRepoPath": "{main repo 절대 경로}", // step 5의 MAIN_REPO 값
  "planFile": "{worktree 절대 경로}/plans/{identifier}.md",

  "projectType": "{backend | frontend | fullstack}",  // CLAUDE.md 또는 파일 감지로 판별
  "techStack": "{프레임워크 / 언어}",                  // 예: "NestJS / TypeScript"
  "commands": {                                        // CLAUDE.md ## Commands에서 추출
    "lint": "{lint 명령어}",
    "build": "{build 명령어}",
    "test": "{test 명령어}"
  },
  "workspace": "worktree",              // 또는 "branch"

  "currentPhase": "start",
  "gates": {
    "planConfirmed": false,
    "expertApproved": false,
    "prConfirmed": false
  },

  "expertReviews": {},

  "testDatabase": {
    "name": null,                   // 테스트 전용 DB 이름 (impl/done에서 생성)
    "url": null,                    // 치환된 DATABASE_URL
    "type": null                    // postgresql | mysql | sqlite | mongodb
  },

  "verification": {
    "lint": null,
    "build": null,
    "test": null,
    "lastRunAt": null
  },

  "pullRequest": {
    "url": null,
    "number": null
  },

  "createdAt": "{현재 ISO 8601}",
  "updatedAt": "{현재 ISO 8601}"
}
```

### 6c. Plan Markdown — `plans/{identifier}.md`

Write 도구로 사람이 읽는 플랜 문서를 생성한다. 포함할 내용:

1. **Tracking** — Jira 링크 또는 브랜치명 (standalone)
2. **Tech Stack** — 프로젝트 기술 스택 요약
3. **Requirements** — step 2에서 정리한 요구사항 요약
4. **Affected Layers** — CLAUDE.md의 아키텍처 정보 기반
5. **Implementation Phases** (반드시 이 정확한 헤딩명 사용) — phase별 작업 항목 + 병렬/순차 표시 + 에이전트 배정 테이블
6. **Risk Assessment** — 주의할 점, 의존성, 잠재 이슈
7. **Status** — "Plan ready — proceed with `/orchestrate:review`"

> 경로·키 등 메타데이터는 plan markdown에 중복 기재하지 않는다. State JSON이 single source of truth.

### 6d. Base Branch 감지

state JSON의 `baseBranch` 필드를 채운다:
```bash
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'
```
출력이 있으면 그 값을 사용 (예: `main`, `develop`). 출력이 없으면 `"main"`을 기본값으로 사용.

### 6e. Gate 1 — Plan Confirmation

두 파일 작성 완료 후:
1. 플랜의 핵심 요약(요구사항, phase 구조, 에이전트 배정)을 텍스트로 출력한다
2. AskUserQuestion으로 확인: "플랜을 승인하고 expert review로 진행할까요?"
   - 승인 → state 갱신 후 다음 phase 안내
   - 수정 요청 → 사용자 피드백 반영 후 재확인

사용자가 확인하면 → state JSON을 Read → 아래 필드 갱신 → Write:
```jsonc
{
  "gates": { "planConfirmed": true },
  "currentPhase": "review",
  "updatedAt": "{현재 ISO 8601}"
}
```

## Done Criteria

아래 조건이 **모두** 충족되어야 이 phase가 완료된 것이다:

- [ ] 요구사항이 명확하게 정리됨
- [ ] Worktree 생성 완료 + 현재 worktree 디렉토리 안에 위치
- [ ] `plans/{identifier}.state.json` 생성, 모든 필드 값이 채워짐
- [ ] `plans/{identifier}.md` 작성, 구현 플랜 포함
- [ ] Jira 이슈 확인 완료 (Jira mode인 경우)
- [ ] Gate 1 통과 (사용자가 플랜 확인)
- [ ] 검증: `pwd` = worktree 경로, `git branch --show-current` ≠ main

> `/orchestrate`로 실행 중이면 자동으로 review phase로 진행한다.
> 단독 실행(`/orchestrate:start`)이면 사용자에게 안내: `/orchestrate:review`
