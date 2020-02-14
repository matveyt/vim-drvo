" Vim syntax file
" Language:     vim-drvo plugin
" Maintainer:   matveyt
" Last Change:  2020 Feb 14
" License:      VIM License
" URL:          https://github.com/matveyt/vim-drvo

if exists('b:current_syntax')
    finish
endif
let b:current_syntax = 'drvo'

let s:save_cpo = &cpo
set cpo&vim

" use g:drvo_glyph[] for cchar's if any
if exists('g:drvo_glyph')
    let s:ccd = 'cchar='..nr2char(g:drvo_glyph[0], 1)
    let s:ccf = 'cchar='..nr2char(g:drvo_glyph[1], 1)
else
    let s:ccd = ''
    let s:ccf = ''
endif

" drvoDir is {drvoDirRoot/}{drvoDirTrunk}{/}
syntax match drvoDir /^.*[\/]$/ contains=drvoDirRoot
execute 'syntax match drvoDirRoot nextgroup=drvoMark,drvoDirTrunk /^.*[\/]\ze./'
    \ 'contained conceal' s:ccd
syntax match drvoDirTrunk nextgroup=drvoLastSlash /[^\/]\+/ contained
syntax match drvoLastSlash /[\/]/ contained conceal
" drvoFile is {drvoFileRoot/}{drvoFileTrunk}
syntax match drvoFile /^.*[^\/]$/ contains=drvoFileRoot
execute 'syntax match drvoFileRoot nextgroup=drvoMark,drvoFileTrunk /^.*[\/]/'
    \ 'contained conceal' s:ccf
syntax match drvoFileTrunk /.\+/ contained

" reset all marks
call drvo#mark()

" setup default color groups
highlight default link drvoDirTrunk Directory
highlight default link drvoMark Todo

let &cpo = s:save_cpo
unlet s:save_cpo s:ccd s:ccf
