" Vim filetype file
" Language:     vim-drvo plugin
" Maintainer:   matveyt
" Last Change:  2021 May 03
" License:      https://unlicense.org
" URL:          https://github.com/matveyt/vim-drvo

if exists('b:did_ftplugin')
    finish
endif
let b:did_ftplugin = 1

let s:save_cpo = &cpo
set cpo&vim

" buffer-local options
let b:undo_ftplugin = 'setl bt< bh< swf< ul<'
setlocal buftype=nowrite noswapfile undolevels=0
let &l:bufhidden = exists('#BufReadCmd#<buffer>') ? 'delete' : 'hide'
" window-local options
let b:undo_ftplugin .= ' cocu< cole< cul< spell< wrap<'
setlocal concealcursor=n conceallevel=2 cursorline nospell nowrap

" create shell script with names from Visual selection (or arglist)
command! -buffer -range -nargs=? -complete=shellcmd Shdo
    \ call drvo#shdo(empty(<q-args>) ? '{}' : <q-args>, @%,
        \ <range> ? getline(<line1>, <line2>) : v:null)
" find file under @% directory
command! -buffer -nargs=1 Findfile
    \ call setloclist(0, [], 'r', {'lines': glob('%/**/'..<q-args>, v:false, v:true),
        \ 'efm': '%f', 'title': 'Find file: '..<q-args>}) | lopen
" select/deselect file mask
command! -buffer -nargs=1 Selectfile $argadd <args> | call drvo#mark()
command! -buffer -nargs=1 Deselectfile argdelete <args> | call drvo#mark()

" g? to show help
nnoremap <buffer><silent>g? :help! drvo-mappings<CR>

" <CR> and <2-LeftMouse> to change directory/open file
nnoremap <buffer><silent><CR> :<C-U>call drvo#enter(getline('.', line('.') +
    \ v:count1 - 1))<CR>
xnoremap <buffer><silent><CR> :<C-U>call drvo#enter(getline("'<", "'>"))<CR>
nnoremap <buffer><silent><2-LeftMouse> :<C-U>call drvo#enter(getline('.', line('.') +
    \ v:count1 - 1))<CR>
xnoremap <buffer><silent><2-LeftMouse> :<C-U>call drvo#enter(getline("'<", "'>"))<CR>

" I/A/O/o to open current file/dir on the left/right/above/below
nnoremap <buffer><silent>I :<C-U>call drvo#enter(getline('.', line('.') +
    \ v:count1 - 1), 'h')<CR>
xnoremap <buffer><silent>I :<C-U>call drvo#enter(getline("'<", "'>"), 'h')<CR>
nnoremap <buffer><silent>A :<C-U>call drvo#enter(getline('.', line('.') +
    \ v:count1 - 1), 'l')<CR>
xnoremap <buffer><silent>A :<C-U>call drvo#enter(getline("'<", "'>"), 'l')<CR>
nnoremap <buffer><silent>O :<C-U>call drvo#enter(getline('.', line('.') +
    \ v:count1 - 1), 'k')<CR>
xnoremap <buffer><silent>O :<C-U>call drvo#enter(getline("'<", "'>"), 'k')<CR>
nnoremap <buffer><silent>o :<C-U>call drvo#enter(getline('.', line('.') +
    \ v:count1 - 1), 'j')<CR>
xnoremap <buffer><silent>o :<C-U>call drvo#enter(getline("'<", "'>"), 'j')<CR>

" <Tab> to move to previous window
nnoremap <buffer><Tab> <C-W>p
" <BS> to move up directory tree
nnoremap <buffer><expr><silent><BS> ':<C-U>edit %'..repeat(':h', v:count1)..'<CR>'
" <C-^> to switch to altbuf
nnoremap <buffer><expr><silent><C-^>
    \ ':<C-U>buffer '..(v:count ? v:count : get(w:, 'drvo_altbuf', '#'))..'<CR>'
" = to sync current working directory to buffer
nnoremap <buffer><nowait><silent>= :noautocmd lcd % <Bar> pwd<CR>
" ~ to go $HOME
nnoremap <buffer><silent>~ :<C-U>edit $HOME<CR>
" . to go to current working directory
nnoremap <buffer><silent>. :<C-U>edit .<CR>

" ! to compose shell command
nnoremap <buffer>! :<C-U><Space><C-R>=join(map(getline('.', line('.') + v:count1 - 1),
    \ 'drvo#forbang(v:val)'))<CR><C-B>!
xnoremap <buffer>! :<C-U><Space><C-R>=join(map(getline("'<", "'>"),
    \ 'drvo#forbang(v:val)'))<CR><C-B>!

" <C-D> to change drive
nnoremap <buffer><silent><C-D> :call drvo#change_drive()<CR>
" <C-L> to reload directory
nnoremap <buffer><silent><C-L> :edit<CR>
" <C-G> to show file(s) size/time/permissions etc.
nnoremap <buffer><silent><C-G> :<C-U>call drvo#fileinfo(getline('.', line('.') +
    \ v:count1 - 1))<CR>
xnoremap <buffer><silent><C-G> :<C-U>call drvo#fileinfo(getline("'<", "'>"))<CR>

" <Space> to toggle items in the arglist
nnoremap <buffer><silent><Space>
    \ :<C-U>call drvo#sel_toggle(getline('.', line('.') + v:count1 - 1)) <Bar>
    \ call cursor(line('.') + v:count1, 1)<CR>
xnoremap <buffer><silent><Space>
    \ :<C-U>call drvo#sel_toggle(getline("'<", "'>")) <Bar>
    \ call cursor(line("'>") + 1, 1)<CR>
" D to clear arglist
nnoremap <buffer><silent>D :%argdelete <Bar> syntax clear drvoMark<CR>
" <kMultiply> to invert selection
nnoremap <buffer><silent><kMultiply> :call drvo#sel_toggle(getline(1, '$'))<CR>
" +/- to select/deselect file mask
nnoremap <buffer>+ :Selectfile<Space>%/*
nnoremap <buffer><kPlus> :Selectfile<Space>%/*
nnoremap <buffer>- :Deselectfile<Space>%/*
nnoremap <buffer><kMinus> :Deselectfile<Space>%/*
" ? to find file
nnoremap <buffer>? :Findfile<Space>

" sort lines, set cursor etc.
call drvo#prettify()

let &cpo = s:save_cpo
unlet s:save_cpo
