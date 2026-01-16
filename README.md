# Claude Workflows

Claude Code workflow 모음 (slash commands)

## 설치

```bash
curl -fsSL https://raw.githubusercontent.com/js-koo/claude-workflows/main/install.sh | bash
```

## 업데이트

```bash
cd ~/.claude-workflows && git pull
```

## 삭제

```bash
~/.claude-workflows/uninstall.sh
```

## Skills

### pr-resolver

PR 리뷰 코멘트 확인, 코드 수정, 답글 처리 자동화

**사용법:**
```
/pr-resolver              # PR 자동 감지
/pr-resolver 2874         # 특정 PR 지정
/pr-resolver help         # 도움말
/pr-resolver config       # 설정 보기
```

**주요 기능:**
- 리뷰 코멘트 목록 조회
- 코드 수정 제안 및 적용
- 답글 자동 생성
- 리액션 자동 추가
- 설정 커스터마이징 (git config)

**액션:**
| 액션 | 코드수정 | 답글 | 리액션 |
|------|----------|------|--------|
| Fixed | ✅ | ✅ | 👍 |
| Will fix later | ❌ | ✅ | 👀 |
| Explain | ❌ | ✅ | ❌ |
| Disagree | ❌ | ✅ | ❌ |
| Skip | ❌ | ❌ | 👍 |
| Praise response | ❌ | ❌ | ❤️ |

## 문서

- [요구사항 정의서](docs/pr-resolver-spec.md)
- [구현 계획서](docs/pr-resolver-impl-plan.md)

## 라이선스

MIT
