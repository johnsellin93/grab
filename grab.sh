#!/usr/bin/env zsh
set -euo pipefail
# AI context grab for terminal workflows, search/extract → accumulate context → copy to clipboard.

usage() {
  cat <<'EOF'
Usage:
  grab <pattern> [path...]
  grab --all <pattern> [path...]
  grab <start> <end> <file> [label...]
  grab --clear
  grab --functions <file> [symbol]

Examples:
  grab variable /dir/proj
  grab --all VAR
  grab 500 635 file.cs HandleSetupHotkeys
  sed -n '500,635p' file.cs | grab HandleSetupHotkeys
  grab --clear
  grab --functions ./app.py
  grab --functions ./UserService.cs SaveUser

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

grab_print_footer() {
  local copy_target="$1"
  local context_file="$2"
  local added_lines="${3:-0}"
  local label="${4:-}"

  local context_lines
  local context_bytes
  local footer

  context_lines=$(wc -l < "$context_file" | tr -d ' ')
  context_bytes=$(wc -c < "$context_file" | tr -d ' ')

  footer="${added_lines}|${context_lines}|${context_bytes}|${copy_target}|${label}"

  grab_emit_footer "$footer"
}

grab_emit_footer() {
  local footer="$1"

  if [[ "${GRAB_DELAY_FOOTER:-0}" != "1" ]]; then
    local added_lines context_lines context_bytes copy_target label

    IFS='|' read -r added_lines context_lines context_bytes copy_target label <<< "$footer"

    print -r -- ""
    if [[ -n "$label" ]]; then
      print -r -- "[grab] ${label} +${added_lines}L → context ${context_lines}L / ${context_bytes}B copied to ${copy_target}"
    else
      print -r -- "[grab] +${added_lines}L → context ${context_lines}L / ${context_bytes}B copied to ${copy_target}"
    fi
    return
  fi

  local buffer_dir="${GRAB_BUFFER_DIR:-$HOME/.cache/grab}"
  local footer_queue="${buffer_dir}/footer_queue.txt"
  local footer_lock="${buffer_dir}/footer_queue.lock"

  mkdir -p "$buffer_dir"
  print -r -- "$footer" >> "$footer_queue"

  (
    exec 9>"$footer_lock"

    if ! flock -n 9; then
      exit 0
    fi

    sleep 1.0

    if [[ -s "$footer_queue" ]]; then
      local count total_added last_context_lines last_context_bytes last_copy_target
      count=$(wc -l < "$footer_queue" | tr -d ' ')
      total_added=0

      while IFS='|' read -r added_lines context_lines context_bytes copy_target label; do
        total_added=$((total_added + added_lines))
        last_context_lines="$context_lines"
        last_context_bytes="$context_bytes"
        last_copy_target="$copy_target"
      done < "$footer_queue"

      print -r -- ""
      print -r -- "[grab] appended ${count} blocks / +${total_added}L → context ${last_context_lines}L / ${last_context_bytes}B copied to ${last_copy_target}"

      while IFS='|' read -r added_lines context_lines context_bytes copy_target label; do
        if [[ -n "$label" ]]; then
          print -r -- "  +${added_lines}L  ${label}"
        else
          print -r -- "  +${added_lines}L"
        fi
      done < "$footer_queue"

      : > "$footer_queue"
    fi
  ) &
}

grab_detect_symbol_name() {
  local file="$1"
  local start_line="$2"

  awk -v start="$start_line" '
    NR > start { exit }

    /^[[:space:]]*def[[:space:]]+/ ||
    /^[[:space:]]*async[[:space:]]+def[[:space:]]+/ ||
    /^[[:space:]]*function[[:space:]]+/ ||
    /^[[:space:]]*(public|private|protected|internal|static|async)/ {

      line=$0
      sub(/^[[:space:]]*/, "", line)

      sig=line
    }

    END {
      print sig
    }
  ' "$file"
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

#   print -r -- "[grab] cleared latest ${buffer_lines} lines and context ${context_lines} lines"
#   print -r -- "[grab] cleared:"
  print -r -- "[grab] cleared:"
  print -r -- "  latest buffer : ${buffer_lines} lines"
  print -r -- "  context stack : ${context_lines} lines"
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
  byte_count=$(wc -c < "$buffer_file" | tr -d ' ')
  context_lines=$(wc -l < "$context_file" | tr -d ' ')
  context_bytes=$(wc -c < "$context_file" | tr -d ' ')

  print -r -- "[grab] copy ${run_no}: latest ${line_count} lines / ${byte_count} bytes"
  print -r -- "  latest : $buffer_file"
  print -r -- "  context: $context_file"
  print -r -- "  size   : ${context_lines} lines / ${context_bytes} bytes"
  print -r -- "  copied : ${copy_target}"

  exit 0
#   line_count=$(wc -l < "$buffer_file" | tr -d ' ')
#
#   print -r -- "[grab] tree ${line_count} lines copied to ${copy_target}" >&2
#
#   exit 0
fi

if [[ "${1:-}" == "--functions" ]]; then
  shift

  target="${1:-.}"
  symbol="${2:-}"

  buffer_dir="${GRAB_BUFFER_DIR:-$HOME/.cache/grab}"
  buffer_file="${GRAB_BUFFER_FILE:-$buffer_dir/buffer.txt}"
  context_file="${GRAB_CONTEXT_FILE:-$buffer_dir/context.txt}"
  counter_file="${GRAB_COUNTER_FILE:-$buffer_dir/counter.txt}"

  mkdir -p "$buffer_dir"
  : > "$buffer_file"

  function_outline_awk='
    function flush(end_line) {
      if (start > 0) {
        len = end_line - start + 1

        extra = ""
        if (symbol != "" && hits != "") {
          extra = " [" symbol ": " hits "]"
        }

        print file ":" start "-" end_line " [" len "L] " sig extra
      }

      hits = ""
    }

    function add_hit(line_no, where) {
      if (symbol == "") return

      hit = where != "" ? where : line_no

      if (hits == "") hits = hit
      else hits = hits "," hit
    }

    function is_control_word(name) {
      return name ~ /^(if|for|foreach|while|switch|catch|using|lock|fixed|checked|unchecked|else|try|finally|do)$/
    }

    function clean_sig(line) {
      sub(/^[[:space:]]*/, "", line)
      sub(/[[:space:]]*\{[[:space:]]*$/, "", line)
      return line
    }

    function looks_like_function(line, tmp, first, before_paren, parts_count, parts) {
      tmp = line
      sub(/^[[:space:]]*/, "", tmp)

      if (tmp !~ /\(/ || tmp !~ /\)/) return 0

      first = tmp
      sub(/[[:space:]]*\(.*/, "", first)
      sub(/[[:space:]].*/, "", first)

      if (is_control_word(first)) return 0

      if (tmp ~ /^[A-Za-z_][A-Za-z0-9_]*[[:space:]]*\(.*\)[[:space:]]*\{?[[:space:]]*$/) return 1

      if (tmp ~ /^(public|private|protected|internal|static|virtual|override|sealed|async|partial|extern|new)[[:space:]]+/) return 1

      return 0
    }

    /^[[:space:]]*function[[:space:]]+[A-Za-z0-9_]+[[:space:]]*\(/ ||
    /^[[:space:]]*async[[:space:]]+function[[:space:]]+[A-Za-z0-9_]+[[:space:]]*\(/ ||
    /^[[:space:]]*(const|let|var)[[:space:]]+[A-Za-z0-9_]+[[:space:]]*=[[:space:]]*(async[[:space:]]*)?\(.*\)[[:space:]]*=>/ ||
    /^[[:space:]]*def[[:space:]]+[A-Za-z0-9_]+[[:space:]]*\(/ ||
    /^[[:space:]]*async[[:space:]]+def[[:space:]]+[A-Za-z0-9_]+[[:space:]]*\(/ ||
    looks_like_function($0) {

      flush(NR - 1)

      start = NR
      sig = clean_sig($0)

      if (symbol != "" && sig ~ symbol) {
        add_hit(NR, "signature")
      }

      next
    }

    start > 0 && symbol != "" && $0 ~ symbol {
      add_hit(NR, "")
    }

    END {
      flush(NR)
    }
  '
  files=()

  if [[ -f "$target" ]]; then
    files=("$target")
  else
    if [[ -d "$target" ]]; then
      search_root="$target"
      filter_symbol="$symbol"
    else
      search_root="."
      filter_symbol="$target"
    fi

    while IFS= read -r file_path; do
      files+=("$file_path")
    done < <(
      find "$search_root" \
        \( -path '*/node_modules/*' -o \
           -path '*/.git/*' -o \
           -path '*/dist/*' -o \
           -path '*/build/*' -o \
           -path '*/coverage/*' -o \
           -path '*/tmp/*' -o \
           -path '*/vendor/*' -o \
           -path '*/__pycache__/*' -o \
           -path '*/.venv/*' -o \
           -path '*/venv/*' -o \
           -path '*/bin/*' -o \
           -path '*/obj/*' \) \
        -prune -o \
        -type f \
        \( -name '*.cs' -o \
           -name '*.java' -o \
           -name '*.js' -o \
           -name '*.jsx' -o \
           -name '*.ts' -o \
           -name '*.tsx' -o \
           -name '*.py' \) \
        -print
    )

    symbol="$filter_symbol"
  fi

  if [[ "${#files[@]}" -eq 0 ]]; then
    print -r -- "[grab] no function-capable files found for: $target" >&2
    exit 1
  fi

  for function_file in "${files[@]}"; do
    awk -v file="$function_file" -v symbol="$symbol" "$function_outline_awk" "$function_file" >> "$buffer_file"
  done

  if [[ -n "$symbol" ]]; then
    tmp_filtered_file="${buffer_file}.filtered.tmp"

    grep -i -- "$symbol" "$buffer_file" > "$tmp_filtered_file" || true
    mv "$tmp_filtered_file" "$buffer_file"
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
    print -r -- "source: functions"
    print -r -- "target: $target"
    print -r -- "symbol: ${symbol:-<none>}"
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
  byte_count=$(wc -c < "$buffer_file" | tr -d ' ')
  context_lines=$(wc -l < "$context_file" | tr -d ' ')
  context_bytes=$(wc -c < "$context_file" | tr -d ' ')

  grab_print_footer "$copy_target" "$context_file" "$line_count" "functions:${target}"

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
    symbol_name="$(grab_detect_symbol_name "$target_file" "$start_line")"

    if [[ -n "$symbol_name" ]]; then
      label="$symbol_name"
    else
      label="$(basename "$target_file"):$start_line-$end_line"
    fi
  fi


  buffer_dir="${GRAB_BUFFER_DIR:-$HOME/.cache/grab}"
  buffer_file="${GRAB_BUFFER_FILE:-$buffer_dir/buffer.txt}"
  context_file="${GRAB_CONTEXT_FILE:-$buffer_dir/context.txt}"
  counter_file="${GRAB_COUNTER_FILE:-$buffer_dir/counter.txt}"
  tmp_color_file="${buffer_file}.color.tmp"

  mkdir -p "$buffer_dir"
  : > "$buffer_file"
  : > "$tmp_color_file"

  bat_cmd=""
  if command -v bat >/dev/null 2>&1; then
    bat_cmd="bat"
  elif command -v batcat >/dev/null 2>&1; then
    bat_cmd="batcat"
  fi

  if [[ -n "$bat_cmd" ]]; then
    "$bat_cmd" \
      --color=always \
      --style=plain \
      --paging=never \
      --line-range "${start_line}:${end_line}" \
      "$target_file" | tee "$tmp_color_file"

    perl -pe 's/\e\[[0-9;]*m//g' "$tmp_color_file" > "$buffer_file"
  else
    sed -n "${start_line},${end_line}p" "$target_file" | tee "$buffer_file"
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
    print -r -- "source: range"
    print -r -- "file: $target_file"
    print -r -- "lines: ${start_line}-${end_line}"
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
  byte_count=$(wc -c < "$buffer_file" | tr -d ' ')

  grab_print_footer "$copy_target" "$context_file" "$line_count" "$label"
  rm -f "$tmp_color_file"
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

grab_print_footer "$copy_target" "$context_file" "$line_count" "$pattern"
