#!/bin/sh
# agt-only.sh "A" - show only the workspaces whose name starts with "A".
#
# Marks the matching workspaces as the sidebar focus set, unmarks the rest,
# then applies the filter. Nothing is closed.
set -e

VOLKTERMCTL=${VOLKTERMCTL:-volktermctl}

p=$1
if [ -z "$p" ]; then
	echo "usage: ${0##*/} <workspace-name-prefix>" >&2
	exit 2
fi

# suspend the filter first, so the whole tree is on screen while the set is rebuilt
"$VOLKTERMCTL" workspace filter off

"$VOLKTERMCTL" tree --json |
	jq -r --arg p "$p" '.result.tree.workspaces[]
		| "\(if (.name|startswith($p)) then "add" else "off" end) \(.id)"' |
	while read -r mode w; do
		"$VOLKTERMCTL" workspace focus "$mode" --target "$w"
	done

"$VOLKTERMCTL" workspace filter on
