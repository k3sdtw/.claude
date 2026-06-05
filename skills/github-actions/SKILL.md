---
name: github-actions
description: GitHub Actions CI/CD 워크플로우 작성·디버깅·최적화. OIDC·action 핀 고정·시크릿·캐시·matrix, 그리고 ECR push→매니페스트 갱신→GitOps 배포 핸드오프를 다룬다. 트리거 — github actions, workflow, .github/workflows, CI, CD, pipeline, GHA, OIDC, ECR, actionlint, "CI 실패", "빌드 깨짐".
---

# GitHub Actions Workflow

> 지식: `~/.claude/rules/devops/github-actions.md`, 안전: `~/.claude/rules/devops/safety.md`를 먼저 읽는다.
> 이 환경의 배포: CI는 **build → test → ECR push → 매니페스트 이미지 태그 갱신(commit/PR)** 까지. 클러스터 직접 배포(kubectl/helm)는 안 한다 — ArgoCD/Flux가 동기화.

## 작성 시

- **OIDC**로 AWS 인증(`aws-actions/configure-aws-credentials` + `permissions: id-token: write`). 장기 access key secret 금지.
- third-party action은 **commit SHA로 핀 고정**.
- `permissions:`를 최상단에서 최소권한으로 명시.
- `run:`에 `${{ github.event.* }}` 직접 보간 금지(인젝션) — env 경유.
- `concurrency`, `timeout-minutes`, 캐시 설정.
- deploy 잡은 이미지 태그 갱신까지만 — `kubectl apply`/`helm upgrade`로 클러스터 직접 배포하지 않는다.
- 작성/수정 후 **cicd-reviewer** agent로 보안 리뷰.

## 디버깅 (실패한 run)

`/infra:ci-debug` 또는 직접:
```bash
gh run list --workflow <name> --limit 10        # 읽기
gh run view <run-id> --log-failed               # 실패 스텝만, 읽기
actionlint .github/workflows/*.yml               # 정적 검사
```
실패 step → 명령/환경 로컬 재현 → 워크플로우 파일 수정. `gh run rerun`/`gh workflow run`은 변경+외부영향 → 승인.

## "배포 완료"의 정의

GHA 잡 성공 ≠ 배포 완료. 실제 배포 검증은 **ArgoCD Synced + Healthy**로 한다 (eks skill).

## Verification (필수)

1. `actionlint`로 워크플로우 문법/패턴 검사 (설치 시)
2. 수정한 잡이 실제 실행에서 통과하는지(또는 로컬 재현으로) 확인
3. 시크릿이 로그에 노출되지 않는지 확인
4. 배포 워크플로우면 ECR 태그 == 매니페스트 갱신 태그 정합 확인
