" vim: et sw=2 sts=2

" Plugin:      https://github.com/mhinz/vim-startify
" Description: Start screen displaying recently used stuff.
" Maintainer:  Marco Hinz <http://github.com/mhinz>
" Version:     1.8

if exists('g:loaded_startify') || &cp
  finish
endif
let g:loaded_startify = 1

augroup startify
  if !get(g:, 'startify_disable_at_vimenter')
    autocmd VimEnter *
          \ if !argc() && (line2byte('$') == -1) && (v:progname =~? '^[gmnq]\=vim\=x\=\%[\.exe]$') |
          \   call startify#insane_in_the_membrane() |
          \ endif |
          \ autocmd! startify VimEnter
  endif

  if get(g:, 'startify_session_persistence')
    autocmd startify VimLeave *
          \ if exists('v:this_session') && filewritable(v:this_session) |
          \   call startify#session_write(fnameescape(v:this_session)) |
          \ endif
  endif
augroup END

command! -nargs=? -bar -complete=customlist,startify#session_list SSave   call startify#session_save(<f-args>)
command! -nargs=? -bar -complete=customlist,startify#session_list SLoad   call startify#session_load(<f-args>)
command! -nargs=? -bar -complete=customlist,startify#session_list SDelete call startify#session_delete(<f-args>)
command! -nargs=0 -bar Startify enew | call startify#insane_in_the_membrane()
