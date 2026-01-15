---
allowed-tools: Bash(gh:*), Bash(git:*)
argument-hint: [help|config|PR number]
description: PR review comment handler
---

# PR Resolver

## Language Detection

Read language setting: !`git config --global pr-resolver.lang 2>/dev/null || echo "en"`

## Routing

Based on the language setting above:

- If language is `ko` → Follow instructions in **pr-resolver-ko.md**
- Otherwise (default `en`) → Follow instructions in **pr-resolver-en.md**

The language-specific file contains all UI strings, help text, and flow instructions in that language.
