" Plugin:      https://github.com/mhinz/vim-startify
" Description: Start screen displaying recently used stuff.
" Maintainer:  Marco Hinz <http://github.com/mhinz>
" Version:     1.1

if exists("b:current_syntax")
  finish
endif

syntax     match  startifyStartify   /startify>/
highlight  link   startifyStartify   Function

syntax     match  startifyDelimiter  /\[\|\]/
highlight  link   startifyDelimiter  Delimiter

syntax     match  startifyNumber     /\v\[[eq[:digit:]]+\]/hs=s+1,he=e-1 contains=startifyDelimiter
highlight  link   startifyNumber     Number

let b:current_syntax = 'startify'

" vim: et sw=2 sts=2
