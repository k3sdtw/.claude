---
name: jira
description: Jira 이슈 생성 및 관리. Task, Bug, Story 템플릿 제공.
---

# Jira Integration Skill

Jira MCP 도구를 활용한 이슈 생성 및 관리

## 이슈 유형별 템플릿

### Task (작업)

기술 작업, 리팩토링, 성능 개선 등에 사용

```
## 작업배경
왜 이 작업이 필요한가?
- [ ] 기술부채 해소
- [ ] 성능개선
- [ ] 요청사항
- [ ] 기타:

{배경 설명}

## 작업내용
구체적으로 무엇을 해야하는가?

1.
2.
3.

## 완료조건
- [ ]
- [ ]
- [ ] 테스트 통과
- [ ] 코드 리뷰 완료

## 참고자료
-
```

### Bug (버그)

```
## 현상
{무엇이 잘못되었는가}

## 재현 방법
1.
2.
3.

## 기대 동작
{정상적으로 동작해야 하는 방식}

## 원인 분석
{알고 있다면 작성}

## 참고자료
-
```

### Story (스토리)

```
## 사용자 스토리
As a {사용자 유형},
I want {원하는 기능},
so that {얻고자 하는 가치}.

## 인수 조건
- [ ] Given:
      When:
      Then:

## 참고자료
-
```

## MCP 도구 사용법

### 이슈 생성

```typescript
mcp__jira__jira_create_issue({
  project_key: "PROJ",
  summary: "이슈 제목",
  issue_type: "Task", // Task, Bug, Story
  description: "이슈 설명 (위 템플릿 사용)"
})
```

### 이슈 조회

```typescript
mcp__jira__jira_get_issue({
  issue_key: "PROJ-123"
})
```

## Commands

- `/jira-task` - Task 이슈 생성
- `/jira-bug` - Bug 이슈 생성
- `/jira-story` - Story 이슈 생성
