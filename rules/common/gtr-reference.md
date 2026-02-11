# gtr (git-worktree-runner) Command Reference

gtr은 Git subcommand로 등록된 도구다. **반드시 `git gtr`로 실행해야 한다.**

## CRITICAL: 실행 형식

```
CORRECT:  git gtr new <branch>
WRONG:    gtr new <branch>        ← 이렇게 실행하면 command not found
```

> `gtr`은 standalone CLI가 아니다. `git-gtr`이라는 이름으로 PATH에 설치되어 있으며, Git이 `git gtr`을 `git-gtr`로 변환하여 실행한다. 따라서 **항상 `git gtr ...` 형태로 호출해야 한다.**

## 명령어 요약

| 작업 | 명령어 |
|------|--------|
| worktree 생성 | `git gtr new <branch>` |
| 목록 조회 | `git gtr list` |
| .env 동기화 | `git gtr copy <branch>` |
| .env 전체 동기화 | `git gtr copy -a` |
| worktree 삭제 | `git gtr rm <branch>` |
| worktree + 브랜치 삭제 | `git gtr rm <branch> --delete-branch` |
| worktree 경로 이동 | `cd "$(git gtr go <branch>)"` |
| worktree에서 명령 실행 | `git gtr run <branch> <command>` |
| 설치 여부 확인 | `git gtr list 2>/dev/null && echo "AVAILABLE" \|\| echo "NOT_AVAILABLE"` |

## 자동 실행 (`.gtrconfig` hooks)

`git gtr new` 실행 시 자동으로:
1. `.gtrconfig`의 `[copy]` 패턴에 매칭되는 `.env` 파일 복사
2. `[hooks] postCreate` 명령어 실행 (예: `pnpm install --frozen-lockfile`)

별도로 `.env` 복사나 `pnpm install`을 수동 실행할 필요 없다.
