" vim: et sw=2 sts=2

" Plugin:      https://github.com/mhinz/vim-startify
" Description: A fancy start screen for Vim.
" Maintainer:  Marco Hinz <http://github.com/mhinz>

if exists('g:autoloaded_startify') || &compatible
  finish
endif
let g:autoloaded_startify = 1

" Init: values {{{1
let s:nowait         = v:version >= 704 || (v:version == 703 && has('patch1261')) ? '<nowait>' : ''
let s:numfiles       = get(g:, 'startify_files_number', 10)
let s:show_special   = get(g:, 'startify_enable_special', 1)
let s:relative_path  = get(g:, 'startify_relative_path') ? ':~:.' : ':p:~'
let s:session_dir    = resolve(expand(get(g:, 'startify_session_dir',
      \ has('win32') ? '$HOME\vimfiles\session' : '~/.vim/session')))
let s:tf             = exists('g:startify_transformations')

let s:skiplist = get(g:, 'startify_skiplist', [
      \ 'COMMIT_EDITMSG',
      \ 'runtime/doc/.*\.txt',
      \ 'bundle/.*/doc/.*\.txt',
      \ 'plugged/.*/doc/.*\.txt',
      \ escape(fnamemodify(resolve($VIMRUNTIME), ':p'), '\') .'doc/.*\.txt',
      \ ])

let s:padding_left = repeat(' ', get(g:, 'startify_padding_left', 3))
let s:fixed_column = len(s:padding_left) + 2

" Function: #get_separator {{{1
function! startify#get_separator() abort
  return !exists('+shellslash') || &shellslash ? '/' : '\'
endfunction

let s:sep = startify#get_separator()

" Function: #get_lastline {{{1
function! startify#get_lastline() abort
  return b:startify.lastline + 1
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

  silent! setlocal
        \ bufhidden=wipe
        \ colorcolumn=
        \ nobuflisted
        \ nocursorcolumn
        \ nocursorline
        \ nolist
        \ nonumber
        \ norelativenumber
        \ nospell
        \ noswapfile
        \ matchpairs=
  if empty(&statusline)
    setlocal statusline=\ startify
  endif

  " Must be global so that it can be read by syntax/startify.vim.
  if exists('g:startify_custom_header')
    if type(g:startify_custom_header) == type([])
      let g:startify_header = copy(g:startify_custom_header)
    else
      let g:startify_header = eval(g:startify_custom_header)
    endif
  else
    let g:startify_header = startify#fortune#cowsay()
  endif
  if !empty(g:startify_header)
    let g:startify_header += ['']  " add blank line
  endif
  call append('$', g:startify_header)

  let b:startify = { 'tick': 0, 'entries': {} }

  if s:show_special
    call append('$', [s:padding_left .'[e]  <empty buffer>', ''])
  endif
  call s:register(line('$')-1, 'e', 'special', 'enew', '')

  let b:startify.entry_number = 0
  if filereadable('Session.vim')
    call append('$', [s:padding_left .'[0]  '. getcwd() . s:sep .'Session.vim', ''])
    call s:register(line('$')-1, '0', 'session',
          \ 'call startify#session_delete_buffers() | source', 'Session.vim')
    let b:startify.entry_number = 1
    let l:show_session = 1
  endif

  if empty(v:oldfiles)
    call s:warn("startify: Can't read viminfo file. Read :help startify-faq-02")
  endif

  let b:startify.section_header_lines = []
  let s:lists = get(g:, 'startify_list_order', [
        \ [s:padding_left .'MRU'],            'files',
        \ [s:padding_left .'MRU '. getcwd()], 'dir',
        \ [s:padding_left .'Sessions'],       'sessions',
        \ [s:padding_left .'Bookmarks'],      'bookmarks',
        \ [s:padding_left .'Commands'],       'commands',
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
    call append('$', ['', s:padding_left .'[q]  <quit>'])
    call s:register(line('$'), 'q', 'special', 'call s:close()', '')
  else
    " Don't overwrite the last regular entry, thus +1
    call s:register(line('$')+1, 'q', 'special', 'call s:close()', '')
  endif

  " compute first line offset
  let b:startify.firstline = 2
  let b:startify.firstline += len(g:startify_header)
  " no special, no local Session.vim, but a section header
  if !s:show_special && !exists('l:show_session') && type(s:lists[0]) == type([])
    let b:startify.firstline += len(s:lists[0]) + 1
  endif

  let b:startify.lastline = line('$')

  if exists('g:startify_custom_footer')
    call append('$', g:startify_custom_footer)
  endif

  setlocal nomodifiable nomodified

  call s:set_mappings()
  call cursor(b:startify.firstline, 5)
  autocmd startify CursorMoved <buffer> call s:set_cursor()

  silent! file Startify
  set filetype=startify readonly
  if exists('#User#Startified')
    if v:version > 703 || v:version == 703 && has('patch442')
      doautocmd <nomodeline> User Startified
    else
      doautocmd User Startified
    endif
  endif
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

  let spath = s:session_dir . s:sep

  if a:0
    let spath .= a:1
  else
    if has('win32')
      call inputsave()
      let spath .= input(
            \ 'Load this session: ',
            \ fnamemodify(v:this_session, ':t'),
            \ 'custom,startify#session_list_as_string') | redraw
      call inputrestore()
    else
      let spath .= '__LAST__'
    endif
  endif

  if filereadable(spath)
    if get(g:, 'startify_session_persistence') && filewritable(v:this_session)
      call startify#session_write(fnameescape(v:this_session))
    endif
    call startify#session_delete_buffers()
    execute 'source '. fnameescape(spath)
    call s:create_last_session_link(spath)
  else
    echo 'No such file: '. spath
  endif
endfunction

" Function: #session_save {{{1
function! startify#session_save(bang, ...) abort
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
  let vsession = fnamemodify(v:this_session, ':t')
  if vsession ==# '__LAST__'
    let vsession = ''
  endif
  let sname = exists('a:1')
        \ ? a:1
        \ : input('Save under this session name: ', vsession, 'custom,startify#session_list_as_string')
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
  if a:bang || nr2char(getchar()) == 'y'
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
  " clean up session before saving it
  for cmd in get(g:, 'startify_session_before_save', [])
    execute cmd
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
    silent execute 'split' a:spath

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

  call s:create_last_session_link(a:spath)
endfunction

" Function: #session_delete {{{1
function! startify#session_delete(bang, ...) abort
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

  if !filereadable(spath)
    echomsg 'No such session: '. spath
    return
  endif

  echo 'Really delete '. spath .'? [y/n]' | redraw
  if a:bang || nr2char(getchar()) == 'y'
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
function! startify#session_delete_buffers()
  if !get(g:, 'startify_session_delete_buffers', 1)
    return
  endif
  let n = 1
  while n <= bufnr('$')
    if buflisted(n)
      try
        silent execute 'bdelete' n
      catch
        echohl ErrorMsg
        echomsg v:exception
        echohl NONE
      endtry
    endif
    let n += 1
  endwhile
endfunction

" Function: #session_list {{{1
function! startify#session_list(lead, ...) abort
  return filter(map(split(globpath(s:session_dir, '*'.a:lead.'*'), '\n'), 'fnamemodify(v:val, ":t")'), 'v:val !=# "__LAST__"')
endfunction

" Function: #session_list_as_string {{{1
function! startify#session_list_as_string(lead, ...) abort
  return join(filter(map(split(globpath(s:session_dir, '*'.a:lead.'*'), '\n'), 'fnamemodify(v:val, ":t")'), 'v:val !=# "__LAST__"'), "\n")
endfunction

" Function: #debug {{{1
function! startify#debug()
  if exists('b:startify.entries')
    for k in sort(keys(b:startify.entries))
      echomsg '['. k .'] = '. string(b:startify.entries[k])
    endfor
  else
    call s:warn('This is no Startify buffer!')
  endif
endfunction

" Function: #open_buffers {{{1
function! startify#open_buffers(...) abort
  if exists('a:1')  " used in mappings
    call s:open_buffer(b:startify.entries[a:1])
    return
  endif

  let marked = filter(copy(b:startify.entries), 'v:val.marked')
  if empty(marked)  " open current entry
    call s:open_buffer(b:startify.entries[line('.')])
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
    call s:check_user_options(a:entry.path)
  endif
endfunction

" Function: s:display_by_path {{{1
function! s:display_by_path(path_prefix, path_format, use_env) abort
  let oldfiles = call(get(g:, 'startify_enable_unsafe') ? 's:filter_oldfiles_unsafe' : 's:filter_oldfiles',
        \ [a:path_prefix, a:path_format, a:use_env])

  let entry_format = "s:padding_left .'['. index .']'. repeat(' ', (3 - strlen(index)))"
  if exists('*WebDevIconsGetFileTypeSymbol') && get(g:, 'webdevicons_enable')
    " support for vim-devicons
    let entry_format .= ". WebDevIconsGetFileTypeSymbol(entry_path) .' '.  entry_path"
  else
    let entry_format .= '. entry_path'
  endif

  if !empty(oldfiles)
    if exists('s:last_message')
      call s:print_section_header()
    endif

    for [absolute_path, entry_path] in oldfiles
      let index = s:get_index_as_string(b:startify.entry_number)
      call append('$', eval(entry_format))
      if has('win32')
        let absolute_path = substitute(absolute_path, '\[', '\[[]', 'g')
      endif
      call s:register(line('$'), index, 'file', 'edit', absolute_path)
      let b:startify.entry_number += 1
    endfor

    call append('$', '')
  endif
endfunction

" Function: s:filter_oldfiles {{{1
function! s:filter_oldfiles(path_prefix, path_format, use_env) abort
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
          \ || match(absolute_path, path_prefix)
      continue
    endif

    let entry_path = ''
    if s:tf
      let entry_path = s:transform(absolute_path)
    endif
    if empty(entry_path)
      let entry_path = fnamemodify(absolute_path, a:path_format)
    endif

    let entries[absolute_path]  = 1
    let counter                -= 1
    if !has('win32')
      let absolute_path = fnameescape(absolute_path)
    endif
    let oldfiles += [[absolute_path, entry_path]]
  endfor

  if a:use_env
    call s:init_env()
    for i in range(len(oldfiles))
      for [k,v] in s:env
        let p = oldfiles[i][0]
        if !stridx(tolower(p), tolower(v))
          let oldfiles[i][1] = printf('$%s%s', k, p[len(v):])
          break
        endif
      endfor
    endfor
  endif

  return oldfiles
endfun

" Function: s:filter_oldfiles_unsafe {{{1
function! s:filter_oldfiles_unsafe(path_prefix, path_format, use_env) abort
  let path_prefix = '\V'. escape(a:path_prefix, '\')
  let counter     = s:numfiles
  let entries     = {}
  let oldfiles    = []
  let is_dir      = escape(s:sep, '\') . '$'

  for fname in v:oldfiles
    if counter <= 0
      break
    endif

    let absolute_path = glob(fnamemodify(fname, ":p"))
    if empty(absolute_path)
          \ || has_key(entries, absolute_path)
          \ || (absolute_path =~ is_dir)
          \ || match(absolute_path, path_prefix)
          \ || s:is_in_skiplist(absolute_path)
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
  return s:display_by_path(getcwd() . s:sep, ':.', 0)
endfunction

" Function: s:show_files {{{1
function! s:show_files() abort
  return s:display_by_path('', s:relative_path, get(g:, 'startify_use_env'))
endfunction

" Function: s:show_sessions {{{1
function! s:show_sessions() abort
  let limit = get(g:, 'startify_session_number', 999) - 1
  if limit <= -1
    return
  endif

  let sfiles = split(globpath(s:session_dir, '*'), '\n')
  let sfiles = filter(sfiles, 'v:val !~# "__LAST__$"')
  let sfiles = filter(sfiles,
        \ '!(v:val =~# "x\.vim$" && index(sfiles, v:val[:-6].".vim") >= 0)')
  if empty(sfiles)
    if exists('s:last_message')
      unlet s:last_message
    endif
    return
  endif

  if exists('s:last_message')
    call s:print_section_header()
  endif

  if get(g:, 'startify_session_sort')
    function! s:sort_by_mtime(foo, bar)
      let foo = getftime(a:foo)
      let bar = getftime(a:bar)
      return foo == bar ? 0 : (foo < bar ? 1 : -1)
    endfunction
    call sort(sfiles, 's:sort_by_mtime')
  endif

  for i in range(len(sfiles))
    let index = s:get_index_as_string(b:startify.entry_number)
    let fname = fnamemodify(sfiles[i], ':t')
    call append('$', s:padding_left .'['. index .']'. repeat(' ', (3 - strlen(index))) . fname)
    if has('win32')
      let fname = substitute(fname, '\[', '\[[]', 'g')
    endif
    call s:register(line('$'), index, 'session', 'SLoad', fname)
    let b:startify.entry_number += 1
    if i == limit
      break
    endif
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

  for bookmark in g:startify_bookmarks
    if type(bookmark) == type({})
      let [index, path] = items(bookmark)[0]
    else  " string
      let [index, path] = [s:get_index_as_string(b:startify.entry_number), bookmark]
      let b:startify.entry_number += 1
    endif

    let entry_path = ''
    if s:tf
      let entry_path = s:transform(fnamemodify(resolve(expand(path)), ':p'))
    endif
    if empty(entry_path)
      let entry_path = path
    endif
    call append('$', s:padding_left .'['. index .']'. repeat(' ', (3 - strlen(index))) . entry_path)

    if has('win32')
      let path = substitute(path, '\[', '\[[]', 'g')
    endif
    call s:register(line('$'), index, 'file', 'edit', fnameescape(expand(path)))

    unlet bookmark  " avoid type mismatch for heterogeneous lists
  endfor

  call append('$', '')
endfunction

" Function: s:show_commands {{{1
function! s:show_commands() abort
  if !exists('g:startify_commands') || empty(g:startify_commands)
    return
  endif

  if exists('s:last_message')
    call s:print_section_header()
  endif

  for entry in g:startify_commands
    if type(entry) == type({})  " with custom index
      let [index, command] = items(entry)[0]
    else
      let command = entry
      let index = s:get_index_as_string(b:startify.entry_number)
      let b:startify.entry_number += 1
    endif
    " If no list is given, the description is the command itself.
    let [desc, cmd] = type(command) == type([]) ? command : [command, command]

    call append('$', s:padding_left .'['. index .']'. repeat(' ', (3 - strlen(index))) . desc)
    call s:register(line('$'), index, 'special', cmd, '')

    unlet entry command
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
      call s:warn('startify: Pattern '. string(regexp) .' threw an exception. Read :help g:startify_skiplist')
    endtry
  endfor
endfunction

" Function: s:set_cursor {{{1
function! s:set_cursor() abort
  let b:startify.oldline = exists('b:startify.newline') ? b:startify.newline : 2 + len(s:padding_left)
  let b:startify.newline = line('.')

  " going up (-1) or down (1)
  if b:startify.oldline == b:startify.newline && col('.') != s:fixed_column
    let movement = 2 * (col('.') > s:fixed_column) - 1
    let b:startify.newline += movement
  else
  let movement = 2 * (b:startify.newline > b:startify.oldline) - 1
  endif

  " skip section headers lines until an entry is found
  while index(b:startify.section_header_lines, b:startify.newline) != -1
    let b:startify.newline += movement
  endwhile

  " skip blank lines between lists
  if empty(getline(b:startify.newline))
    let b:startify.newline += movement
  endif

  " don't go beyond first or last entry
  let b:startify.newline = max([b:startify.firstline, min([b:startify.lastline, b:startify.newline])])

  call cursor(b:startify.newline, s:fixed_column)
endfunction

" Function: s:set_mappings {{{1
function! s:set_mappings() abort
  execute "nnoremap <buffer>". s:nowait ."<silent> i             :enew <bar> startinsert<cr>"
  execute "nnoremap <buffer>". s:nowait ."<silent> <insert>      :enew <bar> startinsert<cr>"
  execute "nnoremap <buffer>". s:nowait ."<silent> b             :call <sid>set_mark('B')<cr>"
  execute "nnoremap <buffer>". s:nowait ."<silent> s             :call <sid>set_mark('S')<cr>"
  execute "nnoremap <buffer>". s:nowait ."<silent> t             :call <sid>set_mark('T')<cr>"
  execute "nnoremap <buffer>". s:nowait ."<silent> v             :call <sid>set_mark('V')<cr>"
  execute "nnoremap <buffer>". s:nowait ."<silent> <cr>          :call startify#open_buffers()<cr>"
  execute "nnoremap <buffer>". s:nowait ."<silent> <2-LeftMouse> :call startify#open_buffers()<cr>"
  execute "nnoremap <buffer>". s:nowait ."<silent> <MiddleMouse> :enew <bar> execute 'normal! \"'.(v:register=='\"'?'*':v:register).'gp'<cr>"

  " Without these mappings n/N wouldn't work properly, since autocmds always
  " force the cursor back on the index.
  nnoremap <buffer><expr> n ' j'[v:searchforward].'n'
  nnoremap <buffer><expr> N 'j '[v:searchforward].'N'

  function! s:compare_by_index(foo, bar)
    return a:foo.index - a:bar.index
  endfunction

  for entry in sort(values(b:startify.entries), 's:compare_by_index')
    execute 'nnoremap <buffer><silent>'. s:nowait entry.index
          \ ':call startify#open_buffers('. string(entry.line) .')<cr>'
  endfor
endfunction

" Function: s:set_mark {{{1
function! s:set_mark(type, ...) abort
  let index = expand('<cword>')
  let line  = exists('a:1') ? a:1 : line('.')
  let entry = b:startify.entries[line]

  if entry.type != 'file'
    return
  endif

  let default_cmds = {
        \ 'B': 'edit',
        \ 'S': 'split',
        \ 'V': 'vsplit',
        \ 'T': 'tabnew',
        \ }

  setlocal noreadonly modifiable

  if entry.marked && index[0] == a:type
    let entry.cmd = 'edit'
    let entry.marked = 0
    execute 'normal! ci]'. entry.index
  else
    let entry.cmd = default_cmds[a:type]
    let entry.marked = 1
    let entry.tick = b:startify.tick
    let b:startify.tick += 1
    execute 'normal! ci]'. repeat(a:type, len(index))
  endif

  " Reset cursor to fixed column, which is important for s:set_cursor().
  call cursor(line('.'), s:fixed_column)

  setlocal readonly nomodifiable nomodified
endfunction

" Function: s:sort_by_tick {{{1
function! s:sort_by_tick(one, two)
  return a:one.tick - a:two.tick
endfunction

" Function: s:check_user_options {{{1
function! s:check_user_options(path) abort
  let session = a:path . s:sep .'Session.vim'

  if get(g:, 'startify_session_autoload') && filereadable(glob(session))
    execute 'silent bwipeout' a:path
    call startify#session_delete_buffers()
    execute 'source' session
  elseif get(g:, 'startify_change_to_vcs_root')
    call s:cd_to_vcs_root(a:path)
  elseif get(g:, 'startify_change_to_dir', 1)
    if isdirectory(a:path)
      execute 'lcd' a:path
    else
      let dir = fnamemodify(a:path, ':h')
      if isdirectory(dir)
        execute 'lcd' dir
      else
        " Do nothing. E.g. a:path == `scp://foo/bar`
      endif
    endif
  endif
endfunction

" Function: s:cd_to_vcs_root {{{1
function! s:cd_to_vcs_root(path) abort
  let dir = fnamemodify(a:path, ':p:h')
  for vcs in [ '.git', '.hg', '.bzr', '.svn' ]
    let root = finddir(vcs, dir .';')
    if !empty(root)
      execute 'cd '. fnameescape(fnamemodify(root, ':h'))
      return
    endif
  endfor
endfunction

" Function: s:close {{{1
function! s:close() abort
  if len(filter(range(0, bufnr('$')), 'buflisted(v:val)')) - &buflisted
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
    call add(b:startify.section_header_lines, lnum)
  endfor

  call append('$', s:last_message + [''])
  unlet s:last_message
endfunction

" Function: s:register {{{1
function! s:register(line, index, type, cmd, path)
  let b:startify.entries[a:line] = {
        \ 'index':  a:index,
        \ 'type':   a:type,
        \ 'line':   a:line,
        \ 'cmd':    a:cmd,
        \ 'path':   a:path,
        \ 'marked': 0,
        \ }
endfunction

" Function: s:create_last_session_link {{{1
function! s:create_last_session_link(spath)
  if !has('win32') && a:spath !~# '__LAST__$'
    let cmd = printf('ln -sf %s %s',
          \ shellescape(fnamemodify(a:spath, ':t')),
          \ shellescape(s:session_dir .'/__LAST__'))
    call system(cmd)
    if v:shell_error
      echomsg "startify: Can't create 'last used session' symlink."
    endif
  endif
endfunction

" Function: s:init_env {{{1
function! s:init_env()
  let s:env = []
  let ignore = {
        \ 'HOME':   1,
        \ 'OLDPWD': 1,
        \ 'PWD':    1,
        \ }

  function! s:get_env()
    redir => s
      silent! execute "norm!:ec$\<c-a>'\<c-b>\<right>\<right>\<del>'\<cr>"
    redir END
    redraw
    return split(s)
  endfunction

  function! s:compare_by_key_len(foo, bar)
    return len(a:foo[0]) - len(a:bar[0])
  endfunction
  function! s:compare_by_val_len(foo, bar)
    return len(a:bar[1]) - len(a:foo[1])
  endfunction

  for k in s:get_env()
    silent! execute "let v = eval('$'.k)"
    if has('win32') ? (v[1] != ':') : (v[0] != '/')
          \ || has_key(ignore, k)
          \ || len(k) > len(v)
      continue
    endif
    call insert(s:env, [k,v], 0)
  endfor

  let s:env = sort(s:env, 's:compare_by_key_len')
  let s:env = sort(s:env, 's:compare_by_val_len')
endfunction

" Function: s:transform {{{1
function s:transform(absolute_path)
  for [k,V] in g:startify_transformations
    if a:absolute_path =~ k
      return type(V) == type('') ? V : V(a:absolute_path)
    endif
    unlet V
  endfor
  return ''
endfunction

" Function: s:warn {{{1
function! s:warn(msg) abort
  echohl WarningMsg
  echomsg a:msg
  echohl NONE
endfunction
