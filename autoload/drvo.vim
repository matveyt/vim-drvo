" Vim drvo plugin
" Maintainer:   matveyt
" Last Change:  2020 Feb 14
" License:      VIM License
" URL:          https://github.com/matveyt/vim-drvo

let s:save_cpo = &cpo
set cpo&vim

" Remove trailing slash if any
function s:chomp(name)
    return a:name !~# '[\/]$' ? a:name : a:name[:-2]
endfunction

" Convert file size to a printable string
function s:fsize2str(size) abort
    if a:size < -1
        " file is too big
        return 'BIG'
    elseif a:size == -1
        " OS error
        return 'ERR'
    elseif a:size < 1024
        return a:size
    else
        " divide by 2^10 while possible
        let [l:num, l:frac, l:pow] = [a:size, 0, 0]
        while l:num >= 1024
            let [l:num, l:frac] = [l:num / 1024, l:num % 1024]
            let l:pow += 1
        endwhile
        let l:frac = (l:frac > 102) ? '.'..(l:frac * 10 / 1024) : ''
        " 'traditional' binary prefix
        return l:num..l:frac..strpart('KMGTPEZY', l:pow - 1, 1)
    endif
endfunction

" Get system drives List on Windows
function s:get_drives() abort
    let l:result = []
    if has('win32') && has('libcall')
        let l:letter = char2nr('A')
        let l:mask = libcallnr('kernel32', 'GetLogicalDrives', 0)
        while l:mask
            if l:mask % 2
                " the drive exists
                call add(l:result, nr2char(l:letter)..':')
            endif
            let l:mask /= 2
            let l:letter += 1
        endwhile
    endif
    return l:result
endfunction

" Implements 'Change drive' dialog on MS-Windows.
function! drvo#change_drive() abort
    let l:drives = s:get_drives()
    if !empty(l:drives)
        " 'closure' function to process user choice
        function! s:on_end_dialog(_, result) closure
            if a:result > 0
                "BUG: Neovim cannot fnamemodify('C:', ':p:h')
                let l:dir = has('nvim') ? l:drives[a:result - 1]..'/' :
                    \ fnamemodify(l:drives[a:result - 1], ':p:h')
                " 'cd' to new dir
                execute 'edit' l:dir
            endif
        endfunction
        " execute dialog
        if has('popupwin')
            call popup_menu(l:drives, {'title': '[Change drive]', 'callback':
                \ funcref('s:on_end_dialog')})
        else
            call s:on_end_dialog(0, confirm('Change drive', join(l:drives, "\n")))
        endif
    endif
endfunction

" Print misc file info
function! drvo#fileinfo(items) abort
    for l:item in a:items
        let l:item = s:chomp(l:item)
        let l:ftype = getftype(l:item)[0]
        echo printf('%s%s %7s %s %s%s', l:ftype is# 'f' ? '-' : l:ftype,
            \ getfperm(l:item), s:fsize2str(getfsize(l:item)),
            \ strftime('%c', getftime(l:item)), fnameescape(fnamemodify(l:item, ':t')),
            \ l:ftype is# 'l' ? ' -> '..fnameescape(resolve(l:item)) : '')
    endfor
endfunction

" Get item simplified
function! drvo#getline(lnum) abort
    return simplify(s:chomp(getline(a:lnum)))
endfunction

" Get raw items [lnum..end] filtering out '..' and such
function! drvo#items(lnum, end) abort
    return filter(getline(a:lnum, a:end), {_, v -> v !~# '\([\/]\)\.\+\1$'})
endfunction

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

" Select files dialog
function! drvo#sel_mask(add) abort
    let l:prompt = a:add ? 'Select: ' : 'Deselect: '
    let l:mask = expand('%:p:h') ==# getcwd() ? '*' : '%:./*'
    if exists('*inputdialog')
        let l:mask = inputdialog(l:prompt, l:mask)
    else
        let l:mask = input(l:prompt, l:mask, 'file')
    endif
    if !empty(l:mask)
        silent! execute (a:add ? '$argadd' : 'argdelete') l:mask
        call drvo#mark()
    endif
endfunction

" Xor arglist with another {items} List
" Note: List of {items} must be fully expanded
function! drvo#sel_toggle(items) abort
    " expand all names in arglist
    let l:argv = map(argv(), {_, v -> fnamemodify(v, ':p')})
    for l:item in a:items
        let l:idx = index(l:argv, l:item)
        if l:idx == -1
            execute '$argadd' fnameescape(l:item)
        else
            execute string(l:idx + 1) 'argdelete'
            call remove(l:argv, l:idx)
        endif
    endfor
    call drvo#mark()
endfunction

" drvo#shdo({fmt}, {dir}, {items})
" Open new window with a shell script containing names from {items} List
"     {fmt} is format string with one or several '{filename-modifiers}'
"     {dir} is new directory to change to
"     {items} is List of file names, or empty to use arglist instead
function! drvo#shdo(fmt, dir, items) abort
    new +set\ ft=sh
    silent! execute 'lcd' a:dir
    call setline(1, '#!/bin/sh')
    for l:item in (empty(a:items) ? argv() : a:items)
        call append('$', substitute(a:fmt, '{\([^}]*\)}',
            \ '\=fnamemodify(l:item, empty(submatch(1)) ? ":~:.:S" : submatch(1))', 'g'))
    endfor
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
