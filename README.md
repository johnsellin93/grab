# Terminal workflows for debugging large codebases with AI

grab is a small terminal tool for building explicit repository context during AI-assisted debugging.

It combines `ripgrep`, `sed`, and clipboard/tmux workflows into deterministic code-context extraction.

Instead of repeatedly copy-pasting fragmented snippets, `grab` incrementally accumulates surrounding implementation context across multiple extraction passes.

## Demo
<video src="https://github.com/user-attachments/assets/7c451617-e470-4b72-b2e4-d75b3148fe31" controls autoplay loop muted width="100%"></video>


It lets you:

- search relevant project files
- extract exact code ranges
- capture directory structure
- accumulate debugging context incrementally
- automatically copy accumulated context to clipboard/tmux
- paste clean AI-ready context directly into AI tools

## Supported Languages

Python, C#, JavaScript, TypeScript, shell scripts, and generic text/code repositories.

## Quick Example

```
grab --clear  # reset previous debugging context

grab --tree # capture repository structure

grab ExactPattern # locate relevant call flow and implementation paths

grab 500 635 file.cs # extract exact implementation range from line number and file
```


## AI Workflow Example

```
grab --functions server.py   # function index for a single file
grab --functions .           # search current repository and index all discovered functions
```

Example output:

```
server.py:38-58 [21L] def _init_logging() -> None:
server.py:59-95 [37L] def format(self, record: logging.LogRecord) -> str:
server.py:96-110 [15L] def _get_client() -> str:
server.py:111-121 [11L] def get_cloudflare_access_email() -> str:
server.py:122-166 [45L] def _log_request_start():
server.py:167-211 [45L] def _log_request_end(resp: Response):
server.py:212-227 [16L] def _log_unhandled_exception(e: Exception):
server.py:228-246 [19L] def _safe_float(x: Any) -> float:
server.py:247-264 [18L] def _enqueue_all_trading_commands(bot_to_instance: dict, val: bool) -> int:
server.py:265-269 [5L] def _line_key(bot_id: str, instance_id: str, line_id: str) -> Tuple[str, str, str]:
server.py:270-303 [34L] def _coerce_nonneg_float(x: Any) -> float | None:
server.py:304-357 [54L] def _history_add_event(row: Dict[str, Any], event_type: str) -> bool:
server.py:358-473 [116L] def _history_update_last_open_event_with_outcome(out_row: Dict[str, Any]) -> bool:

[grab] functions:. +13L → context 489L / 44768B copied to X clipboard via xclip
```

Format:

```
file:start_line-end_line [function_length] signature
```



```
grab --functions .
    ↓

AI sees exact function ranges
    ↓

AI emits additional grab extraction commands
    ↓

repository context expands incrementally
```

Function indexing gives the AI exact extraction coordinates that can be used to gather additional surrounding implementation context.

```
grab 265 269 server.py
grab 167 211 server.py
grab 122 166 server.py
grab 212 227 server.py
```

Each extraction incrementally expands the active repository context and copies the accumulated result into the active clipboard buffer

With delayed footer summaries enabled: ```export GRAB_DELAY_FOOTER=1```

```
[grab] +4 blocks (+110L) → context 254L / 6202B

  +45L  _attach_maxage_fields(...)
  +45L  _parse_duration_to_seconds(...)
  +16L  _parse_iso_utc_to_dt(...)
  +4L   _line_key(...)
```

Instead of guessing missing code, the AI progressively acquires explicit repository context through deterministic extraction commands.


# What grab Solves

AI-assisted debugging fails when:

- context is incomplete
- irrelevant files are included
- the model guesses missing code

grab fixes this through explicit context selection and incremental context accumulation.


Developers often:

- search across many files
- copy fragmented snippets
- miss related code
- lose directory structure
- paste partial context into AI tools

That causes AI to guess.

grab fixes this by making context explicit, accumulated, and reusable.

## Why grab Exists

Large repositories spread logic across multiple files and services.

Developers debugging with AI tools often paste fragmented snippets, lose surrounding context, and force the model to guess missing implementation details.

`grab` turns repository exploration into a deterministic context acquisition workflow built around exact search results, function boundaries, and explicit range extraction.

> You are not copying results. You are exporting context.


# Clipboard Integration

Supported targets:

- tmux buffer
- Wayland clipboard via wl-copy
- X clipboard via xclip
- macOS clipboard via pbcopy

## Vim / Neovim Integration

```
set clipboard+=unnamedplus
set clipboard+=unnamed
```

# Requirements

Required:

zsh
ripgrep

Optional:
tree
tmux
wl-copy
xclip
pbcopy

If tree is not installed, grab --tree falls back to find.

# Install

```
git clone https://github.com/johnsellin93/grab.git
cd grab
chmod +x grab
echo 'export PATH="$HOME/grab:$PATH"' >> ~/.zshrc
source ~/.zshrc
```


## Smart Search Mode

By default, `grab` searches only relevant project files:

- source code
- configs
- documentation
- scripts

It automatically ignores:

- node_modules
- build/dist output
- vendor directories
- minified files
- lock files
- generated artifacts


## Workflow Tips

For fast keyboard-driven AI workflows, browser extensions like Vimium C work well alongside `grab`.
