# Terminal-native AI context engineering for large codebases.

grab is a terminal-native AI context builder for large codebases.

it's built on top of standard Unix tooling: `ripgrep` for search, `sed` for precise range extraction, and clipboard for transport.

Every `grab` command automatically appends context and copies the accumulated result into the active clipboard/tmux buffer.

`grab` helps you collect clean, explicit code context for debugging and AI-assisted development.

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

grab --tree # capture repository structure

grab ExactPattern # locate relevant symbols/functions

grab 500 635 file.cs # extract exact implementation range from line number and file
```


## AI Workflow Example

```
grab --functions server.py
```

Example output:

```
server.py:167-211 [45L] def _log_request_end(resp: Response):
server.py:212-227 [16L] def _log_unhandled_exception(e: Exception):
server.py:38-58 [21L] def _init_logging() -> None:
server.py:59-95 [37L] def format(self, record: logging.LogRecord) -> str:
server.py:96-110 [15L] def _get_real_client_ip() -> str:
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

 [grab] copy 25: functions 13 lines / 969 bytes
 latest : /root/.cache/grab/buffer.txt
 context: /root/.cache/grab/context.txt
 size   : 862 lines / 29874 bytes
 copied : X clipboard via xclip

```
Format:

```
file:start_line-end_line [function_length] signature
```

The AI can request exact implementations directly from function boundaries:

```
grab 167 211 server.py _log_request_end
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


## AI-Assisted Context Acquisition

`grab` is designed for iterative AI debugging workflows.

Instead of manually searching through a codebase and copy/pasting fragments into an AI assistant, the workflow becomes:

1. Ask the AI what context it needs
2. The AI generates explicit `grab` commands
3. Run the commands locally
4. `grab` accumulates the results automatically
5. Paste the resulting context back into the AI

Example AI response:

```text
grab --clear
grab --tree
grab auth
grab 500 635 auth.cs LoginFlow
grab 170 250 file.py
grab "token refresh"
```

The user runs the commands locally.

Each command appends additional context into:

```text
~/.cache/grab/context.txt
```

This creates a controlled feedback loop:

```text
AI identifies missing context
→ AI emits grab commands
→ User executes commands
→ Context accumulates automatically
→ AI receives explicit inputs
→ Hallucination decreases
```
AI assistants should use function index output and deterministic extraction ranges to request exact implementations instead of guessing surrounding code.

Instead of guessing missing architecture, dependencies, or variable call flow, the AI works from progressively expanded explicit context.

`grab` exposes:

- exact filenames
- exact line numbers
- function boundaries
- function start/end lines
- function size in lines
- deterministic extraction coordinates

This allows the AI to progressively refine context acquisition without inferring hidden implementation details.

Search results and function indexes provide explicit extraction coordinates that can be converted directly into deterministic `grab` range commands.

Because the AI receives exact line ranges and function boundaries, it can request surrounding implementation context without missing nearby logic, dependencies, or variable flow.

Typical workflow:

```
AI searches symbol
→ grab returns exact file + line numbers
→ AI requests function index
→ grab returns function boundaries + sizes
→ AI emits exact extraction ranges
→ surrounding implementation context is preserved
→ Context expands incrementally
```

grab does not infer hidden repository structure or dependencies automatically.

Instead, context is expanded explicitly through iterative search and deterministic extraction commands.


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





## AI Protocol

When working with `grab`, the AI should treat the accumulated `grab` context as the only source of truth.

The workflow is iterative:

1. The user describes the problem
2. The AI identifies missing context
3. The AI emits explicit `grab` commands
4. The user runs the commands locally
5. The accumulated context is pasted back into the AI
6. The AI continues reasoning from the expanded context

Example AI response:

```
grab --clear
grab --tree
grab auth
grab "token refresh"
grab --functions auth.cs
grab 500 635 auth.cs LoginFlow
```
## --Function Index Format

 ```
 file:start_line-end_line [function_length] function_signature
 ```
 Example:

  ```
  server.py:167-211 [45L] def _log_request_end(resp: Response):
  server.py:212-227 [16L] def _log_unhandled_exception(e: Exception):
  ```

 Interpretation:

 - `server.py` → source file
 - `167` → function start line
 - `211` → function end line
 - `[45L]` → function length in lines
 - `def _log_request_end(resp: Response):` → function signature

 To request the full function body, convert the range directly into a grab range command:

 grab 167 211 server.py _log_request_end
 or
 grab 167 211 server.py

 AI assistants should use function index output to request exact full-function implementations instead of guessing surrounding code.

 Rules:

 Never assume code outside the provided grab context
 Request additional context using explicit grab commands
 Use grab --tree early when architecture or file layout is unclear
 Use grab <pattern> to locate symbols, call sites, routes, handlers, config keys, and error strings
 Use grab --functions <file> to inspect function boundaries before requesting full implementations
 Interpret function index lines as file:start_line-end_line [function_length] function_signature
 Use file:start_line-end_line from function index output to request exact range extraction
 Use [function_length] to estimate context size before requesting large functions
 Prefer whole-function extraction over tiny snippets when debugging behavior
 Prefer exact line-range extraction whenever possible
 Prefer deterministic context expansion over guessing
 Use filenames and line numbers from previous results
 Request related call sites and dependencies incrementally
 When modifying code, show BEFORE and AFTER
 Prefer full function replacements over partial snippets
 Do not remove existing behavior unless explicitly requested

 The goal is not to infer hidden code.

 The goal is to progressively construct explicit debugging context.



## Context Model

grab maintains two outputs:

| File | Purpose |
|---|---|
| `buffer.txt` | latest command output |
| `context.txt` | accumulated AI context |

Every new command appends into `context.txt`.

This allows incremental context building across debugging sessions.

All context accumulates automatically into:

```
~/.cache/grab/context.txt

```


The latest command output is saved to:

```
~/.cache/grab/buffer.txt
```

## Usage

```
grab <pattern> [path...]
grab --all <pattern> [path...]
grab <start> <end> <file> [label...]
grab --clear
```

## Examples

```
grab variable /dir/proj
grab --all VAR
grab 500 635 file.cs HandleSetupHotkeys
sed -n '500,635p' file.cs | grab HandleSetupHotkeys
grab --clear
```

## Modes

| Mode | Description |
|---|---|
| default | Search smart project files only |
| --all | Search all non-ignored files |
| range | Extract line ranges from files |
| stdin | Capture piped input automatically |


Search results include exact filenames and line numbers, allowing the AI to request deterministic range extraction commands.

## Notes

- Latest clean output: `~/.cache/grab/buffer.txt`
- Accumulated AI context: `~/.cache/grab/context.txt`
- Clipboard integration supported



## Directory Context

Capture repository structure directly into AI context:

grab --tree
grab --tree backend/

### Example output:

==================== DIRECTORY CONTEXT ====================
path: /root/project
===========================================================

.
├── README.md
├── src
│   ├── auth.cs
│   └── api.cs
└── tests

==================== grab copy 4 ====================
source: range extract
file: auth.cs
lines: 500-635
label: LoginFlow
=====================================================

public async Task<LoginResult> Authenticate()
{
    ...
}



This helps AI understand the project layout before reading code snippets.

# Precise Range Extraction

Extract exact line ranges:

```
grab 500 635 file.cs HandleSetupHotkeys
```

This appends the selected code to the accumulated context file.

Labels can contain multiple words without quotes:

grab 500 635 file.cs Handle Setup Hotkeys


# Clear Context
```
grab --clear
```

This clears:

```
~/.cache/grab/buffer.txt
~/.cache/grab/context.txt
~/.cache/grab/counter.txt
```

## Output Files
Latest command output:

```
~/.cache/grab/buffer.txt
```

Accumulated AI context:

```
~/.cache/grab/context.txt
```

Counter state:
```
~/.cache/grab/counter.txt
```


# Clipboard Integration

After each command, grab copies the accumulated context.

Supported targets:

tmux buffer
Wayland clipboard via wl-copy
X clipboard via xclip
macOS clipboard via pbcopy

## Vim / Neovim Integration

### Example clipboard setup

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
