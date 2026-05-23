#!/usr/bin/env zsh
set -euo pipefail
# AI context grabber for terminal workflows, not just “another rg wrapper.” The unique value is: search/extract → accumulate context → copy to clipboard.

usage() {
  cat <<'EOF'
Usage:
  grab <pattern> [path...]
  grab --all <pattern> [path...]
  grab <start> <end> <file> [label...]
  grab --clear

Examples:
  grab variable /dir/proj
  grab --all VAR
  grab 500 635 file.cs HandleSetupHotkeys
  sed -n '500,635p' file.cs | grab HandleSetupHotkeys
  grab --clear

Modes:
  default   Search smart project files only
  --all     Search all non-ignored files from type_filters
  range     Extract line range from file
  stdin     Capture piped input automatically

Notes:
  - Latest clean output: ~/.cache/grab/buffer.txt
  - AI context history:   ~/.cache/grab/context.txt
  - Copies to tmux/clipboard when available
EOF
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

# if [[ "${1:-}" == "--clear" ]]; then
#   buffer_dir="${GRAB_BUFFER_DIR:-$HOME/.cache/grab}"
#   buffer_file="${GRAB_BUFFER_FILE:-$buffer_dir/buffer.txt}"
#   context_file="${GRAB_CONTEXT_FILE:-$buffer_dir/context.txt}"
#   counter_file="${GRAB_COUNTER_FILE:-$buffer_dir/counter.txt}"
#
#   mkdir -p "$buffer_dir"
#   : > "$buffer_file"
#   : > "$context_file"
#   print -r -- "0" > "$counter_file"
#
#
#   exit 0
# fi

if [[ "${1:-}" == "--clear" ]]; then
  buffer_dir="${GRAB_BUFFER_DIR:-$HOME/.cache/grab}"
  buffer_file="${GRAB_BUFFER_FILE:-$buffer_dir/buffer.txt}"
  context_file="${GRAB_CONTEXT_FILE:-$buffer_dir/context.txt}"
  counter_file="${GRAB_COUNTER_FILE:-$buffer_dir/counter.txt}"
  mkdir -p "$buffer_dir"

  buffer_lines=0
  context_lines=0

  if [[ -f "$buffer_file" ]]; then
    buffer_lines=$(wc -l < "$buffer_file" | tr -d ' ')
  fi

  if [[ -f "$context_file" ]]; then
    context_lines=$(wc -l < "$context_file" | tr -d ' ')
  fi

  : > "$buffer_file"
  : > "$context_file"
  print -r -- "0" > "$counter_file"

  print -r -- "[grab] cleared latest ${buffer_lines} lines and context ${context_lines} lines"
  exit 0
fi

if [[ "${1:-}" == "--tree" ]]; then
  shift

  tree_path="${1:-.}"

  if [[ ! -d "$tree_path" ]]; then
    print -r -- "[grab] tree path is not a directory: $tree_path" >&2
    exit 1
  fi

  buffer_dir="${GRAB_BUFFER_DIR:-$HOME/.cache/grab}"
  buffer_file="${GRAB_BUFFER_FILE:-$buffer_dir/buffer.txt}"
  context_file="${GRAB_CONTEXT_FILE:-$buffer_dir/context.txt}"
  counter_file="${GRAB_COUNTER_FILE:-$buffer_dir/counter.txt}"

  mkdir -p "$buffer_dir"
  : > "$buffer_file"
  if command -v tree >/dev/null 2>&1; then
    {
      print -r -- "==================== DIRECTORY CONTEXT ===================="
      print -r -- "path: $(realpath "$tree_path" 2>/dev/null || print -r -- "$tree_path")"
      print -r -- "==========================================================="
      print -r -- ""

      tree \
        -a \
        -I 'node_modules|.git|dist|build|coverage|tmp|vendor|__pycache__|.venv|venv|bin|obj' \
        "$tree_path"
    } > "$buffer_file"

  else
    {
      print -r -- "$tree_path"

      find "$tree_path" \
        \( -path '*/node_modules' -o \
           -path '*/.git' -o \
           -path '*/dist' -o \
           -path '*/build' -o \
           -path '*/coverage' -o \
           -path '*/tmp' -o \
           -path '*/vendor' -o \
           -path '*/__pycache__' -o \
           -path '*/.venv' -o \
           -path '*/venv' -o \
           -path '*/bin' -o \
           -path '*/obj' \) \
        -prune -o -print |
        sed "s#^\./##" |
        awk '
          NR == 1 { print; next }
          {
            path = $0
            depth = gsub("/", "/", path)
            name = path
            sub(/^.*\//, "", name)

            indent = ""
            for (i = 0; i < depth; i++) {
              indent = indent "  "
            }

            print indent "├── " name
          }
        '
    } > "$buffer_file"
  fi
  if [[ ! -f "$context_file" ]]; then
    : > "$context_file"
  fi

  if [[ ! -f "$counter_file" ]]; then
    print -r -- "0" > "$counter_file"
  fi

  run_no="$(cat "$counter_file" 2>/dev/null || print -r -- 0)"
  run_no=$((run_no + 1))
  print -r -- "$run_no" > "$counter_file"

  {
    print -r -- ""
    print -r -- "==================== grab copy ${run_no} ===================="
    print -r -- "source: tree"
    print -r -- "path: $tree_path"
    print -r -- "============================================================="
    cat "$buffer_file"
  } >> "$context_file"

  cat "$buffer_file"

  copy_target="none"

  if [[ -n "${TMUX:-}" ]] && command -v tmux >/dev/null 2>&1; then
    tmux load-buffer "$context_file"
    copy_target="tmux buffer"
  elif command -v wl-copy >/dev/null 2>&1 && [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
    wl-copy < "$context_file"
    copy_target="Wayland clipboard"
  elif command -v xclip >/dev/null 2>&1 && [[ -n "${DISPLAY:-}" ]]; then
    xclip -selection clipboard -in < "$context_file"
    copy_target="X clipboard via xclip"
  elif command -v pbcopy >/dev/null 2>&1; then
    pbcopy < "$context_file"
    copy_target="macOS clipboard"
  fi

  line_count=$(wc -l < "$buffer_file" | tr -d ' ')

  print -r -- "[grab] tree ${line_count} lines copied to ${copy_target}" >&2

  exit 0
fi




# Auto-detect real piped stdin.
# This avoids hanging on "cat > buffer_file" when stdin looks non-TTY
# but no real data arrives.
if [[ ! -t 0 ]]; then
  if ! IFS= read -r -t 0.2 first_line; then
    print -r -- "[grab] stdin looked piped but no data arrived; continuing with normal argument mode" >&2
  else
    if [[ $# -ge 1 ]]; then
      label_parts=("$@")
      label="${(j: :)label_parts}"
    else
      label="stdin"
    fi

    buffer_dir="${GRAB_BUFFER_DIR:-$HOME/.cache/grab}"
    buffer_file="${GRAB_BUFFER_FILE:-$buffer_dir/buffer.txt}"
    context_file="${GRAB_CONTEXT_FILE:-$buffer_dir/context.txt}"
    counter_file="${GRAB_COUNTER_FILE:-$buffer_dir/counter.txt}"
    mkdir -p "$buffer_dir"
    : > "$buffer_file"

    print -r -- "$first_line" > "$buffer_file"
    cat >> "$buffer_file"

    if [[ ! -f "$context_file" ]]; then
      : > "$context_file"
    fi

    if [[ ! -f "$counter_file" ]]; then
      print -r -- "0" > "$counter_file"
    fi

    run_no="$(cat "$counter_file" 2>/dev/null || print -r -- 0)"
    run_no=$((run_no + 1))
    print -r -- "$run_no" > "$counter_file"

    {
      print -r -- ""
      print -r -- "==================== grab copy ${run_no} ===================="
      print -r -- "source: stdin"
      print -r -- "label: $label"
      print -r -- "============================================================="
      cat "$buffer_file"
    } >> "$context_file"

    copy_target="none"

    if [[ -n "${TMUX:-}" ]] && command -v tmux >/dev/null 2>&1; then
      tmux load-buffer "$context_file"
      copy_target="tmux buffer"
    elif command -v wl-copy >/dev/null 2>&1 && [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
      wl-copy < "$context_file"
      copy_target="Wayland clipboard"
    elif command -v xclip >/dev/null 2>&1 && [[ -n "${DISPLAY:-}" ]]; then
      xclip -selection clipboard -in < "$context_file"
      copy_target="X clipboard via xclip"
    elif command -v pbcopy >/dev/null 2>&1; then
      pbcopy < "$context_file"
      copy_target="macOS clipboard"
    fi

    line_count=$(wc -l < "$buffer_file" | tr -d ' ')
    context_lines=$(wc -l < "$context_file" | tr -d ' ')

    print -r -- "[grab] copy ${run_no}: stdin ${line_count} lines; context ${context_lines} lines copied to ${copy_target}" >&2
    exit 0
  fi
fi


mode="smart"

# Range extraction mode:
# grab 500 635 file.cs "OptionalLabel"

# if [[ $# -ge 3 ]] \
#   && [[ "$1" =~ '^[0-9]+$' ]] \
#   && [[ "$2" =~ '^[0-9]+$' ]] \
#   && [[ -f "$3" ]]; then

if [[ $# -ge 3 ]] \
  && [[ "$1" == <-> ]] \
  && [[ "$2" == <-> ]] \
  && [[ -f "$3" ]]; then

  start_line="$1"
  end_line="$2"
  target_file="$3"

  if [[ $# -ge 4 ]]; then
    label_parts=("${@:4}")
    label="${(j: :)label_parts}"
  else
    label="$(basename "$target_file"):$start_line-$end_line"
  fi

  buffer_dir="${GRAB_BUFFER_DIR:-$HOME/.cache/grab}"
  buffer_file="${GRAB_BUFFER_FILE:-$buffer_dir/buffer.txt}"
  context_file="${GRAB_CONTEXT_FILE:-$buffer_dir/context.txt}"
  counter_file="${GRAB_COUNTER_FILE:-$buffer_dir/counter.txt}"
  mkdir -p "$buffer_dir"

  sed -n "${start_line},${end_line}p" "$target_file" > "$buffer_file"

  if [[ ! -f "$context_file" ]]; then
    : > "$context_file"
  fi

  if [[ ! -f "$counter_file" ]]; then
    print -r -- "0" > "$counter_file"
  fi

  run_no="$(cat "$counter_file" 2>/dev/null || print -r -- 0)"
  run_no=$((run_no + 1))
  print -r -- "$run_no" > "$counter_file"

  {
    print -r -- ""
    print -r -- "==================== grab copy ${run_no} ===================="
    print -r -- "source: range extract"
    print -r -- "file: $target_file"
    print -r -- "lines: ${start_line}-${end_line}"
    print -r -- "label: $label"
    print -r -- "============================================================="
    cat "$buffer_file"
  } >> "$context_file"

  cat "$buffer_file"

  copy_target="none"

  if [[ -n "${TMUX:-}" ]] && command -v tmux >/dev/null 2>&1; then
    tmux load-buffer "$context_file"
    copy_target="tmux buffer"
  elif command -v wl-copy >/dev/null 2>&1 && [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
    wl-copy < "$context_file"
    copy_target="Wayland clipboard"
  elif command -v xclip >/dev/null 2>&1 && [[ -n "${DISPLAY:-}" ]]; then
    xclip -selection clipboard -in < "$context_file"
    copy_target="X clipboard via xclip"
  elif command -v pbcopy >/dev/null 2>&1; then
    pbcopy < "$context_file"
    copy_target="macOS clipboard"
  fi

  line_count=$(wc -l < "$buffer_file" | tr -d ' ')

  print -r -- "[grab] extracted ${line_count} lines copied to ${copy_target}" >&2

  exit 0
fi



if [[ "${1:-}" == "--all" ]]; then
  mode="all"
  shift
fi


if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

pattern="$1"
shift || true


if [[ $# -gt 0 ]]; then
  paths=("$@")
else
  paths=(.)
fi

buffer_dir="${GRAB_BUFFER_DIR:-$HOME/.cache/grab}"
buffer_file="${GRAB_BUFFER_FILE:-$buffer_dir/buffer.txt}"          # latest result
context_file="${GRAB_CONTEXT_FILE:-$buffer_dir/context.txt}"       # accumulated results
counter_file="${GRAB_COUNTER_FILE:-$buffer_dir/counter.txt}"
tmp_color_file="${buffer_file}.color.tmp"

mkdir -p "$buffer_dir"


cleanup() {
  rm -f "$tmp_color_file"
}
trap cleanup EXIT


: > "$buffer_file"
: > "$tmp_color_file"

if [[ ! -f "$context_file" ]]; then
  : > "$context_file"
fi

if [[ ! -f "$counter_file" ]]; then
  print -r -- "0" > "$counter_file"
fi



type_filters=()

if [[ "$mode" == "smart" ]]; then
  type_filters=(
    --glob '**/*.{cs,js,jsx,ts,tsx,py,sh,bash,zsh}'
    --glob '**/*.{html,css,scss}'
    --glob '**/*.{json,yaml,yml,toml,ini,conf,env,sql}'
    --glob '**/*.{md,txt,rst}'
  )
fi


# if [[ "$mode" == "code" ]]; then
#   type_filters=(
#     --glob '**/*.cs'
#     --glob '**/*.js'
#     --glob '**/*.jsx'
#     --glob '**/*.ts'
#     --glob '**/*.tsx'
#     --glob '**/*.py'
#     --glob '**/*.sh'
#   )
# elif [[ "$mode" == "docs" ]]; then
#   type_filters=(
#     --glob '**/*.md'
#     --glob '**/*.txt'
#     --glob '**/*.rst'
#   )
# elif [[ "$mode" == "config" ]]; then
#   type_filters=(
#     --glob '**/*.json'
#     --glob '**/*.yaml'
#     --glob '**/*.yml'
#     --glob '**/*.toml'
#     --glob '**/*.ini'
#     --glob '**/*.conf'
#     --glob '**/*.env'
#     --glob '**/*.sql'
#   )
# fi

common_args=(
  -n
  --color always
  --max-columns 300
  --max-columns-preview
  --max-filesize 2M

  # selected mode file types
  "${type_filters[@]}"

  # dirs
  --glob '!**/node_modules/**'
  --glob '!**/.git/**'
  --glob '!**/dist/**'
  --glob '!**/build/**'
  --glob '!**/coverage/**'
  --glob '!**/tmp/**'
  --glob '!**/vendor/**'
  --glob '!**/__pycache__/**'
  --glob '!**/.venv/**'
  --glob '!**/venv/**'
  --glob '!**/bin/**'
  --glob '!**/obj/**'

  # files
  --glob '!**/*.min.js'
  --glob '!**/*.min.css'
  --glob '!**/*.map'
  --glob '!**/*.bundle.js'
  --glob '!**/*.chunk.js'
  --glob '!**/*.generated.*'
  --glob '!**/*bak*'
  --glob '!**/deoplete.log'
  --glob '!**/state.json'
  --glob '!**/state.json.bak'
  --glob '!**/*.lock'
)

set +e
rg "${common_args[@]}" "$pattern" "${paths[@]}" | tee "$tmp_color_file"
pipe_status=("${pipestatus[@]}")
set -e

rg_status="${pipe_status[1]:-${pipe_status[0]:-0}}"
# Strip ANSI color codes before saving/copying.
perl -pe 's/\e\[[0-9;]*m//g' "$tmp_color_file" > "$buffer_file"

run_no="$(cat "$counter_file" 2>/dev/null || print -r -- 0)"
run_no=$((run_no + 1))
print -r -- "$run_no" > "$counter_file"

{
  print -r -- ""
  print -r -- "==================== grab copy ${run_no} ===================="
  print -r -- "pattern: $pattern"
  print -r -- "mode: $mode"
  print -r -- "path: ${paths[*]}"
  print -r -- "============================================================="
  cat "$buffer_file"
} >> "$context_file"

line_count=$(wc -l < "$buffer_file" | tr -d ' ')
byte_count=$(wc -c < "$buffer_file" | tr -d ' ')

if [[ "$rg_status" -eq 1 ]]; then
  print -r -- "[grab] no matches. clean buffer saved: $buffer_file" >&2
  exit 1
elif [[ "$rg_status" -ne 0 ]]; then
  print -r -- "[grab] rg failed with status $rg_status. clean buffer saved: $buffer_file" >&2
  exit "$rg_status"
fi

copy_target="none"

if [[ -n "${TMUX:-}" ]] && command -v tmux >/dev/null 2>&1; then
  tmux load-buffer "$context_file"
  copy_target="tmux buffer"
elif command -v wl-copy >/dev/null 2>&1 && [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
  wl-copy < "$context_file"
  copy_target="Wayland clipboard"
elif command -v xclip >/dev/null 2>&1 && [[ -n "${DISPLAY:-}" ]]; then
  xclip -selection clipboard -in < "$context_file"
  copy_target="X clipboard via xclip"
elif command -v pbcopy >/dev/null 2>&1; then
  pbcopy < "$context_file"
  copy_target="macOS clipboard"
fi


if [[ "$copy_target" == "none" ]]; then
  print -r -- "[grab] latest ${line_count} lines / ${byte_count} bytes saved to:"
  print -r -- "  latest : $buffer_file"
else
  context_lines=$(wc -l < "$context_file" | tr -d ' ')
  context_bytes=$(wc -c < "$context_file" | tr -d ' ')

  print -r -- "[grab] copy ${run_no}: latest ${line_count} lines / ${byte_count} bytes"
  print -r -- "  latest : $buffer_file"
  print -r -- "  context: $context_file"
  print -r -- "  size   : ${context_lines} lines / ${context_bytes} bytes"
  print -r -- "  copied : ${copy_target}"
fi
