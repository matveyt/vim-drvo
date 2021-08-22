" Vim drvo plugin
" Maintainer:   matveyt
" Last Change:  2021 Aug 22
" License:      https://unlicense.org
" URL:          https://github.com/matveyt/vim-drvo

let s:save_cpo = &cpo
set cpo&vim

" Remove trailing slash
function s:chomp(name) abort
    return a:name =~# printf('[%s]$', drvo#slash()) ? a:name[:-2] : a:name
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
        let [l:num, l:frac, l:pow] = [a:size, 0, -1]
        while l:num >= 1024
            let [l:num, l:frac] = [l:num / 1024, l:num % 1024]
            let l:pow += 1
        endwhile
        let l:frac = (l:frac > 102) ? '.'..(l:frac * 10 / 1024) : ''
        " 'traditional' binary prefix
        return l:num..l:frac..strpart('KMGTPEZY', l:pow, 1)
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
            let l:letter += 1
            let l:mask /= 2
        endwhile
    endif
    return l:result
endfunction

" drop '.' and '..' out of {items}
function s:no_dots(items) abort
    return filter(copy(a:items), {_, v -> v !~# '\([\/]\)\.\+\1$'})
endfunction

" read directory contents
function s:readdir(dir) abort
    let l:dir = fnamemodify(a:dir, ':p')
    let l:is_root = l:dir is# fnamemodify(l:dir, ':h')
    let l:lines = v:null
    let l:slash = l:dir[-1:]

    if l:slash is# '/' || l:slash is# '\'
        if exists('*readdir')
            let l:lines = readdir(l:dir)
            call map(l:lines, {_, f -> isdirectory(l:dir..f) ? l:dir..f..l:slash :
                \ l:dir..f})
            if !l:is_root
                " non-root directory: add '..'
                call insert(l:lines, l:dir..'..'..l:slash)
            endif
        else "glob()
            let l:lines = glob(l:dir..'.?*', 0, 1) + glob(l:dir..'*', 0, 1)
            call map(l:lines, {_, f -> isdirectory(f) ? f..l:slash : f})
            if l:is_root
                " root directory: filter out '..'
                let l:lines = s:no_dots(l:lines)
            endif
        endif
    endif

    return l:lines
endfunction

" Implements 'Change drive' dialog on MS-Windows
function! drvo#change_drive() abort
    let l:drives = s:get_drives()
    if !empty(l:drives)
        " 'closure' function to process user choice
        function! s:on_end_dialog(_, result) abort closure
            if a:result > 0
                "BUG: Neovim cannot fnamemodify('C:', ':p:h')
                let l:dir = has('nvim') ? l:drives[a:result - 1]..'/' :
                    \ fnameescape(fnamemodify(l:drives[a:result - 1], ':p:h'))
                " cd to new dir
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

" Open List of items
function! drvo#enter(items, ...) abort
    let l:altbuf = get(w:, 'drvo_altbuf', bufnr())
    let l:dir = get(a:, 1)
    if l:dir is# 'h'
        let [l:cmd, l:split] = ['leftabove vnew', v:true]
    elseif l:dir is# 'j'
        let [l:cmd, l:split] = ['rightbelow new', v:true]
    elseif l:dir is# 'k'
        let [l:cmd, l:split] = ['leftabove new', v:true]
    elseif l:dir is# 'l'
        let [l:cmd, l:split] = ['rightbelow vnew', v:true]
    else
        let [l:cmd, l:split] = ['vnew', v:false]
    endif

    if l:split
        let l:winid = win_getid()
        execute winnr(l:dir) != win_id2win(l:winid) ? 'wincmd '..l:dir : l:cmd
    endif
    execute 'edit' fnameescape(s:chomp(a:items[0]))
    let @# = l:altbuf
    for l:item in reverse(a:items[1:])
        execute 'keepalt' l:cmd fnameescape(s:chomp(l:item))
        wincmd p
    endfor
    if l:split
        call win_gotoid(l:winid)
    endif
endfunction

" Print misc. file info
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

" Prepare file name for passing to :!cmd
function! drvo#forbang(fname) abort
    " relative path?
    let l:fname = fnamemodify(a:fname, ':~:.')
    if has('win32') && l:fname =~# '^[\/]'
        " force drive letter under Windows not to confuse MSYS/Cygwin etc.
        let l:fname = fnamemodify(a:fname, ':p')
    endif
    return shellescape(l:fname, v:true)
endfunction

" Make syntax to match arglist
function! drvo#mark() abort
    syntax clear drvoMark
    for l:name in map(argv(), {_, v -> fnamemodify(v, ':p')})
        let l:tail = fnamemodify(l:name, ':t')
        let l:head = fnamemodify(l:name, ':h')
        let l:isdir = empty(l:tail)
        if l:isdir
            " this is a directory: go one level deeper
            let l:tail = fnamemodify(l:head, ':t')
            let l:head = fnamemodify(l:head, ':h')
        endif
        " make sure our head ends in a slash
        let l:head = fnamemodify(l:head, ':p')
        " match tail if preceded by head and followed by slash (for dirs)
        execute printf('syntax match drvoMark %s/\V\%s\%%(\^%s\)\@%d<=%s%s\$/ contained',
            \ l:isdir ? 'nextgroup=drvoLastSlash ' : '', &fileignorecase ? 'c' : 'C',
            \ escape(l:head, '\/'), strlen(l:head), l:tail, l:isdir ? printf('\ze\[%s]',
            \ drvo#slash()) : '')
    endfor
endfunction

" Apply sorting and such
function! drvo#prettify() abort
    " force bufname update
    silent! noautocmd lcd .

    " sort directories first; then sort files by extension
    execute printf('sort %s /^.*[%s]/', &fileignorecase ? 'i' : '', drvo#slash())
    execute printf('sort %s /\.[^.%s]\+$/r', &fileignorecase ? 'i' : '', drvo#slash())

    " remember altbuf
    let l:altbuf = bufnr(0)
    if buflisted(l:altbuf) && getbufvar(l:altbuf, '&filetype') isnot# 'drvo'
        let w:drvo_altbuf = l:altbuf
    endif

    " move cursor to the previous buffer's name
    call search('\V\C'..escape(@#, '\'), 'cw')
endfunction

" Fill in our buffer
function! drvo#readcmd(fmt) abort
    if a:fmt is# 'dir'
        let l:lines = s:readdir(@%)
    else
        "TODO
    endif

    if empty(l:lines)
        echohl ErrorMsg | echo 'Cannot read a directory' | echohl None
        let l:lines = fnamemodify(empty(@#) ? getcwd() : @#, ':p')
    endif

    silent call deletebufline('', 1, '$')
    call setline(1, l:lines)
    setfiletype drvo
endfunction

" Xor arglist with another {items} List
" Note: List of {items} must be fully expanded
function! drvo#sel_toggle(items) abort
    " expand all names in arglist
    let l:argv = map(argv(), {_, v -> fnamemodify(v, ':p')})
    " toggle all items
    for l:item in s:no_dots(a:items)
        let l:idx = index(l:argv, l:item)
        if l:idx < 0
            $argadd `=l:item`
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
    new
    silent! lcd `=a:dir`
    call setline(1, '#!'..&shell)
    call setline(2, 'cd '..shellescape(getcwd()))
    for l:item in (empty(a:items) ? argv() : a:items)
        call append('$', substitute(a:fmt, '{\([^}]*\)}',
            \ '\=fnamemodify(l:item, empty(submatch(1)) ? ":.:S" : submatch(1))', 'g'))
    endfor
    filetype detect
endfunction

" drvo#slash()
" Get path separator(s), i.e. '\/' or '/'
function! drvo#slash() abort
    return exists('+shellslash') ? '\/' : '/'
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
