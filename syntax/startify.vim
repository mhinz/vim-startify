" Plugin:      https://github.com/mhinz/vim-startify
" Description: Start screen displaying recently used stuff.
" Maintainer:  Marco Hinz <http://github.com/mhinz>
" Version:     1.7

if exists("b:current_syntax")
  finish
endif

let s:sep = startify#get_separator()

syntax match StartifySpecial /\V<empty buffer>\|<quit>/
syntax match StartifyBracket /\[\|\]/
syntax match StartifyNumber  /\[[^BSV]\+\]/hs=s+1,he=e-1 contains=StartifyBracket
syntax match StartifyFile    /.*/ contains=StartifyBracket,StartifyNumber,StartifyPath,StartifySpecial

execute 'syntax match StartifySlash /\'. s:sep .'/'
execute 'syntax match StartifyPath /\%9c.*\'. s:sep .'/ contains=StartifySlash'

if exists('g:startify_custom_header')
  execute 'syntax region StartifyHeader start=/\%1l/ end=/\%'. (len(g:startify_custom_header) + 2) .'l/'
endif

highlight default link StartifyHeader  Normal
highlight default link StartifyBracket Delimiter
highlight default link StartifyNumber  Number

let b:current_syntax = 'startify'

" vim: et sw=2 sts=2
