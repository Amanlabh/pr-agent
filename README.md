# pr-summary — Claude Code skill

Fetch a pull request from **GitHub** or **Bitbucket Cloud** (auto-detected from the repo's `origin` remote) by PR number or short description, and get an editable, reusable Markdown commit summary.

## Install

Tell Claude Code:

> Install the Claude skill from https://github.com/OWNER/REPO into ~/.claude/skills/pr-summary

or run it yourself:

```bash
git clone https://github.com/OWNER/REPO ~/.claude/skills/pr-summary
```

Update later with `git -C ~/.claude/skills/pr-summary pull`.

**Requirements:** `git`, `jq`, `curl`
- GitHub repos: [`gh`](https://cli.github.com) logged in (`gh auth login`)
- Bitbucket repos: `export BITBUCKET_EMAIL=you@example.com BITBUCKET_TOKEN=...` (Bitbucket → Personal settings → API tokens, scope `read:pullrequest:bitbucket`)

## Use

From inside any GitHub or Bitbucket repo:

```
/pr-summary 42
/pr-summary "login timeout fix"
```

The summary is saved to `pr-summaries/<host>-PR-<n>.md`. To change the format, edit `template.md`.

## Limits
- Bitbucket: only the first page is read (50 commits, 100 files).
- Bitbucket Server/Data Center isn't supported (it uses a different API).
