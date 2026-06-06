# Terminal workflows for AI-assisted debugging and repository analysis

grab is a terminal tool for deterministic repository context extraction during AI-assisted debugging and codebase analysis.

It combines `ripgrep`, `sed`, and clipboard/tmux workflows into deterministic code-context extraction.

Instead of indexing entire repositories, grab allows developers and AI systems to progressively acquire only the context required for a specific debugging or implementation task.

Unlike repository indexing tools, grab focuses on explicit, user-directed context acquisition.

> You are not copying results. You are exporting context.

grab helps developers build explicit repository context for AI systems instead of relying on repository-wide indexing or incomplete snippets.

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
Python, C#, JavaScript, TypeScript, shell scripts, YAML/Ansible.


## Basic Workflow

```
grab --clear  # reset previous debugging context

grab --tree # capture repository structure

grab ExactPattern # locate relevant call flow and implementation paths

grab 500 635 file.cs # extract exact implementation range from line number and file

Filter discovered functions by keyword:

grab --functions . Order
grab --functions . Trade
grab --functions . Execute
grab --functions . Rebuy
grab --functions . Breakout
```

## Function Indexing and Context Acquisition

1. Search for symbols, variables, functions, or configuration values.
2. Extract relevant code ranges.
3. Accumulate context across multiple files and searches.
4. Automatically copy aggregated context to tmux or the system clipboard.
5. Paste directly into AI tools for troubleshooting and analysis.

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


Workflow:

```
grab --functions .
    ↓
AI sees function ranges and name context
    ↓
AI emits batches of grab extraction commands
    ↓
repository context expands incrementally to clipboard

grab '--clear' clears the context from .cache/grab/context.txt
```

The intended workflow is batch-oriented. Rather than extracting one function at a time, the AI generates multiple extraction commands that can be executed together to rapidly expand repository context across related code paths.

Function indexing gives the AI exact extraction coordinates that can be used to gather additional surrounding implementation context.

```
grab 265 269 server.py
grab 167 211 server.py
grab 122 166 server.py
grab 212 227 server.py
```

Example batch emitted by the AI:

Each extraction incrementally expands the active repository context and copies the accumulated result into the active clipboard buffer

With delayed footer summaries enabled: ```export GRAB_DELAY_FOOTER=1```

```
[grab] +4 blocks (+110L) → context 254L / 6202B copied to X clipboard via xclip

  +45L  _attach_maxage_fields(...)
  +45L  _parse_duration_to_seconds(...)
  +16L  _parse_iso_utc_to_dt(...)
  +4L   _line_key(...)
```

## Context Storage

Latest extraction:
```
~/.cache/grab/buffer.txt
```

Accumulated AI context:

```
~/.cache/grab/context.txt
```

The context file maintains a growing repository investigation history, making it easier to build context for large-scale debugging and codebase analysis.



Instead of guessing missing code, the AI progressively acquires explicit repository context through deterministic extraction commands.


# What grab Solves

AI-assisted debugging breaks down when:

- Context is incomplete
- Relevant implementation details are missing
- Irrelevant files pollute the prompt
- The model is forced to guess missing code


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
