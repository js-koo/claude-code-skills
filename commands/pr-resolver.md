---
allowed-tools: Bash(gh:*), Bash(git:*)
argument-hint: [help|config|PR number]
description: PR review comment handler
---

# PR Resolver

## Language Detection

Read language setting: !`git config --global pr-resolver.lang 2>/dev/null || echo "en"`

## Command Routing

Check `$1` argument:

- If `$1` = "help" → Go to **Help Section** below
- If `$1` = "config" → Go to **Config Section** below
- Otherwise (PR number or empty) → Go to **Main Flow Routing** below

---

# Help Section

Display help based on detected language:

### If language is `en`:
```
╔═══════════════════════════════════════════════════════════╗
║                    PR Resolver Help                        ║
╚═══════════════════════════════════════════════════════════╝

Usage:
  /pr-resolver [PR number]    - Handle PR review comments
  /pr-resolver help           - Show this help
  /pr-resolver config         - Show/update configuration

Config Commands:
  /pr-resolver config                     - Show current settings
  /pr-resolver config lang <en|ko>        - Set language
  /pr-resolver config action <name> <enable|disable>
  /pr-resolver config action <name> reaction <+1|eyes|heart|rocket|null>
  /pr-resolver config reset               - Reset to defaults

Examples:
  /pr-resolver                - Auto-detect PR and handle comments
  /pr-resolver 2874           - Handle comments for PR #2874
  /pr-resolver config lang ko - Switch to Korean

Actions:
  fixed          - Code fixed (reply + 👍)
  will_fix_later - Address later (reply + 👀)
  explain        - Explain reason (reply only)
  disagree       - Disagree (reply only)
  skip           - Already resolved (👍 only)
  praise         - Respond to praise (❤️ only)
```

### If language is `ko`:
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

After displaying help, exit.

---

# Main Flow Routing

For main flow (handling PR comments), read and follow instructions in the language-specific file:

- If language is `ko` → Read `~/.claude/commands/pr-resolver-ko.md` and follow the **Main Flow** section
- Otherwise (default `en`) → Read `~/.claude/commands/pr-resolver-en.md` and follow the **Main Flow** section

**Important:** Read the file content using the Read tool, then follow the Main Flow instructions.

---

# Config Section

Configuration is stored using git config (global). This section handles all config commands regardless of language.

## Load Current Config

Read settings: !`git config --global --get-regexp '^pr-resolver\.' 2>/dev/null || echo ""`

## Show Config (no additional args after "config")

Display current configuration:

```
╔═══════════════════════════════════════════════════════════╗
║                 PR Resolver Configuration                  ║
╚═══════════════════════════════════════════════════════════╝

Language: {lang or "en (default)"}

Actions:
  ┌─────────────────┬─────────┬──────────────┐
  │ Action          │ Enabled │ Reaction     │
  ├─────────────────┼─────────┼──────────────┤
  │ fixed           │ ✓       │ 👍 (+1)      │
  │ will_fix_later  │ ✓       │ 👀 (eyes)    │
  │ explain         │ ✓       │ -            │
  │ disagree        │ ✓       │ -            │
  │ skip            │ ✓       │ 👍 (+1)      │
  │ praise          │ ✓       │ ❤️ (heart)   │
  └─────────────────┴─────────┴──────────────┘
```

Show actual values from git config, fall back to defaults if not set.

## Update Config

### Language: `/pr-resolver config lang <en|ko>`
```bash
git config --global pr-resolver.lang {value}
```
Display: "✅ Language set to {value}"

### Action enable/disable: `/pr-resolver config action <name> <enable|disable>`
```bash
git config --global pr-resolver.action.{name}.enabled {true|false}
```
Display: "✅ Action '{name}' {enabled|disabled}"

### Action reaction: `/pr-resolver config action <name> reaction <+1|eyes|heart|rocket|null>`
```bash
git config --global pr-resolver.action.{name}.reaction {value}
```
Display: "✅ Action '{name}' reaction set to {value}"

### Reset: `/pr-resolver config reset`
```bash
git config --global --remove-section pr-resolver 2>/dev/null || true
```
Display: "✅ Configuration reset to defaults"

After config operation, exit.
