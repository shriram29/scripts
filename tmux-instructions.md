# tmux — a newcomer's guide

tmux ("terminal multiplexer") lets you split one terminal into multiple panes,
run several windows, and — the killer feature on servers — **detach a session
and reattach later**. Close your laptop, SSH drops, doesn't matter: your work
keeps running on the server and you pick up exactly where you left off.

This guide matches the `~/.tmux.conf` written by `install-shell-stack.sh`.

## The one concept that matters: the prefix

You don't press tmux commands directly. You first press the **prefix**, release
it, then press the command key. In this config the prefix is **`Ctrl-a`**
(the tmux default is `Ctrl-b`; we changed it because `a` is easier to reach).

So "`prefix d`" means: press `Ctrl-a`, let go, then press `d`.

## Mental model

```
Session  ─ a named workspace you can detach/reattach (survives disconnects)
  └ Window  ─ like a browser tab, full-screen
      └ Pane   ─ a split region inside a window
```

## Starting & sessions

| Command (in the shell)   | What it does                                  |
|--------------------------|-----------------------------------------------|
| `tmux`                   | Start a new unnamed session                   |
| `tmux new -s work`       | Start a session named "work"                  |
| `tmux ls`                | List running sessions                         |
| `tmux attach -t work`    | Reattach to "work"                            |
| `tmux kill-session -t work` | Kill the "work" session                    |

## Inside tmux (press the prefix first: `Ctrl-a`)

| Keys              | Action                                             |
|-------------------|----------------------------------------------------|
| `prefix d`        | **Detach** (session keeps running in background)   |
| `prefix \|`       | Split pane **vertically** (side by side)           |
| `prefix -`        | Split pane **horizontally** (top/bottom)           |
| `prefix c`        | New **window** (tab)                               |
| `prefix r`        | Reload `~/.tmux.conf`                              |
| `prefix x`        | Close current pane (asks to confirm)               |
| `prefix z`        | **Zoom** current pane fullscreen (toggle)          |
| `prefix [`        | Scroll/copy mode — arrow keys/PageUp to scroll, `q` to quit |
| `prefix 1`…`9`    | Jump to window number                              |
| `prefix n` / `p`  | Next / previous window                             |
| `prefix ,`        | Rename current window                              |

## Custom shortcuts in this config (no prefix needed)

| Keys                  | Action                          |
|-----------------------|---------------------------------|
| `Alt + ← ↑ → ↓`       | Move between panes              |
| Mouse click / scroll  | Select panes, scroll, resize    |

## Try it in 60 seconds

1. `tmux new -s demo`
2. `Ctrl-a` then `|`  → you now have two side-by-side panes
3. `Alt-→` to hop to the right pane, run `btop`
4. `Ctrl-a` then `d`  → detached; you're back in your normal shell, btop still runs
5. `tmux attach -t demo`  → right back where you were

## Customizing further

Edit `~/.tmux.conf`, then reload with `prefix r` (or `tmux source ~/.tmux.conf`).
Grammar:

- `set -g <option> <value>` — a global setting (e.g. `set -g mouse on`)
- `bind <key> <command>` — bind a key (used after the prefix)
- `bind -n <key> <command>` — bind a key with **no** prefix needed
- `unbind <key>` — remove a binding

Want to go back to the default `Ctrl-b` prefix? Delete the three `prefix` lines
near the top of `~/.tmux.conf` and reload.
