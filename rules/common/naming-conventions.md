---
name: naming-conventions
description: 변수명, 함수명, repository 메서드 등 코드 식별자 작명 규칙. 합성 단어 수를 최소화하여 간결한 이름 선호.
scope: [variable, function, method, repository, class]
priority: high
applies_to: all
---

# Naming Conventions

## 핵심 원칙

**단어 수를 최소화한다. 의미가 손상되지 않는 한 가장 짧은 이름을 선택한다.**

- 한 단어로 충분하면 한 단어로 작성한다.
- 한 단어로 부족할 때만 합성한다.
- 합성하더라도 단어 수를 최대한 줄인다.
- 단, 모호함이 생기면 단어를 추가한다. 무조건 한 단어를 고집하지 않는다.

## 권장 패턴

### 동사 접두어 제거

문맥에서 동작이 자명한 경우 `get`, `fetch`, `retrieve` 같은 접두어를 생략한다.

| Avoid | Prefer |
|-------|--------|
| `getList()` | `list()` |
| `getById(id)` | `find(id)` 또는 `byId(id)` |
| `getUser()` | `user()` |
| `fetchAll()` | `all()` |
| `retrieveData()` | `load()` |

### Repository 메서드

Repository는 데이터 접근이라는 문맥이 명확하므로 동사를 짧게 유지한다.

| Avoid | Prefer |
|-------|--------|
| `findUserById(id)` | `find(id)` |
| `getAllUsers()` | `list()` |
| `createUser(data)` | `create(data)` |
| `updateUserById(id, data)` | `update(id, data)` |
| `deleteUserById(id)` | `delete(id)` |
| `findUsersByStatus(status)` | `byStatus(status)` |

> Repository 이름(`UserRepository`)이 이미 도메인을 표현하므로 메서드명에 `User`를 반복하지 않는다.

### 상위 컨텍스트 반복 금지

class, 객체, 모듈 등 **상위 식별자가 이미 컨텍스트를 표현하고 있다면 하위 method나 key 이름에서 그 컨텍스트를 접두어로 반복하지 않는다.**

```typescript
// Avoid — class 이름이 이미 User를 표현
class UserService {
  getUserById(id) {}
  updateUserProfile(data) {}
  deleteUserAccount(id) {}
}

// Prefer
class UserService {
  find(id) {}
  updateProfile(data) {}
  deleteAccount(id) {}
}
```

```typescript
// Avoid — 객체 키에 객체 이름 반복
const user = {
  userId: 1,
  userName: 'kim',
  userEmail: 'kim@example.com',
}

// Prefer
const user = {
  id: 1,
  name: 'kim',
  email: 'kim@example.com',
}
```

```typescript
// Avoid — 모듈 이름이 이미 payment를 표현
// payment.ts
export function createPayment() {}
export function cancelPayment() {}

// Prefer
// payment.ts
export function create() {}
export function cancel() {}
```

> 호출부에서 `user.id`, `payment.create()`처럼 컨텍스트가 자연스럽게 합쳐진다. 정의부에서 컨텍스트를 반복하면 호출부가 `user.userId`처럼 중복된다.

### 변수명

```typescript
// Avoid
const userDataList = users.map(...)
const userInfoObject = { ... }
const userItemArray = [...]

// Prefer
const users = users.map(...)
const user = { ... }
const items = [...]
```

추상적 접미사(`Data`, `Info`, `Item`, `Object`, `List`)는 제거한다 — 타입이 이미 그 정보를 담고 있다.

## 합성이 필요한 경우

다음 상황에서는 단어 합성이 정당하다:

- **모호함 제거**: `find()`만으로는 무엇을 찾는지 모호할 때 → `findActive()`, `findByEmail()`
- **유사 메서드 구분**: 같은 클래스에 비슷한 동작이 여럿 있을 때 → `listPending()`, `listArchived()`
- **도메인 용어 보존**: 줄이면 의미가 사라지는 용어 → `paymentIntent`(O), `intent`(X)

## 판단 기준

이름을 정할 때 자문한다:

1. 이 이름의 단어 중 하나를 빼도 의미가 통하는가? → **뺀다**
2. 동사 접두어가 문맥상 자명한가? → **뺀다**
3. 도메인 정보가 클래스/파일/모듈 이름에 이미 있는가? → **메서드명에서 뺀다**
4. 뺐을 때 다른 메서드와 구분이 안 되는가? → **유지한다**

## Anti-Patterns

추상 단어 사용 금지 (CLAUDE.md와 일치):

- `Info`, `Data`, `Item`, `Object`, `Manager`, `Handler`, `Helper`, `Util`
- 위 단어들은 거의 항상 의미 없이 길이만 늘린다. 더 구체적인 단어로 대체하거나 제거한다.
