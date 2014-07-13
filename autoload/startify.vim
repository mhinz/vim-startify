" vim: et sw=2 sts=2

" Plugin:      https://github.com/mhinz/vim-startify
" Description: Start screen displaying recently used stuff.
" Maintainer:  Marco Hinz <http://github.com/mhinz>
" Version:     1.8

if exists('g:autoloaded_startify') || &compatible
  finish
endif
let g:autoloaded_startify = 1

" Init: values {{{1
let s:numfiles         = get(g:, 'startify_files_number', 10)
let s:show_special     = get(g:, 'startify_enable_special', 1)
let s:restore_position = get(g:, 'startify_restore_position')
let s:delete_buffers   = get(g:, 'startify_session_delete_buffers')
let s:relative_path    = get(g:, 'startify_relative_path')
let s:session_dir      = resolve(expand(get(g:, 'startify_session_dir',
      \ has('win32') ? '$HOME\vimfiles\session' : '~/.vim/session')))

if exists('g:startify_list_order')
  let s:lists = g:startify_list_order
else
  let s:lists = [
        \ ['   Last recently opened files:'],
        \ 'files',
        \ ['   Last recently modified files in the current directory:'],
        \ 'dir',
        \ ['   My sessions:'],
        \ 'sessions',
        \ ['   My bookmarks:'],
        \ 'bookmarks',
        \ ]
endif

let s:secoff = type(s:lists[0]) == 3 ? (len(s:lists[0]) + 1) : 0
let s:section_header_lines = []

" Function: #get_separator {{{1
function! startify#get_separator() abort
  return !exists('+shellslash') || &shellslash ? '/' : '\'
endfunction

let s:sep = startify#get_separator()

" Function: #get_lastline {{{1
function! startify#get_lastline() abort
  return s:lastline
endfunction

" Function: #insane_in_the_membrane {{{1
function! startify#insane_in_the_membrane() abort
  if !empty(v:servername) && exists('g:startify_skiplist_server')
    for servname in g:startify_skiplist_server
      if servname == v:servername
        return
      endif
    endfor
  endif

  setlocal noswapfile nobuflisted buftype=nofile bufhidden=wipe
  setlocal nonumber nocursorline nocursorcolumn nolist statusline=\ startify
  set filetype=startify

  if v:version >= 703
    setlocal norelativenumber
  endif

  let cnt = 0
  let s:headoff = 2

  if exists('g:startify_custom_header')
    call append('$', g:startify_custom_header)
    let s:headoff += len(g:startify_custom_header)
  endif

  if s:show_special
    call append('$', ['   [e]  <empty buffer>', ''])
  endif

  if get(g:, 'startify_session_detection', 1) && filereadable('Session.vim')
    call append('$', ['   [0]  '. getcwd() . s:sep .'Session.vim', ''])
    execute 'nnoremap <buffer> 0 :source Session.vim<cr>'
    let cnt = 1
  endif

  for item in s:lists
    if type(item) == 1
      let cnt = s:show_{item}(cnt)
    else
      let s:last_message = item
    endif
    unlet item
  endfor

  silent $delete _

  for item in s:section_header_lines
    execute 'syntax region StartifySection start=/\%'. item .'l/ end=/$/'
  endfor

  if s:show_special
    call append('$', ['', '   [q]  <quit>'])
  endif

  let s:firstline = s:show_special ? s:headoff : (s:headoff + s:secoff)
  let s:lastline  = line('$')

  if exists('g:startify_custom_footer')
    call append('$', g:startify_custom_footer)
  endif

  setlocal nomodifiable nomodified

  nnoremap <buffer><silent> e             :enew<cr>
  nnoremap <buffer><silent> i             :enew <bar> startinsert<cr>
  nnoremap <buffer><silent> <insert>      :enew <bar> startinsert<cr>
  nnoremap <buffer><silent> b             :call <sid>set_mark('B')<cr>
  nnoremap <buffer><silent> s             :call <sid>set_mark('S')<cr>
  nnoremap <buffer><silent> t             :call <sid>set_mark('T')<cr>
  nnoremap <buffer><silent> v             :call <sid>set_mark('V')<cr>
  nnoremap <buffer>         <cr>          :call <sid>open_buffers(expand('<cword>'))<cr>
  nnoremap <buffer>         <2-LeftMouse> :execute 'normal' matchstr(getline('.'), '\w\+')<cr>
  nnoremap <buffer><silent> q             :call <sid>close()<cr>

  if exists('g:startify_empty_buffer_key')
    execute 'nnoremap <buffer><silent> '. g:startify_empty_buffer_key .' :enew<cr>'
  endif

  autocmd startify CursorMoved <buffer> call s:set_cursor()
  if s:restore_position
    autocmd startify BufReadPost * call s:restore_position()
  endif

  call cursor((s:show_special ? 2 : 0) + s:headoff + s:secoff, 5)

  silent! doautocmd <nomodeline> startify User Startified
endfunction

" Function: #session_load {{{1
function! startify#session_load(...) abort
  if !isdirectory(s:session_dir)
    echo 'The session directory does not exist: '. s:session_dir
    return
  elseif empty(startify#session_list_as_string(''))
    echo 'There are no sessions...'
    return
  endif
  call startify#session_delete_buffers()
  let spath = s:session_dir . s:sep . (exists('a:1')
        \ ? a:1
        \ : input('Load this session: ', fnamemodify(v:this_session, ':t'), 'custom,startify#session_list_as_string'))
        \ | redraw
  if filereadable(spath)
    execute 'source '. fnameescape(spath)
  else
    echo 'No such file: '. spath
  endif
endfunction

" Function: #session_save {{{1
function! startify#session_save(...) abort
  if !isdirectory(s:session_dir)
    if exists('*mkdir')
      echo 'The session directory does not exist: '. s:session_dir .'. Create it?  [y/n]'
      if (nr2char(getchar()) == 'y')
        call mkdir(s:session_dir, 'p')
      else
        echo
        return
      endif
    else
      echo 'The session directory does not exist: '. s:session_dir
      return
    endif
  endif

  if exists('a:1')
    let sname = a:1
  else
    let sname = input('Save under this session name: ', fnamemodify(v:this_session, ':t'), 'custom,startify#session_list_as_string')
    redraw
    if empty(sname)
      echo 'You gave an empty name!'
      return
    endif
  endif

  let spath = s:session_dir . s:sep . sname
  if !filereadable(spath)
    call startify#session_write(fnameescape(spath))
    echo 'Session saved under: '. spath
    return
  endif

  echo 'Session already exists. Overwrite?  [y/n]' | redraw
  if nr2char(getchar()) == 'y'
    call startify#session_write(fnameescape(spath))
    echo 'Session saved under: '. spath
  else
    echo 'Did NOT save the session!'
  endif
endfunction

" Function: #session_write {{{1
function! startify#session_write(spath)
  let ssop = &sessionoptions
  try
    set sessionoptions-=options
    execute 'mksession!' a:spath
  catch
    execute 'echoerr' string(v:exception)
  finally
    let &sessionoptions = ssop
  endtry

  if exists('g:startify_session_savevars') || exists('g:startify_session_savecmds')
    execute 'split' a:spath

    " put existing variables from savevars into session file
    call append(line('$')-3, map(filter(get(g:, 'startify_session_savevars', []), 'exists(v:val)'), '"let ". v:val ." = ". strtrans(string(eval(v:val)))'))

    " put commands from savecmds into session file
    call append(line('$')-3, get(g:, 'startify_session_savecmds', []))

    setlocal bufhidden=delete
    silent update
    silent hide
  endif
endfunction

" Function: #session_delete {{{1
function! startify#session_delete(...) abort
  if !isdirectory(s:session_dir)
    echo 'The session directory does not exist: '. s:session_dir
    return
  elseif empty(startify#session_list_as_string(''))
    echo 'There are no sessions...'
    return
  endif

  let spath = s:session_dir . s:sep . (exists('a:1')
        \ ? a:1
        \ : input('Delete this session: ', fnamemodify(v:this_session, ':t'), 'custom,startify#session_list_as_string'))
        \ | redraw

  echo 'Really delete '. spath .'? [y/n]' | redraw
  if (nr2char(getchar()) == 'y')
    if delete(spath) == 0
      echo 'Deleted session '. spath .'!'
    else
      echo 'Deletion failed!'
    endif
  else
    echo 'Deletion aborted!'
  endif
endfunction

" Function: #session_delete_buffers {{{1
function! startify#session_delete_buffers() abort
  if !s:delete_buffers
    return
  endif
  let n = 1
  while n <= bufnr('$')
    if buflisted(n)
      silent execute 'bdelete' n
    endif
    let n += 1
  endwhile
endfunction

" Function: #session_list {{{1
function! startify#session_list(lead, ...) abort
  return map(split(globpath(s:session_dir, '*'.a:lead.'*'), '\n'), 'fnamemodify(v:val, ":t")')
endfunction

" Function: #session_list_as_string {{{1
function! startify#session_list_as_string(lead, ...) abort
  return join(map(split(globpath(s:session_dir, '*'.a:lead.'*'), '\n'), 'fnamemodify(v:val, ":t")'), "\n")
endfunction

" Function: s:show_dir {{{1
function! s:show_dir(cnt) abort
  if empty(v:oldfiles)
    return a:cnt
  endif

  let cnt     = a:cnt
  let num     = s:numfiles
  let entries = {}
  let cwd     = escape(getcwd(), '\')
  let files   = filter(map(copy(v:oldfiles), 'resolve(fnamemodify(v:val, ":p"))'), 'match(v:val, cwd) == 0')

  if !empty(files)
    if exists('s:last_message')
      call s:print_section_header()
    endif

    for fname in files
      let fullpath = resolve(fnamemodify(glob(fname), ':p'))

      " filter duplicates, bookmarks and entries from the skiplist
      if has_key(entries, fullpath)
            \ || !filereadable(fullpath)
            \ || (exists('g:startify_skiplist')  && s:is_in_skiplist(fullpath))
            \ || (exists('g:startify_bookmarks') && s:is_bookmark(fullpath))
        continue
      endif

      let entries[fullpath] = 1
      let index = s:get_index_as_string(cnt)
      let display_fname = s:relative_path ? fnamemodify(glob(fname), ':.') : fnamemodify(glob(fname), ':p:~')

      call append('$', '   ['. index .']'. repeat(' ', (3 - strlen(index))) . display_fname)
      execute 'nnoremap <buffer><silent>' index ':edit' fnameescape(fname) '<bar> call <sid>check_user_options()<cr>'

      let cnt += 1
      let num -= 1

      if !num
        break
      endif
    endfor

    call append('$', '')
  endif

  return cnt
endfunction

" Function: s:show_files {{{1
function! s:show_files(cnt) abort
  if empty(v:oldfiles)
    return a:cnt
  endif

  if exists('s:last_message')
    call s:print_section_header()
  endif

  let cnt     = a:cnt
  let num     = s:numfiles
  let entries = {}

  for fname in v:oldfiles
    let fullpath = resolve(fnamemodify(glob(fname), ':p'))

    " filter duplicates, bookmarks and entries from the skiplist
    if has_key(entries, fullpath)
          \ || !filereadable(fullpath)
          \ || (exists('g:startify_skiplist')  && s:is_in_skiplist(fullpath))
          \ || (exists('g:startify_bookmarks') && s:is_bookmark(fullpath))
      continue
    endif

    let entries[fullpath] = 1
    let index = s:get_index_as_string(cnt)
    let display_fname = s:relative_path ? fnamemodify(glob(fname), ':.') : fnamemodify(glob(fname), ':p:~')

    call append('$', '   ['. index .']'. repeat(' ', (3 - strlen(index))) . display_fname)
    execute 'nnoremap <buffer><silent>' index ':edit' fnameescape(fname) '<bar> call <sid>check_user_options()<cr>'

    let cnt += 1
    let num -= 1

    if !num
      break
    endif
  endfor

  call append('$', '')

  return cnt
endfunction

" Function: s:show_sessions {{{1
function! s:show_sessions(cnt) abort
  let sfiles = split(globpath(s:session_dir, '*'), '\n')

  if empty(sfiles)
    if exists('s:last_message')
      unlet s:last_message
    endif
    return a:cnt
  endif

  if exists('s:last_message')
    call s:print_section_header()
  endif

  let cnt  = a:cnt
  let slen = len(sfiles)

  for i in range(slen)
    let index = s:get_index_as_string(cnt)

    call append('$', '   ['. index .']'. repeat(' ', (3 - strlen(index))) . fnamemodify(sfiles[i], ':t:r'))
    execute 'nnoremap <buffer><silent>' index ':source' fnameescape(sfiles[i]) '<cr>'

    let cnt += 1
  endfor

  call append('$', '')

  return cnt
endfunction

" Function: s:show_bookmarks {{{1
function! s:show_bookmarks(cnt) abort
  if !exists('g:startify_bookmarks')
    return a:cnt
  endif

  if exists('s:last_message')
    call s:print_section_header()
  endif

  let cnt = a:cnt

  for fname in g:startify_bookmarks
    let index = s:get_index_as_string(cnt)

    call append('$', '   ['. index .']'. repeat(' ', (3 - strlen(index))) . fname)
    execute 'nnoremap <buffer><silent>' index ':edit' fnameescape(fname) '<bar> call <sid>check_user_options()<cr>'

    let cnt += 1
  endfor

  call append('$', '')

  return cnt
endfunction

" Function: s:is_in_skiplist {{{1
function! s:is_in_skiplist(arg) abort
  for regexp in g:startify_skiplist
    if (a:arg =~# regexp)
      return 1
    endif
  endfor
endfunction

" Function: s:is_bookmark {{{1
function! s:is_bookmark(arg) abort
  for foo in map(filter(copy(g:startify_bookmarks), '!isdirectory(v:val)'), 'resolve(fnamemodify(v:val, ":p"))')
    if foo == a:arg
      return 1
    endif
  endfor
endfunction

" Function: s:set_cursor {{{1
function! s:set_cursor() abort
  let s:oldline = exists('s:newline') ? s:newline : 5
  let s:newline = line('.')

  " going up (-1) or down (1)
  let movement = 2 * (s:newline > s:oldline) - 1

  " skip section headers lines until an entry is found
  while index(s:section_header_lines, s:newline) != -1
    let s:newline += movement
  endwhile

  " skip blank lines between lists
  if empty(getline(s:newline))
    let s:newline += movement
  endif

  " don't go beyond first or last entry
  let s:newline = max([s:firstline, min([s:lastline, s:newline])])

  call cursor(s:newline, 5)
endfunction

" Function: s:set_mark {{{1
"
" Markers are saved in the s:marked dict using the follow format:
"   - s:marked[0]: ID
"   - s:marked[1]: path
"   - s:marked[2]: type (buffer, split, vsplit)
"
function! s:set_mark(type) abort
  if !exists('s:marked')
    let s:marked = {}
  endif

  let [id, path] = matchlist(getline('.'), '\v\[(.*)\]\s+(.*)')[1:2]

  if path =~# '\V<empty buffer>\|<quit>' || path =~# '^\w\+$'
    return
  endif

  setlocal modifiable

  " set markers
  if id =~# '[BSTV]'
    " replace marker by old ID
    execute 'normal! ci]'. remove(s:marked, line('.'))[0]
  else
    " save ID and replace it by the marker of the given type
    let s:marked[line('.')] = [id, path, a:type]
    execute 'normal! ci]'. repeat(a:type, len(id))
  endif

  setlocal nomodifiable nomodified
endfunction

" Function: s:open_buffers {{{1
function! s:open_buffers(cword) abort
  " markers found; open one or more buffers
  if exists('s:marked') && !empty(s:marked)
    enew
    setlocal nobuflisted

    for val in values(s:marked)
      let [path, type] = val[1:2]
      let path = fnameescape(path)

      if line2byte('$') == -1
        " open in current window
        execute 'edit' path
      elseif type == 'S'
        " open in split
        execute 'split' path
      elseif type == 'V'
        " open in vsplit
        execute 'vsplit' path
      elseif type == 'T'
        " open in tab
        execute 'tabnew' path
      else
        " open in current window
        execute 'edit' path
      endif

      call s:check_user_options()
    endfor

    " remove markers for next instance of :Startify
    if exists('s:marked')
      unlet s:marked
    endif
  " no markers found; open a single buffer
  else
    try
      execute 'normal' a:cword
    catch /E832/  " don't ask for undo encryption key twice
      edit
    catch /E325/  " swap file found
    endtry
  endif
endfunction

" Function: s:check_user_options {{{1
function! s:check_user_options() abort
  let path    = expand('%')
  let session = path . s:sep .'Session.vim'

  " autoload session
  if get(g:, 'startify_session_autoload') && filereadable(session)
    execute 'source' session
  " change to VCS root directory
  elseif get(g:, 'startify_change_to_vcs_root')
    call s:cd_to_vcs_root(path)
  " change directory
  elseif get(g:, 'startify_change_to_dir', 1)
    if isdirectory(path)
      lcd %
    else
      lcd %:h
    endif
  endif
endfunction

" Function: s:cd_to_vcs_root {{{1
function! s:cd_to_vcs_root(path) abort
  let dir = fnamemodify(a:path, ':p:h')
  for vcs in [ '.git', '.hg', '.bzr', '.svn' ]
    let root = finddir(vcs, dir .';')
    if !empty(root)
      execute 'cd '. fnamemodify(root, ':h')
      return
    endif
  endfor
endfunction

" Function: s:close {{{1
function! s:close() abort
  if len(filter(range(0, bufnr('$')), 'buflisted(v:val)'))
    if bufloaded(bufnr('#'))
      buffer #
    else
      bnext
    endif
  else
    quit
  endif
endfunction

" Function: s:get_index_as_string {{{1
function! s:get_index_as_string(idx) abort
  if exists('g:startify_custom_indices')
    let listlen = len(g:startify_custom_indices)
    return (a:idx < listlen) ? g:startify_custom_indices[a:idx] : string(a:idx - listlen)
  else
    return string(a:idx)
  endif
endfunction

" Function: s:restore_position {{{1
function! s:restore_position() abort
  autocmd! startify *
  if line("'\"") > 0 && line("'\"") <= line('$')
    call cursor(getpos("'\"")[1:])
  endif
endfunction

" Function: s:print_section_header {{{1
function! s:print_section_header() abort
  $
  let curline = line('.')

  for lnum in range(curline, curline + len(s:last_message) + 1)
    call add(s:section_header_lines, lnum)
  endfor

  call append('$', s:last_message + [''])
  unlet s:last_message
endfunction
