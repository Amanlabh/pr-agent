---
name: pr-connect
description: Connect Claude to GitHub or Bitbucket so /pr-summ can read pull requests, and verify access to the current project. Use when the user says "connect github", "connect bitbucket", "set up bitbucket token", or invokes /pr-connect git or /pr-connect bitbucket.
argument-hint: <git | bitbucket>
allowed-tools: Bash(bash *connect.sh*)
---

# PR connect

Input: `$ARGUMENTS` — `git` (GitHub) or `bitbucket`. Missing → ask which one.

Run from the user's project folder:
```bash
bash "${CLAUDE_SKILL_DIR}/connect.sh" <git|bitbucket>
```

Act on the output:
- `OK:` lines → tell the user they're connected (and to which repo). Done.
- `NOT_CONNECTED` for git → tell the user to type `! gh auth login` in this prompt and pick GitHub.com → HTTPS → browser login, then rerun `/pr-connect git`.
- `NOT_CONNECTED` for bitbucket → tell the user to:
  1. Create a token: Bitbucket → avatar → Account settings → Security → **Create API token with scopes** → app Bitbucket → scopes `read:repository:bitbucket` and `read:pullrequest:bitbucket`.
  2. Run the printed `bash .../connect.sh bitbucket` command **in their own terminal** (it prompts for email + token and saves them with owner-only permissions).
  3. Rerun `/pr-connect bitbucket`.
- `NO_ACCESS` → the account is logged in but can't see this repo; tell them to ask a repo admin for read access or use the right account.

Never ask the user to paste a token into the chat.
