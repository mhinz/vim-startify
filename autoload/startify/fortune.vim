" Variables {{{1
let s:cow = [
      \ '       o',
      \ '        o   ^__^',
      \ '         o  (oo)\_______',
      \ '            (__)\       )\/\',
      \ '                ||----w |',
      \ '                ||     ||',
      \ ]

let s:quotes = exists('g:startify_custom_header_quotes')
      \ ? g:startify_custom_header_quotes
      \ : [
      \ ['Almost every programming language is overrated by its practitioners.', '', '- Larry Wall'],
      \ ]

" Function: s:get_random_offset {{{1
function! s:get_random_offset(max) abort
  return str2nr(matchstr(reltimestr(reltime()), '\.\zs\d\+')[1:]) % a:max
endfunction

" Function: s:draw_box {{{1
function! s:draw_box(lines) abort
  let longest_line = max(map(copy(a:lines), 'strwidth(v:val)'))
  if &encoding == 'utf-8' && get(g:, 'startify_fortune_use_unicode')
      let top_left_corner = '╭'
      let top_right_corner = '╮'
      let bottom_left_corner = '╰'
      let bottom_right_corner = '╯'
      let side = '│'
      let top_bottom_side = '─'
  else
      let top_left_corner = '*'
      let top_right_corner = '*'
      let bottom_left_corner = '*'
      let bottom_right_corner = '*'
      let side = '|'
      let top_bottom_side = '-'
  endif
  let top = top_left_corner . repeat(top_bottom_side, longest_line + 2) . top_right_corner
  let bottom = bottom_left_corner . repeat(top_bottom_side, longest_line + 2) . bottom_right_corner
  let lines = [top]
  for l in a:lines
    let offset = longest_line - strwidth(l)
    let lines += [side . ' '. l . repeat(' ', offset) .' ' . side]
  endfor
  let lines += [bottom]
  return lines
endfunction

" Function: #quote {{{1
function! startify#fortune#quote() abort
  return s:quotes[s:get_random_offset(len(s:quotes))]
endfunction

" Function: #boxed {{{1
function! startify#fortune#boxed() abort
  let wrapped_quote = []
  let quote = startify#fortune#quote()
  for line in quote
    let wrapped_quote += split(line, '\%50c.\{-}\zs\s', 1)
  endfor
  let wrapped_quote = s:draw_box(wrapped_quote)
  return wrapped_quote
endfunction

" Function: #cowsay {{{1
function! startify#fortune#cowsay() abort
  let boxed_quote = startify#fortune#boxed()
  let boxed_quote += s:cow
  return map(boxed_quote, '"   ". v:val')
endfunction
