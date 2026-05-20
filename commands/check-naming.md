# Check Naming Conventions

소스코드 내 식별자가 `~/.claude/rules/common/naming-conventions.md`의 작명 규칙을 따르는지 검사한다.

## 사용법

```
/check-naming               # 변경된 파일(git diff)만 검사
/check-naming <path>        # 특정 경로/파일 검사
/check-naming --all         # 프로젝트 전체 검사 (느릴 수 있음)
```

## Step 1: 규칙 로드

먼저 `~/.claude/rules/common/naming-conventions.md`를 Read하여 검사 기준을 내면화한다.

## Step 2: 검사 대상 수집

- 인자 없음 → `git diff --name-only HEAD` 그리고 `git diff --name-only --staged`로 변경된 소스파일 수집
- 경로 인자 → Glob으로 해당 경로의 소스파일 수집
- `--all` → 프로젝트 소스 디렉토리(`src/`, `lib/`, `app/` 등) 전체

대상 확장자: `.ts`, `.tsx`, `.js`, `.jsx`, `.py`, `.go`, `.kt`, `.java` (프로젝트에 맞게 자동 판단)

## Step 3: 검사 항목

각 파일에서 다음 패턴을 검출한다.

### 3.1 상위 컨텍스트 반복 (HIGH)

- **class 내 메서드가 class 이름을 반복**:
  - `class UserService { getUserById() }` → `class UserService { find() }`
  - Grep 패턴: `class (\w+)\s*{[^}]*\b(get|find|update|delete|create)\1\w*\(`

- **객체 키가 객체 이름(혹은 변수명)을 접두어로 반복**:
  - `const user = { userId, userName }` → `{ id, name }`
  - Grep으로 `const (\w+)\s*=\s*{` 매칭 후, 키들이 `\1` 접두어로 시작하는지 확인

- **모듈 함수가 파일/모듈 이름을 반복**:
  - `payment.ts` 안의 `createPayment()` → `create()`
  - 파일명을 추출하여 export된 함수명에 포함되어 있는지 확인

### 3.2 자명한 동사 접두어 (MEDIUM)

다음 접두어가 문맥상 불필요해 보이면 플래그:
- `getList()` → `list()`
- `fetchAll()` → `all()`
- `retrieveData()` → `load()`
- `getById(id)` → `find(id)`

Grep 패턴: `\b(get|fetch|retrieve)(List|All|Data)\b`

### 3.3 추상 접미사 (MEDIUM)

타입이 이미 표현하는 접미사를 변수명에서 검출:
- `xxxData`, `xxxInfo`, `xxxItem`, `xxxObject`, `xxxList`, `xxxArray`

Grep 패턴: `\b\w+(Data|Info|Item|Object|List|Array)\b` (단, 도메인 용어 예외: `metadata`, `userInfo` 등 표준 용어는 제외)

### 3.4 금지 단어 (LOW)

class, 함수, 변수명에 다음이 포함되면 플래그:
- `Manager`, `Handler`, `Helper`, `Util`, `Utils`

표준 라이브러리/프레임워크 클래스(`EventHandler`, `RequestHandler` 등 framework가 강제하는 이름)는 예외.

### 3.5 Repository 메서드 (HIGH)

`*Repository` 또는 `*Repo`로 끝나는 class의 메서드가 도메인 이름을 반복:
- `class UserRepository { findUserById() }` → `{ find() }`
- `class OrderRepo { getAllOrders() }` → `{ list() }`

## Step 4: 컨텍스트 검증

규칙 위반 후보가 검출되면 **실제 코드를 Read하여 다음을 확인**:

1. 호출부에서 어떻게 쓰이고 있는가? (`user.userId` 같은 중복이 실제로 일어나는가?)
2. 같은 class/모듈 내 유사 메서드가 있어 단어 추가가 정당화되는가?
3. 도메인 용어 보존이 필요한 경우인가? (`paymentIntent` 같은 단어)

검증 후 false-positive는 제외한다.

## Step 5: 리포트

```
## Naming Convention Report

검사 범위: {N개 파일, M개 식별자}

### CRITICAL/HIGH ({개수}건)

#### {파일경로}:{라인}
- 현재: `class UserService { getUserById(id) }`
- 위반: 상위 컨텍스트 반복 (UserService가 이미 User 표현)
- 제안: `class UserService { find(id) }`
- 호출부 영향: `userService.getUserById(1)` → `userService.find(1)`
- 영향 받는 호출부: {grep으로 찾은 호출 위치들}

### MEDIUM ({개수}건)

#### {파일경로}:{라인}
- 현재: `const userDataList = ...`
- 위반: 추상 접미사 (Data, List)
- 제안: `const users = ...`

### LOW ({개수}건)

#### {파일경로}:{라인}
- 현재: `class PaymentManager`
- 위반: 금지 단어 (Manager)
- 제안: `class Payment` 또는 더 구체적인 동작 기반 이름 고려

### 위반 없음
- {파일들}

## 통계
- 총 검사 식별자: {N}
- 위반: HIGH {N} / MEDIUM {N} / LOW {N}
- 가장 빈번한 위반 패턴: {예: 상위 컨텍스트 반복}
```

## Step 6: 수정 제안

리포트 끝에 사용자에게 다음을 묻는다:

```
다음 중 어떻게 진행할까요?

1. HIGH/CRITICAL 항목만 자동 수정
2. 모든 항목 자동 수정 (호출부 포함)
3. 리포트만 보고 수동 수정
4. 특정 파일만 선별 수정
```

수정 시에는 호출부까지 함께 변경해야 하므로 **반드시 grep으로 호출 위치를 모두 찾은 뒤** 일괄 변경한다.

## Rules

- false-positive를 줄이기 위해 패턴 매칭 후 **반드시 실제 코드를 Read하여 컨텍스트를 확인**한다.
- 도메인 용어(`paymentIntent`, `accessToken`, `metadata` 등)는 예외 처리한다.
- framework가 강제하는 이름(`EventHandler`, `*Controller`, `*Module` 등 NestJS/Angular 규약)은 제외한다.
- 테스트 파일의 작명은 별도 규칙이 있을 수 있으므로 우선순위를 낮춘다.
- 단 한 줄도 자동 수정하기 전에 사용자 승인을 받는다.
