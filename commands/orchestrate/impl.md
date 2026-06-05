---
description: Implement with parallel agents. Plan-based layer development with verification.
---

# Parallel Agent Implementation

승인된 플랜을 병렬 에이전트로 구현한다.
Prerequisite: `/orchestrate:review`에서 expert 승인 완료 + Gate 2 통과.

## 0. State Guard

아래 절차를 순서대로 수행한다. 실패 시 즉시 중단하고 사용자에게 알린다.

1. **State 파일 탐색**: Glob으로 `plans/*.state.json` 검색
   - 파일 없음 → STOP: "`/orchestrate:start`를 먼저 실행하세요"
   - 파일 여러 개 → 목록을 보여주고 AskUserQuestion으로 선택 요청
2. **State 읽기**: Read 도구로 state.json을 읽고 JSON 파싱
3. **작업 디렉토리 전환**: `workPath` 디렉토리 존재 확인 후 Bash `cd {workPath}` 실행 → 없으면 STOP. 이후 모든 명령은 이 디렉토리에서 실행
4. **브랜치 확인** (worktree 모드만): `git branch --show-current`가 `branchName`과 일치하는지 확인 → 불일치 시 STOP. main 모드는 생략
5. **필드 추출**: workspace, projectType, techStack, commands, planFile, branchName, baseBranch 등 필요한 값 보관
6. **Phase 갱신**: state의 `currentPhase`를 `"impl"`로, `updatedAt`을 현재 시각으로 갱신 → Write로 저장

## 1. Load Plan

state JSON의 `planFile` 경로를 Read 도구로 읽는다.
플랜의 **Implementation Phases** 섹션에서 에이전트 배정 테이블을 추출한다.

## 2. Execute by Phase (플랜 기반)

플랜에 정의된 phase 순서와 병렬/순차 의존성을 그대로 따른다.

**일반적 패턴 (프로젝트 타입별 예시):**

### Backend (NestJS / Express / Django 등)
- **Phase A (병렬):** Domain 레이어 + Infrastructure 레이어
- **Phase B (순차, A 완료 후):** Application 레이어 (Use Case, Controller, DTO, Module, E2E Test)

### Frontend (Next.js / React 등)
- **Phase A (병렬):** 공통 컴포넌트 + 훅 + 유틸리티
- **Phase B (순차, A 완료 후):** 페이지 컴포넌트 + 라우팅 + 통합 테스트

### Fullstack
- **Phase A (병렬):** Backend domain + Frontend 공통 컴포넌트
- **Phase B (순차):** Backend application + Frontend 페이지

> 위는 예시일 뿐이다. **반드시 플랜에 정의된 phase 구조를 따를 것.** 플랜에 phase 정의가 없으면 사용자에게 확인한다.

## 3. Launch Agents

**Workflow 도구 우선**(3b), 미지원·권한 거부 시 Task 병렬 fallback(3c).

> 이 스킬의 지시에 의한 Workflow 호출이므로 multi-agent orchestration opt-in 조건을 충족한다.

### 3a. 에이전트 프롬프트 (공통)

**각 에이전트 프롬프트에 반드시 포함할 내용:**

```
당신은 {담당 영역} 구현 전문가입니다.

## 컨텍스트
- 프로젝트 경로: {workPath}
- 기술 스택: {state JSON의 techStack 값}
- CLAUDE.md 경로: {workPath}/CLAUDE.md (프로젝트 규칙 참조용)

## 플랜
아래는 구현할 내용입니다:
{해당 에이전트에 배정된 플랜 phase의 구체적 작업 항목을 여기에 복사}

## 규칙
1. {workPath} 안에서만 파일을 생성·수정하세요.
2. 기존 프로젝트의 코드 패턴을 먼저 탐색(Glob/Grep/Read)하고, 동일한 패턴을 따르세요.
3. 다른 에이전트가 담당하는 파일은 수정하지 마세요: {다른 에이전트 담당 파일 목록}
4. 완료 후 변경한 파일 경로 목록과 작업 요약을 보고하세요.
```

**충돌 방지:** 에이전트 간 파일 겹침이 없도록 각 에이전트에게 담당 파일 범위를 명시한다. 공유 파일(예: module registration)은 마지막 순차 phase에서 한 에이전트가 처리한다.

### 3b. Workflow 실행 (기본)

플랜의 Implementation Phases를 그대로 args로 옮긴다. **phase 간 순차, phase 내 병렬**이 스크립트 코드로 보장된다.

**args** (실제 JSON 값으로, 문자열 인코딩 금지):

```jsonc
{
  "phases": [
    {
      "name": "A",
      "agents": [
        { "area": "domain", "prompt": "{3a 템플릿을 채운 전문}" },
        { "area": "infra", "prompt": "..." }
      ]
    },
    { "name": "B", "agents": [ /* ... */ ] }
  ]
}
```

**script:**

```javascript
export const meta = {
  name: 'orchestrate-impl',
  description: '플랜 phase 순서대로 구현 — phase 간 순차, phase 내 병렬',
}
const REPORT = {
  type: 'object',
  required: ['files', 'summary'],
  properties: {
    files: { type: 'array', items: { type: 'string' } },   // 생성·수정한 파일 경로
    summary: { type: 'string' }
  }
}
const done = []
for (const p of args.phases) {
  log('Phase ' + p.name + ': agents ' + p.agents.length)
  const results = await parallel(p.agents.map(a => () =>
    agent(a.prompt, { label: 'impl:' + a.area, phase: p.name, schema: REPORT })
  ))
  done.push({ phase: p.name, results: results.filter(Boolean) })
}
return { phases: done, files: done.flatMap(d => d.results.flatMap(r => r.files)) }
```

> phase 간 barrier는 의도적이다 — 다음 phase가 이전 phase의 파일에 의존한다.
> 에이전트들은 같은 workPath에서 파일을 만든다. 담당 파일이 겹치지 않으므로(충돌 방지 규칙) worktree isolation은 쓰지 않는다.

반환값의 `files`(전체 변경 파일 목록)를 done phase의 코드 리뷰·커밋 스테이징에 활용한다.

### 3c. Task fallback (Workflow 미지원·거부 시)

플랜의 phase 순서대로, 각 phase의 에이전트를 **동시에** Task 도구(`subagent_type: "general-purpose"`)로 실행한다. 다음 phase는 이전 phase의 모든 에이전트 완료 후 시작한다.

## 4. Integration Verification

모든 에이전트 완료 후, state JSON의 `commands` 필드에 저장된 명령어를 순서대로 실행:

1. **Lint**: `commands.lint` 값을 Bash로 실행 (예: `pnpm lint`)
2. **Build**: `commands.build` 값을 Bash로 실행 (예: `pnpm build`)
3. **Test DB 준비**: `rules/common/test-db-isolation.md` 프로토콜의 1~6단계를 수행한다.
   - state.json에 `testDatabase` 필드가 이미 있으면 기존 DB 재사용
   - 없으면 감지 → 생성 → 마이그레이션 → state 기록
4. **Test**: `DATABASE_URL="{testDatabase.url}" {commands.test}` 형태로 실행

> state JSON에 commands 값이 없는 경우 → AskUserQuestion으로 사용자에게 명령어를 직접 질문

**실패 시 처리** (state의 `attempts.implVerify`로 추적 — 실패마다 +1 후 state Write, 최대 3회):

| attempts.implVerify | 행동 |
|------|------|
| 1~2 | 에러 메시지를 분석하고 직접 수정 후 재실행 |
| 3 | Task 도구로 `build-error-resolver` 에이전트 실행 |
| 3 초과 | STOP: 사용자에게 에러 내용 보고 및 수동 해결 요청 |

전체 통과 시 `attempts.implVerify`를 0으로 리셋한다. 카운터는 state에 영속 — 세션이 끊겨도 한도 유지.

## 5. Update State

verification 완료 후 state JSON을 Read → 아래 필드 갱신 → Write:

```jsonc
{
  "verification": {
    "lint": "pass",                    // 또는 "fail"
    "build": "pass",                   // 또는 "fail"
    "test": "pass",                    // 또는 "fail"
    "lastRunAt": "{현재 ISO 8601}"
  },
  "currentPhase": "done",
  "updatedAt": "{현재 ISO 8601}"
}
```

## Done Criteria

- [ ] 플랜의 모든 phase 에이전트가 완료됨
- [ ] Lint 통과
- [ ] Build 통과
- [ ] Test 통과
- [ ] state JSON의 verification 필드에 결과 기록
- [ ] currentPhase가 "done"으로 갱신됨

> `/orchestrate`로 실행 중이면 자동으로 done phase로 진행한다.
> 단독 실행(`/orchestrate:impl`)이면 사용자에게 안내: `/orchestrate:done`
