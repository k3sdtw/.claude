---
description: Expert review of the plan. Context-aware agent groups (backend/frontend/fullstack) review and approve.
---

# Expert Plan Review

플랜을 병렬 전문가 에이전트로 리뷰한다.
Prerequisite: `/orchestrate:start`에서 플랜 작성 완료 + Gate 1 통과.

## 0. State Guard

아래 절차를 순서대로 수행한다. 실패 시 즉시 중단하고 사용자에게 알린다.

1. **State 파일 탐색**: Glob으로 `plans/*.state.json` 검색
   - 파일 없음 → STOP: "`/orchestrate:start`를 먼저 실행하세요"
   - 파일 여러 개 → 목록을 보여주고 AskUserQuestion으로 선택 요청
2. **State 읽기**: Read 도구로 state.json을 읽고 JSON 파싱
3. **Worktree 확인**: `worktreePath` 디렉토리가 존재하는지 Bash `ls {worktreePath}`로 확인 → 없으면 STOP
4. **작업 디렉토리 전환**: Bash `cd {worktreePath}` 실행. 이후 모든 명령은 이 디렉토리에서 실행
5. **브랜치 확인**: `git branch --show-current` → main이면 STOP
6. **필드 추출**: jiraKey, projectType, techStack, commands, planFile, branchName, baseBranch 등 필요한 값 보관
7. **Phase 갱신**: state의 `currentPhase`를 `"review"`로, `updatedAt`을 현재 시각으로 갱신 → Write로 저장

## 1. Read Plan

state JSON의 `planFile` 경로를 Read 도구로 읽어 플랜 내용을 확보한다.

## 2. Select Agent Group

아래 기준으로 에이전트 그룹을 결정한다. **첫 번째 매치 사용:**

| 우선순위 | 조건 | 그룹 |
|---------|------|------|
| 1 | `--group backend` 또는 `--group frontend` 플래그 | 지정된 그룹 |
| 2 | state JSON의 `projectType` 값 | 해당 그룹 사용 |
| 3 | `nest-cli.json` 또는 `src/main.ts` 존재 | BACKEND |
| 4 | `next.config.*` 또는 `app/layout.tsx` 존재 | FRONTEND |
| 5 | backend + frontend 파일 모두 존재 | FULLSTACK |
| 6 | 위 어디에도 해당 없음 | AskUserQuestion으로 사용자에게 질문 |

## 3. Agent Group Definitions

### BACKEND_GROUP (5 agents)

| # | Agent (subagent_type) | Review Focus |
|---|----------------------|-------------|
| 1 | `schema-designer` | 테이블 구조, 관계, 인덱스, 마이그레이션 안전성, 제약조건, 네이밍 |
| 2 | `architect` | 레이어 분리, 의존성 방향, DI 토큰, bounded context, 도메인 이벤트 |
| 3 | `api-designer` | REST 규칙, 에러 응답 형식, 페이지네이션, 버전관리, DTO 경계 |
| 4 | `security-reviewer` | SQL injection, auth/authz 우회, rate limiting, 민감 데이터 노출, 입력 검증 |
| 5 | `performance-reviewer` | N+1 쿼리, 누락 인덱스, 캐싱 전략, 커넥션 관리, 트랜잭션 범위 |

### FRONTEND_GROUP (4 agents)

| # | Agent (subagent_type) | Review Focus |
|---|----------------------|-------------|
| 1 | `architect` | 컴포넌트 구조, 상태 관리, 라우팅, 코드 스플리팅, 모듈 경계 |
| 2 | `ux-reviewer` | 접근성(a11y), 반응형, 로딩/에러/빈 상태, 인터랙션 패턴 |
| 3 | `security-reviewer` | XSS, CSP, 토큰 저장, CORS, 서드파티 스크립트, 클라이언트 민감 데이터 |
| 4 | `performance-reviewer` | 번들 사이즈, 렌더링 최적화, lazy loading, 요청 워터폴, 메모리 누수 |

### FULLSTACK_GROUP (6 agents)

BACKEND_GROUP 전체(5) + FRONTEND_GROUP의 `ux-reviewer`(1).
ux-reviewer는 프론트엔드 관점의 리뷰 포커스를 그대로 유지한다.

## 4. Launch Reviews (병렬)

선택된 그룹의 **모든 에이전트를 동시에** Task 도구로 실행한다.

**각 에이전트 프롬프트에 반드시 포함할 내용:**

```
당신은 {agent_type} 전문가입니다.

## 컨텍스트
- 프로젝트 경로: {worktreePath}
- 기술 스택: {state JSON의 techStack 값}
- 플랜 파일: {planFile의 절대 경로}

## 작업
1. Read 도구로 위 플랜 파일을 읽으세요.
2. 아래 관점에서 플랜을 리뷰하세요:
   {해당 에이전트의 Review Focus — 위 테이블에서 복사}
3. 프로젝트 소스코드를 탐색하여 기존 패턴·규칙과의 일관성을 확인하세요.

## 출력 형식
발견사항을 아래 형식으로 보고하세요. 문제가 없으면 "No concerns"만 출력.

- [CRITICAL] {발견} → {권고}
- [HIGH] {발견} → {권고}
- [MEDIUM] {발견} → {권고}
- [LOW] {발견} → {권고}
```

## 5. Aggregate & Fix (최대 2회)

모든 에이전트 결과를 수집하여 통합 리포트를 사용자에게 보여준다.

| 조건 | 행동 |
|------|------|
| CRITICAL 또는 HIGH 발견 | 플랜을 수정하고 수정 내역을 보고. 수정 후 해당 에이전트만 재실행 |
| MEDIUM 이하만 | 사용자에게 보고 후 진행 여부 확인 |
| 2회 수정 후에도 CRITICAL 남음 | STOP: 사용자에게 수동 판단 요청 |

## 6. Approve

모든 CRITICAL/HIGH가 해소되면, plan markdown의 Status를 갱신:
```
Status: Plan approved — proceed with /orchestrate:impl
Approved: {날짜}
Reviews: {Agent1} OK | {Agent2} OK | ...
```

state JSON을 Read → 아래 필드 갱신 → Write:
```jsonc
{
  "expertReviews": {
    "architect": "approved",
    "security-reviewer": "approved"
    // ... 각 에이전트의 결과
  },
  "updatedAt": "{현재 ISO 8601}"
}
```

## GATE 2: Expert Approval

**STOP.** 리뷰 결과 요약을 보여주고 사용자에게 확인을 요청한다.

사용자가 확인하면 → state JSON을 Read → 아래 필드 갱신 → Write:
```jsonc
{
  "gates": { "expertApproved": true },
  "currentPhase": "impl",
  "updatedAt": "{현재 ISO 8601}"
}
```

## Done Criteria

- [ ] 선택된 그룹의 모든 에이전트가 리뷰 완료
- [ ] CRITICAL/HIGH 이슈가 모두 해소됨
- [ ] 플랜 markdown에 승인 상태 기록
- [ ] state JSON의 expertReviews 필드에 각 에이전트 결과 기록
- [ ] Gate 2 통과 (사용자 확인)

→ 다음: `/orchestrate:impl`
