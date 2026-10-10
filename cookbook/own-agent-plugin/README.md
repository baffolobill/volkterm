# An agent of your own

A plugin that teaches VolkTerm a coding agent it does not know, so the agent gets what Claude Code and Codex get.

## What it does

VolkTerm knows `claude` and `codex` by name. Any other agent is just a program in a shell until a plugin describes it. This recipe is a template of that plugin, for an agent started as `my-agent`:

- **Restore.** A pane running the agent comes back running it again after a restart, with the options from the typed line kept and those that only make sense once (`droppedOptions`) left out.
- **Ask about a file.** The agent can answer a file question, started read-only with the words in `readOnly`, on the model chosen in Settings ▸ Agents through `model`. It reads the asking session's conversation from the file `transcript.sh` finds.
- **The phone's chat.** The phone shows the agent's conversation as a chat, which `chat.py` reads from that same file. Without it the phone shows the pane's screen.
- **Agent commands.** A Settings ▸ Agents command with only a message sends it to the agent already running in the pane, and one run where the agent already works starts in a new tile beside it, as for Claude Code.

## Requirements

- VolkTerm 1.5.12 or later, the version that added `agents` to `plugin.json`, with `transcript` and `conversation`.
- `python3` (it comes with the Xcode command line tools) for `chat.py`.
- An agent that writes its conversation to a file as it goes: a JSONL log, one record per message, is what `chat.py` reads as shipped.

## Setup

Copy the folder into VolkTerm's plugins folder and name it after the plugin:

```sh
mkdir -p ~/.config/volkterm/plugins
cp -R own-agent-plugin ~/.config/volkterm/plugins/my-agent
```

If Settings ▸ General points the config directory somewhere else, the plugins folder is `plugins` inside it. Settings ▸ Plugins ▸ Open Plugins Folder opens it.

Then fit it to your agent:

- In `plugin.json`, `programs` is the agent's program name exactly as `ps` shows it. `resume` is how it reopens a conversation, `{id}` standing for the conversation's id. `readOnly` is how to start it unable to change files. `model` is how to choose a model, `{model}` standing for it. Delete any of the three your agent does not have. `booleanOptions` lists the agent's flags that take no value, so a restore does not mistake the word after them for theirs.
- In `transcript.sh`, set `LOGS` to the folder where the agent keeps its conversation logs, and `PATTERN` to their file names.
- In `chat.py`, set `ROLE_KEY`, `TEXT_KEY` and `TIME_KEY` to the fields the log's records use, and `ROLES` to its role names.
- To let auto-continue check the agent's API before it types `continue`, add `"probe": "https://…"` to the agent, set to an address the API answers without a key: a 401 there means the network gets through.

Turn the plugin on in Settings ▸ Plugins, or run `volktermctl plugin reload`. Settings ▸ Plugins shows why a plugin did not load, and so does `volktermctl plugin list`.

To remove it, delete `~/.config/volkterm/plugins/my-agent`.

## Usage

Run the agent in a VolkTerm pane the way you always do. Nothing else changes until you need it: open the phone on that session for the chat, ⌘-click a file and Ask about it, or restart VolkTerm with Settings ▸ General ▸ Sessions set to restore running commands.

Check the scripts by hand before relying on them. In a pane running the agent, from a second pane:

```sh
VOLKTERM_AGENT_PID=$(pgrep -n my-agent) ~/.config/volkterm/plugins/my-agent/transcript.sh
VOLKTERM_TRANSCRIPT=<the path it printed> python3 ~/.config/volkterm/plugins/my-agent/chat.py
```

The first prints the log's path, the second one JSON object per message.

## How it works

VolkTerm reads the agent descriptions of every plugin that is on and adds them after the built-in ones. A plugin cannot take over `claude` or `codex`, and a program two plugins both name stays with the first.

`transcript` and `conversation` are shell lines VolkTerm runs out of sight, with `/bin/sh` in the session's directory. `$VOLKTERM_PLUGIN_DIR` names the plugin's folder, `$VOLKTERM_AGENT_PID` the agent's process, and the conversation command also gets `$VOLKTERM_TRANSCRIPT`, the file the transcript command printed. They run with the app's environment, not your shell's, which is why the settings live at the top of the scripts rather than in variables you export.

`transcript.sh` first looks for a log the agent holds open (`lsof`), which is exact when the agent keeps its log open. Otherwise it takes the newest log written since the agent's process started. `lsof` prints real paths, so the script resolves `LOGS` the same way before comparing; a folder reached through a symlink would otherwise never match.

`chat.py` prints one JSON object per message, `{"role": "user|assistant|tool", "text": "…", "time": "…"}`, oldest first. VolkTerm keeps the latest of them. `time` is optional, and so is an `id`, which VolkTerm otherwise derives from the line. The script reads only the log's last 4 MB, since the phone asks again every few seconds while the chat is open.

## Limits

- Restore brings the agent back with its options, but resumes its conversation only once VolkTerm knows the conversation's id, which it reads for Claude Code and Codex only so far. A plugin's agent comes back in a new conversation, and Continue as does not offer it.
- Two runs of the agent in the same project, each writing to the folder, can make `transcript.sh`'s fallback pick the other one's log. The `lsof` match does not have that problem.
- A file question waits up to two seconds for `transcript.sh`, and the phone's chat about ten for both scripts. Past that the question goes without the conversation and the phone shows the pane's screen.
- Auto-continue needs the agent to report its stops: VolkTerm learns of an API error from Claude Code's hook. Another agent's hooks would have to call `volktermctl session stopped <reason>` themselves, with Claude Code's error names (`rate_limit`, `overloaded`, `server_error`).
- Questions the agent asks in its terminal (a permission prompt, a menu) reach the phone only when they look like Claude Code's or Codex's: a `❯` or `›` cursor beside numbered options.
