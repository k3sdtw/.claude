---
name: eks
description: EKS/Kubernetes 운영·디버깅 워크플로우. GitOps(ArgoCD/Flux) 환경에서 pod/deployment 진단, 배포 미반영, 롤아웃 문제를 다룬다. 읽기 kubectl은 자동, 변경은 git을 통해. 트리거 — eks, kubernetes, k8s, kubectl, pod, deployment, rollout, argocd, gitops, helm, CrashLoopBackOff, ImagePullBackOff, OOMKilled, Pending.
---

# EKS / Kubernetes Workflow (GitOps)

> 지식: `~/.claude/rules/devops/kubernetes.md`, 안전: `~/.claude/rules/devops/safety.md`를 먼저 읽는다.
> 핵심: 클러스터 상태의 source of truth는 **git**. `kubectl apply/edit`로 직접 바꾸지 않는다 — ArgoCD가 되돌린다.

## 1. 컨텍스트 먼저

```bash
kubectl config current-context
kubectl config view --minify -o jsonpath='{..namespace}'
```
prod면 읽기라도 한 번 확인받는다. 컨텍스트 세팅: `aws eks update-kubeconfig --name <cluster> --region <region>`.

## 2. 진단 (GitOps-first, 위→아래)

복잡하거나 근본 원인이 불분명하면 **eks-doctor** agent를 쓴다. 직접 볼 때 순서:

1. **ArgoCD**: `argocd app get <app>` / `argocd app diff <app>` (CLI 없으면 `kubectl get applications -A`). git 태그 ≠ live 태그거나 `OutOfSync`면 배포 경로(CI/매니페스트) 문제 → `/infra:ci-debug`
2. **Workload**: `kubectl get deploy,rs,pod -n <ns> -o wide`
3. **Events**: `kubectl get events -n <ns> --sort-by=.lastTimestamp | tail -30`
4. **Logs**: `kubectl logs <pod> -n <ns> [--previous] --tail=100`
5. **Resources**: `kubectl top pod -n <ns>` + requests/limits/OOM
6. **Network**: `kubectl get svc,ep,ingress -n <ns>` (endpoints 비었는지)

상세 증상→원인 매핑은 `/infra:eks-debug` 또는 kubernetes.md 표.

## 3. 변경은 git을 통해

앱/매니페스트를 바꿔야 하면:
1. git의 매니페스트(또는 helm values) 수정
2. commit/PR
3. ArgoCD sync (auto-sync면 자동, 아니면 `argocd app sync <app>` — 승인)

직접 `kubectl` 변경은 GitOps 위반 — 긴급 시에만, 승인 + **git에도 즉시 반영**(안 하면 self-heal로 사라짐).

## Verification (필수)

1. `kubectl rollout status deploy/<name> -n <ns>` 가 성공
2. `argocd app get <app>` 가 **Synced + Healthy**
3. git의 이미지 태그 == live 태그
4. 대상 엔드포인트가 실제 응답하는지 확인 — describe만 보고 끝내지 않는다
