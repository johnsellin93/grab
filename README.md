# rgui

Built for real debugging workflows, not just search.

**Deterministic code-context pipeline for debugging large codebases and AI-assisted workflows.**

---

You are debugging a large codebase (10k+ lines, multiple services, mixed languages).

- You know the variable name
- You know the function exists
- You don’t know where it lives, the call flow, its side effects, or how it interacts with the rest of the system

So you:

- try to locate it (`rg`, IDE search, or manual navigation)
- jump between multiple files and directories
- hit irrelevant matches (build artifacts, generated files, minified code)
- mentally reconstruct the call flow across files
- copy fragments into notes or into an AI assistant
- lose context between steps
- repeat the process

Now add AI:

- you paste partial code
- it infers missing pieces
- it connects code paths that don’t actually connect
- it gives confident but incorrect answers


---

## What rgui solves

`rgui` turns this into a controlled, repeatable process.

Instead of “search and guess”, you:

1. **Search precisely**
2. **Extract exact code ranges**
3. **Accumulate context step-by-step**
4. **Work from a single, clean source of truth**

No hidden code.
No guessing.
No context drift.

---

## What rgui is

`rgui` is a deterministic debugging interface built on top of `ripgrep`.

It adds:

- structured context extraction via `rg` and `sed`
- session-based accumulation across multiple debugging steps
- clean, ANSI-free buffers for reliable copy/paste
- automatic clipboard/tmux integration

Every search and extraction step is appended into a single session buffer and copied automatically.

This allows you to:

- build context incrementally
- paste a complete, structured trace into an editor, ticket, or AI assistant
- avoid missing dependencies or partial code

The result is a **reproducible debugging context**, not fragmented snippets.

You are not copying results.

You are exporting context.

---

## What This Actually Does

`rgui` does not just search code.

It enforces a workflow where:

- context is explicitly selected (not inferred)
- results are accumulated across steps
- output is normalized and reusable
- debugging becomes traceable and repeatable

Instead of jumping between files and losing state, you build a **linear, inspectable context history**.


---

## Core Concept

`rgui` turns debugging into a **deterministic pipeline**:

1. Search → locate symbols precisely
2. Extract → pull exact line ranges
3. Accumulate → build session context
4. Copy → clean, ANSI-free output
5. Reuse → in editor, ticket, or AI

The session becomes the **single source of truth**.

---

## Why This Matters

AI-assisted debugging fails when:

- context is incomplete
- irrelevant files are included
- the model guesses missing code

`rgui` fixes this by enforcing:

- explicit context boundaries
- no hidden code
- reproducible inputs

This makes results **predictable and verifiable**.

---


## Features

- Structured search via `ripgrep` with language-aware filtering
- Precise code extraction via `sed` + session capture
- Automatic session accumulation across commands
- ANSI-stripped buffers for clean reuse
- Clipboard and tmux integration (zero manual copying)
- Noise filtering:
  - node_modules, build, dist, obj, bin
  - minified files, source maps, lock files
- Safe constraints:
  - file size limits
  - line length limits



---

## Example Workflow (real debugging)

```bash
# reset context
rgui --clear

# find where variable is used
rgui "TakeProfitEur"

# inspect specific implementation
sed -n '480,620p' TradingEngine.cs | rgui --stdin "TakeProfit logic"

# find related calls
rgui "ApplyTakeProfit"
```

At this point:

- you have **only relevant code**
- context is accumulated step-by-step
- no unrelated files are included
- output is clean and reusable

---

## AI Protocol (KEY FEATURE)

`rgui` is designed to work with AI under strict constraints to eliminate hallucination.

Use this prompt:

```
Use rgui session mode.

I will provide context strictly via commands. You must:
- Ask for exact rgui and sed commands when context is missing
- Never assume code outside provided rgui/sed output
- When changing code, show BEFORE and AFTER
- Prefer full function/section replacements over tiny fragments

Command format:

1) Clear session:
rgui --clear

2) Search:
rgui "<EXACT_PATTERN>"

3) Extract code:
sed -n '<START>,<END>p' <FILE> | rgui --stdin "<LABEL>"

Rules:
- Request exact sed ranges with line numbers when possible
- Prefer multiple small, precise extractions
- Treat the accumulated rgui session as the ONLY source of truth
- Do not remove existing logic unless explicitly asked
- Preserve existing behavior, then extend

Output rules:
- For code changes, send:
  1. File name
  2. What section/function to replace
  3. BEFORE code block
  4. AFTER code block
- Do NOT send partial edits unless explicitly requested
- Do NOT summarize code unless asked
```

This converts AI from:

> “best guess engine”

into:

> **a deterministic code transformation tool**

---

## Install

```bash
git clone https://github.com/YOUR_USERNAME/rgui.git
cd rgui
./install.sh
```

---

## Requirements

- zsh
- ripgrep

Optional:

- tmux
- wl-copy / xclip / pbcopy

---

## Output Files

Latest result:
```
~/.cache/rgui/buffer.txt
```

Session context:
```
~/.cache/rgui/session.txt
```

---

## Positioning

This is not a search tool.

This is:

> **a deterministic debugging protocol for large codebases**
