" Plugin:      https://github.com/mhinz/vim-startify
" Description: Start screen displaying recently used stuff.
" Maintainer:  Marco Hinz <http://github.com/mhinz>
" Version:     1.1

if exists('g:loaded_startify') || &cp
  finish
endif
let g:loaded_startify = 1

" Init {{{1
let g:startify_session_dir = resolve(expand(get(g:, 'startify_session_dir',
      \ has('win32') ? '$HOME\vimfiles\session' : '~/.vim/session')))

augroup startify
  autocmd!
  autocmd VimEnter *
        \ if !argc() && (line2byte('$') == -1) |
        \   call s:start() |
        \ endif
augroup END

command! -nargs=? -bar -complete=customlist,startify#get_session_names SSave call startify#save_session(<f-args>)
command! -nargs=? -bar -complete=customlist,startify#get_session_names SLoad call startify#load_session(<f-args>)
command! -nargs=0 -bar Startify enew | call s:start()

" Function: s:start {{{1
function! s:start() abort
  setfiletype startify
  setlocal nonumber buftype=nofile
  if v:version >= 703
    setlocal norelativenumber
  endif
  if get(g:, 'startify_unlisted_buffer', 1)
    setlocal nobuflisted
  endif

  call append('$', ['   startify>', '', '   [e]  <empty buffer>'])
  let cnt = 0
  let sep = startify#get_sep()

  if get(g:, 'startify_show_files', 1) && !empty(v:oldfiles)
    let numfiles = get(g:, 'startify_show_files_number', 10)
    call append('$', '')
    for fname in v:oldfiles
      if !filereadable(expand(fname))
            \ || (expand(fname) =~# $VIMRUNTIME . sep .'doc')
            \ || (fname =~# 'bundle'. sep .'.*'. sep .'doc')
        continue
      endif
      call append('$', '   ['. cnt .']'. repeat(' ', 3 - strlen(string(cnt))) . fname)
      execute 'nnoremap <buffer> '. cnt .' :edit '. startify#escape(fname) .'<cr>'
      let cnt += 1
      if cnt == numfiles
        break
      endif
    endfor
  endif

  let sfiles = split(globpath(g:startify_session_dir, '*'), '\n')

  if get(g:, 'startify_show_sessions', 1) && !empty(sfiles)
    call append('$', '')
    for i in range(len(sfiles))
      let idx = i + cnt
      call append('$', '   ['. idx .']'. repeat(' ', 3 - strlen(string(idx))) . fnamemodify(sfiles[i], ':t:r'))
      execute 'nnoremap <buffer> '. idx .' :source '. startify#escape(sfiles[i]) .'<cr>'
    endfor
    let cnt = idx
  endif

  if exists('g:startify_bookmarks')
    call append('$', '')
    for fname in g:startify_bookmarks
      if !filereadable(expand(fname))
        continue
      endif
      let cnt += 1
      call append('$', '   ['. cnt .']'. repeat(' ', 3 - strlen(string(cnt))) . fname)
      execute 'nnoremap <buffer> '. cnt .' :edit '. startify#escape(fname) .'<cr>'
    endfor
  endif

  call append('$', ['', '   [q]  quit'])

  setlocal nomodifiable

  nnoremap <buffer> q :quit<cr>
  nnoremap <buffer><silent> e :enew<cr>
  nnoremap <buffer><silent> <cr> :normal <c-r><c-w><cr>

  autocmd! startify *
  autocmd startify CursorMoved <buffer> call cursor(line('.') < 4 ? 4 : 0, 5)
  autocmd startify BufLeave <buffer> autocmd! startify *

  call cursor(6, 5)
endfunction

" vim: et sw=2 sts=2
