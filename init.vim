function! MoveTextOneCharSpace(direction)
    " Get the visual selection range
    let [line_start, line_end] = [line("'<"), line("'>")]
    let col_start = col("'<")

    " Create a vertical guide spanning the selected column across the entire visible window
    let vertical_marker_pattern = '\%'.col_start.'c'
    let vertical_guide_id = matchadd('VerticalGuide', vertical_marker_pattern, -1)

    " Move text based on the direction
    if a:direction == 'right'
        " Insert a space at the beginning of each selected line
        execute line_start . "," . line_end . "s/^/ /"
    elseif a:direction == 'left'
        " Remove a space from the beginning of each selected line
        execute line_start . "," . line_end . "s/^ \\{1}//"
    endif

    " Reselect the visual block to maintain user context
    normal! gv

    " Remove the vertical guide after a short delay
    call timer_start(1000, { -> matchdelete(vertical_guide_id) }) " Increase delay for better visibility
endfunction

" Mappings for visual mode operations
xnoremap <M-m> :<C-U>call MoveTextOneCharSpace('left')<CR>
xnoremap <M-.> :<C-U>call MoveTextOneCharSpace('right')<CR>

function! CommentLine() range
  let l:filetype = &filetype
  if l:filetype ==# 'cs' || l:filetype ==# 'csharp' || l:filetype ==# 'javascript'
    execute a:firstline . "," . a:lastline . "s/^/\\/\\/ /"
  elseif l:filetype ==# 'sh' || l:filetype ==# 'python' || l:filetype ==# 'i3config' || l:filetype ==# 'zsh' || l:filetype ==# 'tmux' || l:filetype ==# 'yaml'
    execute a:firstline . "," . a:lastline . "s/^/# /"
  elseif l:filetype ==# 'vim'
    execute a:firstline . "," . a:lastline . "s/^/\" /"
  elseif l:filetype ==# 'lua'
    execute a:firstline . "," . a:lastline . "s/^/-- /"
  endif
endfunction

function! UncommentLine() range
  let l:filetype = &filetype
  if l:filetype ==# 'cs' || l:filetype ==# 'csharp' || l:filetype ==# 'javascript'
    execute a:firstline . "," . a:lastline . "s/^\\(\\s*\\)\\/\\/ /\\1/e"
  elseif l:filetype ==# 'sh' || l:filetype ==# 'python' || l:filetype ==# 'i3config' || l:filetype ==# 'zsh' || l:filetype ==# 'tmux' || l:filetype ==# 'yaml'
    execute a:firstline . "," . a:lastline . "s/^\\(\\s*\\)# /\\1/e"
  elseif l:filetype ==# 'vim'
    execute a:firstline . "," . a:lastline . "s/^\\(\\s*\\)\" /\\1/e"
  elseif l:filetype ==# 'lua'
    execute a:firstline . "," . a:lastline . "s/^\\(\\s*\\)-- /\\1/e"
  endif
endfunction



function! HighlightToLine()
    let target_line = input("Highlight to line: ")
    if target_line =~ '^\d\+$'
        " Start visual selection from the current line and go to the target line
        execute "normal! V" . target_line . "G"
    else
        echo "Invalid line number. Please enter a valid number."
    endif
endfunction

nnoremap <silent> <Space>h :call HighlightToLine()<CR>

function! PasteAndHighlight()
    " Mark current cursor position before pasting
    let l:save_cursor = getpos(".")

    " Mark start of paste
    normal! m'[

    " Paste from clipboard
    normal! "+p

    " Mark end of paste
    normal! m']

    " Visually select only the pasted text
    execute "normal! '[V']"

    " Move cursor to end of pasted content
    call setpos('.', getpos("']"))
endfunction

" Normal mode: Paste from clipboard and highlight
nnoremap p :call PasteAndHighlight()<CR>

" Visual mode: Paste and highlight selection
vnoremap p :call PasteAndHighlight()<CR>

" Override `<C-v>` for pasting in terminal mode
nnoremap <C-v> :call PasteAndHighlight()<CR>
vnoremap <C-v> :call PasteAndHighlight()<CR>




      
function! SelectWholeFunction() abort
    normal! mz
    let l:filetype = &filetype

    " ---- C# path (method first, then class/type) ----
    if l:filetype ==# 'cs' || l:filetype ==# 'csharp'
        if s:SelectCSharpMethod()
            return
        endif
        if SelectWholeClass()
            return
        endif
        echo "No C# method or type block found."
        normal! `z
        return
    endif

    " ---- Generic path ----
    let l:start_pattern = ''
    let l:end_pattern = ''

    if l:filetype ==# 'python'
        let l:start_pattern = '^\s*def'
    elseif l:filetype ==# 'sh'
        let l:start_pattern = '^\s*function'
    elseif l:filetype ==# 'vim'
        let l:start_pattern = '^\s*function!'
        let l:end_pattern = '^\s*endfunction'
    elseif l:filetype ==# 'yaml' || l:filetype ==# 'ansible'
        let l:start_pattern = '^\s*\-\s*name:\|\s*\-$'
        let l:end_pattern   = '^\s*\-\s*name:\|\s*\-$'
    elseif l:filetype ==# 'javascript'
        let l:start_pattern = '^\s*function\s'
        let l:end_pattern   = '^\s*}'
    elseif l:filetype ==# 'java'
        let l:start_pattern = '^\s*\(public\|private\|protected\)\=\s*void\s\|^\s*\(public\|private\|protected\)\=\s*\w\+\s\+\w\+\s*('
        let l:end_pattern   = '^\s*}'
    elseif l:filetype ==# 'ruby'
        let l:start_pattern = '^\s*def\s'
        let l:end_pattern   = '^\s*end'
    else
        echo "Unsupported filetype: " . l:filetype
        normal! `z
        return
    endif

    let l:is_visual_mode = mode() ==# 'v' || mode() ==# 'V' || mode() ==# "\<C-V>"

    if !l:is_visual_mode
        let l:start_pos = search(l:start_pattern, 'bW')
        if l:start_pos == 0
            normal! `z
            return
        endif
        execute 'normal! ' . l:start_pos . 'G^'
        let l:start_indent = indent('.')
        normal! V
    else
        let l:start_indent = indent(line("'>"))
    endif

    if l:filetype ==# 'yaml' || l:filetype ==# 'ansible'
        let l:current_indent = indent('.')
        while 1
            normal! j
            if line('.') == line('$')
                break
            endif
            let l:next_line = getline('.')
            if l:next_line =~ l:end_pattern && indent('.') == l:current_indent
                normal! k
                break
            endif
        endwhile
    else
        while 1
            normal! j
            if line('.') == line('$') || (l:end_pattern !=# '' && getline('.') =~ l:end_pattern)
                break
            endif
            let l:current_line = getline('.')
            if l:current_line !~# '^\s*$' && (indent('.') <= l:start_indent || l:current_line =~ l:start_pattern)
                normal! k
                break
            endif
        endwhile
    endif

    if line("'<") == line("'>")
        normal! `z
    endif


function! SearchAndReplace()
    let search_term = escape(input('Enter search term: '), '/\')
    let replace_term = escape(input('Enter replacement term: '), '/\')
    execute '%s/'.search_term.'/'.replace_term.'/g'
endfunction

command! SReplace call SearchAndReplace()
nnoremap <Leader>r :SReplace<CR>



" Both call the same function
nnoremap <silent> <C-s> :call SelectWholeFunction()<CR>
nnoremap <silent> <M-s> :call SelectWholeFunction()<CR>

" Mappings to run the script
"nnoremap <leader>m :!python %<CR>
"nnoremap <leader>v :!dotnet run<CR>

xnoremap # :call CommentLine()<CR>
xnoremap @ :call UncommentLine()<CR>

      
set clipboard+=unnamedplus
set clipboard+=unnamed




      
endfunction

      
