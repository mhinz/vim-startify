" vim: et sw=2 sts=2

" Plugin:      https://github.com/mhinz/vim-startify
" Description: Start screen displaying recently used stuff.
" Maintainer:  Marco Hinz <http://github.com/mhinz>
" Version:     1.8

if exists("b:current_syntax")
  finish
endif

let s:sep = startify#get_separator()

syntax sync fromstart

syntax match StartifyBracket /.*\%9c/ contains=
      \ StartifyNumber,
      \ StartifySelect,
syntax match StartifySpecial /\V<empty buffer>\|<quit>/
syntax match StartifyNumber  /^\s*\[\zs[^BSVT]\{-}\ze\]/
syntax match StartifySelect  /^\s*\[\zs[BSVT]\{-}\ze\]/
syntax match StartifyFile    /.*/ contains=
      \ StartifyBracket,
      \ StartifyPath,
      \ StartifySpecial,

execute 'syntax match StartifySlash /\'. s:sep .'/'
execute 'syntax match StartifyPath /\%9c.*\'. s:sep .'/ contains=StartifySlash'

if exists('g:startify_custom_header')
  execute 'syntax region StartifyHeader start=/\%1l/ end=/\%'. (len(g:startify_custom_header) + 2) .'l/'
endif

if exists('g:startify_custom_footer')
  execute 'syntax region StartifyFooter start=/\%'. startify#get_lastline() .'l/ end=/*/'
endif

if exists('w:startify_section_header_lines')
  for line in w:startify_section_header_lines
    execute 'syntax region StartifySection start=/\%'. line .'l/ end=/$/'
  endfor
endif

autocmd startify User Startified
      \ for item in w:startify_section_header_lines
      \ | execute 'syntax region StartifySection start=/\%'. item .'l/ end=/$/'
      \ | endfor

highlight default link StartifyBracket Delimiter
highlight default link StartifyFile    Identifier
highlight default link StartifyFooter  Title
highlight default link StartifyHeader  Title
highlight default link StartifyNumber  Number
highlight default link StartifyPath    Directory
highlight default link StartifySection Statement
highlight default link StartifySelect  Title
highlight default link StartifySlash   Delimiter
highlight default link StartifySpecial Comment

let b:current_syntax = 'startify'
