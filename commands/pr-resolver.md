---
allowed-tools: Bash(gh:*), Bash(git:*)
argument-hint: [PR번호]
description: PR 리뷰 코멘트 확인 및 답글 처리
---

# PR Resolver

PR 리뷰 코멘트를 확인하고 답글을 처리합니다.

## 환경 확인

먼저 실행 환경을 확인하세요:
1. git repo 확인: !`git rev-parse --git-dir 2>/dev/null || echo "NOT_GIT_REPO"`
2. gh 인증 확인: !`gh auth status 2>&1 | head -3`
3. remote 정보: !`git remote -v | head -2`

- git repo가 아니면: "❌ git 저장소에서 실행해주세요." 출력 후 종료
- gh 미인증이면: "❌ `gh auth login`을 먼저 실행해주세요." 출력 후 종료

## PR 감지

사용자 인자: $1

1. `$1`이 있으면 → PR 번호로 사용
2. `$1`이 없으면 → `gh pr view --json number -q '.number' 2>/dev/null` 실행
3. 실패 시 → 사용자에게 PR 번호 입력 요청

## 코멘트 조회

repo 정보 추출:
```bash
gh repo view --json owner,name -q '"\(.owner.login)/\(.name)"'
```

코멘트 조회:
```bash
gh api repos/{owner}/{repo}/pulls/{pr}/comments --jq '.[] | {id, path, body: .body[0:100]}'
```

코멘트 목록을 표 형식으로 표시:
```
📋 리뷰 코멘트 {n}개:

| # | 파일 | 내용 |
|---|------|------|
| 1 | Repository.kt:64 | SQL 인젝션 위험... |
| 2 | Service.kt:176 | check() 검증... |
```

코멘트가 없으면: "✅ 처리할 리뷰 코멘트가 없습니다." 출력 후 종료

## 사용자 선택

AskUserQuestion을 사용하여 순차적으로 질문:

### Step 1: 코멘트 선택
"어떤 코멘트를 처리할까요?"
- 옵션: 코멘트 번호들 (1, 2, 3...)

### Step 2: 유형 선택
"이 코멘트의 유형은?"
- 🔴 버그/이슈 - 수정 필요한 문제
- 🟡 제안 - 개선 제안 (선택적)
- 🔵 질문 - 설명 필요
- 🟢 칭찬/승인 - LGTM 류
- ⚪ 기타

### Step 3: 행동 선택
"어떻게 처리할까요?"
- 수정 완료 - 코드 수정함 (답글 + 👍)
- 다음에 반영 - 지금은 안 함 (답글 + 👀)
- 설명 - 이유 설명 (답글만)
- 반박 - 동의 안 함 (답글만)
- 스킵 - 이미 해결됨 (👍만)
- 칭찬 응답 - 감사 표시 (❤️만)

## 답글 생성

### 행동이 "수정 완료" 또는 "다음에 반영"인 경우:

1. 코멘트 원문 내용을 분석
2. 행동에 맞는 적절한 답글 제안
3. 커밋 해시 필요시: `git rev-parse HEAD --short` 실행
4. "이 커밋이 맞나요? {hash}" 확인
5. 코멘트 언어 감지 (한글/영어) → 같은 언어로 답글 작성
6. 답글 제안 후 사용자에게 확인/수정 요청

예시 (수정 완료, 한글):
```
💬 제안 답글:
"파라미터 바인딩 방식으로 수정 완료했습니다. (커밋: abc1234)"

[전송] [수정] [취소]
```

예시 (다음에 반영, 영어):
```
💬 Suggested reply:
"Thank you for the suggestion. Will address this in a future update."

[Send] [Edit] [Cancel]
```

### 행동이 "설명" 또는 "반박"인 경우:

1. 사용자에게 직접 답글 내용 입력 요청
2. 입력받은 내용 확인

### 행동이 "스킵" 또는 "칭찬 응답"인 경우:

답글 생성 없이 리액션만 추가

## 전송

### 답글 전송 (스킵, 칭찬 응답 제외):
```bash
gh api repos/{owner}/{repo}/pulls/{pr}/comments/{comment_id}/replies -f body="{답글}"
```

### 리액션 추가:
```bash
gh api repos/{owner}/{repo}/pulls/{pr}/comments/{comment_id}/reactions -f content="{reaction}"
```

리액션 매핑:
| 행동 | reaction |
|------|----------|
| 수정 완료 | +1 |
| 다음에 반영 | eyes |
| 스킵 | +1 |
| 칭찬 응답 | heart |
| 설명/반박 | (없음) |

전송 완료 후 결과 표시:
```
✅ 답글 전송 완료!
   코멘트: #{comment_id}
   리액션: 👍
```

## 반복

전송 완료 후 AskUserQuestion으로 질문:
"다른 코멘트도 처리할까요?"
- 예 → 코멘트 목록 표시로 돌아가기
- 아니오 → "👋 PR Resolver를 종료합니다." 출력 후 종료

## 에러 처리

| 상황 | 메시지 |
|------|--------|
| git repo 아님 | ❌ git 저장소에서 실행해주세요. |
| gh 미인증 | ❌ `gh auth login`을 먼저 실행해주세요. |
| PR 없음 | ❌ PR을 찾을 수 없습니다. PR 번호를 입력해주세요. |
| 코멘트 없음 | ✅ 처리할 리뷰 코멘트가 없습니다. |
| API 실패 | ❌ GitHub API 오류: {에러 메시지} |
| 사용자 취소 | 👋 취소되었습니다. |
