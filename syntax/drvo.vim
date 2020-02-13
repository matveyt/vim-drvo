" Vim syntax file
" Language:     vim-drvo plugin
" Maintainer:   matveyt
" Last Change:  2020 Feb 13
" License:      VIM License
" URL:          https://github.com/matveyt/vim-drvo

if exists('b:current_syntax')
    finish
endif
let b:current_syntax = 'drvo'

let s:save_cpo = &cpo
set cpo&vim

" Refresh our syntax to match argument list
function! drvo#mark() abort
    "BUG: Neovim has always :set nofileignorecase
    let l:case = &fileignorecase || has('win32') ? '\c' : '\C'
    syntax clear drvoMark
    for l:name in map(argv(), {_, v -> fnamemodify(v, ':p')})
        let l:tail = fnamemodify(l:name, ':t')
        let l:head = fnamemodify(l:name, ':h')
        let l:isdir = empty(l:tail)
        if l:isdir
            " this is a directory: break one level more
            let l:tail = fnamemodify(l:head, ':t')
            let l:head = fnamemodify(l:head, ':h')
        endif
        " make sure our head ends in a slash
        let l:head = fnamemodify(l:head, ':p')
        " match tail if preceded by head and followed by slash (for dirs)
        execute printf('syntax match drvoMark %s/\V%s\%%(\^%s\)\@%d<=%s%s\$/ contained',
            \ l:isdir ? 'nextgroup=drvoLastSlash ' : '', l:case, escape(l:head, '\/'),
            \ strlen(l:head), l:tail, l:isdir ? '\ze\[\/]' : '')
    endfor
endfunction

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

" setup default color groups
highlight default link drvoDirTrunk Directory
highlight default link drvoMark Todo

" redraw all marks
call drvo#mark()

let &cpo = s:save_cpo
unlet s:save_cpo s:ccd s:ccf
