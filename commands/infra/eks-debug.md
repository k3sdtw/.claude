# EKS Debug — GitOps 서비스 장애 진단

EKS 서비스가 안 뜨거나·배포가 안 되거나·죽는 원인을 읽기 전용으로 추적한다.

```
/infra:eks-debug <서비스/pod/namespace>    # 예: /infra:eks-debug payment-api
```

> 지식: [kubernetes.md](../../rules/devops/kubernetes.md) · 안전: [safety.md](../../rules/devops/safety.md)
> 깊은 진단은 **eks-doctor** agent에 위임한다.

## Step 0: 컨텍스트 확인 (필수)

```bash
kubectl config current-context
kubectl config view --minify -o jsonpath='{..namespace}'
```
잘못된 클러스터를 진단하면 무의미. prod면 대상 확인받고 진행.

## Step 1: 진단 순서 (GitOps-first)

복잡하면 **eks-doctor** agent를 띄운다. 직접 볼 때:

1. **ArgoCD**: `argocd app get <app>` / `argocd app diff <app>` — `OutOfSync`/`SyncFailed`, git태그≠live태그면 배포 경로(CI/매니페스트) 문제 → `/infra:ci-debug`
2. **Workload**: `kubectl get deploy,rs,pod -n <ns> -o wide`
3. **Events**: `kubectl get events -n <ns> --sort-by=.lastTimestamp | tail -30`
4. **Logs**: `kubectl logs <pod> -n <ns> [--previous] --tail=100`
5. **Resources**: `kubectl top pod -n <ns>` + requests/limits/OOM
6. **Network**: `kubectl get svc,ep,ingress -n <ns>`

## Step 2: 결과

```
컨텍스트: {context}/{ns}
근본 원인: {한 문장}
증거: {명령 → 핵심 출력}
조치(GitOps): git 매니페스트 {수정점} → commit/PR → ArgoCD sync
  (직접 kubectl 변경 필요 시: 승인 + git 반영 필수)
```

## Rules

- 읽기 전용 kubectl만. `apply/delete/edit/scale/exec`는 승인 + GitOps에선 git으로 대체.
- 시크릿 값 출력 금지 ([safety.md](../../rules/devops/safety.md) §3).
- 배포 미반영은 클러스터가 아니라 파이프라인 문제일 수 있다 — ArgoCD부터 본다.
