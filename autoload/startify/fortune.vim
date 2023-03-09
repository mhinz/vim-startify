scriptencoding utf-8

" Function: s:get_random_offset {{{1
function! s:get_random_offset(max) abort
    return str2nr(matchstr(reltimestr(reltime()), '\.\zs\d\+')[1:]) % a:max
endfunction

" Function: s:draw_box {{{1
function! s:draw_box(lines) abort
    let longest_line = max(map(copy(a:lines), 'strwidth(v:val)'))
    let top_bottom_without_corners = repeat(s:char_top_bottom, longest_line + 2)
    let top = s:char_top_left . top_bottom_without_corners . s:char_top_right
    let bottom = s:char_bottom_left . top_bottom_without_corners . s:char_bottom_right
    let lines = [top]
    for l in a:lines
        let offset = longest_line - strwidth(l)
        let lines += [s:char_sides . ' '. l . repeat(' ', offset) .' ' . s:char_sides]
    endfor
    let lines += [bottom]
    return lines
endfunction

" Function: #quote {{{1
function! startify#fortune#quote() abort
    return g:startify_custom_header_quotes[s:get_random_offset(len(g:startify_custom_header_quotes))]
endfunction

" Function: #boxed {{{1
function! startify#fortune#boxed(...) abort
    let wrapped_quote = []
    if a:0 && type(a:1) == type([])
        let quote = a:1
    else
        let Quote = startify#fortune#quote()
        let quote = type(Quote) == type(function('tr')) ? Quote() : Quote
    endif
    for line in quote
        let wrapped_quote += split(line, '\%50c.\{-}\zs\s', 1)
    endfor
    let wrapped_quote = s:draw_box(wrapped_quote)
    return wrapped_quote
endfunction

" Function: #cowsay {{{1
function! startify#fortune#cowsay(...) abort
    if a:0
        let quote = a:0 && type(a:1) == type([]) ? a:1 : startify#fortune#quote()
        let s:char_top_bottom   = get(a:000, 1, s:char_top_bottom)
        let s:char_sides        = get(a:000, 2, s:char_sides)
        let s:char_top_left     = get(a:000, 3, s:char_top_left)
        let s:char_top_right    = get(a:000, 4, s:char_top_right)
        let s:char_bottom_right = get(a:000, 5, s:char_bottom_right)
        let s:char_bottom_left  = get(a:000, 6, s:char_bottom_left)
    else
        let quote = startify#fortune#quote()
    endif
    let boxed_quote = startify#fortune#boxed(quote)
    return boxed_quote + s:cow
endfunction

" Function: #predefined_quotes {{{1
function! startify#fortune#predefined_quotes() abort
    return s:predefined_quotes
endfunction

" Variables {{{1
let s:cow = [
            \ '       o',
            \ '        o   ^__^',
            \ '         o  (oo)\_______',
            \ '            (__)\       )\/\',
            \ '                ||----w |',
            \ '                ||     ||',
            \ ]

let g:startify_fortune_use_unicode = &encoding == 'utf-8' && get(g:, 'startify_fortune_use_unicode')

let s:char_top_bottom   = ['-', '─'][g:startify_fortune_use_unicode]
let s:char_sides        = ['|', '│'][g:startify_fortune_use_unicode]
let s:char_top_left     = ['*', '╭'][g:startify_fortune_use_unicode]
let s:char_top_right    = ['*', '╮'][g:startify_fortune_use_unicode]
let s:char_bottom_right = ['*', '╯'][g:startify_fortune_use_unicode]
let s:char_bottom_left  = ['*', '╰'][g:startify_fortune_use_unicode]

let s:predefined_quotes = startify#langs#SetLanguage()

let g:startify_custom_header_quotes = exists('g:startify_custom_header_quotes')
            \ ? g:startify_custom_header_quotes
            \ : startify#fortune#predefined_quotes()

