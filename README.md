# Function based Context Management 


Extract functions, symbols, and execution paths for AI-agent debugging.


## Basic Workflow

| Command | Purpose |
|----------|----------|
| `grab --clear` | Start investigation |
| `grab --tree` | when investigation scope is unclear |
| `grab --symbol <file> <function_name>` |  Extract function from file | 
| `grab <lineid_start> <lineid_end> <file> <function_name>` | Extract function by START LINE / END LINE |
| `grab <pattern> <path> <dot>` | Symbol call flow |
| `grab --replace FILE FUNCTION` | Not supported |


See [`GRAB_PROTOCOL.md`](./GRAB_PROTOCOL.md) for the complete investigation workflow.

## Supported Languages
Python, C#, JavaScript, TypeScript, shell scripts, YAML/Ansible.

### Why not export the entire repository?

Large repositories often exceed practical context limits and contain
substantial amounts of irrelevant implementation detail.

`grab` allows assistants to acquire only the repository evidence
necessary to understand a problem, reducing noise and preserving
deterministic investigation workflows.

Larger repositories benefit from progressive evidence acquisition.

# What this Solves

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

See the included [`GRAB_PROTOCOL.md`](./GRAB_PROTOCOL.md) for a complete example AI-assisted debugging workflow.

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
assistant uses function boundaries to identify
likely investigation targets
↓
assistant proposes batches of grab commands
↓
repository evidence accumulates incrementally
↓
clipboard context is pasted into AI tools
```

Assistants guide repository exploration by proposing deterministic extraction commands, while developers retain control over execution, review, and decision-making throughout the investigation process.

After repository context has been accumulated, developers can paste the resulting clipboard content directly into AI tools for troubleshooting, analysis, and implementation guidance.

# Install

```
curl -fsSL https://raw.githubusercontent.com/johnsellin93/grab/main/install.sh | zsh
```

The installer will:

- install required dependencies such as `ripgrep`
- configure the Unix tooling used by Grab's investigation workflows
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



## Built on Proven Tools

Rather than reimplementing mature Unix utilities, `grab`
composes battle-tested tools into higher-level workflows
for deterministic repository investigation.

Core components include:

- [`ripgrep`](https://github.com/BurntSushi/ripgrep) for fast repository search
- [`sed`](https://github.com/mirror/sed) for precise text transformations
- system clipboard integrations for accumulated context export

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
