---
name: terraform
description: Terraform/IaC 작업 워크플로우. .tf/HCL 작성·수정, terraform plan/apply, 콘솔 자원 import, 드리프트 처리 시 사용한다. 읽기는 자동, apply 등 변경은 승인. 트리거 — terraform, terragrunt, .tf, HCL, plan, apply, import, drift, IaC, backend, state.
---

# Terraform Workflow

> 지식: `~/.claude/rules/devops/terraform.md`, 안전: `~/.claude/rules/devops/safety.md`를 먼저 읽는다.
> 이 환경은 **콘솔 관리(legacy) ↔ Terraform 관리**가 섞여 있다. 신규는 전부 TF, 기존 콘솔 자원은 import로 흡수.

## 1. 환경 감지 (가정 금지)

```bash
terraform version
ls *.tf backend.tf 2>/dev/null; cat terragrunt.hcl 2>/dev/null
terraform workspace list 2>/dev/null
```
`terragrunt.hcl` 있으면 `terragrunt`로, 없으면 `terraform`으로. 환경 분리(디렉토리 vs workspace)와 대상 account/region을 파악한다.

## 2. 변경 워크플로우 (plan → review → apply)

1. `terraform fmt -recursive` · `terraform validate` (읽기, 자동)
2. `terraform plan -out=tfplan` (읽기, 자동)
3. plan이 자명하지 않거나 destroy/replace가 있으면 **terraform-reviewer** agent로 검토
4. 요약 제시: `+N / ~N / -N / -/+N(교체)`, 데이터 보유 자원의 파괴/교체는 강조
5. **승인 후** `terraform apply tfplan` — 가능하면 CI/PR 경유 우선 ([safety.md](../../rules/devops/safety.md))

## 3. 콘솔 자원 import

콘솔에서 만든 자원을 IaC로 흡수: `/infra:tf-import` 사용. 요지 — 자원 식별 → HCL 작성 → `terraform import`(승인) → `plan`이 **no changes**가 될 때까지 HCL 정합.

## 4. 드리프트

`/infra:drift`로 managed drift(state엔 있는데 콘솔에서 변경) / unmanaged(콘솔 자원, import 후보) / orphaned(state엔 있는데 실제 없음)를 분류.

## 5. 작성 규칙 (요약)

- 식별 태그(`ManagedBy`, `Environment`, `Service`)를 default_tags로 일괄
- provider·module version 핀 고정
- 시크릿 평문 금지 (SSM/Secrets Manager + data source)
- 이름은 [naming-conventions](../../rules/common/naming-conventions.md)

## Verification (필수)

apply 후 반드시:
1. `terraform plan`이 **No changes** 인지 확인 (의도한 상태로 수렴했는가)
2. import의 경우 plan diff가 0인지 확인
3. 원격 state면 lock 해제·정상 반영 확인
4. 변경한 자원이 실제 동작하는지(서비스 영향 시) 확인 — 코드만 다시 읽고 끝내지 않는다
