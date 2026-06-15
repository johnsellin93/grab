
# Grab Prompt Protocol

Repository context is provided strictly through `grab`.

The accumulated `grab` session is the **only source of truth**.

Never assume code that has not been extracted.

---


## PHASE 1 — DISCOVERY

### Goal

Establish repository structure and discover investigation targets.

### Requirements

If function boundaries are unknown, assistants **MUST** request:

```
grab --functions .
```

### Rules

1. Do not request range extractions before function indexing has been performed.
2. Use `grab --tree` only when repository structure is unclear.
3. Respond **ONLY** with a single copy-pasteable batch of `grab` commands.

### Discovery Completion Criteria

Discovery is considered complete only after:

* function boundaries have been indexed;
* likely investigation targets have been identified.

Do not proceed to **PHASE 2 — HYPOTHESIS FORMATION** until discovery is complete.

---



## PHASE 2 — HYPOTHESIS FORMATION

Based on:

* the problem statement;
* the function index;
* the repository structure;

identify the highest-ROI investigation targets.

### Rules

* Prefer deterministic extraction over speculation.
* Prefer small, targeted extractions over large files.
* Request only the minimum evidence required to validate hypotheses.
* When multiple hypotheses exist, investigate the top 2–3 simultaneously.
* Do not pursue a single hypothesis if adjacent call flows may influence behavior.

After receiving a function index, assistants **MUST** identify:

* target functions;
* caller functions;
* related configuration;
* relevant logs or error messages;
* lifecycle methods relevant to the investigation.

Respond **ONLY** with a single copy-pasteable batch of `grab` commands.

---

## PHASE 3 — EVIDENCE VALIDATION

Before proposing modifications, determine whether sufficient evidence exists.

### Required Output

1. Intended change.
2. Relevant extracted functions or sections.
3. Missing evidence required for safe implementation.
4. Whether the modification is currently safe.

If evidence is insufficient:

```text
STOP.

Request additional grab commands.

Do not generate code.
```

### Do Not Produce Code If

* target functions have not been extracted;
* callers or lifecycle methods may influence behavior but remain unreviewed;
* required fields, types, or configuration are missing;
* threading, timers, async behavior, or concurrency may be affected without sufficient evidence;
* persistence or state-management behavior remains unexplored.

---

## PHASE 4 — MODIFICATION

Only after sufficient evidence exists:

```text
Propose complete replacements.
```

### Requirements

* Preserve existing behavior unless explicitly instructed otherwise.
* Prefer symbol-based replacements.
* Prefer complete functions or sections over partial edits.

### Preferred Workflow

```bash
grab --replace FILE FUNCTION
```

Examples:

```bash
grab --replace server.py _safe_float
grab --replace lineflow.js showError
grab --replace SampleLinesTrader.cs OnTick
grab --replace roles/os_settings/tasks/main.yml "Render hardened sshd_config"
```

### Fallback Workflow

```bash
grab --replace START END FILE LABEL
```

### Provide

1. File name.
2. Replacement target.
3. Why this target was selected.
4. Compatibility considerations.
5. Full BEFORE code block.
6. Full AFTER code block.

### Do Not

* invent functions, classes, fields, or configuration;
* rely on knowledge from previous repositories;
* remove existing logic unless explicitly requested;
* provide partial edits unless explicitly requested.

---

## Investigation Output Rules

When asked:

```text
What should I run next?
```

respond **ONLY** with:

> A single copy-pasteable batch of `grab` commands designed to acquire the highest-value missing evidence.

### Example

```bash
grab --functions .

grab 2681 2780 lines18.cs OnStart
grab 3023 3127 lines18.cs OnTick
grab 982 1094 SampleLinesTrader.Python.cs PollCommandsAsync
grab 1180 1213 SampleLinesTrader.Python.cs ShouldExecuteCommand

grab ExecuteOrder .
grab OrderRetryLimit .
grab "duplicate notification" .
```

---

## Objective

Guide deterministic repository exploration, progressively acquire only the repository evidence necessary to solve the problem, and produce safe modifications based solely on the accumulated `grab` session.
