# Kubernetes / EKS 규칙

> 실행 안전(읽기 자동/변경 승인)은 [safety.md](safety.md)를 따른다.
> 디버깅은 **eks-doctor** agent 또는 `/infra:eks-debug`로 진행한다.

## 이 환경의 현실: EKS + GitOps(ArgoCD/Flux)

- 입사 이후 만든 서비스는 전부 **EKS**로 이관됨.
- 배포는 **GitOps**: 클러스터 상태의 source of truth는 **git**이다. CI는 이미지를 빌드/푸시하고 매니페스트(이미지 태그)를 갱신하며, **ArgoCD/Flux가 git을 클러스터로 동기화**한다.

### 핵심 규칙

- **`kubectl apply/edit/patch/scale/delete`로 클러스터를 직접 바꾸지 않는다.** ArgoCD가 git 상태로 되돌려 drift만 남는다.
- 앱 상태를 바꾸려면 **git 매니페스트를 수정 → commit/PR → ArgoCD sync**가 정석이다.
- 긴급 hotfix로 직접 변경이 불가피하면: 변경을 git에도 즉시 반영해 self-heal로 사라지지 않게 하고, 사용자 승인 + 컨텍스트 확인을 거친다.

## 컨텍스트 확인

```bash
kubectl config current-context        # 대상 클러스터
kubectl config view --minify -o jsonpath='{..namespace}'
aws eks update-kubeconfig --name <cluster> --region <region>   # 컨텍스트 세팅 (필요 시)
```

prod 클러스터면 읽기라도 한 번 확인받는다 ([safety.md](safety.md) §0).

## 디버깅 방법론 (GitOps-first, 위→아래)

1. **ArgoCD/Flux 상태** — 동기화 자체가 깨졌는지 먼저 본다.
   ```bash
   argocd app get <app>            # Sync(Synced/OutOfSync) + Health 상태
   argocd app diff <app>           # git ↔ live 차이
   # CLI 미설치 시: kubectl get applications -n argocd
   ```
   - `OutOfSync` / `SyncFailed` / git의 이미지 태그 ≠ live 태그 → 배포가 도달 못한 것. 클러스터가 아니라 **파이프라인/매니페스트** 문제일 수 있다.
2. **Workload**: `kubectl get deploy,rs,pod -n <ns>` → READY/AVAILABLE, 재시작 횟수.
3. **Events**: `kubectl get events -n <ns> --sort-by=.lastTimestamp` / `kubectl describe pod <pod>`.
4. **Logs**: `kubectl logs <pod> [-c <container>] [--previous]`.
5. **Resources**: `kubectl top pod/node`, requests/limits, OOM 여부.
6. **Networking**: `kubectl get svc,ep,ingress`, endpoints 비어있는지, readiness 통과 여부.

## 흔한 실패 모드

| 증상 | 1차 확인 |
|------|----------|
| `CrashLoopBackOff` | `logs --previous`, 종료코드, 설정/시크릿 누락, liveness 과민 |
| `ImagePullBackOff` | 이미지 태그/레지스트리(ECR) 권한, IRSA, 태그 오타 |
| `OOMKilled` | memory limit, `top`, 누수/과소 limit |
| `Pending` | 스케줄 불가(노드 리소스/taint), PVC 미바인딩, nodegroup 스케일 |
| readiness 실패 → endpoint 없음 | probe 경로/포트, 앱 부팅 시간 |
| ArgoCD `OutOfSync`인데 변화 없음 | auto-sync 꺼짐, sync error, git 태그 미갱신(CI 문제) |

## 읽기/변경

읽기(`get/describe/logs/top/events`)는 자동. 변경(`apply/delete/scale/edit/patch/rollout restart`)·`exec`·`port-forward`는 승인 — 그리고 GitOps 환경에선 대부분 git 변경으로 대체해야 한다. 시크릿 조회는 [safety.md](safety.md) §3.
