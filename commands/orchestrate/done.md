---
description: Finalize development. Verification loop → code review → commit → ship (main: commit only / worktree: push + PR).
---

# Finalize and Ship

Prerequisite: `/orchestrate:impl`에서 구현 완료.

마무리 방식은 state의 `workspace`에 따라 갈린다:

| workspace | 마무리 |
|-----------|--------|
| `main` | commit까지만. **push·PR을 하지 않는다** — push는 사용자가 직접 |
| `worktree` | commit → push → PR 생성 |

## 0. State Guard

아래 절차를 순서대로 수행한다. 실패 시 즉시 중단하고 사용자에게 알린다.

1. **State 파일 탐색**: Glob으로 `plans/*.state.json` 검색
   - 파일 없음 → STOP: "`/orchestrate:start`를 먼저 실행하세요"
   - 파일 여러 개 → 목록을 보여주고 AskUserQuestion으로 선택 요청
2. **State 읽기**: Read 도구로 state.json을 읽고 JSON 파싱
3. **작업 디렉토리 전환**: `workPath` 디렉토리 존재 확인 후 Bash `cd {workPath}` 실행 → 없으면 STOP. 이후 모든 명령은 이 디렉토리에서 실행
4. **브랜치 확인** (worktree 모드만): `git branch --show-current`가 `branchName`과 일치하는지 확인 → 불일치 시 STOP. main 모드는 생략
5. **필드 추출**: workspace, **autonomy**, projectType, techStack, commands, planFile, branchName, baseBranch 등 필요한 값 보관
6. **Phase 갱신**: state의 `currentPhase`를 `"done"`으로, `updatedAt`을 현재 시각으로 갱신 → Write로 저장

## 1. Verification Loop (최대 3회)

**검증 스킵 조건 (impl↔done 중복 제거):** phase 진입 시 state의 `implVerifiedClean === true` **이고** `verification.lint`/`build`/`test`가 모두 `"pass"`이면, impl phase에서 방금 전체 검증을 통과했고 이후 편집이 없다는 뜻이다 → **이 최초 검증 루프를 건너뛰고 곧바로 §2(Code Review)로 진행한다** (build를 통째로 두 번 도는 낭비 제거). 단 개별 `/orchestrate:done`으로 재개해 impl 이후 수동 편집 가능성이 있으면 스킵하지 말고 검증한다 — **애매하면 검증**한다. 스킵하지 않는 경우 아래 루프를 정상 수행한다.

state JSON의 `commands` 필드에 저장된 명령어를 순서대로 실행한다.

**테스트 DB 격리:** `rules/common/test-db-isolation.md` 프로토콜을 따른다.
state.json에 `testDatabase` 필드가 이미 있으면 기존 DB를 재사용한다.
없으면 프로토콜의 1~6단계를 수행한 후 테스트를 실행한다.

```
각 iteration:
  1. Lint:  commands.lint 값을 Bash로 실행
  2. Build: commands.build 값을 Bash로 실행 → 실패 시 수정 후 iteration 재시작
  3. Test:  DATABASE_URL="{testDatabase.url}" {commands.test} 실행 → 실패 시 수정 후 iteration 재시작
  4. 모두 통과 → 루프 종료
```

> state JSON에 commands 값이 없으면 AskUserQuestion으로 사용자에게 명령어를 직접 질문

**실패 시 처리** (state의 `attempts.doneVerify`로 추적 — 실패마다 +1 후 state Write, 최대 3회):

| attempts.doneVerify | 행동 |
|------|------|
| 1~2 | 에러 분석 → 직접 수정 → iteration 재시작 |
| 3 | Task 도구로 `build-error-resolver` 에이전트 실행 |
| 3 초과 | STOP: 사용자에게 에러 내용 보고 및 수동 해결 요청 |

전체 통과 시 `attempts.doneVerify`를 0으로 리셋한다. 카운터는 state에 영속 — 세션이 끊겨도 한도 유지.

## 2. Code Review (병렬)

1. **변경 파일 목록 획득** — untracked 신규 파일까지 포함해야 한다:
   ```bash
   git status --porcelain                              # 미커밋 변경 + untracked 신규 파일
   git diff --name-only {baseBranch}...HEAD            # worktree 모드: 이미 커밋된 변경이 있으면 합산
   ```
   두 출력을 합쳐 변경 파일 목록을 만든다. `plans/{identifier}.md`, `plans/{identifier}.state.json`은 제외한다.
2. **에이전트 프롬프트 작성 및 병렬 실행**: Task 도구로 `security-reviewer`와 `code-reviewer`를 동시에 실행

   > **모델**: `code-reviewer`는 `model: "sonnet"`으로 핀 고정한다. `security-reviewer`는 실제 코드의 취약점 캐치율을 위해 opus를 유지한다(핀하지 않음 — 메인 모델 상속).

**각 에이전트 프롬프트:**
```
당신은 {security-reviewer | code-reviewer} 전문가입니다.

## 컨텍스트
- 프로젝트 경로: {workPath}
- 기술 스택: {state JSON의 techStack 값}
- 변경된 파일 목록:
{step 1에서 만든 변경 파일 목록을 여기에 삽입}

## 작업
1. 위 파일들을 Read 도구로 읽으세요.
2. {security: 보안 취약점 | code: 코드 품질, 패턴 일관성} 관점에서 리뷰하세요.
3. 제공된 변경 파일 안에서 판단을 우선하세요. 기존 패턴과의 일관성 확인이 꼭 필요한 경우에만 직접 관련된 파일을 좁게 Grep/Glob 하세요 — 변경 파일 밖으로의 광역 탐색은 불필요한 왕복으로 리뷰 지연의 주원인이므로 최소화합니다.

## 출력 형식
아래 JSON 하나만 출력하세요 (다른 텍스트 없이):
{
  "agent": "{security-reviewer | code-reviewer}",
  "findings": [
    { "severity": "CRITICAL | HIGH | MEDIUM | LOW", "finding": "...", "recommendation": "...", "file": "..." }
  ]
}
문제가 없으면 "findings": []
```

3. **결과 처리** (state의 `attempts.codeFix`로 추적, 최대 2회):
   - CRITICAL/HIGH 발견 → `attempts.codeFix` +1 → **`implVerifiedClean=false`로 갱신** → state Write → 수정 후 step 1 verification loop 재실행 (수정으로 코드가 바뀌었으므로 스킵 조건이 거짓 → 반드시 전체 검증)
   - MEDIUM 이하만 → **자율 모드**: 보고만 하고 자동 진행 · **게이트 모드**: 사용자에게 보고 후 진행 여부 확인
   - `attempts.codeFix` = 2인데 CRITICAL/HIGH 잔존 → 사용자에게 판단 요청 (자율 모드도 [에스컬레이션 조건](../orchestrate.md#autonomy-mode-게이트-자동-통과-vs-승인) 6번으로 멈춤. 카운터는 state에 영속 — 세션이 끊겨도 유지)

## GATE 3: Ship (commit 전)

어느 모드든 아래 요약을 먼저 정리해 **보고**한다 (이 출력은 진행 상황 보고일 뿐, 질문이 아니다):

- Verification 결과 (lint/build/test 각각 pass/fail)
- Code review 결과 요약
- 커밋할 파일 목록 + 커밋 메시지
- **main 모드**: "main 브랜치에 직접 커밋됩니다. push는 하지 않습니다" 명시
- **worktree 모드**: 생성될 PR의 제목과 타겟 브랜치({baseBranch})

그다음 **`autonomy` 값에 따라 분기**한다:

- **자율 모드 (`auto`, worktree 전용 — 기본)**: 위 요약을 보고한 **즉시** commit → push → PR 생성까지 **끝까지 무인으로 실행한다.** "PR을 만들까요?"·"진행할까요?"·"commit할까요?" 같은 확인을 **절대 묻지 않는다** — 자율 모드의 핵심은 ship(PR 생성)까지 무인 완료다. **유일한 예외:** 최종 diff에 [에스컬레이션 조건](../orchestrate.md#autonomy-mode-게이트-자동-통과-vs-승인)(운영/스테이징 데이터 손실·비가역 변경·보안 민감·호환성 파괴)에 해당하는 변경이 실제로 있을 때만 멈추고 AskUserQuestion으로 질문한다. 그 외에는 어떤 경우에도 멈추지 않고 PR까지 완료한다.
- **게이트 모드 (`gated`)**: **STOP.** 위 내용을 보여주고 사용자에게 확인을 요청한다.

통과(자동 또는 확인)하면 → state JSON을 Read → 아래 필드 갱신 → Write:
```jsonc
{
  "gates": { "finish": true },
  "updatedAt": "{현재 ISO 8601}"
}
```

## 3. Commit

```bash
# 1. 변경 파일 확인
git status

# 2. 특정 파일만 스테이징 (git add -A 사용 금지)
#    plans/{identifier}.md, plans/{identifier}.state.json은 스테이징하지 않는다
git add {구현된 파일들만 개별 지정}

# 3. 커밋 (프로젝트의 .claude/rules/git-workflow.md 또는 CLAUDE.md의 commit convention을 따름)
#    Claude/AI를 Co-Author·contributor로 넣지 않는다 — Co-Authored-By 트레일러를 추가하지 않는다.
git commit -m "$(cat <<'EOF'
{type}({scope}): {description}
EOF
)"
```

> commit format은 프로젝트의 `.claude/rules/git-workflow.md` 또는 CLAUDE.md의 convention을 따른다. 규칙이 없으면 `"type(scope): description"` 형식을 기본으로 사용.
> **Claude/AI 계정을 커밋 contributor로 포함하지 않는다** — `Co-Authored-By: Claude ...` 트레일러를 넣지 않는다. 프로젝트 convention이 co-author 트레일러를 요구하더라도 AI 계정은 제외하고 사람 기여자만 남긴다.

## 4. Ship

### main 모드

**push하지 않는다.** commit까지가 이 워크플로우의 끝이다.

state JSON을 Read → 아래 필드 갱신 → Write:
```jsonc
{
  "currentPhase": "completed",
  "updatedAt": "{현재 ISO 8601}"
}
```

### worktree 모드

```bash
# 1. Push
git push -u origin {branchName}

# 2. PR 생성 — rules/common/pull-request.md 템플릿을 따름
#    --assignee @me: 본인을 담당자로 지정해 GitHub 알림을 받는다.
#    (PR 작성자는 자신을 reviewer로 요청할 수 없으므로 reviewer 대신 assignee 사용)
gh pr create --base {baseBranch} --assignee @me --title "{type}({scope}): {description}" --body "$(cat <<'EOF'
## 개요
{이 PR이 해결하는 문제 또는 추가하는 기능}

## 주요 변경사항
- {논리적 단위로 정리된 변경사항}

## 테스트
- [ ] E2E 테스트 추가/수정
- [ ] 로컬 테스트 완료
- [ ] 기존 테스트 통과

## 참고사항
{필요한 경우에만}
EOF
)"
```

PR 생성 후 → state JSON을 Read → 아래 필드 갱신 → Write:
```jsonc
{
  "pullRequest": {
    "url": "{gh 출력에서 추출한 PR URL}",
    "number": {PR 번호}
  },
  "currentPhase": "completed",
  "updatedAt": "{현재 ISO 8601}"
}
```

## 5. Test DB Cleanup

state.json의 `testDatabase` 필드가 존재하면 `rules/common/test-db-isolation.md`의 Cleanup 절차를 수행한다.

`testDatabase.type`에 따라 해당 drop 명령어를 실행한다:

| type | 명령어 |
|------|--------|
| postgresql | `dropdb "{testDatabase.name}" 2>/dev/null \|\| true` |
| mysql | `mysql -u root -e "DROP DATABASE IF EXISTS \`{testDatabase.name}\`;" 2>/dev/null \|\| true` |
| sqlite | `rm -f "{SQLite 파일 경로}" 2>/dev/null \|\| true` |
| mongodb | `mongosh --eval "db.getSiblingDB('{testDatabase.name}').dropDatabase()" 2>/dev/null \|\| true` |

실행 후 state.json의 `testDatabase`를 `null`로 갱신한다.

> cleanup 실패 시 에러를 무시하고 진행한다. Output에서 결과(성공/실패)를 보고한다.

## 6. Output

사용자에게 아래 결과를 보고한다:

1. **Verification**: lint/build/test 각 결과
2. **Ship 결과**:
   - main 모드: 커밋 해시 + "push는 직접 실행하세요: `git push origin {baseBranch}`"
   - worktree 모드: PR URL + 제목 + 브랜치명
3. **Test DB Cleanup**: 삭제한 DB 이름 + 결과 (성공/실패)
4. **Cleanup 안내** (실행은 하지 않음, 사용자가 직접 결정):
   - `/orchestrate:cleanup`으로 일괄 정리 — worktree, 로컬·원격 브랜치, plan·state 파일, 테스트 DB (미리보기 + 승인 후 삭제)
   - worktree 모드는 PR merge 후 정리 권장

## Done Criteria

- [ ] Verification 전체 통과 (lint + build + test)
- [ ] Code review 완료, CRITICAL/HIGH 해소
- [ ] Gate 3 통과 — 자율 모드: 확인 없이 자동 ship / 게이트 모드: 사용자 확인 (commit 전)
- [ ] 커밋 완료 (plans/ 파일 제외)
- [ ] 커밋 메시지에 Claude/AI co-author 트레일러 없음
- [ ] main 모드: push 미실행 + push 안내 출력 / worktree 모드: PR 생성(본인 `--assignee @me` 지정) + URL 보고
- [ ] state JSON 갱신 — currentPhase = "completed" (worktree 모드: pullRequest 필드 포함)
- [ ] 테스트 DB 자동 삭제 완료, state의 testDatabase = null
