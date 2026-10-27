#!/usr/bin/env bash
# Fetch a PR (by number or short description) from GitHub or Bitbucket Cloud.
# Host is auto-detected from the current repo's `origin` remote.
# Usage: fetch_pr.sh <pr-number | "short description">
# Prints JSON: {host, number, title, description, author, source, target, state, url, commits[], files[]}
# If a description matches several PRs, prints {"matches":[...]} instead so the caller can pick one.
set -euo pipefail

query="${1:?usage: fetch_pr.sh <pr-number | \"short description\">}"
remote="$(git remote get-url origin 2>/dev/null)" || { echo "no git origin remote in $(pwd)" >&2; exit 1; }

# owner/repo from git@host:owner/repo.git or https://[user@]host/owner/repo(.git)
slug="$(sed -E 's#^(git@|ssh://git@|https?://([^@/]+@)?)[^/:]+[:/]##; s#\.git$##' <<<"$remote")"

case "$remote" in
*github.com*)
  if [[ ! "$query" =~ ^[0-9]+$ ]]; then
    matches="$(gh pr list -R "$slug" --state all --search "$query" --limit 5 --json number,title,state)"
    [[ "$(jq length <<<"$matches")" -eq 1 ]] || { jq '{matches: .}' <<<"$matches"; exit 0; }
    query="$(jq '.[0].number' <<<"$matches")"
  fi
  gh pr view "$query" -R "$slug" \
    --json number,title,body,author,headRefName,baseRefName,state,url,commits,files |
    jq '{host: "github", number, title, description: .body, author: .author.login,
         source: .headRefName, target: .baseRefName, state, url,
         commits: [.commits[] | {sha: .oid[0:7], message: .messageHeadline}],
         files: [.files[] | {path, additions, deletions}]}'
  ;;
*bitbucket.org*)
  : "${BITBUCKET_EMAIL:?set BITBUCKET_EMAIL (Atlassian account email)}"
  : "${BITBUCKET_TOKEN:?set BITBUCKET_TOKEN (Bitbucket API token with pull request read scope)}"
  api="https://api.bitbucket.org/2.0/repositories/$slug/pullrequests"
  bb() { curl -sfG -u "$BITBUCKET_EMAIL:$BITBUCKET_TOKEN" "$@"; }
  if [[ ! "$query" =~ ^[0-9]+$ ]]; then
    matches="$(bb "$api" --data-urlencode "q=title ~ \"$query\"" \
      -d state=OPEN -d state=MERGED -d state=DECLINED -d pagelen=5 |
      jq '[.values[] | {number: .id, title, state}]')"
    [[ "$(jq length <<<"$matches")" -eq 1 ]] || { jq '{matches: .}' <<<"$matches"; exit 0; }
    query="$(jq '.[0].number' <<<"$matches")"
  fi
  # ponytail: first page only (commits 50, files 100); follow `.next` if huge PRs matter
  pr="$(bb "$api/$query")"
  commits="$(bb "$api/$query/commits" -d pagelen=50)"
  files="$(bb "$api/$query/diffstat" -d pagelen=100)"
  jq -n --argjson pr "$pr" --argjson c "$commits" --argjson f "$files" \
    '{host: "bitbucket", number: $pr.id, title: $pr.title, description: $pr.description,
      author: $pr.author.display_name, source: $pr.source.branch.name,
      target: $pr.destination.branch.name, state: $pr.state, url: $pr.links.html.href,
      commits: [$c.values[] | {sha: .hash[0:7], message: (.message | split("\n")[0])}],
      files: [$f.values[] | {path: (.new.path // .old.path), additions: .lines_added, deletions: .lines_removed}]}'
  ;;
*)
  echo "origin is neither GitHub nor Bitbucket: $remote" >&2; exit 1 ;;
esac
