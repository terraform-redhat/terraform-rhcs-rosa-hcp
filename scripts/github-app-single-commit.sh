#!/usr/bin/env bash
# Create a single commit on a branch using the GitHub REST Git Database API.
# Intended for automation authenticated with a GitHub App installation token so
# commits can show as verified for the app (see GitHub docs on API-created commits).
#
# Usage: GH_TOKEN, REPOSITORY (owner/name), BRANCH, COMMIT_MESSAGE must be set.
# Remaining arguments: paths of files to include (repo-relative), readable from CWD.

set -euo pipefail

log() {
  echo "[github-app-single-commit] $*" >> ./github-app-single-commit.out
}

: "${GH_TOKEN:?GH_TOKEN is required}"
: "${REPOSITORY:?REPOSITORY is required}"
: "${BRANCH:?BRANCH is required}"
: "${COMMIT_MESSAGE:?COMMIT_MESSAGE is required}"

COMMIT_MESSAGE+=$'\n\n'"Signed-off-by: $(git config --get user.name) <$(git config --get user.email)>"

if [ "$#" -lt 1 ]; then
  log "error: no file paths passed"
  exit 1
fi

log "start repository=${REPOSITORY} branch=${BRANCH} file_count=$#"
log "paths: $*"

ref_enc() {
  python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "$1"
}

# GitHub GET ref path uses e.g. heads/my-branch (see REST docs for git/ref/{ref})
REF_PATH="heads/${BRANCH}"
REF_URLENC="$(ref_enc "${REF_PATH}")"

log "resolve ref path=${REF_PATH}"

PARENT_SHA="$(gh api "repos/${REPOSITORY}/git/ref/${REF_URLENC}" --jq .object.sha)"
BASE_TREE_SHA="$(gh api "repos/${REPOSITORY}/git/commits/${PARENT_SHA}" --jq .tree.sha)"

log "parent_commit=${PARENT_SHA:0:7}… base_tree=${BASE_TREE_SHA:0:7}…"

tree_json='[]'
for rel in "$@"; do
  if [ ! -f "$rel" ]; then
    log "error: missing file: ${rel}"
    exit 1
  fi
  log "post blob path=${rel}"
  blob_sha="$(
    jq -n --arg c "$(base64 -w 0 "$rel")" '{encoding: "base64", content: $c}' \
      | gh api "repos/${REPOSITORY}/git/blobs" -X POST --input - --jq .sha
  )"
  log "  blob_sha=${blob_sha:0:7}…"
  tree_json="$(
    jq -n --argjson t "$tree_json" --arg path "$rel" --arg sha "$blob_sha" \
      '$t + [{path: $path, mode: "100644", type: "blob", sha: $sha}]'
  )"
done

log "create tree (base_tree + $# path(s))"

NEW_TREE_SHA="$(
  jq -n --arg base "$BASE_TREE_SHA" --argjson tree "$tree_json" \
    '{base_tree: $base, tree: $tree}' \
    | gh api "repos/${REPOSITORY}/git/trees" -X POST --input - --jq .sha
)"

log "new_tree=${NEW_TREE_SHA:0:7}…"

log "create commit"

NEW_COMMIT_SHA="$(
  jq -n \
    --arg msg "$COMMIT_MESSAGE" \
    --arg tree "$NEW_TREE_SHA" \
    --arg parent "$PARENT_SHA" \
    '{message: $msg, tree: $tree, parents: [$parent]}' \
    | gh api "repos/${REPOSITORY}/git/commits" -X POST --input - --jq .sha
)"

log "new_commit=${NEW_COMMIT_SHA:0:7}…"

# PATCH must use /git/refs/ (plural); GET uses /git/ref/ (singular).
log "update ref PATCH …/git/refs/${REF_PATH}"

jq -n --arg sha "$NEW_COMMIT_SHA" '{sha: $sha}' \
  | gh api "repos/${REPOSITORY}/git/refs/${REF_URLENC}" -X PATCH --input -

log "done branch=${BRANCH} commit=${NEW_COMMIT_SHA}"
