" vim: et sw=2 sts=2

" Plugin:      https://github.com/mhinz/vim-startify
" Description: A fancy start screen for Vim.
" Maintainer:  Marco Hinz <http://github.com/mhinz>

if exists('g:autoloaded_startify') || &compatible
  finish
endif
let g:autoloaded_startify = 1

" Init: values {{{1
let s:numfiles       = get(g:, 'startify_files_number', 10)
let s:show_special   = get(g:, 'startify_enable_special', 1)
let s:delete_buffers = get(g:, 'startify_session_delete_buffers')
let s:relative_path  = get(g:, 'startify_relative_path') ? ':.' : ':p:~'
let s:session_dir    = resolve(expand(get(g:, 'startify_session_dir',
      \ has('win32') ? '$HOME\vimfiles\session' : '~/.vim/session')))

let s:skiplist = get(g:, 'startify_skiplist', [
      \ 'COMMIT_EDITMSG',
      \ escape(fnamemodify($VIMRUNTIME, ':p'), '\') .'doc',
      \ 'bundle/.*/doc',
      \ ])

" Function: #get_separator {{{1
function! startify#get_separator() abort
  return !exists('+shellslash') || &shellslash ? '/' : '\'
endfunction

let s:sep = startify#get_separator()

" Function: #get_lastline {{{1
function! startify#get_lastline() abort
  return s:lastline + 1
endfunction

" Function: #insane_in_the_membrane {{{1
function! startify#insane_in_the_membrane() abort
  if &insertmode
    return
  endif

  if !empty(v:servername) && exists('g:startify_skiplist_server')
    for servname in g:startify_skiplist_server
      if servname == v:servername
        return
      endif
    endfor
  endif

  setlocal
        \ bufhidden=wipe
        \ buftype=nofile
        \ nobuflisted
        \ nocursorcolumn
        \ nocursorline
        \ nolist
        \ nonumber
        \ noswapfile
  if empty(&statusline)
    setlocal statusline=\ startify
  endif
  if v:version >= 703
    setlocal norelativenumber
  endif

  if exists('g:startify_custom_header')
    call append('$', g:startify_custom_header)
  endif

  let s:tick = 0
  let s:entries = {}

  if s:show_special
    call append('$', ['   [e]  <empty buffer>', ''])
  endif
  call s:register(line('$')-1, 'e', 'special', 'enew', '')

  let s:entry_number = 0
  if filereadable('Session.vim')
    call append('$', ['   [0]  '. getcwd() . s:sep .'Session.vim', ''])
    call s:register(line('$')-1, '0', 'session',
          \ 'call startify#session_delete_buffers() | source', 'Session.vim')
    let s:entry_number = 1
    let l:show_session = 1
  endif

  if empty(v:oldfiles)
    echohl WarningMsg
    echomsg "startify: Can't read viminfo file.  Read :help startify-faq-02"
    echohl NONE
  endif

  let b:startify_section_header_lines = []
  let s:lists = get(g:, 'startify_list_order', [
        \ ['   Most recently used files:'],
        \ 'files',
        \ ['   Most recently used files in the current directory:'],
        \ 'dir',
        \ ['   My sessions:'],
        \ 'sessions',
        \ ['   My bookmarks:'],
        \ 'bookmarks',
        \ ])

  for item in s:lists
    if type(item) == 1
      call s:show_{item}()
    else
      let s:last_message = item
    endif
    unlet item
  endfor

  silent $delete _

  if s:show_special
    call append('$', ['', '   [q]  <quit>'])
    call s:register(line('$'), 'q', 'special', 'call s:close()', '')
  else
    " Don't overwrite the last regular entry, thus +1
    call s:register(line('$')+1, 'q', 'special', 'call s:close()', '')
  endif

  " compute first line offset
  let s:firstline = 2
  " increase offset if there is a custom header
  if exists('g:startify_custom_header')
    let s:firstline += len(g:startify_custom_header)
  endif
  " no special, no local Session.vim, but a section header
  if !s:show_special && !exists('l:show_session') && type(s:lists[0]) == 3
    let s:firstline += len(s:lists[0]) + 1
  endif

  let s:lastline = line('$')

  if exists('g:startify_custom_footer')
    call append('$', g:startify_custom_footer)
  endif

  setlocal nomodifiable nomodified

  call s:set_mappings()
  call cursor(s:firstline + (s:show_special ? 2 : 0), 5)
  autocmd startify CursorMoved <buffer> call s:set_cursor()

  set filetype=startify
  silent! doautocmd <nomodeline> User Startified
endfunction

" Function: #session_load {{{1
function! startify#session_load(...) abort
  if !isdirectory(s:session_dir)
    echomsg 'The session directory does not exist: '. s:session_dir
    return
  elseif empty(startify#session_list_as_string(''))
    echomsg 'There are no sessions...'
    return
  endif
  call inputsave()
  let spath = s:session_dir . s:sep . (exists('a:1')
        \ ? a:1
        \ : input('Load this session: ', fnamemodify(v:this_session, ':t'), 'custom,startify#session_list_as_string'))
        \ | redraw
  call inputrestore()
  if filereadable(spath)
    if get(g:, 'startify_session_persistence')
          \ && exists('v:this_session')
          \ && filewritable(v:this_session)
      call startify#session_write(fnameescape(v:this_session))
    endif
    call startify#session_delete_buffers()
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

  call inputsave()
  let sname = exists('a:1')
        \ ? a:1
        \ : input('Save under this session name: ', fnamemodify(v:this_session, ':t'), 'custom,startify#session_list_as_string')
        \ | redraw
  call inputrestore()

  if empty(sname)
    echo 'You gave an empty name!'
    return
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

" Function: #session_close {{{1
function! startify#session_close() abort
  if exists('v:this_session') && filewritable(v:this_session)
    call startify#session_write(fnameescape(v:this_session))
    let v:this_session = ''
  endif
  call startify#session_delete_buffers()
  Startify
endfunction

" Function: #session_write {{{1
function! startify#session_write(spath)
  " if this function is called while being in the Startify buffer
  " (by loading another session or running :SSave/:SLoad directly)
  " switch back to the previous buffer before saving the session
  if &filetype == 'startify'
    let callingbuffer = bufnr('#')
    if callingbuffer > 0
      execute 'buffer' callingbuffer
    endif
  endif
  " prevent saving already deleted buffers that were in the arglist
  for arg in argv()
    if !buflisted(arg)
      execute 'silent! argdelete' fnameescape(arg)
    endif
  endfor

  let ssop = &sessionoptions
  set sessionoptions-=options
  try
    execute 'mksession!' a:spath
  catch
    echohl ErrorMsg
    echomsg v:exception
    echohl NONE
    return
  finally
    let &sessionoptions = ssop
  endtry

  if exists('g:startify_session_remove_lines')
        \ || exists('g:startify_session_savevars')
        \ || exists('g:startify_session_savecmds')
    execute 'split' a:spath

    " remove lines from the session file
    if exists('g:startify_session_remove_lines')
      for pattern in g:startify_session_remove_lines
        execute 'silent global/'. pattern .'/delete _'
      endfor
    endif

    " put existing variables from savevars into session file
    if exists('g:startify_session_savevars')
      call append(line('$')-3, map(filter(copy(g:startify_session_savevars), 'exists(v:val)'), '"let ". v:val ." = ". strtrans(string(eval(v:val)))'))
    endif

    " put commands from savecmds into session file
    if exists('g:startify_session_savecmds')
      call append(line('$')-3, g:startify_session_savecmds)
    endif

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

  call inputsave()
  let spath = s:session_dir . s:sep . (exists('a:1')
        \ ? a:1
        \ : input('Delete this session: ', fnamemodify(v:this_session, ':t'), 'custom,startify#session_list_as_string'))
        \ | redraw
  call inputrestore()

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

" Function: #debug {{{1
function! startify#debug()
  if exists('s:entries')
    for k in sort(keys(s:entries))
      echomsg '['. k .'] = '. string(s:entries[k])
    endfor
  endif
endfunction

" Function: #open_buffers {{{1
function! startify#open_buffers(...) abort
  if exists('a:1')  " used in mappings
    call s:open_buffer(s:entries[a:1])
    return
  endif

  let marked = filter(copy(s:entries), 'v:val.marked')
  if empty(marked)  " open current entry
    call s:open_buffer(s:entries[line('.')])
    return
  endif

  enew
  setlocal nobuflisted

  " Open all marked entries.
  for entry in sort(values(marked), 's:sort_by_tick')
    call s:open_buffer(entry)
  endfor

  wincmd =
endfunction

" Function: s:open_buffer {{{1
function! s:open_buffer(entry)
  if a:entry.type == 'special'
    execute a:entry.cmd
  elseif a:entry.type == 'session'
    execute a:entry.cmd a:entry.path
  elseif a:entry.type == 'file'
    if line2byte('$') == -1
      execute 'edit' a:entry.path
    else
      if a:entry.cmd == 'tabnew'
        wincmd =
      endif
      execute a:entry.cmd a:entry.path
    endif
    call s:check_user_options()
  endif
endfunction

" Function: s:display_by_path {{{1
function! s:display_by_path(path_prefix, path_format) abort
  let oldfiles = call(get(g:, 'startify_enable_unsafe') ? 's:filter_oldfiles_unsafe' : 's:filter_oldfiles',
        \ [a:path_prefix, a:path_format])

  if !empty(oldfiles)
    if exists('s:last_message')
      call s:print_section_header()
    endif

    for [absolute_path, entry_path] in oldfiles
      let index = s:get_index_as_string(s:entry_number)
      call append('$', '   ['. index .']'. repeat(' ', (3 - strlen(index))) . entry_path)
      if has('win32')
        let absolute_path = substitute(absolute_path, '\[', '\[[]', 'g')
      endif
      call s:register(line('$'), index, 'file', 'edit', absolute_path)
      let s:entry_number += 1
    endfor

    call append('$', '')
  endif
endfunction

" Function: s:filter_oldfiles {{{1
function! s:filter_oldfiles(path_prefix, path_format) abort
  let path_prefix = '\V'. escape(a:path_prefix, '\')
  let counter     = s:numfiles
  let entries     = {}
  let oldfiles    = []

  for fname in v:oldfiles
    if counter <= 0
      break
    endif

    let absolute_path = fnamemodify(resolve(fname), ":p")

    " filter duplicates, bookmarks and entries from the skiplist
    if has_key(entries, absolute_path)
          \ || !filereadable(absolute_path)
          \ || s:is_in_skiplist(absolute_path)
          \ || (exists('g:startify_bookmarks') && s:is_bookmark(absolute_path))
          \ || match(absolute_path, path_prefix)
      continue
    endif

    let entry_path              = fnamemodify(absolute_path, a:path_format)
    let entries[absolute_path]  = 1
    let counter                -= 1
    let oldfiles               += [[fnameescape(absolute_path), entry_path]]
  endfor

  return oldfiles
endfun

" Function: s:filter_oldfiles_unsafe {{{1
function! s:filter_oldfiles_unsafe(path_prefix, path_format) abort
  let path_prefix = '\V'. escape(a:path_prefix, '\')
  let counter     = s:numfiles
  let entries     = {}
  let oldfiles    = []

  for fname in v:oldfiles
    if counter <= 0
      break
    endif

    let absolute_path = glob(fnamemodify(fname, ":p"))
    if empty(absolute_path)
          \ || has_key(entries, absolute_path)
          \ || s:is_in_skiplist(absolute_path)
          \ || match(absolute_path, path_prefix)
      continue
    endif

    let entry_path              = fnamemodify(absolute_path, a:path_format)
    let entries[absolute_path]  = 1
    let counter                -= 1
    let oldfiles               += [[fnameescape(absolute_path), entry_path]]
  endfor

  return oldfiles
endfun

" Function: s:show_dir {{{1
function! s:show_dir() abort
  return s:display_by_path(getcwd(), ':.')
endfunction

" Function: s:show_files {{{1
function! s:show_files() abort
  return s:display_by_path('', s:relative_path)
endfunction

" Function: s:show_sessions {{{1
function! s:show_sessions() abort
  let sfiles = split(globpath(s:session_dir, '*'), '\n')
  if empty(sfiles)
    if exists('s:last_message')
      unlet s:last_message
    endif
    return
  endif

  if exists('s:last_message')
    call s:print_section_header()
  endif

  for i in range(len(sfiles))
    let index = s:get_index_as_string(s:entry_number)
    let fname = fnamemodify(sfiles[i], ':t')
    call append('$', '   ['. index .']'. repeat(' ', (3 - strlen(index))) . fname)
    if has('win32')
      let fname = substitute(fname, '\[', '\[[]', 'g')
    endif
    call s:register(line('$'), index, 'session', 'SLoad', fname)
    let s:entry_number += 1
  endfor

  call append('$', '')
endfunction

" Function: s:show_bookmarks {{{1
function! s:show_bookmarks() abort
  if !exists('g:startify_bookmarks') || empty(g:startify_bookmarks)
    return
  endif

  if exists('s:last_message')
    call s:print_section_header()
  endif

  for fname in g:startify_bookmarks
    let index = s:get_index_as_string(s:entry_number)
    call append('$', '   ['. index .']'. repeat(' ', (3 - strlen(index))) . fname)
    if has('win32')
      let fname = substitute(fname, '\[', '\[[]', 'g')
    endif
    call s:register(line('$'), index, 'file', 'edit', fname)
    let s:entry_number += 1
  endfor

  call append('$', '')
endfunction

" Function: s:is_in_skiplist {{{1
function! s:is_in_skiplist(arg) abort
  for regexp in s:skiplist
    try
      if a:arg =~# regexp
        return 1
      endif
    catch
      echohl WarningMsg
      echomsg 'startify: Pattern '. string(regexp) .' threw an exception. Read :help g:startify_skiplist'
      echohl NONE
    endtry
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
  while index(b:startify_section_header_lines, s:newline) != -1
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

" Function: s:set_mappings {{{1
function! s:set_mappings() abort
  for k in keys(s:entries)
    execute 'nnoremap <buffer><silent>' s:entries[k].index
          \ ':call startify#open_buffers('. string(k) .')<cr>'
  endfor

  nnoremap <buffer><silent> i             :enew <bar> startinsert<cr>
  nnoremap <buffer><silent> <insert>      :enew <bar> startinsert<cr>
  nnoremap <buffer><silent> b             :call <sid>set_mark('B')<cr>
  nnoremap <buffer><silent> s             :call <sid>set_mark('S')<cr>
  nnoremap <buffer><silent> t             :call <sid>set_mark('T')<cr>
  nnoremap <buffer><silent> v             :call <sid>set_mark('V')<cr>
  nnoremap <buffer><silent> <cr>          :call startify#open_buffers()<cr>
  nnoremap <buffer><silent> <2-LeftMouse> :call startify#open_buffers()<cr>

  " Prevent 'nnoremap j gj' mappings, since they would break navigation.
  " (One can't leave the [x].)
  if !empty(maparg('j', 'n'))
    nnoremap <buffer> j j
  endif
  if !empty(maparg('k', 'n'))
    nnoremap <buffer> k k
  endif
endfunction

" Function: s:set_mark {{{1
function! s:set_mark(type, ...) abort
  let index = expand('<cword>')
  let line  = exists('a:1') ? a:1 : line('.')
  let entry = s:entries[line]

  if entry.type != 'file'
    return
  endif

  let default_cmds = {
        \ 'B': 'edit',
        \ 'S': 'split',
        \ 'V': 'vsplit',
        \ 'T': 'tabnew',
        \ }

  setlocal modifiable

  if entry.marked && index[0] == a:type
    let entry.cmd = 'edit'
    let entry.marked = 0
    execute 'normal! ci]'. entry.index
  else
    let entry.cmd = default_cmds[a:type]
    let entry.marked = 1
    let entry.tick = s:tick
    let s:tick += 1
    execute 'normal! ci]'. repeat(a:type, len(index))
  endif

  setlocal nomodifiable nomodified
endfunction

" Function: s:sort_by_tick {{{1
function! s:sort_by_tick(one, two)
  return a:one.tick - a:two.tick
endfunction

" Function: s:check_user_options {{{1
function! s:check_user_options() abort
  let path    = expand('%')
  let session = path . s:sep .'Session.vim'

  " change to VCS root directory
  if get(g:, 'startify_session_autoload') && filereadable(session)
    execute 'source' session
  elseif get(g:, 'startify_change_to_vcs_root')
    call s:cd_to_vcs_root(path)
  " change directory
  elseif get(g:, 'startify_change_to_dir', 1)
    if isdirectory(path)
      lcd %
    else
      lcd %:p:h
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
    if bufloaded(bufnr('#')) && bufnr('#') != bufnr('%')
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


" Function: s:print_section_header {{{1
function! s:print_section_header() abort
  $
  let curline = line('.')

  for lnum in range(curline, curline + len(s:last_message) + 1)
    call add(b:startify_section_header_lines, lnum)
  endfor

  call append('$', s:last_message + [''])
  unlet s:last_message
endfunction

" Function: s:register {{{1
function! s:register(line, index, type, cmd, path)
  let s:entries[a:line] = {
        \ 'index':  a:index,
        \ 'type':   a:type,
        \ 'cmd':    a:cmd,
        \ 'path':   a:path,
        \ 'marked': 0,
        \ }
endfunction
