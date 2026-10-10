#!/usr/bin/env python3
"""Prints the conversation in $VOLKTERM_TRANSCRIPT as VolkTerm's chat messages, one JSON object per line.

Reads a JSONL log of {"role": ..., "content": ..., "timestamp": ...} records. Edit the settings below when your
agent names its fields otherwise.
"""
import json
import os
import sys

ROLE_KEY = "role"
TEXT_KEY = "content"
TIME_KEY = "timestamp"
# the agent's role names, mapped to the chat's user, assistant and tool
ROLES = {"user": "user", "assistant": "assistant", "tool": "tool"}
# only the log's tail is read: VolkTerm shows the latest messages
TAIL_BYTES = 4 * 1024 * 1024


def text_of(value):
    """A string, or content blocks such as [{"type": "text", "text": ...}] joined."""
    if isinstance(value, str):
        return value
    if isinstance(value, list):
        return "\n".join(block.get("text", "") for block in value if isinstance(block, dict))
    return ""


def main():
    path = os.environ.get("VOLKTERM_TRANSCRIPT")
    if not path:
        return 1
    with open(path, "rb") as log:
        log.seek(max(0, os.path.getsize(path) - TAIL_BYTES))
        lines = log.read().decode("utf-8", errors="replace").splitlines()
    for line in lines:
        try:
            record = json.loads(line)
        except ValueError:
            continue  # a line cut by reading the tail, or not a record
        if not isinstance(record, dict):
            continue
        role = ROLES.get(record.get(ROLE_KEY))
        text = text_of(record.get(TEXT_KEY)).strip()
        if role and text:
            message = {"role": role, "text": text}
            if isinstance(record.get(TIME_KEY), str):
                message["time"] = record[TIME_KEY]
            print(json.dumps(message, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
