# Terminal-native AI context engineering for large codebases

grab is a terminal-native context acquisition tool for debugging and AI-assisted development in large repositories.

It combines `ripgrep`, `sed`, and clipboard/tmux workflows into deterministic repository-context extraction.

Instead of copy-pasting fragmented snippets, `grab` incrementally accumulates explicit AI-ready debugging context across multiple extraction passes.

It lets you:

- search relevant project files
- extract exact code ranges
- capture directory structure
- accumulate debugging context incrementally
- automatically copy accumulated context to clipboard/tmux
- paste clean AI-ready context directly into AI tools

## Quick Example

```
grab --clear  # reset previous debugging context

grab --tree` helps expose repository layout before extracting implementation details.

grab ExactPattern # locate relevant call flow and implementation paths

grab 500 635 file.cs # extract exact implementation range from line number and file
```


## AI Workflow Example

```
grab --functions server.py   # function index for a single file
grab --functions .           # repository-wide function index (Python/C#/JS/TS)
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


Function indexing lets the AI request additional repository context using exact `grab` extraction commands.

```
grab 265 269 server.py
grab 167 211 server.py
grab 122 166 server.py
grab 212 227 server.py
```

Each command appends additional repository context and copies the accumulated result into the active clipboard/tmux buffer.

With delayed footer summaries enabled: ```export GRAB_DELAY_FOOTER=1```

```
[grab] +3 blocks (+106L) → context 254L / 6202B

  +45L  _attach_maxage_fields(...)
  +45L  _parse_duration_to_seconds(...)
  +16L  _parse_iso_utc_to_dt(...)
  +4L   _line_key(...)
```

Instead of guessing missing code, the AI progressively acquires explicit repository context through deterministic extraction commands.

## Demo
<video src="simpledemo-cut.mp4" controls autoplay loop muted width="100%"></video>

The workflow shown above is typically driven iteratively by an AI assistant.

Search results expose exact filenames and line numbers, allowing the AI to request precise implementation ranges while preserving surrounding logic and minimizing missing context during debugging.

### Example workflow:
- clear previous context
- capture repository structure
- search relevant code
- extract exact implementation ranges
- accumulate AI-ready debugging context


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


Every `grab` command incrementally expands a reusable AI context buffer:

- ChatGPT
- Claude
- an editor
- a ticket
- a debugging note


## Why grab Exists

Large repositories spread logic across multiple files, services, and directories.

Often a single file contains thousands of lines, making it impractical to paste entire implementations into an AI assistant without overwhelming the context window.

Developers end up manually hunting for the smallest relevant fragments while trying to preserve enough surrounding context for accurate reasoning.

`grab` turns this into a controlled, repeatable workflow.

Instead of “search and guess”, `grab` lets you:

- search precisely
- extract exact code ranges
- accumulate reusable context incrementally
- work from explicit inputs

The result is reproducible debugging context instead of fragmented snippets.

> You are not copying results. You are exporting context.


## Supported Languages

Python, C#, JavaScript, TypeScript, shell scripts, and generic text/code repositories.

# Clipboard Integration

Supported targets:

- tmux buffer
- Wayland clipboard via wl-copy
- X clipboard via xclip
- macOS clipboard via pbcopy

## Vim / Neovim Integration

```vim
set clipboard+=unnamedplus
set clipboard+=unnamed


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
git clone https://github.com/YOUR_USERNAME/grab.git
cd grab
chmod +x install.sh
./install.sh
```


## Typical Workflow

```
grab --clear

grab --tree

grab auth

grab 500 635 auth.cs LoginFlow

cat ~/.cache/grab/context.txt
```

This builds incremental AI-ready debugging context across multiple extraction steps.




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
