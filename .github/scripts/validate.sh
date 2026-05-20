#!/usr/bin/env bash
# Validate SKILL.md against the installed `quire` CLI.
#
# Two checks:
#   1. Frontmatter has the required fields (name, description, version, requires.bins).
#   2. Every `quire ...` invocation inside a bash code fence in the body
#      resolves to a real subcommand — i.e. `quire <subcommand-path> --help`
#      exits 0 against the installed CLI version.
#
# Run from repo root: bash .github/scripts/validate.sh
#
# Future work: also run `clawhub skill publish . --dry-run` once the ClawHub
# CLI is available on GitHub-hosted runners without requiring a token.

set -euo pipefail

SKILL_FILE="${SKILL_FILE:-SKILL.md}"

if [ ! -f "$SKILL_FILE" ]; then
  echo "ERROR: $SKILL_FILE not found (run from repo root)" >&2
  exit 1
fi

if ! command -v quire >/dev/null 2>&1; then
  echo "ERROR: 'quire' not on PATH. Install with: npm i -g @quire-io/quire-cli" >&2
  exit 1
fi

echo "==> Checking frontmatter in $SKILL_FILE"

FRONTMATTER=$(mktemp)
RAW_CMDS=$(mktemp)
SUBCMDS=$(mktemp)
trap 'rm -f "$FRONTMATTER" "$RAW_CMDS" "$SUBCMDS"' EXIT

awk '
  /^---$/ { c++; next }
  c == 1 { print }
  c == 2 { exit }
' "$SKILL_FILE" > "$FRONTMATTER"

required_top_fields=(name description version)
for field in "${required_top_fields[@]}"; do
  if ! grep -qE "^${field}:" "$FRONTMATTER"; then
    echo "FAIL: frontmatter missing required field '${field}:'" >&2
    exit 1
  fi
done

if ! grep -qE "^[[:space:]]+- quire[[:space:]]*$" "$FRONTMATTER"; then
  echo "FAIL: frontmatter missing 'requires.bins: [..., quire, ...]'" >&2
  exit 1
fi

echo "    OK"

echo "==> Extracting 'quire ...' invocations from bash code fences"

awk '
  /^```bash/ { in_block = 1; next }
  in_block && /^```/ { in_block = 0; next }
  in_block && /^quire / { print }
' "$SKILL_FILE" > "$RAW_CMDS"

if [ ! -s "$RAW_CMDS" ]; then
  echo "FAIL: no 'quire ...' commands found in any bash code fence" >&2
  exit 1
fi

# For each command line, isolate the subcommand path: all tokens after
# `quire` until the first flag (-/--), placeholder (<...>), bracketed
# optional ([...]), grouped choice ((...)), or shell separator (|, ;, \).
awk '
  {
    sub(/^quire[[:space:]]+/, "")
    path = ""
    for (i = 1; i <= NF; i++) {
      c = substr($i, 1, 1)
      if (c == "-" || c == "<" || c == "[" || c == "(" || c == "|" || c == ";" || c == "\\") break
      path = (path == "" ? $i : path " " $i)
    }
    if (path != "") print path
  }
' "$RAW_CMDS" | sort -u > "$SUBCMDS"

echo "    Found $(wc -l < "$SUBCMDS" | tr -d ' ') unique subcommand path(s):"
sed 's/^/      quire /' "$SUBCMDS"

echo "==> Verifying each subcommand against \`quire <path> --help\`"

fail_count=0
while IFS= read -r path; do
  [ -z "$path" ] && continue
  if quire $path --help >/dev/null 2>&1; then
    echo "    OK    quire $path"
  else
    echo "    FAIL  quire $path --help did not succeed" >&2
    fail_count=$((fail_count + 1))
  fi
done < "$SUBCMDS"

if [ "$fail_count" -gt 0 ]; then
  echo "" >&2
  echo "$fail_count subcommand(s) in $SKILL_FILE do not resolve against the installed quire CLI." >&2
  echo "Either SKILL.md is stale or the CLI version is too old." >&2
  exit 1
fi

echo ""
echo "All checks passed."
