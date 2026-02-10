---
name: worktree
description: Git worktree 관리. gtr(git-worktree-runner)을 활용한 병렬 개발 환경 자동화.
---

# Git Worktree Management Skill

gtr(git-worktree-runner)을 활용한 Git worktree 관리 자동화

## 개요

Git worktree는 하나의 저장소에서 여러 브랜치를 동시에 체크아웃할 수 있게 해주는 기능입니다.
gtr은 worktree 생성 시 환경 파일(.env) 복사와 의존성 설치를 자동화합니다.

## 현재 프로젝트 설정

`.gtrconfig`:
```ini
[copy]
include = **/.env
include = **/.env.test

[hooks]
postCreate = pnpm install --frozen-lockfile
```

매칭 파일: `app/.env`, `admin/.env`, `db/.env`, `app/.env.test`, `admin/.env.test`

## 핵심 명령어

### Worktree 생성

```bash
# 기본 생성 (자동으로 .env 복사 + pnpm install)
git gtr new <branch-name>

# 생성 + 에디터 열기
git gtr new <branch-name> -e

# 생성 + 에디터 + AI
git gtr new <branch-name> -e -a

# 특정 커밋/브랜치에서 생성
git gtr new <branch-name> --from main

# 현재 브랜치에서 변형 생성
git gtr new variant-1 --from-current
```

### Worktree 목록

```bash
git gtr list
# 또는
git gtr ls
```

### Worktree 이동

```bash
# 디렉토리 이동
cd "$(git gtr go <branch-name>)"

# 메인 저장소로 이동
cd "$(git gtr go 1)"
```

### Worktree에서 명령 실행

```bash
git gtr run <branch-name> pnpm test
git gtr run <branch-name> pnpm dev
```

### 에디터/AI 열기

```bash
# 에디터 열기
git gtr editor <branch-name>

# AI 도구 시작
git gtr ai <branch-name>
```

### .env 파일 동기화

```bash
# 특정 worktree에 복사
git gtr copy <branch-name>

# 모든 worktree에 복사
git gtr copy -a

# 복사 미리보기 (dry-run)
git gtr copy <branch-name> -n
```

### Worktree 삭제

```bash
# worktree만 삭제
git gtr rm <branch-name>

# worktree + 브랜치 삭제
git gtr rm <branch-name> --delete-branch

# 강제 삭제 (dirty worktree)
git gtr rm <branch-name> --force
```

### 정리

```bash
# 오래된 worktree 정리
git gtr clean

# 병합된 PR의 worktree 정리
git gtr clean --merged
```

## 설정 관리

```bash
# 설정 확인
git gtr config list

# 설정 추가
git gtr config add gtr.copy.include "path/to/.env"

# 설정 변경
git gtr config set gtr.editor.default code

# 설정 제거
git gtr config unset gtr.hook.postCreate
```

## 일반적인 워크플로우

### 새 기능 개발

```bash
# 1. 기능 브랜치 worktree 생성
git gtr new feature/my-feature -e

# 2. 개발 완료 후 정리
git gtr rm feature/my-feature --delete-branch
```

### 핫픽스

```bash
# 1. main에서 핫픽스 브랜치 생성
git gtr new hotfix/urgent-fix --from main -e

# 2. 수정 후 PR 생성, 병합

# 3. 정리
git gtr rm hotfix/urgent-fix --delete-branch
```

### 병렬 AI 개발

```bash
# 여러 AI 에이전트를 각각의 worktree에서 실행
git gtr new agent-1 --from-current -a
git gtr new agent-2 --from-current -a
git gtr new agent-3 --from-current -a
```

## Commands

- `/wt-new` - 새 worktree 생성
- `/wt-list` - worktree 목록 조회
- `/wt-rm` - worktree 삭제
- `/wt-sync` - .env 파일 동기화
