# PR Resolver (한국어)

PR 리뷰 코멘트 확인, 코드 수정, 답글 처리 자동화

## 기본 설정

```
lang: ko
Actions:
  fixed:          답글 + 👍 (+1)
  will_fix_later: 답글 + 👀 (eyes)
  explain:        답글만
  disagree:       답글만
  skip:           👍만 (+1)
  praise:         ❤️만 (heart)
```

## 명령어 분기

`$1` 인자 확인:

- `$1` = "help" → **도움말 섹션**으로 이동
- `$1` = "config" → **설정 섹션**으로 이동
- 그 외 → **메인 플로우**로 이동 (숫자면 PR 번호로 사용)

---

# 도움말 섹션

도움말 표시:

```
╔═══════════════════════════════════════════════════════════╗
║                   PR Resolver 도움말                       ║
╚═══════════════════════════════════════════════════════════╝

사용법:
  /pr-resolver [PR번호]       - PR 리뷰 코멘트 처리
  /pr-resolver help           - 도움말 표시
  /pr-resolver config         - 설정 보기/변경

설정 명령어:
  /pr-resolver config                     - 현재 설정 보기
  /pr-resolver config lang <en|ko>        - 언어 변경
  /pr-resolver config action <name> <enable|disable>
  /pr-resolver config action <name> reaction <+1|eyes|heart|rocket|null>
  /pr-resolver config reset               - 설정 초기화

예시:
  /pr-resolver                - PR 자동 감지 후 코멘트 처리
  /pr-resolver 2874           - PR #2874 코멘트 처리
  /pr-resolver config lang en - 영어로 변경

액션:
  fixed          - 수정 완료 (답글 + 👍)
  will_fix_later - 다음에 반영 (답글 + 👀)
  explain        - 설명 (답글만)
  disagree       - 반박 (답글만)
  skip           - 스킵 (👍만)
  praise         - 칭찬 응답 (❤️만)
```

도움말 표시 후 종료.

---

# 설정 섹션

설정은 git config (global)에 저장됨.

## 현재 설정 읽기

설정 읽기: !`git config --global --get-regexp '^pr-resolver\.' 2>/dev/null || echo ""`

## 설정 표시 ("config" 뒤에 추가 인자 없을 때)

현재 설정 표시:

```
╔═══════════════════════════════════════════════════════════╗
║                   PR Resolver 설정                         ║
╚═══════════════════════════════════════════════════════════╝

언어: {lang 또는 "en (기본값)"}

액션:
  ┌─────────────────┬─────────┬──────────────┐
  │ 액션            │ 활성화  │ 리액션       │
  ├─────────────────┼─────────┼──────────────┤
  │ fixed           │ ✓       │ 👍 (+1)      │
  │ will_fix_later  │ ✓       │ 👀 (eyes)    │
  │ explain         │ ✓       │ -            │
  │ disagree        │ ✓       │ -            │
  │ skip            │ ✓       │ 👍 (+1)      │
  │ praise          │ ✓       │ ❤️ (heart)   │
  └─────────────────┴─────────┴──────────────┘
```

git config에서 실제 값 표시, 없으면 기본값 사용.

## 설정 변경

### 언어: `/pr-resolver config lang <en|ko>`
```bash
git config --global pr-resolver.lang {value}
```
표시: "✅ 언어가 {value}로 변경되었습니다"

### 액션 활성화/비활성화: `/pr-resolver config action <name> <enable|disable>`
```bash
git config --global pr-resolver.action.{name}.enabled {true|false}
```
표시: "✅ '{name}' 액션이 {활성화|비활성화}되었습니다"

### 액션 리액션: `/pr-resolver config action <name> reaction <+1|eyes|heart|rocket|null>`
```bash
git config --global pr-resolver.action.{name}.reaction {value}
```
표시: "✅ '{name}' 리액션이 {value}로 변경되었습니다"

### 초기화: `/pr-resolver config reset`
```bash
git config --global --remove-section pr-resolver 2>/dev/null || true
```
표시: "✅ 설정이 초기화되었습니다"

설정 작업 후 종료.

---

# 메인 플로우

## 환경 확인

1. git repo 확인: !`git rev-parse --git-dir 2>/dev/null || echo "NOT_GIT_REPO"`
2. gh 인증 확인: !`gh auth status 2>&1 | head -3`
3. 리모트 정보: !`git remote -v | head -2`

- git repo 아닌 경우: "❌ git 저장소에서 실행해주세요." 출력 후 종료
- gh 미인증인 경우: "❌ 먼저 `gh auth login`을 실행해주세요." 출력 후 종료

## PR 감지

1. `$1`이 숫자면 → PR 번호로 사용
2. `$1`이 비어있으면 → `gh pr view --json number -q '.number' 2>/dev/null` 실행
3. 실패 시 → 사용자에게 질문: "PR 번호를 입력하세요:"

## 코멘트 조회

레포 정보 추출:
```bash
gh repo view --json owner,name -q '"\(.owner.login)/\(.name)"'
```

코멘트 조회:
```bash
gh api repos/{owner}/{repo}/pulls/{pr}/comments --jq '.[] | {id, path, body: .body[0:50], in_reply_to_id}'
```

필터: `in_reply_to_id`가 null인 코멘트만 표시 (최상위 코멘트)

표시:
```
📋 {count}개의 코멘트를 찾았습니다

| # | 파일 | 내용 |
|---|------|------|
| 1 | Repository.kt:64 | SQL 인젝션 위험... |
```

코멘트 없으면: "✅ 처리할 코멘트가 없습니다." 출력 후 종료

## 사용자 선택

AskUserQuestion 사용:

### Step 1: 코멘트 선택
질문: "어떤 코멘트를 처리할까요?"
옵션: 코멘트 번호 (1, 2, 3...)

### Step 2: 액션 선택
질문: "어떻게 처리할까요?"
옵션:
- 수정 완료 - 수정 확인 답글 + 👍
- 다음에 반영 - 확인 답글 + 👀
- 설명 - 설명 답글
- 반박 - 반박 답글
- 스킵 - 해결됨 표시 (👍만)
- 칭찬 응답 - 리뷰어에게 감사 (❤️만)

## 코멘트 처리

### Step 1: 전체 코멘트 표시

리뷰어 코멘트 전체 표시:
```
┌─────────────────────────────────────────────────────────────┐
│  📝 리뷰어 코멘트                                            │
│  ─────────────────────────────────────────────────────────  │
│  파일: {path}:{line}                                        │
│  내용: {전체 코멘트 내용}                                    │
└─────────────────────────────────────────────────────────────┘
```

### Step 2: 언어 감지

코멘트 언어 감지 → 코드 제안 및 답글에 같은 언어 사용

### Step 3: 코드 수정 (액션이 "수정 완료"인 경우)

1. 코멘트와 관련 코드 분석
2. 수정 코드 제안 생성
3. 표시:
```
┌─────────────────────────────────────────────────────────────┐
│  💡 제안 수정 코드                                           │
│  ─────────────────────────────────────────────────────────  │
│  - {원본 코드}                                               │
│  + {수정 코드}                                               │
└─────────────────────────────────────────────────────────────┘
```
4. 사용자에게 질문: [적용] [수정] [의견 추가] [건너뛰기]
   - 적용: 제안 코드 그대로 적용
   - 수정: 제안 코드 수정 후 적용
   - 의견 추가: 추가 컨텍스트 제공 → 제안 재생성
   - 건너뛰기: 이 코멘트 건너뛰고 다음으로

5. 적용/수정된 경우 → 변경사항 커밋
   - 커밋 해시 가져오기: !`git rev-parse --short HEAD`
   - 질문: "이 커밋이 맞나요? {hash}" [예] [다른 커밋 선택]

### Step 4: 답글 생성

#### 액션이 "수정 완료" 또는 "다음에 반영"인 경우:
1. 커밋 참조 포함하여 답글 생성 (해당되는 경우)
2. 감지된 언어에 맞춤

#### 액션이 "설명" 또는 "반박"인 경우:
1. 사용자에게 질문: "답글을 입력하세요:"
2. 사용자 입력 받기

#### 액션이 "스킵" 또는 "칭찬 응답"인 경우:
답글 생성 건너뛰고 리액션만 진행

### Step 5: 답글 확인

제안 답글 표시:
```
┌─────────────────────────────────────────────────────────────┐
│  💬 제안 답글                                                │
│  ─────────────────────────────────────────────────────────  │
│  {제안 답글 내용}                                            │
└─────────────────────────────────────────────────────────────┘
```

사용자에게 질문: [전송] [수정] [의견 추가] [취소]
- 전송: 답글 그대로 전송
- 수정: 답글 수정 후 전송
- 의견 추가: 추가 컨텍스트 제공 → 답글 재생성
- 취소: 취소하고 다음 코멘트로

## 전송

### 답글 전송 (답글 필요한 액션인 경우):
```bash
gh api repos/{owner}/{repo}/pulls/{pr}/comments/{comment_id}/replies -f body="{reply}"
```

### 리액션 추가 (액션에 따라):
```bash
gh api repos/{owner}/{repo}/pulls/{pr}/comments/{comment_id}/reactions -f content="{reaction}"
```

리액션 매핑:
- fixed: +1
- will_fix_later: eyes
- skip: +1
- praise: heart

### 결과 표시:
```
✅ 전송 완료!
   코멘트 ID: {id}
   리액션: {emoji}
```

## 반복

질문: "다른 코멘트도 처리할까요?"
옵션: [예] [아니오]

- 예 → 코멘트 조회로 돌아가기
- 아니오 → "👋 완료!" 출력 후 종료

## 에러 처리

| 상황 | 메시지 |
|------|--------|
| git repo 아님 | ❌ git 저장소에서 실행해주세요. |
| gh 미인증 | ❌ 먼저 `gh auth login`을 실행해주세요. |
| PR 없음 | ❌ PR을 찾을 수 없습니다. 올바른 PR 번호를 입력해주세요. |
| 코멘트 없음 | ✅ 처리할 코멘트가 없습니다. |
| API 실패 | ❌ GitHub API 오류: {message} |
| 사용자 취소 | 👋 취소되었습니다. |
