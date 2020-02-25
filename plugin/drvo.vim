" Vim drvo plugin
" Maintainer:   matveyt
" Last Change:  2020 Feb 25
" License:      http://unlicense.org
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
        \         'call s:reload() | setf drvo' |
        \ endif
    autocmd BufFilePost,ShellCmdPost *
        \ if &ft is# 'drvo' | call s:reload() | endif
    autocmd DirChanged global,tabpage,window ++nested
        \ if &ft is# 'drvo' | execute 'edit' fnameescape(getcwd()) | endif
augroup end

function s:reload() abort
    " remember altbuf if it's a regular one
    let l:altbuf = bufnr('#')
    if l:altbuf != -1 && buflisted(l:altbuf) &&
        \ getbufvar(l:altbuf, '&filetype') isnot# 'drvo'
            let w:drvo_altbuf = l:altbuf
    endif
    " read in directory contents
    let l:dir = fnamemodify(@%, ':p')
    let l:files = map(glob(l:dir..'.?*', 0, 1) + glob(l:dir..'*', 0, 1),
        \ {_, f -> isdirectory(f) ? f..l:dir[-1:] : f})
    if l:dir ==# fnamemodify(l:dir, ':h')
        " root directory: filter out '..'
        call filter(l:files, {_, v -> v !~# '\([\/]\)\.\.\1$'})
    elseif empty(l:files)
        " no '..' in a subdirectory: access denied
        echohl WarningMsg | echo 'Access denied' | echohl None
        call add(l:files, l:dir..'..'..l:dir[-1:])
    endif
    " set new buffer
    silent call deletebufline('%', 1, '$')
    call setline(1, l:files)
    " apply sorting, filtering etc.
    if exists('#User#drvo')
        doautocmd <nomodeline> User drvo
    else
        "BUG: Neovim has always :set nofileignorecase
        let l:case = &fileignorecase || has('win32') ? 'i' : ''
        " sort directories first; then sort files by extension
        execute 'sort' l:case '/^.*[\/]/'
        execute 'sort' l:case '/\.[^.\/]\+$/r'
    endif
    " move cursor to the previous buffer's name
    call search('\V\C' . escape(@#, '\'), 'c')
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
