" Plugin:      https://github.com/mhinz/vim-startify
" Description: Start screen displaying recently used stuff.
" Maintainer:  Marco Hinz <http://github.com/mhinz>
" Version:     1.4

if exists('g:loaded_startify') || &cp
  finish
endif
let g:loaded_startify = 1

" Init {{{1
let g:startify_session_dir = resolve(expand(get(g:, 'startify_session_dir',
      \ has('win32') ? '$HOME\vimfiles\session' : '~/.vim/session')))

if exists('g:startify_bookmarks')
  let exclude = map(copy(g:startify_bookmarks), 'expand(v:val)')
  if exists('g:startify_skiplist')
    call extend(g:startify_skiplist, exclude)
  else
    let g:startify_skiplist = exclude
  endif
endif

augroup startify
  autocmd!
  autocmd VimEnter *
        \ if !argc() && (line2byte('$') == -1) && (v:progname =~? '^[gm]\=vim\%[\.exe]$') |
        \   call s:insane_in_the_membrane() |
        \ endif
augroup END

command! -nargs=? -bar -complete=customlist,startify#get_session_names SSave   call startify#save_session(<f-args>)
command! -nargs=? -bar -complete=customlist,startify#get_session_names SLoad   call startify#load_session(<f-args>)
command! -nargs=? -bar -complete=customlist,startify#get_session_names SDelete call startify#delete_session(<f-args>)
command! -nargs=0 -bar Startify enew | call s:insane_in_the_membrane()

" Function: s:insane_in_the_membrane {{{1
function! s:insane_in_the_membrane() abort
  if !empty(v:servername) && exists('g:startify_skiplist_server')
    for servname in g:startify_skiplist_server
      if (servname == v:servername)
        return
      endif
    endfor
  endif
  setlocal nonumber noswapfile bufhidden=wipe
  if (v:version >= 703)
    setlocal norelativenumber
  endif
  setfiletype startify

  let special = get(g:, 'startify_enable_special', 1)
  let sep = startify#get_separator()
  let cnt = 0

  if special
    call append('$', '   [e]  <empty buffer>')
  endif

  if get(g:, 'startify_show_files', 1) && !empty(v:oldfiles)
    let numfiles = get(g:, 'startify_show_files_number', 10)
    if special
      call append('$', '')
    endif
    for fname in v:oldfiles
      let expfname = expand(fname)
      if !filereadable(expfname) || (exists('g:startify_skiplist') && startify#is_in_skiplist(expfname))
        continue
      endif
      let index = s:get_index_as_string(cnt)
      call append('$', '   ['. index .']'. repeat(' ', (3 - strlen(index))) . fname)
      execute 'nnoremap <buffer> '. index .' :edit '. startify#escape(fname) .' <bar> lcd %:h<cr>'
      let cnt += 1
      if (cnt == numfiles)
        break
      endif
    endfor
  endif

  let sfiles = split(globpath(g:startify_session_dir, '*'), '\n')

  if get(g:, 'startify_show_sessions', 1) && !empty(sfiles)
    call append('$', '')
    for i in range(len(sfiles))
      let idx = (i + cnt)
      let index = s:get_index_as_string(idx)
      call append('$', '   ['. index .']'. repeat(' ', (3 - strlen(index))) . fnamemodify(sfiles[i], ':t:r'))
      execute 'nnoremap <buffer> '. index .' :source '. startify#escape(sfiles[i]) .'<cr>'
    endfor
    let cnt = idx
  endif

  if exists('g:startify_bookmarks')
    call append('$', '')
    for fname in g:startify_bookmarks
      let cnt += 1
      let index = s:get_index_as_string(cnt)
      call append('$', '   ['. index .']'. repeat(' ', (3 - strlen(index))) . fname)
      execute 'nnoremap <buffer> '. index .' :edit '. startify#escape(fname) .' <bar> lcd %:h<cr>'
    endfor
  endif

  if special
    call append('$', ['', '   [q]  <quit>'])
  endif

  setlocal nomodifiable nomodified

  nnoremap <buffer><silent> e       :enew<cr>
  nnoremap <buffer><silent> i       :enew <bar> startinsert<cr>
  nnoremap <buffer>         <space> :call <SID>set_mark('B')<cr>
  nnoremap <buffer>         s       :call <SID>set_mark('S')<cr>
  nnoremap <buffer>         v       :call <SID>set_mark('V')<cr>
  nnoremap <buffer>         <cr>    :call <SID>open_buffers(expand('<cword>'))<cr>
  nnoremap <buffer>         <2-LeftMouse> :execute 'normal '. matchstr(getline('.'), '\w\+')<cr>
  nnoremap <buffer>         q
        \ :if (len(filter(range(0, bufnr('$')), 'buflisted(v:val)')) > 1) <bar>
        \   bd <bar>
        \ else <bar>
        \   quit <bar>
        \ endif<cr>

  if exists('g:startify_empty_buffer_key')
    execute 'nnoremap <buffer><silent> '. g:startify_empty_buffer_key .' :enew<cr>'
  endif

  autocmd! startify *
  autocmd  startify CursorMoved <buffer> call s:set_cursor()
  autocmd  startify BufLeave    <buffer> try | wincmd c | catch /E444/ | endtry | autocmd! startify *

  call cursor(special ? 4 : 2, 5)
endfunction

" Function: s:open_buffers {{{1
function! s:open_buffers(cword) abort
  if exists('s:marked') && !empty(s:marked)
    for i in range(len(s:marked))
      for val in values(s:marked)
        if val[0] == i
          if val[3] == 'S'
            execute 'split '. val[2]
          elseif val[3] == 'V'
            execute 'vsplit '. val[2]
          else
            execute 'edit '. val[2]
          endif
          continue
        endif
      endfor
    endfor
  else
    execute 'normal '. a:cword
  endif
endfunction

" Function: s:set_mark {{{1
"
" Markers are saved in the s:marked dict using the follow format:
"   - s:marked[0]: ID (for sorting)
"   - s:marked[1]: what the brackets contained before
"   - s:marked[2]: the actual path
"   - s:marked[3]: type (buffer, split, vsplit)
"
function! s:set_mark(type) abort
  if !exists('s:marked')
    let s:marked  = {}
    let s:nmarked = 0
  endif
  " matches[1]: content between brackets
  " matches[2]: path
  let matches = matchlist(getline('.'), '\v\[(.*)\]\s+(.*)')
  if matches[2] =~ '\V<empty buffer>\|<quit>' || matches[2] =~ '^\w\+$'
    return
  endif
  setlocal modifiable
  if matches[1] =~ 'B\|S\|V'
    let s:nmarked -= 1
    execute 'normal! ci]'. remove(s:marked, line('.'))[1]
  else
    let s:marked[line('.')] = [s:nmarked, matches[1], matches[2], a:type]
    let s:nmarked += 1
    execute 'normal! ci]'. repeat(a:type, len(matches[1]))
  endif
  setlocal nomodifiable nomodified
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

" Function: s:set_cursor {{{1
function! s:set_cursor() abort
  let s:line_old = exists('s:line_new') ? s:line_new : 5
  let s:line_new = line('.')
  if empty(getline(s:line_new))
    if (s:line_new > s:line_old)
      let s:line_new += 1
      call cursor(s:line_new, 5) " going down
    else
      let s:line_new -= 1
      call cursor((s:line_new < 2 ? 2 : s:line_new), 5) " going up
    endif
  else
    call cursor((s:line_new < 2 ? 2 : 0), 5) " hold cursor in column
  endif
endfunction

" vim: et sw=2 sts=2
