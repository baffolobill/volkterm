#!/usr/bin/env bash
# lights-common.sh — settings and helpers shared by the truthful-agent-lights
# scripts. Sourced, never executed: every value below is a variable you can
# override in the environment of the hooks and of the sweeper, and both sides
# must agree on VOLK_LIGHTS_STATE or the sweeper reads no stamps at all.
#
# Colors and shapes are per-call overrides. A per-call override BEATS whatever
# you picked in Settings ▸ Agent Status, so if a shape here collides with your
# own vocabulary, change it here rather than in Settings.

# the CLI that talks to the control socket
VOLKTERMCTL=${VOLKTERMCTL:-volktermctl}

# Where the pid notes, turn stamps and heartbeats live. The hooks and the
# sweeper must resolve this to the SAME directory or the sweeper reads no
# stamps at all and reports every session as idle.
#
# XDG_STATE_HOME is ignored deliberately, and this is the reason: the hooks run
# inside your shell, where an XDG_STATE_HOME exported from a shell rc is set,
# while the sweeper runs from launchd, which starts with no such environment.
# Honoring it would put the two halves in two different directories on exactly
# the machines that set it — the hooks writing stamps nobody reads, the sweeper
# concluding that live sessions are dead. A path off $HOME is the same path in
# both. Override VOLK_LIGHTS_STATE if you must, and then set it in both places.
VOLK_LIGHTS_STATE=${VOLK_LIGHTS_STATE:-$HOME/.local/state/volkterm-lights}

# the stock status script the hooks package installs. When one is present the
# recipe posts through it, so socket, pane and pane-id handling stay upstream's;
# when none is, the fallback in set-status.sh calls volktermctl directly.
#
# Since volkterm 0.26.0 the package wires the Claude hooks to
# volkterm-claude-status.sh: an adapter that stays silent when the hook was fired
# by a worker agent spawned inside the session (a headless `claude -p` from a
# tool call inherits the spawner's VOLKTERM_* environment and would otherwise
# repaint the spawner's row) and hands every other post to volkterm-agent-status.sh.
# Posting through the adapter keeps that guard; posting through the generic
# script would undo it. So the adapter is preferred when it is installed, and an
# older package without it falls back to the generic script. Set
# VOLK_STATUS_SCRIPT to post through something else.
if [ -z "${VOLK_STATUS_SCRIPT:-}" ]; then
  VOLK_STATUS_SCRIPT=$HOME/.config/volkterm/agent-status/volkterm-claude-status.sh
  [ -x "$VOLK_STATUS_SCRIPT" ] ||
    VOLK_STATUS_SCRIPT=$HOME/.config/volkterm/agent-status/volkterm-agent-status.sh
fi

# extended regex of agent binaries, matched against the WHOLE command name:
# every alternative is an exact basename, not a prefix. Add yours as its own
# alternative (`claude|codex|my-agent-wrapper`) rather than relying on a prefix
# to cover it — a prefix would also swallow ordinary commands that merely start
# the same way, and a process wrongly read as an agent makes a row claim a
# worker that does not exist.
VOLK_AGENT_PATTERN=${VOLK_AGENT_PATTERN:-claude|codex|kimi|opencode|pi}

# The work tint, and the silhouette per sub-state. These six take the `${VAR-…}`
# form on purpose, not `${VAR:-…}`: setting one to the empty string is how you
# say "post this state with no override of my own", and a `:-` default would
# quietly hand the default back instead of honoring that.
VOLK_WORK_COLOR=${VOLK_WORK_COLOR-#4A9EFF}
VOLK_STUCK_COLOR=${VOLK_STUCK_COLOR-#FF3B30}
VOLK_SHAPE_RUNNING=${VOLK_SHAPE_RUNNING-square}      # machinery is executing
VOLK_SHAPE_MIXED=${VOLK_SHAPE_MIXED-diamond}         # executing AND queued
VOLK_SHAPE_QUEUED=${VOLK_SHAPE_QUEUED-triangle}      # only waiting for a slot
VOLK_SHAPE_STUCK=${VOLK_SHAPE_STUCK-star}            # claims to run, makes no progress

# timings, all seconds
VOLK_HB_FRESH_SECS=${VOLK_HB_FRESH_SECS:-300}   # a hook fired this recently: hands off
VOLK_HB_STALE_SECS=${VOLK_HB_STALE_SECS:-1500}  # no hook this long: the glyph is unbacked
VOLK_OWN_LIVE_SECS=${VOLK_OWN_LIVE_SECS:-900}   # cap on "my own turn is live" without writes
VOLK_STALL_SECS=${VOLK_STALL_SECS:-1500}        # running claim, no transcript progress: stuck
VOLK_SSH_WORK_SECS=${VOLK_SSH_WORK_SECS:-120}   # ssh older than this is a run, not a probe

agt_active_args() { # color shape [extra flags…] -> fills VOLK_STATUS_ARGS
  # Blank a color or shape variable to mean "post this state without that
  # override", so the glyph falls back to your Settings ▸ Agent Status choice.
  # The empty value must never reach the CLI: volktermctl rejects `--shape ""`,
  # and the status call swallows its own errors, so it would fail invisibly.
  local color=$1 shape=$2
  shift 2
  VOLK_STATUS_ARGS=(active "$@")
  [ -n "$color" ] && VOLK_STATUS_ARGS+=(--color "$color")
  [ -n "$shape" ] && VOLK_STATUS_ARGS+=(--shape "$shape")
  return 0
}

agt_pid_start() { # pid -> its start time as one normalized line, empty when gone
  ps -o lstart= -p "$1" 2>/dev/null | tr -s ' ' | sed 's/^ *//; s/ *$//'
}

agt_write_pid_note() { # note-path pid — records the pid AND when it started
  # The start time is what makes the note safe to believe later: pids are
  # recycled, and a recycled one can land on another agent process, which no
  # name check can tell apart from the original.
  printf '%s %s\n' "$2" "$(agt_pid_start "$2")" > "$1" 2>/dev/null || true
}

agt_note_pid() { # note-path -> the pid it records, or nothing
  local line
  line=$(cat "$1" 2>/dev/null) || return 1
  [ -n "$line" ] || return 1
  printf '%s' "${line%% *}"
}

agt_note_is_live() { # note-path -> 0 when that exact process is still running
  # pid alive, still an agent binary, and started when the note says it did
  local line pid start
  line=$(cat "$1" 2>/dev/null) || return 1
  pid=${line%% *}
  start=${line#* }
  [ -n "$pid" ] || return 1
  case "$pid" in *[!0-9]*) return 1 ;; esac
  agt_is_agent_name "$(agt_base_name "$(ps -o command= -p "$pid" 2>/dev/null)")" || return 1
  [ "$start" = "$line" ] && return 0    # note predates start-time recording
  [ "$start" = "$(agt_pid_start "$pid")" ]
}

agt_state_dir() { # ensure and echo a state subdirectory
  # 0700 like the root above: these hold session ids, pids and transcript
  # paths. The umask is confined to a subshell so sourcing this file never
  # changes the mode of anything else the caller writes.
  (umask 077; mkdir -p "$VOLK_LIGHTS_STATE/$1") 2>/dev/null || true
  printf '%s\n' "$VOLK_LIGHTS_STATE/$1"
}

agt_is_agent_name() { # command name -> 0 when it is an agent binary
  # anchored at both ends: `pi` must not match `ping`, `pip` or `pipx`
  printf '%s' "$1" | grep -qE "^($VOLK_AGENT_PATTERN)$"
}

agt_base_name() { # argv string -> bare command name, unwrapping ps's (parens)
  local b=${1%% *}
  b=${b##*/}; b=${b#\(}; b=${b%\)}
  printf '%s' "$b"
}

agt_find_agent_pid() { # walk up from $1 (default $PPID) to the agent process
  local p=${1:-$PPID} cmd
  local _
  for _ in 1 2 3 4 5 6; do
    [ -n "$p" ] || break
    [ "$p" -gt 1 ] 2>/dev/null || break
    cmd=$(ps -o command= -p "$p" 2>/dev/null) || break
    if agt_is_agent_name "$(agt_base_name "$cmd")"; then
      printf '%s\n' "$p"
      return 0
    fi
    p=$(ps -o ppid= -p "$p" 2>/dev/null | tr -d ' ')
  done
  return 1
}
