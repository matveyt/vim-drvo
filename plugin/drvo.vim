" Vim drvo plugin
" Maintainer:   matveyt
" Last Change:  2020 Aug 15
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

" check already created buffers (e.g. command-line args)
if !v:vim_did_enter
    for s:buf in getbufinfo({'buflisted': 1})
        if !s:buf.loaded && isdirectory(s:buf.name)
            execute 'autocmd! BufReadCmd <buffer='..s:buf.bufnr..'>'
                \ 'call drvo#readcmd("dir")'
        endif
    endfor
    unlet! s:buf
endif

let &cpo = s:save_cpo
unlet s:save_cpo
