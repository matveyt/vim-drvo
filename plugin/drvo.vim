" Vim drvo plugin
" Maintainer:   matveyt
" Last Change:  2020 Feb 14
" License:      VIM License
" URL:          https://github.com/matveyt/vim-drvo

if exists('g:loaded_drvo')
    finish
endif
let g:loaded_drvo = 1

let s:save_cpo = &cpo
set cpo&vim

" Note: augroup FileExplorer is intentionally overwritten,
" so netrw-plugin becomes (mostly) disabled
augroup FileExplorer | au!
    autocmd BufNew *
        \ if isdirectory(expand('<afile>')) |
        \     execute 'autocmd! BufReadCmd <buffer=abuf>'
        \         'call drvo#reload() | setf drvo' |
        \ endif
    autocmd BufFilePost,ShellCmdPost *
        \ if &ft is# 'drvo' | call drvo#reload() | endif
    autocmd DirChanged global,tabpage,window ++nested
        \ if &ft is# 'drvo' | execute 'edit' getcwd() | endif
augroup end

let &cpo = s:save_cpo
unlet s:save_cpo
