---
name: pr-summ
description: Fetch a pull request from GitHub or Bitbucket (auto-detected from the repo's origin remote) by PR number or short description, and write an editable, reusable commit summary in Markdown. Use when the user says "summarize PR 42", "PR summary for the login fix", "commit summary for this PR", or invokes /pr-summ.
argument-hint: <pr-number | "short description">
allowed-tools: Bash(bash *fetch_pr.sh*), Read, Write
---

# PR summary

Input: `$ARGUMENTS` — a PR number (`42`, `#42`) or a short description (`login timeout fix`).

1. Strip a leading `#`, then run from the repo the user is working in:
   ```bash
   bash "${CLAUDE_SKILL_DIR}/fetch_pr.sh" "<number or description>"
   ```
   - Output has `matches` → description hit 0 or several PRs. 0: tell the user, ask for a number. Several: list `#number title (state)` and ask which one. Then rerun with the number.
   - Only PRs of the current project's repo are searched (`upstream` remote if present, else `origin`); the JSON's `repo` field says which. Never fetch from another repo.
   - "not inside a git project" → ask the user to `cd` into their project first.
   - `gh` auth error → tell the user to run `/pr-connect git`.
   - "Bitbucket not connected" → tell the user to run `/pr-connect bitbucket`.

2. Read `${CLAUDE_SKILL_DIR}/template.md` and fill it from the JSON:
   - `{{placeholders}}` → JSON fields verbatim.
   - HTML comments → replace with content following the comment's instruction; remove the comment.
   - Use only what the PR data says. Never invent tests, tickets or motivation; write "None" when absent.
   - Squash commit: Conventional Commits, type from the dominant change (feat/fix/refactor/chore/docs/test).

3. Write the result to `pr-summaries/<host>-PR-<number>.md` in the current repo (overwrite if it exists — it's regenerated output) and print it in the reply so the user can copy it.

The template is the format contract: to change the output format, edit `template.md`, not this file.
