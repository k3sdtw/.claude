# Infra Commands

AWS · Terraform · EKS(GitOps) · GitHub Actions 인프라 작업용 command 모음.

> **안전 정책**: 읽기(plan/get/describe/list)는 자동 실행, 변경(apply/delete/sync/rerun)은 승인 후 실행.
> 단일 기준: [rules/devops/safety.md](../rules/devops/safety.md).

## 명령어

| 명령 | 용도 |
|------|------|
| `/infra:tf-import <자원>` | 콘솔에서 만든 AWS 자원을 Terraform으로 import (IaC 흡수) |
| `/infra:drift [범위]` | 콘솔↔Terraform 정합성 점검 — drift / 미관리(import 후보) / orphaned |
| `/infra:eks-debug <서비스/pod/ns>` | EKS 서비스 장애 진단 (GitOps-first, eks-doctor) |
| `/infra:ci-debug [run-id\|워크플로우]` | 실패한 GitHub Actions run 디버깅 |
| `/infra:inventory <자원타입> [region]` | AWS 자원 읽기 인벤토리 + 관리 주체(콘솔/TF) 표시 |

## 관련 컴포넌트

- 지식: `rules/devops/{terraform,kubernetes,github-actions,aws,safety}.md`
- agent: terraform-reviewer · eks-doctor · cicd-reviewer · aws-auditor
- skill: terraform · eks · github-actions (작업 시 자동 활성화)

## 환경 메모

- 자원이 **콘솔 관리(legacy) ↔ Terraform 관리**로 분리됨 → import로 점진 흡수
- EKS 배포는 **GitOps(ArgoCD/Flux)** → 클러스터 직접 변경 금지, git 경유
- **비용은 MSP 대시보드 별도** → harness는 비용 분석 안 함
