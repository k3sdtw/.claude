# Test DB Isolation

## 목적

orchestrate 워크플로우가 병렬로 실행될 때 DB 충돌을 방지한다.
각 워크플로우는 독립된 테스트 DB를 생성하여 사용하고, 완료 후 자동 삭제한다.

## 프로토콜

테스트 실행 전 아래 절차를 수행한다.

### 1. 기존 테스트 DB 확인

state.json에 `testDatabase` 필드가 이미 있으면 **기존 DB를 재사용**한다 → 3단계(마이그레이션)부터 시작.
없으면 아래 2단계부터 순서대로 진행한다.

### 2. DB 설정 감지

worktreePath에서 `.env`, `.env.test`, `docker-compose*.yml` 등을 Read하여 `DATABASE_URL`을 찾는다.

| DB URL 패턴 | DB 종류 |
|-------------|---------|
| `postgresql://` 또는 `postgres://` | PostgreSQL |
| `mysql://` | MySQL |
| `mongodb://` 또는 `mongodb+srv://` | MongoDB |
| `*.sqlite`, `*.db`, `file:` | SQLite |
| 감지 실패 | AskUserQuestion으로 사용자에게 질문 |

> `DATABASE_URL` 외의 변수명을 사용하는 프로젝트(예: `DB_HOST` + `DB_PORT` + `DB_NAME` 분리형)는
> `.env` 파일에서 해당 변수명을 감지하여 동일하게 override한다.

### 3. 테스트 DB 이름 생성

state.json의 `identifier`에서 파생한다:

```bash
# identifier의 하이픈을 언더스코어로 치환
TEST_DB_SUFFIX=$(echo "{identifier}" | tr '-' '_' | tr '[:upper:]' '[:lower:]')

# 원본 DB 이름에 suffix 부착
# 예: 원본 myapp_test → myapp_test_gifca_123_voucher
```

### 4. DB 생성 및 마이그레이션

**PostgreSQL:**
```bash
createdb "{TEST_DB_NAME}" 2>/dev/null || true
DATABASE_URL="{치환된 URL}" {migration 명령어}
```

**MySQL:**
```bash
mysql -u root -e "CREATE DATABASE IF NOT EXISTS \`{TEST_DB_NAME}\`;"
DATABASE_URL="{치환된 URL}" {migration 명령어}
```

**SQLite:**
```bash
# 별도 생성 불필요 — 파일 경로만 변경하면 자동 생성
DATABASE_URL="{치환된 URL}" {migration 명령어}
```

**MongoDB:**
```bash
# 별도 생성 불필요 — 접속 시 자동 생성
DATABASE_URL="{치환된 URL}" {migration 명령어}
```

> migration 명령어는 프로젝트의 CLAUDE.md 또는 package.json scripts에서 탐색한다.
> 찾을 수 없으면 AskUserQuestion으로 사용자에게 질문한다.

### 5. 테스트 실행

**반드시 `DATABASE_URL` 환경변수를 override하여 실행한다:**

```bash
DATABASE_URL="{치환된 URL}" {commands.test}
```

### 6. State 기록

state.json에 생성한 테스트 DB 정보를 기록한다:

```jsonc
{
  "testDatabase": {
    "name": "{TEST_DB_NAME}",
    "url": "{치환된 DATABASE_URL}",
    "type": "postgresql"  // 감지된 DB 종류
  }
}
```

## Cleanup (자동)

**done.md의 PR 생성 완료 후** 자동으로 테스트 DB를 삭제한다.

state.json의 `testDatabase` 필드를 읽고 `type`에 따라 실행:

**PostgreSQL:**
```bash
dropdb "{testDatabase.name}" 2>/dev/null || true
```

**MySQL:**
```bash
mysql -u root -e "DROP DATABASE IF EXISTS \`{testDatabase.name}\`;" 2>/dev/null || true
```

**SQLite:**
```bash
rm -f "{SQLite 파일 경로}" 2>/dev/null || true
```

**MongoDB:**
```bash
mongosh --eval "db.getSiblingDB('{testDatabase.name}').dropDatabase()" 2>/dev/null || true
```

> cleanup 실패 시 에러를 무시하고 진행한다 (`|| true`).
> 사용자에게 cleanup 결과(성공/실패)를 Output에서 보고한다.

cleanup 후 state.json의 `testDatabase` 필드를 `null`로 갱신한다.
