# pr-agent — Claude Code skills for PR summaries

Two [Claude Code](https://claude.com/claude-code) skills:

| Command | What it does |
|---|---|
| `/pr-connect git` | Connect to GitHub and check access to the current project |
| `/pr-connect bitbucket` | Connect to Bitbucket Cloud and check access to the current project |
| `/pr-summ <number \| "description">` | Fetch a PR from the current project and write an editable Markdown commit summary |

Only PRs of the project you're in are fetched. The repo comes from its `upstream` remote (fork workflow) or else `origin`, and GitHub vs Bitbucket is detected from that URL.

Works in the **Claude Code CLI** and the **Claude desktop app (Code tab)**. It doesn't work in claude.ai chat, which has no local repo or logins.

## 1. Install

Tell Claude Code:

> Install the skills from https://github.com/Amanlabh/pr-agent: clone it to ~/.claude/pr-agent and symlink every folder in its skills/ into ~/.claude/skills/

or run it yourself:

```bash
git clone https://github.com/Amanlabh/pr-agent ~/.claude/pr-agent
mkdir -p ~/.claude/skills && ln -s ~/.claude/pr-agent/skills/* ~/.claude/skills/
```

Restart Claude Code, then type `/pr-` and you should see `/pr-connect` and `/pr-summ`.
Update later with `git -C ~/.claude/pr-agent pull`.

**Requirements:** `git`, `jq`, `curl`, plus [`gh`](https://cli.github.com) for GitHub (`brew install gh`).

## 2. Connect

### GitHub
1. In Claude Code, `cd` into your project and run `/pr-connect git`.
2. If you're not logged in, type `! gh auth login` and choose **GitHub.com → HTTPS → Login with a web browser**.
3. Run `/pr-connect git` again. It should print `OK: GitHub logged in as <you>` and `OK: access to <owner/repo>`.

### Bitbucket Cloud
1. Create an API token: Bitbucket → avatar → **Account settings → Security → Create API token with scopes** → app **Bitbucket** → scopes `read:repository:bitbucket` and `read:pullrequest:bitbucket`. Copy the token.
2. In **your own terminal** (not the chat), run:
   ```bash
   bash ~/.claude/skills/pr-connect/connect.sh bitbucket
   ```
   It asks for your Atlassian email and the token (input is hidden) and saves them to `~/.config/pr-agent/bitbucket.env`, readable only by you.
3. In Claude Code, inside your Bitbucket project, run `/pr-connect bitbucket`. It should print `OK: Bitbucket access to <workspace/repo>`.

Alternative: export `BITBUCKET_EMAIL` and `BITBUCKET_TOKEN` in your shell profile instead. Never paste tokens into the chat.

## 3. Use

From inside your project:

```
/pr-summ 42
/pr-summ "login timeout fix"
```

- Number → that PR. Description → searches PR titles (open, merged, declined). If several match, Claude asks which one.
- The summary is saved to `pr-summaries/<host>-PR-<n>.md` and shown in the chat. It covers the summary, grouped changes, commits, files touched, testing notes and a suggested squash commit.
- Edit the saved file freely. To change the format for every future summary, edit `skills/pr-summ/template.md`.

## Limits
- Bitbucket: only the first page is read (50 commits, 100 files).
- Bitbucket Server/Data Center isn't supported (it uses a different API).
