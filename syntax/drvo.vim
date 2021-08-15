" Vim syntax file
" Language:     vim-drvo plugin
" Maintainer:   matveyt
" Last Change:  2021 Aug 14
" License:      https://unlicense.org
" URL:          https://github.com/matveyt/vim-drvo

if exists('b:current_syntax')
    finish
endif
let b:current_syntax = 'drvo'

let s:save_cpo = &cpo
set cpo&vim

function! s:glyph(ix) abort
    return exists('g:drvo_glyph') ? 'cchar='..nr2char(get(g:drvo_glyph, a:ix)) : ''
endfunction

function! s:synmatch(group, pat) abort
    if !empty(a:pat)
        let l:pat = (type(a:pat) == v:t_list) ?
            \ printf('\V\%%(%s\)\$', join(a:pat, '\|')) : a:pat
        execute printf('syntax match %s /.\+%s%s/ contained', a:group,
            \ &fileignorecase ? '\c' : '\C', l:pat)
    endif
endfunction

" drvoDir is {drvoDirRoot/}{drvoDirTrunk}{/}
syntax match drvoDir /^.*[\/]$/ contains=drvoDirRoot
execute 'syntax match drvoDirRoot nextgroup=drvoDirTrunk,drvoMark /^.*[\/]\ze./'
    \ 'contained conceal' s:glyph(0)
syntax match drvoDirTrunk nextgroup=drvoLastSlash /[^\/]\+/ contained
syntax match drvoLastSlash /[\/]/ contained conceal
" drvoFile is {drvoFileRoot/}{drvoFileXXX}
syntax match drvoFile /^.*[^\/]$/ contains=drvoFileRoot
execute 'syntax match drvoFileRoot nextgroup=drvoFileExecutable,drvoFileIgnore,'
    \ 'drvoFileSuffixes,drvoMark /^.*[\/]/ contained conceal' s:glyph(1)
call s:synmatch('drvoFileExecutable', split($PATHEXT, ';'))
call s:synmatch('drvoFileIgnore', g:ft_ignore_pat)
call s:synmatch('drvoFileSuffixes', split(&suffixes, ','))

" setup default color groups
highlight default link drvoDirTrunk Directory
highlight default link drvoFileExecutable Macro
highlight default link drvoFileIgnore Special
highlight default link drvoFileSuffixes Comment
highlight default link drvoMark IncSearch

" reset all marks
call drvo#mark()

let &cpo = s:save_cpo
unlet s:save_cpo
