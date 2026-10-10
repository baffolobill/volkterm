#!/bin/sh
# Prints the log of the conversation the agent process $VOLKTERM_AGENT_PID runs: a log it holds open, else the
# newest one written since it started. Edit the two settings below for your agent.
set -eu

LOGS="$HOME/.my-agent/sessions"   # where the agent keeps its conversation logs
PATTERN='*.jsonl'                 # their file names

pid=${VOLKTERM_AGENT_PID:?}
# lsof names files by their real path
LOGS=$(cd "$LOGS" 2>/dev/null && pwd -P) || exit 1

# the logs among the files the process holds open; PATTERN is a glob on purpose
# shellcheck disable=SC2254
logs_held() {
    while IFS= read -r file; do
        case "$file" in
            "$LOGS"/*) case "${file##*/}" in $PATTERN) printf '%s\n' "$file" ;; esac ;;
        esac
    done
}

held=$(lsof -p "$pid" -Fn 2>/dev/null | sed -n 's/^n//p' | logs_held | head -n 1)
if [ -n "$held" ]; then
    printf '%s\n' "$held"
    exit 0
fi

# ps prints the start as "Fri Oct  9 23:54:47 2026" in the C locale; find compares against a file stamped with it
start=$(LC_ALL=C ps -o lstart= -p "$pid" | sed 's/[[:space:]]*$//')
stamp=$(LC_ALL=C date -j -f '%a %b %e %T %Y' "$start" +%Y%m%d%H%M.%S)
marker=$(mktemp)
trap 'rm -f "$marker"' EXIT
touch -t "$stamp" "$marker"
newest=$(find "$LOGS" -type f -name "$PATTERN" -newer "$marker" -exec stat -f '%m %N' {} + 2>/dev/null \
    | sort -rn | head -n 1 | cut -d' ' -f2-)
[ -n "$newest" ] || exit 1
printf '%s\n' "$newest"
