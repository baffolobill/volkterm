# VolkTerm FAQ

## Windows

**Can I keep several windows open, and do they come back on the same monitors?**
Yes. Each window's position and size, monitor included, is saved when it closes and restored on the next launch;
windows open at quit reopen. A window whose monitor is gone is moved by macOS onto a screen that is there.

## Install and updates

**Do I need Homebrew?**
No. Download the `.dmg` from the releases page and drag VolkTerm into Applications. Updates then install from inside
the app: the arrow in the title bar or VolkTerm ▸ Check for Updates… downloads the new version, checks it is signed by
the same developer as the copy you run, replaces it and offers to restart. With Homebrew the same button runs brew.

**How do I update Claude Code or Codex?**
VolkTerm ▸ Update Claude Code… or Update Codex…. VolkTerm updates each the way it was installed, Homebrew, Claude's
own installer, npm or bun, then offers to restart the sessions still on the old version, each resuming its
conversation.

**Can VolkTerm work through a proxy?**
Yes, two of them at once. Settings ▸ General ▸ Proxy covers VolkTerm's own connections and gives new terminal sessions
the proxy variables that curl, git, npm and agents read. Settings ▸ Agents sets a proxy for every agent command or for
one, which wins over the first; `direct` there runs that agent with no proxy at all. Programs that ignore the proxy
variables, such as ssh, still connect directly.

**Can I move a session, workspace or group to another window?**
Yes: right-click it in the sidebar ▸ Move to Window, and pick an open window or New Window. What moves keeps running;
a workspace takes its group along. `volktermctl window take` does the same.

## Restarts and Live sessions

**What happens after the Mac restarts?**
Windows and sessions come back. In Live sessions mode a clean quit (an ordinary restart quits apps cleanly) records
each pane's running command; the restart ends the processes, and on the next launch each pane starts that command
again. Claude Code and Codex resume their conversations. Other programs start a fresh shell that first prints the
pane's last text. After a power loss or a force quit nothing is recorded, so panes open as fresh shells in their
directories. VolkTerm opens by itself after login only if macOS's "Reopen windows when logging back in" was checked.

**Does updating VolkTerm stop my Live sessions?**
No. A Live session is a separate process (a zmx daemon), not part of the app: VolkTerm quits, updates, starts again and
reattaches, and whatever runs inside keeps running. The exception is an update that changes zmx itself: sessions
created before it keep the old zmx until VolkTerm ▸ Reset Live Sessions… recreates them, and that reset stops the work
running in them. The update window says when an update is one of these.

**What is the difference between quitting VolkTerm and restarting it for an update?**
For Live sessions, none: quitting only disconnects the app, and the sessions keep running in the background. They end
when you delete their session, pane or window, switch the restore mode to Fresh shells and restart, or run
Reset Live Sessions… (`volktermctl zmx reset --force`).

**VolkTerm will not start, but my Live sessions are still running. How do I stop them?**
The bundled zmx works without the app:

```
/Applications/volkterm.app/Contents/MacOS/zmx list
/Applications/volkterm.app/Contents/MacOS/zmx kill <name> --force
```

## Agents

**What is Continue as?**
It carries an agent's conversation on under another of your agent commands (Settings ▸ Agents), so another
subscription: the agent in the pane is ended and the other command resumes the same conversation. Use it when one
subscription reaches its limit mid-task. It lists only commands that start an agent, less the one already running, so
with none set up it does not show.

**My agent stopped when the connection dropped or the limit ran out. Do I have to come back and tell it to go on?**
No. VolkTerm continues it by itself once the cause clears: after a spent limit it waits for the window to reset,
after a lost connection for the network, after an overloaded API for a short pause that grows with each try. Then it
types `continue` into the agent. The tile header shows when (`↻ 18:00` or `↻ network`); typing into the agent first
cancels it, and Settings ▸ Agents turns it off. It needs the agent hooks installed (Help ▸ Install Agent Status Hooks).

## Notifications

**I never see notifications from VolkTerm.**
Older versions only notified when an agent asked for permission, which auto mode almost never does. VolkTerm now
also notifies when an agent finishes (unless you are typing in that session), when one stops on an error, and when a
subscription's window reaches 80% or runs out. Every notification is kept in the bell at the bottom of the sidebar,
so one you missed, or whose banner macOS hid, is still there.

## Language

**Can VolkTerm show its interface in another language?**
English, Russian, German and Simplified Chinese: Settings ▸ General ▸ Language, or the language set for VolkTerm in
macOS (System Settings ▸ General ▸ Language & Region ▸ Applications). It applies after a restart. Scripts and the
command line stay English.

## License

**What does a license add?**
VolkTerm works without one. A license adds what saves time when several agents and subscriptions are at work:
agents that continue by themselves after a lost connection or a spent limit, Continue as, side agents that answer
questions about a file, and every session on the phone instead of the top one and those the phone opened. Without a
license those items stay in the menus and say so when used. Enter a key in VolkTerm ▸ License….

## Phone app

**Can the phone work with several Macs?**
Yes. Scan each Mac's code (VolkTerm ▸ Pair Phone…); they all stay connected at once, and the title of the session
list picks which one you see. Notifications come from every connected Mac, named after it. In Settings each Mac can
be disconnected, renamed or removed. A Mac with several windows shows its sessions under each window.

**Can I see my subscription limits and notifications on the phone?**
Yes. When a subscription's 5-hour or weekly window passes 80%, a line above the session list says so; tap it for
every subscription's usage and when each window resets. The bell lists what the Mac notified, and a new notification
shows over whatever screen is open; tap it to open its session.

**How do I open a file on the phone?**
Files the agent opened with `preview` or `edit` appear as buttons above the chat; tap one to read or edit it. A file
path inside an agent's message is a link too, for any text file in the session's folder.
