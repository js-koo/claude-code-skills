# PR Resolver - Main Flow (English)

This file contains the Main Flow instructions for PR Resolver in English.
Help and Config sections are handled by the router (pr-resolver.md).

---

# Main Flow

## Environment Check

1. Check git repo: !`git rev-parse --git-dir 2>/dev/null || echo "NOT_GIT_REPO"`
2. Check gh auth: !`gh auth status 2>&1 | head -3`
3. Remote info: !`git remote -v | head -2`

- If not a git repo: Print "❌ Please run in a git repository." and exit
- If gh not authenticated: Print "❌ Please run `gh auth login` first." and exit

## PR Detection

1. If `$1` is numeric → Use as PR number
2. If `$1` is empty → Run `gh pr view --json number -q '.number' 2>/dev/null`
3. On failure → Ask user: "Enter PR number:"

## Comment Retrieval

Extract repo info:
```bash
gh repo view --json owner,name -q '"\(.owner.login)/\(.name)"'
```

Retrieve comments:
```bash
gh api repos/{owner}/{repo}/pulls/{pr}/comments --jq '.[] | {id, path, body: .body[0:50], in_reply_to_id}'
```

Filter: Only show comments where `in_reply_to_id` is null (top-level comments)

Display:
```
📋 Found {count} comment(s)

| # | File | Content |
|---|------|---------|
| 1 | Repository.kt:64 | SQL injection risk... |
```

If no comments: Print "✅ No comments to process." and exit

## User Selection

Use AskUserQuestion:

### Step 1: Select Comment
Question: "Which comment to handle?"
Options: Comment numbers (1, 2, 3...)

### Step 2: Select Action
Question: "How do you want to handle this?"
Options:
- Fixed - Reply with fix confirmation + 👍
- Will fix later - Reply with acknowledgment + 👀
- Explain - Reply with explanation
- Disagree - Reply with disagreement
- Skip - Mark as resolved (👍 only)
- Praise response - Thank reviewer (❤️ only)

## Process Comment

### Step 1: Show Full Comment

Display the full reviewer comment:
```
┌─────────────────────────────────────────────────────────────┐
│  📝 Reviewer Comment                                        │
│  ─────────────────────────────────────────────────────────  │
│  File: {path}:{line}                                        │
│  Content: {full comment body}                               │
└─────────────────────────────────────────────────────────────┘
```

### Step 2: Detect Language

Detect comment language → Use same language for code suggestions and replies

### Step 3: Code Fix (if action is "fixed")

1. Analyze comment and related code
2. Generate suggested code fix
3. Display:
```
┌─────────────────────────────────────────────────────────────┐
│  💡 Suggested Code Fix                                      │
│  ─────────────────────────────────────────────────────────  │
│  - {original code}                                          │
│  + {suggested fix}                                          │
└─────────────────────────────────────────────────────────────┘
```
4. Ask user: [Apply] [Edit] [Add context] [Skip]
   - Apply: Apply suggested code as-is
   - Edit: Let user modify the suggestion before applying
   - Add context: User provides additional context → Regenerate suggestion
   - Skip: Skip this comment, move to next

5. If applied/modified → Commit the change
   - Get commit hash: !`git rev-parse --short HEAD`
   - Ask: "Is this the correct commit? {hash}" [Yes] [Select other]

### Step 4: Generate Reply

#### If action is "fixed" or "will_fix_later":
1. Generate reply with commit reference (if applicable)
2. Match detected language

#### If action is "explain" or "disagree":
1. Ask user: "Enter your reply:"
2. Get user input

#### If action is "skip" or "praise":
Skip reply generation, proceed to reaction only

### Step 5: Confirm Reply

Display suggested reply:
```
┌─────────────────────────────────────────────────────────────┐
│  💬 Suggested Reply                                         │
│  ─────────────────────────────────────────────────────────  │
│  {suggested reply content}                                  │
└─────────────────────────────────────────────────────────────┘
```

Ask user: [Send] [Edit] [Add context] [Cancel]
- Send: Send reply as-is
- Edit: Let user modify the reply before sending
- Add context: User provides additional context → Regenerate reply
- Cancel: Cancel and move to next comment

## Send

### Send reply (if action requires reply):
```bash
gh api repos/{owner}/{repo}/pulls/{pr}/comments/{comment_id}/replies -f body="{reply}"
```

### Add reaction (based on action):
```bash
gh api repos/{owner}/{repo}/pulls/{pr}/comments/{comment_id}/reactions -f content="{reaction}"
```

Reaction mapping:
- fixed: +1
- will_fix_later: eyes
- skip: +1
- praise: heart

### Display result:
```
✅ Sent successfully!
   Comment ID: {id}
   Reaction: {emoji}
```

## Repeat

Ask: "Handle another comment?"
Options: [Yes] [No]

- Yes → Go back to Comment Retrieval
- No → Print "👋 Done!" and exit

## Error Handling

| Situation | Message |
|-----------|---------|
| Not a git repo | ❌ Please run in a git repository. |
| gh not authenticated | ❌ Please run `gh auth login` first. |
| PR not found | ❌ PR not found. Please enter a valid PR number. |
| No comments | ✅ No comments to process. |
| API failure | ❌ GitHub API error: {message} |
| User cancelled | 👋 Cancelled. |
