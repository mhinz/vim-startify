" Plugin:      https://github.com/mhinz/vim-startify
" Description: Start screen displaying recently used stuff.
" Maintainer:  Marco Hinz <http://github.com/mhinz>
" Version:     1.6

if exists('g:loaded_startify') || &cp
  finish
endif
let g:loaded_startify = 1

augroup startify
  autocmd!
  autocmd VimEnter *
        \ if !argc() && (line2byte('$') == -1) && (v:progname =~? '^[gm]\=vim\%[\.exe]$') |
        \   call startify#insane_in_the_membrane() |
        \ endif
augroup END

command! -nargs=? -bar -complete=customlist,startify#session_list SSave   call startify#session_save(<f-args>)
command! -nargs=? -bar -complete=customlist,startify#session_list SLoad   call startify#session_load(<f-args>)
command! -nargs=? -bar -complete=customlist,startify#session_list SDelete call startify#session_delete(<f-args>)
command! -nargs=0 -bar Startify call startify#insane_in_the_membrane()

" vim: et sw=2 sts=2
