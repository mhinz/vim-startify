" vim: et sw=2 sts=2

" Plugin:      https://github.com/mhinz/vim-startify
" Description: A fancy start screen for Vim.
" Maintainer:  Marco Hinz <http://github.com/mhinz>

if exists('g:loaded_startify') || &cp
  finish
endif
let g:loaded_startify = 1
let g:startify_locked = 0

augroup startify
  if !get(g:, 'startify_disable_at_vimenter')
    autocmd VimEnter * nested call s:genesis()
  endif

  if get(g:, 'startify_session_persistence')
    autocmd VimLeave * call s:extinction()
  endif

  autocmd QuickFixCmdPre  *vimgrep* let g:startify_locked = 1
  autocmd QuickFixCmdPost *vimgrep* let g:startify_locked = 0
augroup END

function! s:genesis()
  if !argc() && (line2byte('$') == -1) && (v:progname =~? '^[-gmnq]\=vim\=x\=\%[\.exe]$')
    if get(g:, 'startify_session_autoload') && filereadable('Session.vim')
      source Session.vim
    else
      call startify#insane_in_the_membrane()
    endif
  endif
  autocmd startify BufNewFile,BufRead,BufFilePre *
        \ if !g:startify_locked && exists('v:oldfiles') |
        \   call insert(v:oldfiles, expand('<afile>'), 0) |
        \ endif
  autocmd! startify VimEnter
endfunction

function! s:extinction()
  if exists('v:this_session') && filewritable(v:this_session)
    call startify#session_write(fnameescape(v:this_session))
  endif
endfunction

command! -nargs=? -bar -complete=customlist,startify#session_list SSave   call startify#session_save(<f-args>)
command! -nargs=? -bar -complete=customlist,startify#session_list SLoad   call startify#session_load(<f-args>)
command! -nargs=? -bar -complete=customlist,startify#session_list SDelete call startify#session_delete(<f-args>)
command! -nargs=0 -bar SClose call startify#session_close()
command! -nargs=0 -bar Startify enew | call startify#insane_in_the_membrane()
command! -nargs=0 -bar StartifyDebug call startify#debug()

nnoremap <silent><plug>(startify-open-buffers) :<c-u>call startify#open_buffers()<cr>
