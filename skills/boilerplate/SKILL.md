---
name: boilerplate
description: 새 프로젝트 보일러플레이트를 인터랙티브하게 생성하는 커맨드. /boilerplate 입력 시 분야, 기술스택, 모노레포 여부, 포매터, 배포환경을 순차적으로 선택하고 best-practice 기반의 프로젝트 코드를 생성한다.
---

# /boilerplate — 프로젝트 보일러플레이트 생성기

## 개요

새 프로젝트의 보일러플레이트 코드를 인터랙티브하게 생성하는 커맨드.
사용자에게 순차적으로 옵션을 질문한 뒤, 최신 버전 기반의 best-practice 보일러플레이트를 생성한다.

---

## 실행 흐름

사용자가 `/boilerplate`를 입력하면 아래 순서대로 진행한다.
**각 단계를 하나씩 질문하고, 답변을 받은 뒤 다음 단계로 넘어간다.**

### Step 1: 분야 선택

```
프로젝트 분야를 선택해주세요:
1. Backend
2. Frontend
3. Standalone (CLI tool, utility, script 등)
```

### Step 2: 기술스택 선택

분야에 따라 선택지가 달라진다:

| 분야 | 선택지 |
|------|--------|
| Backend | NestJS (TypeScript), Go (Gin/Echo), Python (FastAPI) |
| Frontend | React (Vite + SPA), Next.js (App Router) |
| Standalone | TypeScript (tsx), Go, Python |

### Step 3: 모노레포 여부

```
모노레포로 구성할까요?
1. Yes (Turborepo) — TypeScript 프로젝트일 때
1. Yes (Go Workspace) — Go 프로젝트일 때
1. Yes (uv workspace) — Python 프로젝트일 때
2. No (단일 프로젝트)
```

- TypeScript 기반 → Turborepo
- Go 기반 → Go Workspace (`go.work`)
- Python 기반 → uv workspace

### Step 4: Formatter / Linter 선택

```
Formatter/Linter를 선택해주세요:
1. Biome (기본 권장) — TypeScript/JavaScript 프로젝트
2. ESLint + Prettier — TypeScript/JavaScript 프로젝트
3. golangci-lint — Go 프로젝트 (자동 선택)
4. Ruff — Python 프로젝트 (자동 선택)
```

- TypeScript/JS 프로젝트: Biome이 기본값. 사용자가 원하면 ESLint+Prettier 가능.
- Go: golangci-lint가 자동 선택됨 (gofmt/goimports 포함).
- Python: Ruff가 자동 선택됨.

### Step 5: 배포 환경 선택 (AWS 기준)

```
배포 환경을 선택해주세요:
1. Serverless Framework (Lambda)
2. Docker → ECS (Fargate)
3. Docker → EKS (Kubernetes)
4. 배포 설정 없음
```

### Step 6: 확인 및 생성

모든 선택이 끝나면 요약을 보여주고 확인 후 생성한다:

```
📋 프로젝트 설정 요약:
─────────────────────
분야:       Backend
기술스택:    NestJS (TypeScript)
모노레포:    No
Formatter:  Biome
배포환경:    Docker → ECS (Fargate)
─────────────────────
이대로 생성할까요? (Y/n)
```

---

## 보일러플레이트 상세 스펙

### 공통 사항

모든 프로젝트에 포함되는 것:

- `.gitignore` (기술스택에 맞는 것)
- `README.md` (프로젝트 설명, 실행 방법, 구조 설명)
- `.editorconfig`
- 선택된 Formatter/Linter 설정 파일
- `Makefile` 또는 `Taskfile.yml` (공통 명령어: dev, build, test, lint, format)
- `.github/` 디렉토리 (기본 CI workflow — lint, test, build)
- `.env.example`

---

### Backend: NestJS (Hexagonal Architecture)

**버전**: Node.js 22 LTS, NestJS 최신, TypeScript 5.x

```
src/
├── main.ts
├── app.module.ts
├── common/
│   ├── decorators/
│   ├── filters/
│   │   └── all-exceptions.filter.ts
│   ├── interceptors/
│   │   └── logging.interceptor.ts
│   ├── guards/
│   └── pipes/
├── config/
│   ├── config.module.ts
│   └── env.validation.ts          # class-validator 기반 환경변수 검증
├── health/
│   └── health.controller.ts       # /health 엔드포인트
└── modules/
    └── example/                    # 예시 도메인 모듈 (Hexagonal)
        ├── domain/
        │   ├── model/
        │   │   └── example.entity.ts
        │   ├── port/
        │   │   ├── in/
        │   │   │   └── example.use-case.ts        # Input Port (interface)
        │   │   └── out/
        │   │       └── example.repository.ts      # Output Port (interface)
        │   └── service/
        │       └── example.service.ts             # Domain Service (Use Case 구현)
        ├── adapter/
        │   ├── in/
        │   │   └── web/
        │   │       ├── example.controller.ts      # Input Adapter
        │   │       ├── dto/
        │   │       │   ├── create-example.request.ts
        │   │       │   └── example.response.ts
        │   │       └── mapper/
        │   │           └── example.mapper.ts
        │   └── out/
        │       └── persistence/
        │           ├── example.persistence.adapter.ts  # Output Adapter
        │           ├── entity/
        │           │   └── example.orm-entity.ts
        │           └── mapper/
        │               └── example.persistence.mapper.ts
        └── example.module.ts
test/
├── unit/
├── integration/
└── e2e/
```

**필수 패키지**:
- `@nestjs/config`, `@nestjs/swagger` (OpenAPI)
- `class-validator`, `class-transformer`
- `@nestjs/terminus` (health check)
- `helmet`, `compression`
- 테스트: `jest`, `@nestjs/testing`, `supertest`

**설정 포인트**:
- `tsconfig.json`: strict mode, path aliases (`@/`)
- `nest-cli.json`: 적절한 설정
- Swagger 자동 생성 (`/api/docs`)
- Global validation pipe, exception filter 적용
- Config module에서 환경변수 타입 안전하게 관리

---

### Backend: Go (Hexagonal Architecture)

**버전**: Go 1.23+

```
cmd/
└── server/
    └── main.go
internal/
├── common/
│   ├── errors/
│   │   └── errors.go
│   └── logger/
│       └── logger.go              # slog 기반
├── config/
│   └── config.go                  # env 기반 설정 (envconfig/viper)
├── health/
│   └── handler.go
└── modules/
    └── example/
        ├── domain/
        │   ├── model.go           # 도메인 모델
        │   ├── repository.go      # Output Port (interface)
        │   └── service.go         # Use Case / Domain Service
        ├── adapter/
        │   ├── handler.go         # Input Adapter (HTTP handler)
        │   ├── dto.go             # Request/Response DTO
        │   └── persistence.go     # Output Adapter (DB 구현체)
        └── module.go              # DI wiring
pkg/                               # 외부 공개 가능한 패키지
├── middleware/
│   ├── logging.go
│   ├── recovery.go
│   └── cors.go
└── response/
    └── response.go                # 표준 응답 포맷
```

**필수 의존성**:
- HTTP: `net/http` (stdlib) 또는 `echo`/`gin`(사용자 선호에 따라)
- Logger: `log/slog` (stdlib)
- Config: `github.com/caarlos0/env/v11`
- Validation: `github.com/go-playground/validator/v10`
- 테스트: `testing` (stdlib), `github.com/stretchr/testify`

**설정 포인트**:
- `Makefile`: build, run, test, lint, generate 타겟
- `golangci-lint` 설정 (`.golangci.yml`)
- Graceful shutdown 구현
- Structured logging (slog)

---

### Backend: Python / FastAPI (Hexagonal Architecture)

**버전**: Python 3.12+, FastAPI 최신

**패키지 매니저**: `uv`

```
src/
├── main.py
├── config/
│   ├── __init__.py
│   └── settings.py                # pydantic-settings 기반
├── common/
│   ├── __init__.py
│   ├── exceptions.py
│   └── middleware/
│       ├── __init__.py
│       └── logging.py
├── health/
│   ├── __init__.py
│   └── router.py
└── modules/
    └── example/
        ├── __init__.py
        ├── domain/
        │   ├── __init__.py
        │   ├── model.py           # 도메인 모델 (Pydantic or dataclass)
        │   ├── ports.py           # Input/Output Port (ABC)
        │   └── service.py         # Use Case 구현
        ├── adapter/
        │   ├── __init__.py
        │   ├── web/
        │   │   ├── __init__.py
        │   │   ├── router.py      # Input Adapter (FastAPI router)
        │   │   └── dto.py         # Request/Response 스키마
        │   └── persistence/
        │       ├── __init__.py
        │       └── repository.py  # Output Adapter
        └── di.py                  # Dependency Injection 설정
tests/
├── unit/
├── integration/
└── conftest.py
```

**필수 패키지**:
- `fastapi`, `uvicorn`
- `pydantic`, `pydantic-settings`
- `structlog` (structured logging)
- 테스트: `pytest`, `pytest-asyncio`, `httpx`

**설정 포인트**:
- `pyproject.toml`: uv 기반 의존성 관리
- Ruff 설정 (`ruff.toml` 또는 `pyproject.toml` 내)
- Type hints 적극 사용
- Auto-generated OpenAPI docs

---

### Frontend: React (Vite SPA)

**버전**: React 19, Vite 6, TypeScript 5.x

```
src/
├── main.tsx
├── App.tsx
├── app/
│   ├── providers/
│   │   └── app-provider.tsx       # 전역 Provider 조합
│   └── router.tsx                 # React Router v7 설정
├── components/
│   ├── ui/                        # 재사용 UI 컴포넌트
│   └── layout/
│       └── root-layout.tsx
├── features/
│   └── example/                   # Feature-based 구조
│       ├── api/
│       │   └── use-example.ts     # TanStack Query hooks
│       ├── components/
│       │   └── example-list.tsx
│       ├── hooks/
│       │   └── use-example-logic.ts
│       ├── types/
│       │   └── example.ts
│       └── index.ts               # Public API (barrel export)
├── hooks/                         # 공통 hooks
├── lib/
│   ├── api-client.ts              # Axios/ky 인스턴스
│   └── utils.ts
├── types/
│   └── global.d.ts
└── styles/
    └── global.css
```

**필수 패키지**:
- `react`, `react-dom`
- `react-router` (v7)
- `@tanstack/react-query` (서버 상태 관리)
- `zustand` (클라이언트 상태 관리)
- `axios` 또는 `ky` (HTTP 클라이언트)
- 테스트: `vitest`, `@testing-library/react`

**설정 포인트**:
- `vite.config.ts`: path aliases, proxy 설정
- `tsconfig.json`: strict, paths
- TanStack Query Provider 설정
- Feature-based 폴더 구조 (기능별 캡슐화)

---

### Frontend: Next.js (App Router)

**버전**: Next.js 15, React 19, TypeScript 5.x

```
src/
├── app/
│   ├── layout.tsx                 # Root Layout
│   ├── page.tsx                   # Home
│   ├── loading.tsx
│   ├── error.tsx
│   ├── not-found.tsx
│   ├── globals.css
│   ├── providers.tsx              # Client Provider 조합
│   └── (routes)/
│       └── example/
│           ├── page.tsx
│           ├── loading.tsx
│           └── _components/       # Route-specific 컴포넌트
│               └── example-list.tsx
├── components/
│   ├── ui/                        # 재사용 UI
│   └── layout/
│       ├── header.tsx
│       └── footer.tsx
├── features/
│   └── example/
│       ├── api/
│       │   ├── actions.ts         # Server Actions
│       │   └── queries.ts         # TanStack Query hooks
│       ├── components/
│       ├── hooks/
│       ├── types/
│       └── index.ts
├── hooks/
├── lib/
│   ├── api-client.ts
│   └── utils.ts
└── types/
    └── global.d.ts
```

**필수 패키지**:
- `next`, `react`, `react-dom`
- `@tanstack/react-query` (클라이언트 데이터 페칭)
- `zustand` (클라이언트 상태)
- `server-only` (서버 전용 코드 보호)
- 테스트: `vitest`, `@testing-library/react`

**설정 포인트**:
- `next.config.ts`: turbopack 활성화
- Server Components 기본, 필요 시 `'use client'`
- Server Actions 활용
- Feature-based 구조 + App Router 컨벤션

---

### Standalone: TypeScript CLI/Tool

```
src/
├── index.ts                       # Entry point
├── cli.ts                         # CLI argument parsing (commander/yargs)
├── commands/
│   └── example.command.ts
├── lib/
│   └── core-logic.ts
├── types/
│   └── index.ts
└── utils/
    └── logger.ts
```

**빌드**: `tsup` (번들링), `tsx` (개발)

### Standalone: Go CLI/Tool

```
cmd/
└── toolname/
    └── main.go
internal/
├── cli/
│   └── root.go                    # cobra command
├── core/
│   └── logic.go
└── util/
    └── logger.go
```

**CLI**: `cobra` + `viper`

### Standalone: Python CLI/Tool

```
src/
├── __init__.py
├── __main__.py                    # Entry point
├── cli.py                         # typer/click
├── core/
│   └── logic.py
└── utils/
    └── logger.py
```

**CLI**: `typer` 또는 `click`, 패키지 관리: `uv`

---

## 모노레포 구성

### Turborepo (TypeScript)

```
apps/
├── api/                           # Backend (NestJS 등)
└── web/                           # Frontend (React/Next 등)
packages/
├── shared/                        # 공유 타입, 유틸
├── eslint-config/                 # 또는 biome config
└── tsconfig/                      # 공유 tsconfig
turbo.json
package.json
```

- `turbo.json`에 pipeline 정의 (build, lint, test, dev)
- 각 app은 위의 개별 보일러플레이트 구조를 따름

### Go Workspace

```
go.work
services/
├── api/
│   ├── go.mod
│   └── ...
└── worker/
    ├── go.mod
    └── ...
pkg/
├── shared/
│   ├── go.mod
│   └── ...
```

### uv Workspace (Python)

```
pyproject.toml                     # 워크스페이스 루트
packages/
├── api/
│   ├── pyproject.toml
│   └── src/
├── worker/
│   ├── pyproject.toml
│   └── src/
└── shared/
    ├── pyproject.toml
    └── src/
uv.lock
```

---

## 배포 환경 설정

### Serverless Framework (Lambda)

- `serverless.yml` (또는 `serverless.ts`)
- Lambda handler wrapper
- API Gateway 설정
- 환경별 스테이지 (dev, staging, prod)
- Go: `provided.al2023` 런타임, 바이너리 빌드
- Python: Lambda layer 또는 Docker 이미지 기반
- Node.js: esbuild 번들링

### Docker → ECS (Fargate)

- `Dockerfile` (multi-stage build, 최적화)
- `docker-compose.yml` (로컬 개발용)
- `.dockerignore`
- ECS Task Definition 예시 (`infra/ecs-task-def.json`)
- `infra/` 디렉토리에 기본 IaC 템플릿 (참고용)

**Dockerfile 원칙**:
- Multi-stage build
- Non-root user
- Health check 포함
- 캐시 레이어 최적화
- `.dockerignore` 활용

### Docker → EKS (Kubernetes)

- `Dockerfile` (위와 동일)
- `docker-compose.yml` (로컬 개발용)
- `k8s/` 디렉토리:
  - `deployment.yaml`
  - `service.yaml`
  - `ingress.yaml`
  - `hpa.yaml` (Horizontal Pod Autoscaler)
  - `configmap.yaml`
  - `kustomization.yaml` (환경별 오버레이)

### 배포 설정 없음

- 배포 관련 파일 생략
- `Dockerfile`과 `docker-compose.yml`만 포함 (로컬 개발용)

---

## 코드 생성 시 주의사항

1. **최신 버전**: 웹 검색으로 각 기술의 최신 stable 버전을 확인한 뒤 생성한다.
2. **실제 동작**: 생성된 코드는 `npm install && npm run dev` (또는 동등 명령)으로 바로 실행 가능해야 한다.
3. **타입 안전성**: TypeScript는 strict mode, Go는 정적 타입, Python은 type hints 적극 활용.
4. **테스트 준비**: 테스트 프레임워크 설정과 예시 테스트 1개 이상 포함.
5. **환경변수**: `.env.example`에 필요한 변수 목록 기재, 코드에서 검증.
6. **보안 기본값**: helmet(Node), CORS 설정, input validation 등 포함.
7. **문서화**: README에 프로젝트 구조, 실행 방법, 주요 결정사항 기록.

---

## 실행 예시

```
User: /boilerplate

Claude: 프로젝트 분야를 선택해주세요.
  → [Backend / Frontend / Standalone]

User: Backend

Claude: 기술스택을 선택해주세요.
  → [NestJS (TypeScript) / Go / Python (FastAPI)]

User: NestJS

Claude: 모노레포로 구성할까요?
  → [Yes (Turborepo) / No]

User: No

Claude: Formatter를 선택해주세요. (TypeScript 프로젝트 기본: Biome)
  → [Biome (기본) / ESLint + Prettier]

User: Biome

Claude: AWS 배포 환경을 선택해주세요.
  → [Serverless Framework / Docker → ECS / Docker → EKS / 배포 없음]

User: Docker → ECS

Claude:
📋 프로젝트 설정 요약:
─────────────────────
분야:       Backend
기술스택:    NestJS (TypeScript)
모노레포:    No
Formatter:  Biome
배포환경:    Docker → ECS (Fargate)
─────────────────────
생성을 시작합니다...

[파일 생성]
```
