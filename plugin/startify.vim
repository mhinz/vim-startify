" vim: et sw=2 sts=2

" Plugin:      https://github.com/mhinz/vim-startify
" Description: A fancy start screen for Vim.
" Maintainer:  Marco Hinz <http://github.com/mhinz>

if exists('g:loaded_startify') || &cp
  finish
endif
let g:loaded_startify = 1
let g:startify_locked = 0

if !get(g:, 'startify_disable_at_vimenter')
  set shortmess+=I
endif

augroup startify
  autocmd VimEnter    * nested call s:genesis()
  autocmd VimLeavePre * nested call s:extinction()
  autocmd QuickFixCmdPre  *vimgrep* let g:startify_locked = 1
  autocmd QuickFixCmdPost *vimgrep* let g:startify_locked = 0
augroup END

function! s:update_oldfiles(file)
  if g:startify_locked || !exists('v:oldfiles')
    return
  endif
  let idx = index(v:oldfiles, a:file)
  if idx != -1
    call remove(v:oldfiles, idx)
  endif
  call insert(v:oldfiles, a:file, 0)
endfunction

function! s:genesis()
  if !argc() && (line2byte('$') == -1)
    if get(g:, 'startify_session_autoload') && filereadable('Session.vim')
      source Session.vim
    elseif !get(g:, 'startify_disable_at_vimenter')
      call startify#insane_in_the_membrane()
    endif
  endif
  if get(g:, 'startify_update_oldfiles')
    call map(v:oldfiles, 'fnamemodify(v:val, ":p")')
    autocmd startify BufNewFile,BufRead,BufFilePre *
          \ call s:update_oldfiles(expand('<afile>:p'))
  endif
  autocmd! startify VimEnter
endfunction

function! s:extinction()
  if get(g:, 'startify_session_persistence')
        \ && exists('v:this_session')
        \ && filewritable(v:this_session)
    call startify#session_write(fnameescape(v:this_session))
  endif
endfunction

command! -nargs=? -bar       -complete=customlist,startify#session_list SLoad   call startify#session_load(<f-args>)
command! -nargs=? -bar -bang -complete=customlist,startify#session_list SSave   call startify#session_save(<bang>0, <f-args>)
command! -nargs=? -bar -bang -complete=customlist,startify#session_list SDelete call startify#session_delete(<bang>0, <f-args>)
command! -nargs=0 -bar SClose call startify#session_close()
command! -nargs=0 -bar Startify noautocmd enew | call startify#insane_in_the_membrane()
command! -nargs=0 -bar StartifyDebug call startify#debug()

nnoremap <silent><plug>(startify-open-buffers) :<c-u>call startify#open_buffers()<cr>
