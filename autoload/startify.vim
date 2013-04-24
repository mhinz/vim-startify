" Plugin:      https://github.com/mhinz/vim-startify
" Description: Start screen displaying recently used stuff.
" Maintainer:  Marco Hinz <http://github.com/mhinz>
" Version:     1.1

if exists('g:autoloaded_startify') || &cp
  finish
endif
let g:autoloaded_startify = 1

function! startify#get_session_names(lead, ...) abort
  return map(split(globpath(g:startify_session_dir, '*'.a:lead.'*', '\n')), 'fnamemodify(v:val, ":t")')
endfunction

function! startify#get_session_names_as_string(lead, ...) abort
  return join(map(split(globpath(g:startify_session_dir, '*'.a:lead.'*', '\n')), 'fnamemodify(v:val, ":t")'), "\n")
endfunction

function! startify#save_session(...) abort
  if !isdirectory(g:startify_session_dir)
    echo 'The session directory does not exist: '. g:startify_session_dir
    return
  endif
  let spath = g:startify_session_dir .'/'. (exists('a:1')
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

function! startify#load_session(...) abort
  if !isdirectory(g:startify_session_dir)
    echo 'The session directory does not exist: '. g:startify_session_dir
    return
  endif
  let spath = g:startify_session_dir .'/'. (exists('a:1')
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
