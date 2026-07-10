---
description: Start orchestrate workflow. Requirements Q&A → workspace setup → plan writing.
---

# Start Orchestrate

## 0. Idempotency Check

1. 현재 repo의 `plans/*.state.json`을 Glob으로 검색한다
2. 동일하거나 유사한 identifier의 state가 존재하면:
   - AskUserQuestion: "기존 워크플로우({identifier}, phase: {currentPhase})를 이어서 진행할까요, 새로 시작할까요?"
   - 이어서 진행 → state의 `currentPhase`에 해당하는 sub-command로 재개
   - 새로 시작 → 기존 state 파일 삭제 후 계속
3. worktree 모드(기본)면 `git worktree list`로 동일 identifier의 worktree도 확인한다
4. 매칭되는 것이 없으면 → 정상 진행

## 1. Requirements Q&A

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

> **자율 모드에서도 이 Q&A는 축소하지 않는다.** 자율 진행은 게이트 승인을 생략할 뿐, 요구사항 명확화는 그대로 유지한다. 필수 스펙이 없거나 여러 해석이 가능해 구현이 실질적으로 달라지는 항목은 [에스컬레이션 조건](../orchestrate.md#autonomy-mode-게이트-자동-통과-vs-승인) 1번에 따라 반드시 질문한다.

**출력:** 구조화된 요구사항 문서 (plan 작성에 사용)

## 2. Identifier 결정

feature 요약에서 kebab-case slug를 생성한다 (예: `add-dashboard`, `voucher-notification`).
이 값이 state의 `identifier`이자, worktree 모드의 브랜치명이 된다.

## 3. Workspace Setup

**Workspace 판별** — 플래그로 모드를 정한다: **플래그 없음 → worktree (기본)**, `--main` → main.

**Autonomy 결정** ([orchestrate.md](../orchestrate.md#autonomy-mode-게이트-자동-통과-vs-승인) 기준) — workspace와 플래그로 `autonomy`를 확정해 state에 기록한다:

| workspace | `--gated` | autonomy |
|-----------|:---------:|----------|
| worktree (기본) | 없음 | `auto` (게이트 자동 통과) |
| worktree (기본) | 있음 | `gated` |
| main (`--main`) | 무관 | `gated` (자율 모드는 worktree 전용) |

> 기본 경로는 **worktree 모드**다. 아래 두 절 중 해당하는 모드의 절차를 수행한다.

### main 모드 (`--main` 플래그)

워크스페이스를 만들지 않는다. **현재 체크아웃에서 그대로 개발한다.**

```bash
WORK_PATH=$(git rev-parse --show-toplevel)
git status --porcelain
```

- `workspace = "main"`, `branchName = null`, `workPath = WORK_PATH`, **`autonomy = "gated"`**
- 자율 모드는 worktree 전용이다. `--main`으로 실행하면 **"main 모드는 게이트 승인 방식으로 진행합니다. 무인 진행(→ PR)이 필요하면 플래그 없이(기본 worktree) 실행하세요"**를 1줄 안내한다 ([safety.md](../../rules/devops/safety.md) §4 — 실제 main/master 직접 commit 방지).
- working tree에 **기존 변경사항이 있으면** 사용자에게 알리고 진행 여부를 확인한다 — orchestrate의 변경분과 섞여 커밋 범위가 오염되는 것을 방지

### worktree 모드 (기본 — 플래그 없음)

> **CRITICAL: gtr은 Git subcommand다. 반드시 `git gtr`로 실행해야 한다. `gtr` 단독 실행은 command not found.**

```bash
# CORRECT — 반드시 이 형태로 실행
git gtr list 2>/dev/null && echo "GTR_AVAILABLE" || echo "GTR_NOT_AVAILABLE"

# WRONG — 절대 이렇게 실행하지 않는다
# gtr list                    ← command not found
```

| 결과 | 행동 |
|------|------|
| `GTR_AVAILABLE` | worktree 생성 진행 |
| `GTR_NOT_AVAILABLE` | **STOP**: "gtr(git-worktree-runner)이 설치되어 있지 않습니다. 설치 후 다시 실행하거나, `--main`으로 main 모드(게이트 승인, commit까지)로 진행하세요" |

아래 명령어를 **정확히 이 순서로, 이 형태 그대로** 실행한다:

```bash
# 1. 브랜치명 = identifier
BRANCH_NAME="{identifier}"

# 2. worktree 생성 — 반드시 "git gtr" 형태로 실행
git gtr new "$BRANCH_NAME"

# 3. worktree 경로 획득
WORK_PATH=$(git worktree list | grep "$BRANCH_NAME" | awk '{print $1}')

# 4. worktree 진입 및 검증
cd "$WORK_PATH"
[ "$(git branch --show-current)" = "$BRANCH_NAME" ] || echo "ERROR: worktree 진입 실패"
```

**자동 실행 항목** (수동 실행 불필요):
- `.gtrconfig`의 `[copy]` 패턴에 매칭되는 `.env` 파일 복사
- `[hooks] postCreate` 명령어 실행 (예: `pnpm install --frozen-lockfile`)

**반드시 worktree에 진입하고 브랜치를 검증한 후** 다음 단계로 진행한다.
이후 모든 작업(plan 작성, 파일 편집)은 worktree 안에서 수행한다.

**이미 동일 브랜치의 worktree가 존재하는 경우:**
- AskUserQuestion: "이미 {BRANCH_NAME} worktree가 존재합니다. 해당 worktree를 사용할까요?"
- 예 → 기존 worktree 경로로 cd
- 아니오 → STOP

## 4. Write Plan + State (workPath 안에서)

**먼저 plans/ 디렉토리 생성:**
```bash
mkdir -p plans/
```

> plan·state 파일은 워크플로우 메타데이터다. **커밋에 포함하지 않는다.**

### 4a. Project Context 추출

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

### 4b. Base Branch 감지

```bash
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'
```
출력이 있으면 그 값을 사용 (예: `main`, `develop`). 출력이 없으면 `"main"`을 기본값으로 사용.

### 4c. State JSON — `plans/{identifier}.state.json`

**가장 먼저 생성.** 모든 에이전트가 읽는 single source of truth.

Write 도구로 아래 JSON을 생성한다 (모든 필드를 채울 것):

```jsonc
{
  "identifier": "{slug}",
  "workspace": "{main | worktree}",
  "branchName": "{worktree 모드: identifier, main 모드: null}",
  "baseBranch": "{4b에서 감지한 값}",

  "workPath": "{step 3에서 획득한 절대 경로}",
  "planFile": "{workPath}/plans/{identifier}.md",

  "projectType": "{backend | frontend | fullstack}",
  "techStack": "{프레임워크 / 언어}",
  "commands": {
    "lint": "{lint 명령어}",
    "build": "{build 명령어}",
    "test": "{test 명령어}"
  },

  "currentPhase": "start",
  "autonomy": "{auto | gated — step 3의 Autonomy 결정 표}",
  "gates": {
    "plan": false,
    "review": false,
    "finish": false
  },

  "expertReviews": {},

  "attempts": {
    "planFix": 0,
    "implVerify": 0,
    "codeFix": 0,
    "doneVerify": 0
  },

  "testDatabase": {
    "name": null,
    "url": null,
    "type": null
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

  "createdAt": "{현재 ISO 8601 — date -u +%Y-%m-%dT%H:%M:%SZ}",
  "updatedAt": "{현재 ISO 8601}"
}
```

### 4d. Plan Markdown — `plans/{identifier}.md`

Write 도구로 사람이 읽는 플랜 문서를 생성한다. 포함할 내용:

1. **Workspace** — 모드(main/worktree) + 브랜치명
2. **Tech Stack** — 프로젝트 기술 스택 요약
3. **Requirements** — step 1에서 정리한 요구사항 요약
4. **Affected Layers** — CLAUDE.md의 아키텍처 정보 기반
5. **Implementation Phases** (반드시 이 정확한 헤딩명 사용) — phase별 작업 항목 + 병렬/순차 표시 + 에이전트 배정 테이블
6. **Risk Assessment** — 주의할 점, 의존성, 잠재 이슈
7. **Status** — "Plan ready — proceed with `/orchestrate:review`"

> 경로 등 메타데이터는 plan markdown에 중복 기재하지 않는다. State JSON이 single source of truth.

### 4e. Gate 1 — Plan Confirmation

두 파일 작성 완료 후, **`autonomy` 값에 따라 분기**한다:

**자율 모드 (`auto`)** — 플랜의 핵심 요약(요구사항, phase 구조, 에이전트 배정)을 텍스트로 보고하고 **즉시 자동 통과**해 review phase로 진행한다. "플랜을 승인할까요?" 같은 확인을 **묻지 않는다.** 단 요구사항이 애매하거나 [에스컬레이션 조건](../orchestrate.md#autonomy-mode-게이트-자동-통과-vs-승인)에 해당하면 멈추고 AskUserQuestion으로 질문한다.

**게이트 모드 (`gated`)**:
1. 플랜의 핵심 요약을 텍스트로 출력한다
2. AskUserQuestion으로 확인: "플랜을 승인하고 expert review로 진행할까요?"
   - 승인 → state 갱신 후 다음 phase 진행
   - 수정 요청 → 사용자 피드백 반영 후 재확인

통과(자동 또는 승인)하면 → state JSON을 Read → 아래 필드 갱신 → Write:
```jsonc
{
  "gates": { "plan": true },
  "currentPhase": "review",
  "updatedAt": "{현재 ISO 8601}"
}
```

## Done Criteria

아래 조건이 **모두** 충족되어야 이 phase가 완료된 것이다:

- [ ] 요구사항이 명확하게 정리됨
- [ ] Workspace 확인 완료 — main 모드: repo 루트 + working tree 상태 확인 / worktree 모드: 생성 + 진입 + 브랜치 일치
- [ ] `plans/{identifier}.state.json` 생성, 모든 필드 값이 채워짐
- [ ] `plans/{identifier}.md` 작성, 구현 플랜 포함
- [ ] Gate 1 통과 — 자율 모드: 확인 없이 자동 진행 / 게이트 모드: 사용자가 플랜 확인

> `/orchestrate`로 실행 중이면 자동으로 review phase로 진행한다.
> 단독 실행(`/orchestrate:start`)이면 사용자에게 안내: `/orchestrate:review`
