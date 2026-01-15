# pr-resolver 구현 계획서

## 1. 구현 범위

| 항목 | 내용 |
|------|------|
| 산출물 | `commands/pr-resolver.md` |
| 형식 | Claude Code Custom Command (Markdown) |
| 의존성 | gh CLI, git |

---

## 2. 파일 구조

```
claude-code-skills/
├── README.md                      # 설치 가이드
├── LICENSE
├── install.sh                     # 설치 스크립트
├── uninstall.sh                   # 삭제 스크립트
├── docs/
│   ├── pr-resolver-spec.md        # 요구사항 정의서
│   └── pr-resolver-impl-plan.md   # 구현 계획서 (현재 문서)
└── commands/
    ├── pr-resolver.md             # 라우터 (Help/Config 섹션 포함)
    ├── pr-resolver-en.md          # 메인 플로우 (영어)
    └── pr-resolver-ko.md          # 메인 플로우 (한국어)
```

설정은 `git config --global pr-resolver.*`에 저장됩니다.

---

## 3. 파일별 구조

### pr-resolver.md (라우터)

```markdown
---
(frontmatter: 메타데이터)
---

# Language Detection (git config에서 읽기)
# Command Routing ($1 인자에 따라 분기)
# Help Section (en/ko 양쪽 포함)
# Config Section (설정 표시/변경)
# Main Flow Routing → 언어별 파일로 위임
```

### pr-resolver-{en,ko}.md (메인 플로우)

```markdown
# Main Flow
  - Environment Check
  - PR Detection
  - Comment Retrieval
  - User Selection
  - Process Comment
  - Send
  - Repeat
  - Error Handling
```

---

## 4. 주요 플로우 상세

### 4.1 Frontmatter

```yaml
---
allowed-tools: Bash(gh:*), Bash(git:*)
argument-hint: [help|config|PR number]
description: PR review comment handler
---
```

### 4.2 User Selection

```
Step 1: 코멘트 선택
  └─ "Which comment to handle?" → 번호 선택

Step 2: 액션 선택
  └─ Fixed / Will fix later / Explain / Disagree / Skip / Praise response
```

### 4.3 Process Comment (Fixed 액션)

```
Step 1: 리뷰어 코멘트 전체 표시
  └─ 파일, 라인, 내용 전체

Step 2: 언어 감지
  └─ 코멘트 언어 → 코드 제안/답글 언어 맞춤

Step 3: 코드 수정 제안
  └─ AI가 수정 코드 제안
  └─ [적용] [수정] [의견 추가] [건너뛰기]
      • 적용: 제안 코드 그대로 적용
      • 수정: 사용자가 수정 후 적용
      • 의견 추가: 추가 컨텍스트 → 재생성
      • 건너뛰기: 다음 코멘트로

Step 4: 커밋
  └─ 코드 수정 적용 시 자동 커밋
  └─ "이 커밋이 맞나요? {hash}" 확인

Step 5: 답글 생성
  └─ AI가 답글 제안 (커밋 해시 포함)

Step 6: 답글 확인
  └─ [전송] [수정] [의견 추가] [취소]
      • 전송: 답글 그대로 전송
      • 수정: 사용자가 수정 후 전송
      • 의견 추가: 추가 컨텍스트 → 재생성
      • 취소: 다음 코멘트로
```

### 4.4 Config Section

설정은 `git config --global` 사용:

```bash
# 언어 설정
git config --global pr-resolver.lang ko

# 액션 활성화/비활성화
git config --global pr-resolver.action.disagree.enabled false

# 리액션 변경
git config --global pr-resolver.action.fixed.reaction rocket

# 설정 초기화
git config --global --remove-section pr-resolver
```

---

## 5. 액션별 동작

| 액션 | 코드수정 | 답글 | 리액션 |
|------|----------|------|--------|
| Fixed | ✅ AI 제안 | ✅ AI 제안 | 👍 (+1) |
| Will fix later | ❌ | ✅ AI 제안 | 👀 (eyes) |
| Explain | ❌ | ✅ 사용자 입력 | ❌ |
| Disagree | ❌ | ✅ 사용자 입력 | ❌ |
| Skip | ❌ | ❌ | 👍 (+1) |
| Praise response | ❌ | ❌ | ❤️ (heart) |

---

## 6. GitHub API 사용

```bash
# 레포 정보
gh repo view --json owner,name -q '"\(.owner.login)/\(.name)"'

# 코멘트 조회
gh api repos/{owner}/{repo}/pulls/{pr}/comments \
  --jq '.[] | {id, path, body, in_reply_to_id}'

# 답글 전송
gh api repos/{owner}/{repo}/pulls/{pr}/comments/{id}/replies \
  -f body="{reply}"

# 리액션 추가
gh api repos/{owner}/{repo}/pulls/{pr}/comments/{id}/reactions \
  -f content="{+1|eyes|heart}"
```

---

## 7. 테스트 계획

| # | 시나리오 | 예상 결과 |
|---|----------|----------|
| 1 | `/pr-resolver` (PR 있는 브랜치) | PR 자동 감지 |
| 2 | `/pr-resolver 2874` | 지정 PR 사용 |
| 3 | `/pr-resolver help` | 도움말 표시 |
| 4 | `/pr-resolver config` | 설정 표시 |
| 5 | 코멘트 없는 PR | "처리할 코멘트 없음" |
| 6 | Fixed 선택 | 코드 수정 → 커밋 → 답글 + 👍 |
| 7 | Skip 선택 | 👍만 전송 |
| 8 | 의견 추가 | 재생성 후 다시 선택 |
| 9 | 다중 코멘트 처리 | 반복 동작 확인 |

---

## 8. 설치 방법

```bash
# 설치
curl -fsSL https://raw.githubusercontent.com/js-koo/claude-code-skills/main/install.sh | bash

# 삭제
~/.claude-code-skills/uninstall.sh

# 업데이트
cd ~/.claude-code-skills && git pull
```
