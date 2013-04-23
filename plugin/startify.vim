" Plugin:      https://github.com/mhinz/vim-startify
" Description: Start screen displaying recently used stuff.
" Maintainer:  Marco Hinz <http://github.com/mhinz>
" Version:     0.5

if exists('g:loaded_startify') || &cp
  finish
endif
let g:loaded_startify = 1

" Init {{{1
let g:startify_session_dir = resolve(expand(get(g:, 'startify_session_dir', '~/.vim/session')))
let s:padlen = 3

command! -nargs=0 -bar Lsave call startify#save_session()
command! -nargs=0 -bar Lload call startify#load_session()

nnoremap <silent> <leader>rr :Lload<cr>
nnoremap <silent> <leader>rs :Lsave<cr>

augroup startify
  autocmd!
  autocmd VimEnter *
        \ if !argc() && (line2byte('$') == -1) |
        \   call s:start() |
        \   call cursor(6, s:padlen+2) |
        \endif
augroup END

" Function: s:start {{{1
function! s:start() abort
  setfiletype startify

  setlocal nonumber norelativenumber nobuflisted buftype=nofile

  let numfiles = get(g:, 'startify_show_files_number', 10)
  let pad      = repeat(' ', s:padlen)
  let cnt      = 0

  call append('$', [pad . 'startify>', '', pad . '[e]  <empty buffer>'])

  if get(g:, 'startify_show_files', 1) && !empty(v:oldfiles)
    call append('$', '')
    for fname in v:oldfiles
      if !filereadable(expand(fname)) || (fname =~# $VIMRUNTIME .'/doc') || (fname =~# 'bundle/.*/doc')
        continue
      endif
      call append('$', pad .'['. cnt .']'. repeat(' ', s:padlen - strlen(string(cnt))) . fname)
      execute 'nnoremap <buffer> '. cnt .' :edit '. fname .'<cr>'
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
      call append('$', pad .'['. idx .']'. repeat(' ', s:padlen - strlen(string(idx))) . fnamemodify(sfiles[i], ':t:r'))
      execute 'nnoremap <buffer> '. idx .' :source '. sfiles[i] .'<cr>'
    endfor
  endif

  call append('$', ['', pad .'[q]  quit'])

  setlocal nomodifiable

  nnoremap <buffer> q :quit<cr>
  nnoremap <buffer><silent> e :enew<cr>
  nnoremap <buffer><silent> <cr> :execute 'normal '. <c-r><c-w><cr>

  autocmd! startify *
  autocmd startify CursorMoved <buffer> call cursor(line('.') < 4 ? 4 : 0, s:padlen+2)
  autocmd startify BufLeave <buffer> autocmd! startify *
endfunction

" vim: et sw=2 sts=2
