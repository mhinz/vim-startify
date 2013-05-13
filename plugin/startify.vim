" Plugin:      https://github.com/mhinz/vim-startify
" Description: Start screen displaying recently used stuff.
" Maintainer:  Marco Hinz <http://github.com/mhinz>
" Version:     1.5

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

command! -nargs=? -bar -complete=customlist,startify#get_session_names SSave   call startify#save_session(<f-args>)
command! -nargs=? -bar -complete=customlist,startify#get_session_names SLoad   call startify#load_session(<f-args>)
command! -nargs=? -bar -complete=customlist,startify#get_session_names SDelete call startify#delete_session(<f-args>)
command! -nargs=0 -bar Startify enew | call startify#insane_in_the_membrane()

" vim: et sw=2 sts=2
