---
description: Finalize development and create PR. Verification loop → code review → commit → PR.
---

# Finalize and Create PR

Prerequisite: `/orchestrate:impl`에서 구현 완료.

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
7. **Phase 갱신**: state의 `currentPhase`를 `"done"`으로, `updatedAt`을 현재 시각으로 갱신 → Write로 저장

## 1. Verification Loop (최대 3회)

state JSON의 `commands` 필드에 저장된 명령어를 순서대로 실행한다:

```
각 iteration:
  1. Lint:  commands.lint 값을 Bash로 실행
  2. Build: commands.build 값을 Bash로 실행 → 실패 시 수정 후 iteration 재시작
  3. Test:  commands.test 값을 Bash로 실행 → 실패 시 수정 후 iteration 재시작
  4. 모두 통과 → 루프 종료
```

> state JSON에 commands 값이 없으면 AskUserQuestion으로 사용자에게 명령어를 직접 질문

**실패 시 처리:**

| 시도 | 행동 |
|------|------|
| 1~2회 | 에러 분석 → 직접 수정 → iteration 재시작 |
| 3회 | Task 도구로 `build-error-resolver` 에이전트 실행 |
| 3회 후에도 실패 | STOP: 사용자에게 에러 내용 보고 및 수동 해결 요청 |

## 2. Code Review (병렬)

1. **변경 파일 목록 획득**: worktreePath에서 `git diff --name-only {baseBranch}` 실행
2. **에이전트 프롬프트 작성 및 병렬 실행**: Task 도구로 `security-reviewer`와 `code-reviewer`를 동시에 실행

**각 에이전트 프롬프트:**
```
당신은 {security-reviewer | code-reviewer} 전문가입니다.

## 컨텍스트
- 프로젝트 경로: {worktreePath}
- 기술 스택: {state JSON의 techStack 값}
- 변경된 파일 목록:
{git diff --name-only {baseBranch}의 출력을 여기에 삽입}

## 작업
1. 위 파일들을 Read 도구로 읽으세요.
2. {security: 보안 취약점 | code: 코드 품질, 패턴 일관성} 관점에서 리뷰하세요.
3. 프로젝트의 기존 패턴을 Grep/Glob으로 확인하여 일관성을 검증하세요.

## 출력 형식
- [CRITICAL] {발견} → {권고}
- [HIGH] {발견} → {권고}
- [MEDIUM] {발견} → {권고}
- [LOW] {발견} → {권고}
문제가 없으면 "No concerns" 출력.
```

3. **결과 처리:**
   - CRITICAL/HIGH 발견 → 수정 후 step 1 verification loop 재실행
   - MEDIUM 이하만 → 사용자에게 보고, 진행 여부 확인
   - 수정→재리뷰 순환은 **최대 2회**. 이후에도 해소 안 되면 사용자에게 판단 요청

## 3. Commit

state JSON에서 읽은 JIRA_KEY와 BRANCH를 사용한다.

```bash
# 1. 변경 파일 확인
git status

# 2. 특정 파일만 스테이징 (git add -A 사용 금지)
git add {구현된 파일들만 개별 지정}

# 3. 커밋 (프로젝트의 .claude/rules/git-workflow.md 또는 CLAUDE.md의 commit convention을 따름)
# Jira mode: 커밋 메시지에 JIRA_KEY 포함
# Standalone: JIRA_KEY 생략
git commit -m "$(cat <<'EOF'
{type}({scope}): {description} {JIRA_KEY가 있으면 추가}

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

> commit format은 프로젝트의 `.claude/rules/git-workflow.md` 또는 CLAUDE.md의 convention을 따른다. 규칙이 없으면 `"type(scope): description"` 형식을 기본으로 사용.

## GATE 3: PR Confirmation

**STOP.** 아래 내용을 사용자에게 보여주고 확인을 요청한다:
- Verification 결과 (lint/build/test 각각 pass/fail)
- Code review 결과 요약
- 커밋 내용 요약
- 생성될 PR의 제목과 타겟 브랜치

사용자가 확인하면 → state JSON을 Read → 아래 필드 갱신 → Write:
```jsonc
{
  "gates": { "prConfirmed": true },
  "updatedAt": "{현재 ISO 8601}"
}
```

## 4. Create PR

state JSON에서 읽은 BRANCH와 JIRA_KEY를 사용한다.

```bash
# 1. Push
git push -u origin {BRANCH}

# 2. PR 생성 — rules/common/pull-request.md 템플릿을 따름
#    --base에 baseBranch 사용 (state JSON에서 읽은 값)
gh pr create --base {baseBranch} --title "{type}({scope}): {description} {JIRA_KEY가 있으면 추가}" --body "$(cat <<'EOF'
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

> PR 제목 규칙: `rules/common/pull-request.md` 참조. Standalone mode(JIRA_KEY가 null)이면 JIRA 키 생략.

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

## 5. Update Jira (Jira mode만)

state JSON의 `jiraKey`가 null이면 건너뛴다.

```
1. 먼저 가능한 transition 목록 조회:
   mcp__jira__jira_get_transitions({ issue_key: "{JIRA_KEY}" })

2. "In Review", "코드 리뷰", "Review" 등 리뷰 상태에 해당하는 transition을 찾는다.
   매칭되는 transition이 없으면 → 사용자에게 사용 가능한 transition 목록을 보여주고 선택 요청.

3. 선택된 transition으로 이슈 상태 변경:
   mcp__jira__jira_transition_issue({ issue_key: "{JIRA_KEY}", transition: "{선택된 transition}" })
```

## 6. Output

사용자에게 아래 결과를 보고한다:

1. **Verification**: lint/build/test 각 결과
2. **PR**: URL + 제목
3. **Branch**: 브랜치명
4. **Jira**: 이슈 상태 변경 결과 (Jira mode만)
5. **Cleanup**: 아래 명령어 안내 (실행은 하지 않음, 사용자가 직접 결정)
   - Worktree: `git gtr rm {BRANCH} --delete-branch` (반드시 `git gtr`로 실행)
   - Branch: `git checkout main && git pull && git branch -d {BRANCH}`

## Done Criteria

- [ ] Verification 전체 통과 (lint + build + test)
- [ ] Code review 완료, CRITICAL/HIGH 해소
- [ ] 커밋 완료
- [ ] Gate 3 통과 (사용자 확인)
- [ ] PR 생성 완료, URL 보고
- [ ] state JSON의 pullRequest 필드 갱신, currentPhase = "completed"
- [ ] Jira 상태 변경 완료 (Jira mode인 경우)
