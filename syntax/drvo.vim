" Vim syntax file
" Language:     vim-drvo plugin
" Maintainer:   matveyt
" Last Change:  2021 Aug 16
" License:      https://unlicense.org
" URL:          https://github.com/matveyt/vim-drvo

if exists('b:current_syntax')
    finish
endif
let b:current_syntax = 'drvo'

let s:save_cpo = &cpo
set cpo&vim

function s:glyph(ix) abort
    return exists('g:drvo_glyph') ? 'cchar='..nr2char(g:drvo_glyph[a:ix]) : ''
endfunction

function s:syncontained(group, pat) abort
    if empty(a:pat)
        return
    endif

    let l:pat = type(a:pat) == v:t_string ? a:pat :
        \ printf('\V\%%(%s\)\$', join(a:pat, '\|'))
    execute printf('syntax match %s /.\+%s%s/ contained', a:group,
        \ &fileignorecase ? '\c' : '\C', l:pat)
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
call s:syncontained('drvoFileExecutable', split($PATHEXT, ';'))
call s:syncontained('drvoFileIgnore', g:ft_ignore_pat)
call s:syncontained('drvoFileSuffixes', split(&suffixes, ','))

" default colors
highlight default link drvoDirTrunk Directory
highlight default link drvoFileExecutable Macro
highlight default link drvoFileIgnore Special
highlight default link drvoFileSuffixes Comment
highlight default link drvoMark IncSearch

" reset all marks
call drvo#mark()

let &cpo = s:save_cpo
unlet s:save_cpo
