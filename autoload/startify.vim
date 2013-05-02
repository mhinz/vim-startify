" Plugin:      https://github.com/mhinz/vim-startify
" Description: Start screen displaying recently used stuff.
" Maintainer:  Marco Hinz <http://github.com/mhinz>
" Version:     1.4

if exists('g:autoloaded_startify') || &cp
  finish
endif
let g:autoloaded_startify = 1

" Function: startify#get_session_names {{{1
function! startify#get_session_names(lead, ...) abort
  return map(split(globpath(g:startify_session_dir, '*'.a:lead.'*', '\n')), 'fnamemodify(v:val, ":t")')
endfunction

" Function: startify#get_session_names_as_string {{{1
function! startify#get_session_names_as_string(lead, ...) abort
  return join(map(split(globpath(g:startify_session_dir, '*'.a:lead.'*', '\n')), 'fnamemodify(v:val, ":t")'), "\n")
endfunction

" Function: startify#escape {{{1
function! startify#escape(path) abort
  return !exists('+shellslash') || &shellslash ? fnameescape(a:path) : escape(a:path, '\')
endfunction

" Function: startify#get_separator {{{1
function! startify#get_separator() abort
  return !exists('+shellslash') || &shellslash ? '/' : '\'
endfunction

" Function: startify#is_in_skiplist {{{1
function! startify#is_in_skiplist(arg) abort
  for regexp in g:startify_skiplist
    if (a:arg =~# regexp)
      return 1
    endif
  endfor
endfunction

" Function: startify#delete_session {{{1
function! startify#delete_session(...) abort
  if !isdirectory(g:startify_session_dir)
    echo 'The session directory does not exist: '. g:startify_session_dir
    return
  elseif empty(startify#get_session_names_as_string(''))
    echo 'There are no sessions...'
    return
  endif
  let spath = g:startify_session_dir . startify#get_separator() . (exists('a:1')
        \ ? a:1
        \ : input('Delete this session: ', '', 'custom,startify#get_session_names_as_string'))
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

" Function: startify#save_session {{{1
function! startify#save_session(...) abort
  if !isdirectory(g:startify_session_dir)
    if exists('*mkdir')
      echo 'The session directory does not exist: '. g:startify_session_dir .'. Create it?  [y/n]' | redraw
      if (nr2char(getchar()) == 'y')
        call mkdir(g:startify_session_dir, 'p')
      else
        echo
        return
      endif
    else
      echo 'The session directory does not exist: '. g:startify_session_dir
      return
    endif
  endif
  let spath = g:startify_session_dir . startify#get_separator() . (exists('a:1')
        \ ? a:1
        \ : input('Save under this session name: ', '', 'custom,startify#get_session_names_as_string'))
        \ | redraw
  if !filereadable(spath)
    execute 'mksession '. spath | echo 'Session saved under: '. spath
    return
  endif
  echo 'Session already exists. Overwrite?  [y/n]' | redraw
  if nr2char(getchar()) == 'y'
    execute 'mksession! '. spath | echo 'Session saved under: '. spath
  else
    echo 'Did NOT save the session!'
  endif
endfunction

" Function: startify#load_session {{{1
function! startify#load_session(...) abort
  if !isdirectory(g:startify_session_dir)
    echo 'The session directory does not exist: '. g:startify_session_dir
    return
  elseif empty(startify#get_session_names_as_string(''))
    echo 'There are no sessions...'
    return
  endif
  let spath = g:startify_session_dir . startify#get_separator() . (exists('a:1')
        \ ? a:1
        \ : input('Load this session: ', '', 'custom,startify#get_session_names_as_string'))
        \ | redraw
  if filereadable(spath)
    execute 'source '. spath
  else
    echo 'No such file: '. spath
  endif
endfunction

" vim: et sw=2 sts=2
