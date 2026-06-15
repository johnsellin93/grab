# Terminal workflows for rapid AI-assisted debugging and review-first code modification.


## Basic Workflow

| Command | Purpose |
|----------|----------|
| `grab --snapshot .` | Export the complete context of a small repository |
| `grab --functions .` | Index all functions |
| `grab ExactPattern` | Locate relevant call flows and implementation paths |
| `grab 500 635 file.cs` | Extract an exact implementation range |
| `grab --clear` | Reset previous debugging context |
| `grab --tree` | Capture repository structure |
| `grab --replace FILE FUNCTION` | Replace a function by symbol, validate, show diff, and ask for approval |


> Every extraction expands the active repository context and automatically updates the clipboard/tmux buffer with the accumulated result.

> For larger investigations, assistants propose batches of `grab` commands that developers review and execute to progressively acquire the exact repository context required for a task. See [`prompt.txt`](./prompt.txt) for an example workflow.

> You are not copying results. You are exporting context.


## Snapshot Mode


```
Small repository?
→ grab --snapshot .

Large repository?
→ grab --functions .
   assistants propose extraction batches,
   developers review and execute them.

Need to apply AI-generated changes safely?
→ grab --replace
```


For smaller repositories, examples, demos, and proof-of-concepts, Grab can export the complete local repository context in a single command.

```bash
grab --snapshot .
grab --snapshot ./src
grab --snapshot ~/projects/grab
grab --snapshot /full/path/to/repository
grab --snapshot server.py
```

`grab --snapshot` recursively collects supported project files, appends them to the accumulated context buffer, and automatically updates the clipboard or tmux buffer.

Example:

```
[grab] snapshot:
  path    : .
  files   : 22
  skipped : 0
  lines   : 17964
  size    : 658947B

[grab] snapshot:. +17964L → context 17971L / 659110B copied to X clipboard via xclip
```

Snapshot mode is intended for compact repositories where exporting the complete local context is more efficient than progressive extraction.

For larger investigations, targeted context acquisition remains the recommended workflow.


### Example AI-Generated Extraction Batch

```
grab --clear
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

[grab] +11 entries (+337L) → context 826L / 64192B copied to X clipboard via xclip

```

# What grab Solves

Large repositories spread logic across multiple files and services.

AI-assisted debugging breaks down when:

- Context is incomplete
- Relevant implementation details are missing
- Irrelevant files pollute the prompt
- The model is forced to guess missing code

Developers debugging with AI tools often paste fragmented snippets, lose surrounding context, and force the model to infer missing implementation details.

`grab` turns repository exploration into a deterministic context acquisition workflow built around exact search results, function boundaries, and explicit range extraction.

Instead of relying exclusively on repository-wide indexing or exporting entire codebases, `grab` provides both progressive context acquisition for large investigations and snapshot-based workflows for compact repositories.

Developers can choose the level of context acquisition appropriate for the task.


<!--
## Demo

<video src="https://github.com/user-attachments/assets/7c451617-e470-4b72-b2e4-d75b3148fe31" controls autoplay loop muted width="100%"></video>
-->


## AI-Assisted Function Replacement

After an assistant proposes a full replacement function or task, `grab` can apply the change safely from the terminal.

```bash
grab --replace server.py _safe_float
grab --replace file.js showError
grab --replace roles/os_settings/tasks/main.yml "Render hardened sshd_config"
```

`grab` will:

* resolve the current function or task location by symbol;
* prompt for the replacement implementation;
* validate syntax where supported;
* display a colored diff showing the proposed change;
* require explicit approval before modifying the source file.

This workflow keeps AI-assisted code changes deterministic, review-first, and human-controlled rather than fully autonomous.

See the included [`prompt.txt`](./prompt.txt) for a complete example AI-assisted debugging workflow.


## Supported Languages
Python, C#, JavaScript, TypeScript, shell scripts, YAML/Ansible.


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

### Example Function Index

```
server.py:228-246 [19L] def _safe_float(x: Any) -> float:
server.py:247-264 [18L] def _enqueue_all_trading_commands(bot_to_instance: dict, val: bool) -> int:
server.py:270-303 [34L] def _coerce_nonneg_float(x: Any) -> float | None:

[grab] functions:. +3L → context 489L / 44768B copied to X clipboard via xclip
```


## AI-Assisted Debugging Workflow

```
Problem statement
    ↓
grab --functions .
    ↓
assistant proposes batches of grab commands
    ↓
developer reviews and executes them
    ↓
repository context expands incrementally
```

Assistants guide repository exploration by proposing deterministic extraction commands, while developers retain control over execution, review, and decision-making throughout the investigation process.

After repository context has been accumulated, developers can paste the resulting clipboard content directly into AI tools for troubleshooting, analysis, and implementation guidance.

# Install

```
curl -fsSL https://raw.githubusercontent.com/johnsellin93/grab/main/install.sh | zsh
```

The installer will:

- install required dependencies such as `ripgrep`
- install optional utilities such as `tree`
- clone or update `grab` in `~/grab`
- make the `grab` executable available in your shell
- update your `PATH` automatically if required

Restart your shell or run:

```
source ~/.zshrc
```

Verify the installation:

```
grab --help
grab --functions .
```



## Infrastructure-as-Code Support (Ansible)

grab indexes Ansible tasks as executable units,
allowing assistants to progressively acquire infrastructure context in the same way they acquire source-code context.

```
grab --functions roles
```

### Ansible Task Index Output

```
roles/os_settings/tasks/main.yml:164-176 [13L] [ROLE: os_settings] ansible task: Render hardened sshd_config
roles/os_settings/handlers/main.yml:23-28 [6L] [ROLE: os_settings] ansible task: reload ssh
roles/google_chrome/tasks/main.yml:20-26 [7L] [ROLE: google_chrome] ansible task: Install Google Chrome
roles/google_chrome/tasks/main.yml:49-60 [12L] [ROLE: google_chrome] ansible task: Install Chrome extensions
```

Tasks can then be extracted directly using the reported coordinates:
This enables assistants to reason about infrastructure changes incrementally, without requiring entire playbooks or repository-wide indexing.

```
grab 164 176 roles/os_settings/tasks/main.yml "Render hardened sshd_config"
grab 23 28 roles/os_settings/handlers/main.yml "reload ssh"
grab 20 26 roles/google_chrome/tasks/main.yml "Install Google Chrome"
grab 49 60 roles/google_chrome/tasks/main.yml "Install Chrome extensions"
```

## Vim / Neovim Workflow Integration

The following mappings are not required to use `grab`, but they significantly improve keyboard-driven AI workflows.

A complete example configuration is available here:

See the included [`init.vim`](./init.vim) for a complete example configuration.

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
