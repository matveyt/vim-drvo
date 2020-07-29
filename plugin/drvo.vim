" Vim drvo plugin
" Maintainer:   matveyt
" Last Change:  2020 Jul 29
" License:      https://unlicense.org
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
        \   if isdirectory(expand('<afile>'))
        \ |     execute 'autocmd! BufReadCmd <buffer=abuf> call drvo#readcmd("dir")'
        \ | endif
    autocmd BufFilePost,ShellCmdPost * ++nested
        \   if &filetype is# 'drvo'
        \ |     edit
        \ | endif
    autocmd DirChanged global,tabpage,window ++nested
        \   if &filetype is# 'drvo'
        \ |     edit <afile>
        \ | endif
augroup end

let &cpo = s:save_cpo
unlet s:save_cpo
