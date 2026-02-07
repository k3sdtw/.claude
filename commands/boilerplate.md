# /boilerplate — 프로젝트 보일러플레이트 생성기

당신은 새 프로젝트 보일러플레이트를 인터랙티브하게 생성하는 전문가입니다.

---

## ⚠️ Step 0: 버전 체크 및 문서 자동 업데이트 (매 실행마다 필수)

**이 단계는 사용자에게 질문하기 전에 반드시 먼저 실행해야 합니다.**
**사용자에게는 "🔍 최신 버전을 확인하고 있습니다..." 메시지만 보여주세요.**

### 0-1. 버전 레지스트리 읽기

아래 경로에 있는 `boilerplate-versions.json`을 읽으세요.
경로: `.claude/skills/boilerplate/boilerplate-versions.json`

이 파일에는 모든 기술스택의 **현재 알고 있는 버전**이 기록되어 있습니다.

### 0-2. 최신 버전 웹 검색

`_meta.last_checked` 날짜를 확인하세요. **마지막 체크로부터 7일 이상 지났다면** 아래 항목들의 최신 stable 버전을 웹 검색으로 확인하세요:

검색할 항목 (한 번에 여러 개 병렬 검색):

| 카테고리 | 검색 쿼리 |
|----------|-----------|
| Runtimes | `Node.js LTS latest version`, `Go latest stable version`, `Python latest stable version` |
| Backend | `NestJS latest version`, `FastAPI latest version` |
| Frontend | `React latest version`, `Next.js latest version`, `Vite latest version` |
| Tooling | `Biome latest version`, `Turborepo latest version` |

> 모든 항목을 한 번에 검색할 필요는 없습니다. 사용자가 선택한 스택에 해당하는 항목만 검색해도 됩니다.
> 단, **runtimes는 항상 검색**하세요.

**마지막 체크가 7일 이내라면 이 단계를 건너뛰고 기존 레지스트리의 버전을 그대로 사용하세요.**

### 0-3. 변경사항 감지 및 업데이트

웹 검색 결과와 레지스트리를 비교하여:

1. **메이저 또는 마이너 버전이 변경된 항목이 있다면:**
   - `boilerplate-versions.json`의 해당 버전을 업데이트
   - `_meta.last_checked`와 `_meta.last_updated`를 오늘 날짜로 갱신
   - 파일을 저장

2. **변경된 항목이 없다면:**
   - `_meta.last_checked`만 오늘 날짜로 갱신
   - 파일을 저장

### 0-4. 사용자에게 업데이트 결과 알림

변경사항이 있으면 간단히 알려주세요:

```
🔍 최신 버전을 확인했습니다.
📦 업데이트 발견:
  - Node.js: 22 → 24 (LTS)
  - NestJS: 11 → 12
  - React: 19 → 19.1
✅ 버전 레지스트리가 업데이트되었습니다.
```

변경사항이 없으면:

```
✅ 모든 기술스택이 최신 버전입니다. (마지막 확인: 2025-02-07)
```

### 0-5. 버전 적용 규칙

**보일러플레이트 코드 생성 시, 반드시 `boilerplate-versions.json`에 기록된 버전을 사용하세요.**
- `package.json`의 dependencies 버전
- `go.mod`의 module 버전
- `pyproject.toml`의 dependencies 버전
- `Dockerfile`의 base image 태그
- `tsconfig.json`의 target/lib 설정
- README에 기재하는 버전 정보

이 파일이 single source of truth입니다. 하드코딩하지 마세요.

---

## 실행 규칙

**반드시 아래 순서대로 한 단계씩 질문하고 답변을 받은 뒤 다음 단계로 넘어가세요.**
한 번에 여러 질문을 하지 마세요.

### Step 1: 분야 선택
사용자에게 물어보세요:
- **Backend** (API 서버)
- **Frontend** (웹 앱)
- **Standalone** (CLI tool, utility, script 등)

### Step 2: 기술스택 선택
분야에 따라 다른 선택지를 제시하세요:

| 분야 | 선택지 |
|------|--------|
| Backend | NestJS (TypeScript), Go (Gin/Echo), Python (FastAPI) |
| Frontend | React (Vite SPA), Next.js (App Router) |
| Standalone | TypeScript (tsx), Go, Python |

**이 시점에서 사용자가 선택한 스택의 최신 버전을 아직 검색하지 않았다면 (Step 0에서 스킵된 세부 패키지 등) 추가 검색을 수행하세요.**

### Step 3: 모노레포 여부
- TypeScript → Turborepo
- Go → Go Workspace
- Python → uv workspace
- 또는 단일 프로젝트

### Step 4: Formatter / Linter
- TypeScript/JS: **Biome**(기본) 또는 ESLint + Prettier
- Go: golangci-lint (자동)
- Python: Ruff (자동)

Go/Python은 자동 선택이므로 확인만 하고 넘어가세요.

### Step 5: 배포 환경 (AWS 기준)
- Serverless Framework (Lambda)
- Docker → ECS (Fargate)
- Docker → EKS (Kubernetes)
- 배포 설정 없음

### Step 6: 요약 확인
모든 선택이 끝나면 아래 형식으로 요약을 보여주고 확인을 받으세요.
**레지스트리에서 읽어온 실제 버전 번호를 함께 표시합니다:**

```
📋 프로젝트 설정 요약:
──────────────────────────────
분야:       Backend
기술스택:    NestJS v11 (TypeScript 5.7, Node.js 22)
모노레포:    No
Formatter:  Biome 1.9
배포환경:    Docker → ECS (Fargate)
──────────────────────────────
이대로 생성할까요? (Y/n)
```

확인을 받으면 코드 생성을 시작하세요.

---

## 보일러플레이트 생성 원칙

### 공통
모든 프로젝트에 반드시 포함:
- `.gitignore`, `.editorconfig`, `README.md`
- `.env.example`
- Formatter/Linter 설정 파일
- `Makefile` (dev, build, test, lint, format 타겟)
- `.github/workflows/ci.yml` (lint → test → build)
- 예시 테스트 최소 1개

### 백엔드 — Hexagonal Architecture 필수

모든 백엔드는 Hexagonal Architecture(Ports & Adapters)로 구성합니다.

**NestJS 구조:**
```
src/
├── main.ts
├── app.module.ts
├── common/                        # filters, interceptors, guards, pipes
├── config/                        # @nestjs/config + class-validator env 검증
├── health/                        # @nestjs/terminus health check
└── modules/
    └── example/                   # 예시 도메인
        ├── domain/
        │   ├── model/             # 도메인 엔티티
        │   ├── port/
        │   │   ├── in/            # Input Port (use-case interface)
        │   │   └── out/           # Output Port (repository interface)
        │   └── service/           # Use Case 구현
        ├── adapter/
        │   ├── in/web/            # Controller + DTO + Mapper
        │   └── out/persistence/   # Repository 구현 + ORM Entity + Mapper
        └── example.module.ts
```

패키지 버전은 `boilerplate-versions.json` → `backend.nestjs.packages`를 참조.
테스트 패키지는 `backend.nestjs.dev_packages`를 참조.
설정: strict tsconfig, path aliases (@/), Swagger(/api/docs), Global ValidationPipe, Global ExceptionFilter

**Go 구조:**
```
cmd/server/main.go
internal/
├── common/errors/, logger/ (slog)
├── config/                        # github.com/caarlos0/env
├── health/
└── modules/example/
    ├── domain/                    # model, repository(interface), service
    └── adapter/                   # handler(HTTP), dto, persistence
pkg/middleware/, response/
```

모듈 버전은 `boilerplate-versions.json` → `backend.go.modules`를 참조.
Graceful shutdown 구현 필수. Makefile에 build/run/test/lint 타겟.

**Python (FastAPI) 구조:**
```
src/
├── main.py
├── config/settings.py             # pydantic-settings
├── common/
├── health/
└── modules/example/
    ├── domain/                    # model, ports(ABC), service
    ├── adapter/
    │   ├── web/                   # router, dto
    │   └── persistence/           # repository 구현
    └── di.py                      # DI 설정
```

패키지 버전은 `boilerplate-versions.json` → `backend.fastapi.packages`를 참조.
패키지매니저: uv.

### 프론트엔드 — Feature-based 구조

**React (Vite SPA):**
```
src/
├── app/providers/, router.tsx
├── components/ui/, layout/
├── features/{feature}/            # api/, components/, hooks/, types/, index.ts
├── hooks/, lib/, types/, styles/
```

패키지 버전은 `boilerplate-versions.json` → `frontend.react.packages`를 참조.

**Next.js (App Router):**
```
src/
├── app/                           # layout, page, loading, error, not-found, providers
│   └── (routes)/example/
├── components/ui/, layout/
├── features/{feature}/            # api/(actions, queries), components/, hooks/, types/
├── hooks/, lib/, types/
```

패키지 버전은 `boilerplate-versions.json` → `frontend.nextjs.packages`를 참조.
Server Components 기본, Server Actions 활용.

### Standalone
- TypeScript: 버전은 `standalone.typescript.packages` 참조
- Go: 버전은 `standalone.go.modules` 참조
- Python: 버전은 `standalone.python.packages` 참조

---

## 모노레포

- **Turborepo** (TS): apps/ + packages/(shared, config) + turbo.json. 버전은 `tooling.turborepo` 참조.
- **Go Workspace**: go.work + services/ + pkg/shared/
- **uv workspace**: 루트 pyproject.toml + packages/

---

## 배포 환경

### Serverless Framework
- `serverless.yml` with 환경별 스테이지(dev/staging/prod)
- Lambda handler wrapper
- Go: provided.al2023, Python: Docker 기반, Node: esbuild
- 버전은 `tooling.serverless` 참조

### Docker → ECS
- Multi-stage Dockerfile (non-root user, health check, 캐시 최적화)
- docker-compose.yml (로컬)
- infra/ecs-task-def.json (참고용)
- Base image는 `tooling.docker_*` 참조

### Docker → EKS
- Dockerfile + docker-compose.yml
- k8s/ 디렉토리: deployment, service, ingress, hpa, configmap, kustomization
- Base image는 `tooling.docker_*` 참조

### 배포 없음
- Dockerfile + docker-compose.yml만 포함 (로컬 개발용)

---

## 중요 사항

1. **버전은 레지스트리가 진실**: 코드에 하드코딩하지 말고 반드시 `boilerplate-versions.json`의 값을 사용하세요.
2. **즉시 실행 가능**: 생성된 코드는 의존성 설치 후 바로 실행 가능해야 합니다.
3. **타입 안전성**: TypeScript strict, Go 정적 타입, Python type hints 필수.
4. **보안 기본값**: CORS, helmet, input validation 등 포함.
5. **README**: 프로젝트 구조, 실행 방법, 사용된 버전 정보를 문서화하세요.
