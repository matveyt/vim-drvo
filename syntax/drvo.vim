" Vim syntax file
" Language:     vim-drvo plugin
" Maintainer:   matveyt
" Last Change:  2021 Aug 10
" License:      https://unlicense.org
" URL:          https://github.com/matveyt/vim-drvo

if exists('b:current_syntax')
    finish
endif
let b:current_syntax = 'drvo'

let s:save_cpo = &cpo
set cpo&vim

" use g:drvo_glyph[] for cchar's if any
if exists('g:drvo_glyph')
    let s:ccd = 'cchar='..nr2char(g:drvo_glyph[0])
    let s:ccf = 'cchar='..nr2char(g:drvo_glyph[1])
else
    let s:ccd = ''
    let s:ccf = ''
endif

" drvoDir is {drvoDirRoot/}{drvoDirTrunk}{/}
syntax match drvoDir /^.*[\/]$/ contains=drvoDirRoot
execute 'syntax match drvoDirRoot nextgroup=drvoDirTrunk,drvoMark /^.*[\/]\ze./'
    \ 'contained conceal' s:ccd
syntax match drvoDirTrunk nextgroup=drvoLastSlash /[^\/]\+/ contained
syntax match drvoLastSlash /[\/]/ contained conceal
" drvoFile is {drvoFileRoot/}{drvoFileXXX}
syntax match drvoFile /^.*[^\/]$/ contains=drvoFileRoot
execute 'syntax match drvoFileRoot nextgroup=drvoFileRegular,drvoFileArc,drvoFileBak,'
    \ 'drvoFileExe,drvoMark /^.*[\/]/ contained conceal' s:ccf
syntax match drvoFileRegular /.\+/ contained
syntax match drvoFileArc /\c.\+\.\%(bz2\|cab\|msi\|rar\|tar\|zip\|[7g]z\|t[abgx]z\)$/
    \ contained
syntax match drvoFileBak /\c.\+\.\%(bak\|tmp\)$/ contained
if exists('$PATHEXT')
    let s:pat = join(map(split($PATHEXT, ';'), {_, v -> v[1:]}), '\|')
    execute 'syntax match drvoFileExe /\c.\+\.\%('..s:pat..'\)$/ contained'
    unlet s:pat
endif

" setup default color groups
highlight default link drvoDirTrunk Directory
highlight default link drvoFileRegular NONE
highlight default link drvoFileArc Special
highlight default link drvoFileBak Comment
highlight default link drvoFileExe Macro
highlight default link drvoMark IncSearch

" reset all marks
call drvo#mark()

unlet s:ccd s:ccf

let &cpo = s:save_cpo
unlet s:save_cpo
