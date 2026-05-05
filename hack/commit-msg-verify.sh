#!/usr/bin/env bash
# Copyright Red Hat
# SPDX-License-Identifier: Apache-2.0


set -o errexit
set -o nounset
set -o pipefail

pattern="^(Revert \")?[A-Z]+-[0-9]+ \| (feat|fix|docs|style|refactor|test|chore|build|ci|perf)(\\([a-z0-9._-]+\\))?(!)?: .*$"

print_commit_message_error() {
  local message=$1
  cat <<EOF
$message
Expected format: JIRA-12345 | <conventional-commit>
Example: OCM-12345 | feat(scope): add support for foo
Please check CONTRIBUTING.md for more details
EOF
}

extract_subject() {
  local message=$1
  local line=""

  while IFS= read -r line; do
    line="${line%$'\r'}"

    if [[ "$line" =~ ^[[:space:]]*# ]]; then
      continue
    fi
    if [[ -z "${line//[[:space:]]/}" ]]; then
      continue
    fi

    printf '%s' "$line"
    return 0
  done <<< "$message"

  return 1
}

validate_message() {
  local message=$1
  local subject=""

  if ! subject=$(extract_subject "$message"); then
    print_commit_message_error "Invalid commit message: empty subject"
    return 1
  fi

  if ! [[ $subject =~ $pattern ]]; then
    print_commit_message_error "Invalid commit message subject: $subject"
    return 1
  fi

  return 0
}

resolve_default_branch_ref() {
  local default_ref=""
  local remote_head_branch=""

  default_ref=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)
  if [ -n "$default_ref" ]; then
    printf '%s' "$default_ref"
    return 0
  fi

  remote_head_branch=$(git remote show origin 2>/dev/null | sed -n 's/.*HEAD branch: //p' | head -n 1 || true)
  if [ -n "$remote_head_branch" ] && [ "$remote_head_branch" != "(unknown)" ]; then
    printf 'origin/%s' "$remote_head_branch"
    return 0
  fi

  printf 'origin/HEAD'
}

if [ -n "${1:-}" ]; then
  message_file=$1
  if [ ! -f "$message_file" ]; then
    echo "Unable to read commit message file: $message_file"
    exit 1
  fi

  message=$(<"$message_file")
  validate_message "$message" || exit 1
  exit 0
fi

if [ -z "${PULL_BASE_SHA:-}" ] && [ -z "${BASE_SHA:-}" ] && [ -z "${PULL_PULL_SHA:-}" ] && [ -z "${HEAD_SHA:-}" ]; then
  echo "No commit message file provided; commit message is validated by commit-msg hook during commit."
  exit 0
fi

default_branch_ref=$(resolve_default_branch_ref)
default_merge_base=$(git merge-base "$default_branch_ref" HEAD 2>/dev/null || git merge-base HEAD HEAD)
PULL_BASE_SHA_VALUE="${PULL_BASE_SHA:-${BASE_SHA:-$default_merge_base}}"
PULL_PULL_SHA_VALUE="${PULL_PULL_SHA:-${HEAD_SHA:-HEAD}}"

declare -a bot_authors=(
  "red-hat-konflux[bot]"
  "dependabot[bot]"
)

commits=$(git rev-list --no-merges "$PULL_BASE_SHA_VALUE..$PULL_PULL_SHA_VALUE")
if [ -z "$commits" ]; then
  echo "No commits detected in range ${PULL_BASE_SHA_VALUE}..${PULL_PULL_SHA_VALUE}"
  exit 0
fi

# Check if all commits are bot-authored
all_bot_authored=true
for sha in $commits; do
  commit_author=$(git log --format=%an -n 1 "$sha")
  is_bot=false

  for bot_author in "${bot_authors[@]}"; do
    if [ "${commit_author}" = "${bot_author}" ]; then
      is_bot=true
      break
    fi
  done

  if [ "$is_bot" = false ]; then
    all_bot_authored=false
    break
  fi
done

if [ "$all_bot_authored" = true ]; then
  echo "All commits are bot-authored, skipping validation"
  exit 0
fi

# Validate commit messages
for sha in $commits; do
  message=$(git log --format=%B -n 1 "$sha")
  validate_message "$message" || exit 1
done

echo "All commit messages are valid"
