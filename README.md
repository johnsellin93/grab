# Terminal-native AI context engineering for large codebases.

grab is a terminal-native AI context builder for large codebases.

`grab` helps you collect clean, explicit code context for debugging and AI-assisted development.

It lets you:

- search relevant project files
- extract exact code ranges
- capture directory structure
- accumulate debugging context
- copy clean context directly into AI tools (zero manual copying)

## Quick Example

```
grab --clear

grab --tree

grab ExactPattern

grab 500 635 file.cs
```


## Demo
![grab demo](docs/demo.gif)

# Example workflow:
- clear previous context
- capture repository structure
- search relevant code
- extract exact implementation ranges
- accumulate AI-ready debugging context


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

## Notes

- Latest clean output: `~/.cache/grab/buffer.txt`
- Accumulated AI context: `~/.cache/grab/context.txt`
- Clipboard integration supported
```


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


grab builds a reusable context file that can be pasted into:

- ChatGPT
- Claude
- an editor
- a ticket
- a debugging note

Use --all to disable smart file-type filtering:

grab --all SomePattern

Ignored directories and noisy files are still skipped.

# Directory Context


Capture repository structure directly into AI context:

```
grab --tree
grab --tree backend/
```

# Example output:

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
# Example clipboard setup:

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



# AI Protocol

```
Use grab context mode.

I will provide context strictly through grab output.

Rules:
- Never assume code outside the provided grab context.
- Ask for exact grab commands when more context is needed.
- Prefer exact line-range extraction.
- When changing code, show BEFORE and AFTER.
- Prefer full function or section replacements.
- Do not remove existing behavior unless explicitly asked.
-
```

Recommended workflow:

```
grab --clear
grab --tree
grab ExactPattern
grab 120 220 file.cs RelevantFunction
```


## Why grab Exists

You are debugging a large codebase: multiple services, mixed languages, thousands of lines.

You know the variable name.
You know the function exists.
But you do not know where it lives, what calls it, what it calls, or how it interacts with the rest of the system.

So you search, jump between files, hit noisy matches, copy fragments into notes or AI tools, lose context, and repeat.

Now add AI: partial context leads to inferred code paths, missing dependencies, and confident but incorrect answers.

`grab` turns this into a controlled, repeatable workflow.

Instead of “search and guess”, `grab` lets you:

- search precisely
- extract exact code ranges
- capture project structure
- accumulate reusable context
- work from explicit inputs

The result is reproducible debugging context, not fragmented snippets.

> You are not copying results. You are exporting context.

## Typical Workflow

```
grab --clear

grab --tree

grab auth

grab 500 635 auth.cs LoginFlow
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

Use `--all` to disable smart filtering.
