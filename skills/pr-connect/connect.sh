#!/usr/bin/env bash
# Connect to GitHub or Bitbucket and verify access to the current repo.
# Usage: connect.sh <git|bitbucket>
# Exit codes: 0 connected, 2 not logged in (prints what to run), 3 logged in but no access to this repo.
set -euo pipefail

target="${1:?usage: connect.sh <git|bitbucket>}"
# Same remote rule as pr-summ/fetch_pr.sh: upstream (fork workflow) else origin.
remote="$(git remote get-url upstream 2>/dev/null || git remote get-url origin 2>/dev/null || true)"
slug="$(sed -E 's#^(git@|ssh://git@|https?://([^@/]+@)?)[^/:]+[:/]##; s#\.git$##' <<<"$remote")"
cfg="$HOME/.config/pr-agent/bitbucket.env"

case "$target" in
git|github)
  gh auth status >/dev/null 2>&1 || { echo "NOT_CONNECTED: run 'gh auth login' (GitHub.com, HTTPS, login with browser)"; exit 2; }
  echo "OK: GitHub logged in as $(gh api user -q .login)"
  if [[ "$remote" == *github.com* ]]; then
    gh repo view "$slug" --json nameWithOwner -q '"OK: access to " + .nameWithOwner' 2>/dev/null ||
      { echo "NO_ACCESS: logged in, but this account can't read $slug"; exit 3; }
  else
    echo "NOTE: current folder is not a GitHub repo; cd into your project to verify repo access"
  fi
  ;;
bitbucket|bb)
  [[ -z "${BITBUCKET_TOKEN:-}" && -f "$cfg" ]] && source "$cfg"
  if [[ -z "${BITBUCKET_EMAIL:-}" || -z "${BITBUCKET_TOKEN:-}" ]]; then
    if [[ ! -t 0 ]]; then
      echo "NOT_CONNECTED: run this in your own terminal (it asks for email + API token):"
      echo "  bash $0 bitbucket"
      exit 2
    fi
    read -rp "Atlassian account email: " BITBUCKET_EMAIL
    read -rsp "Bitbucket API token (hidden): " BITBUCKET_TOKEN; echo
    mkdir -p "$(dirname "$cfg")"
    (umask 077; printf 'BITBUCKET_EMAIL=%q\nBITBUCKET_TOKEN=%q\n' "$BITBUCKET_EMAIL" "$BITBUCKET_TOKEN" >"$cfg")
    echo "Saved to $cfg (only you can read it)"
  fi
  if [[ "$remote" == *bitbucket.org* ]]; then
    curl -sf -o /dev/null -u "$BITBUCKET_EMAIL:$BITBUCKET_TOKEN" \
      "https://api.bitbucket.org/2.0/repositories/$slug/pullrequests?pagelen=1" ||
      { echo "NO_ACCESS: credentials rejected or token can't read PRs of $slug (needs read:repository + read:pullrequest scopes)"; exit 3; }
    echo "OK: Bitbucket access to $slug"
  else
    echo "OK: Bitbucket credentials saved; cd into a Bitbucket project to verify repo access"
  fi
  ;;
*)
  echo "usage: connect.sh <git|bitbucket>" >&2; exit 1 ;;
esac
