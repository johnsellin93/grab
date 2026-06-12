# Rapid AI-assisted debugging and repository analysis from the terminal

> You are not copying results. You are exporting context.

grab turns repository exploration into a deterministic workflow for building AI-ready context from large codebases, one extraction at a time.

It combines `ripgrep`, `sed`, and clipboard/tmux workflows into deterministic code-context extraction.

Instead of indexing entire repositories, grab allows developers and AI systems to progressively acquire only the context required for a specific debugging or implementation task.

Unlike repository indexing tools, grab focuses on explicit, user-directed context acquisition.

grab helps developers build explicit repository context for AI systems without relying on repository-wide indexing or fragmented snippets.
Context is acquired incrementally as the investigation evolves.

<!--
## Demo

<video src="https://github.com/user-attachments/assets/7c451617-e470-4b72-b2e4-d75b3148fe31" controls autoplay loop muted width="100%"></video>
-->

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

| Command | Purpose |
|----------|----------|
| `grab --clear` | Reset previous debugging context |
| `grab --tree` | Capture repository structure |
| `grab ExactPattern` | Locate relevant call flows and implementation paths |
| `grab 500 635 file.cs` | Extract an exact implementation range |
| `grab --functions . Order` | Locate Order-related functions |
| `grab --functions .` | index all functions |

# Install

```
git clone https://github.com/johnsellin93/grab.git
cd grab
chmod +x grab
echo 'export PATH="$HOME/grab:$PATH"' >> ~/.zshrc
source ~/.zshrc
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

### Function Index Output

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

## Example Debugging Session

```
Problem statement:

"Users occasionally receive duplicate notifications.

We suspect retry handling might be involved,
but we don't yet know which parts of the codebase to investigate."

grab --functions .
    ↓
assistant sees function ranges and name context
    ↓
assistant identifies likely investigation targets
    ↓
assistant emits batches of grab commands
    ↓
developer reviews and executes them
    ↓
repository context expands incrementally to clipboard
```


The workflow is intentionally batch-oriented. Rather than extracting one function at a time, assistants generate multiple extraction commands that can be executed together to rapidly expand repository context across related code paths.

Each extraction expands the active repository context and copies the accumulated result into the clipboard buffer.

Function indexing provides exact extraction coordinates that assistants can use to request additional implementation context.

Instead of guessing missing code, assistants propose deterministic extraction commands that developers can execute to progressively acquire explicit repository context.


### Example Assistant-Generated Extraction Batch

```
grab --functions .
grab 312 383 NotificationDispatcher.cs ProcessNotificationDelivery
grab 448 486 NotificationDispatcher.cs ShouldRetryNotification
grab 521 564 NotificationDispatcher.cs RecordDeliveryAttempt
grab 612 642 NotificationDispatcher.cs HasRecentSuccessfulDelivery
grab 188 236 RetryPolicy.cs RetryFailedNotification
grab 245 271 RetryPolicy.cs GetRetryBackoffDelay

grab NotificationRetryLimit .               # variable / symbol lookup
grab DeliveryDeduplicationWindowMinutes .  # variable / symbol lookup
grab "duplicate notification" .            # exact text search

```

### Accumulated Clipboard Context

```
  +72L  block  ProcessNotificationDelivery(...)
  +38L  block  ShouldRetryNotification(...)
  +44L  block  RecordDeliveryAttempt(...)
  +31L  block  HasRecentSuccessfulDelivery(...)
  +49L  block  RetryFailedNotification(...)
  +27L  block  GetRetryBackoffDelay(...)
  +18L  symbol NotificationRetryLimit
  +13L  symbol DeliveryDeduplicationWindowMinutes
  +26L  text   "duplicate notification"

[grab] +9 entries (+318L) → context 807L / 64192B copied to X clipboard via xclip

```

## Vim / Neovim Workflow Integration

The following mappings are not required to use `grab`, but they significantly improve keyboard-driven AI workflows.

| Mapping | Purpose |
|----------|----------|
| `<C-s>` | Select the current function or method |
| `<M-s>` | Alternate function-selection mapping |
| `<M-c>` | Copy entire current file to the clipboard |
| `<M-m>` | Indent selected code left by one space |
| `<M-.>` | Indent selected code right by one space |
| `<Leader>r` | Search and replace all occurences of keyword |
| `<Space>h` | Highlight from the current line to a specific line |
| `p` | Paste from clipboard and highlight inserted text |

### Clipboard Integration

```vim
set clipboard+=unnamedplus
set clipboard+=unnamed
```

### Function Selection

Useful when capturing complete implementation context for `grab`.

Functions spanning hundreds of lines can be selected in a single action, making it easy to export entire execution paths without manually scrolling, selecting, or risking partial copies.
```vim
nnoremap <silent> <C-s> :call SelectWholeFunction()<CR>
nnoremap <silent> <M-s> :call SelectWholeFunction()<CR>
```


### Indentation adjustment

Useful when pasting assistant-generated code that requires indentation adjustments.

```vim
xnoremap <M-m> :<C-U>call MoveTextOneCharSpace('left')<CR>
xnoremap <M-.> :<C-U>call MoveTextOneCharSpace('right')<CR>
```

### Paste Highlighting

Useful when reviewing and indent assistant-generated patches immediately after insertion.

```vim
nnoremap p :call PasteAndHighlight()<CR>
vnoremap <C-v> :call PasteAndHighlight()<CR>
```

### Search and Replace

Search and replace keyword in file.

```vim
nnoremap <Leader>r :SReplace<CR>
```

### Copy Entire File

Useful when assistants require complete file context rather than targeted extractions.

```vim
nnoremap <M-c> :%!xclip -sel clip<CR>
```

### Highlight to Line

Highligth code to a specific line.

```vim
nnoremap <silent> <Space>h :call HighlightToLine()<CR>
```

Workflow:

```text
Highlight to line:
250
```

Selects from the current line through line `250`.


Delayed footers summarize newly added context after batch extraction.

```
export GRAB_DELAY_FOOTER=1
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
