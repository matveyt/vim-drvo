" Vim filetype file
" Language:     vim-drvo plugin
" Maintainer:   matveyt
" Last Change:  2020 Feb 13
" License:      VIM License
" URL:          https://github.com/matveyt/vim-drvo

if exists('b:did_ftplugin')
    finish
endif
let b:did_ftplugin = 1

let s:save_cpo = &cpo
set cpo&vim

" force bufname update
noautocmd lcd .

" buffer-local options
let b:undo_ftplugin = 'setl bt< bh< swf< ul<'
setlocal buftype=nowrite bufhidden=delete noswapfile undolevels=0
" window-local options
let b:undo_ftplugin .= ' cocu< cole< cul< list< spell< wrap<'
setlocal concealcursor=n conceallevel=2 cursorline nolist nospell nowrap

" create shell script with names from Visual selection (or arglist)
command! -buffer -range -nargs=? -complete=shellcmd Shdo
    \ call drvo#shdo(empty(<q-args>) ? '{}' : <q-args>, fnameescape(@%),
        \ <range> ? drvo#items(<line1>, <line2>) : v:null)

" local mappings (see :h no_plugin_maps)
if !exists('g:no_plugin_maps') && !exists('g:no_drvo_maps')
    " g? to show help
    nnoremap <buffer><silent>g? :help drvo-mappings<CR>

    " <CR> and <2-LeftMouse> to change directory/open file
    nnoremap <buffer><expr><silent><CR> ':edit ' . drvo#getline('.') . "\<CR>"
    nnoremap <buffer><expr><silent><2-LeftMouse> ':edit ' . drvo#getline('.') . "\<CR>"
    " <BS> to move up directory tree
    nnoremap <buffer><expr><silent><BS>
        \ ":\<C-U>edit %" . repeat(':h', v:count1) . "\<CR>"
    " <C-^> to switch to the altbuf (last known good)
    nnoremap <buffer><expr><silent><C-^>
        \ ":\<C-U>edit #" . (v:count ? v:count : get(w:, 'drvo_altbuf')) . "\<CR>"

    " <C-D> to change drive
    nnoremap <buffer><silent><C-D> :call drvo#change_drive()<CR>
    " <C-L> to reload directory
    nnoremap <buffer><silent><C-L> :edit<CR>
    " <C-G> to show file(s) size/time/permissions etc.
    nnoremap <buffer><silent><C-G>
        \ :<C-U>call drvo#fileinfo(drvo#items('.', line('.') + v:count1 - 1))<CR>
    xnoremap <buffer><silent><C-G> :<C-U>call drvo#fileinfo(drvo#items("'<", "'>"))<CR>

    " <Space> to toggle items in the arglist
    nnoremap <buffer><silent><Space>
        \ :<C-U>call drvo#sel_toggle(drvo#items('.', line('.') + v:count1 - 1))
        \ <Bar>call cursor(line('.') + v:count1, 1)<CR>
    xnoremap <buffer><silent><Space>
        \ :<C-U>call drvo#sel_toggle(drvo#items("'<", "'>"))
        \ <Bar>call cursor(line("'>") + 1, 1)<CR>
    " D to clear arglist
    nnoremap <buffer><silent>D :%argdelete <Bar> syntax clear drvoMark<CR>
    " <kMultiply> to invert selection
    nnoremap <buffer><silent><kMultiply> :call drvo#sel_toggle(drvo#items(1, '$'))<CR>
    " +/- to select/deselect file mask
    nnoremap <buffer><silent>+ :call drvo#sel_mask(v:true)<CR>
    nnoremap <buffer><silent><kPlus> :call drvo#sel_mask(v:true)<CR>
    nnoremap <buffer><silent>- :call drvo#sel_mask(v:false)<CR>
    nnoremap <buffer><silent><kMinus> :call drvo#sel_mask(v:false)<CR>

    " I/A/O/o to open current file/dir on the left/right/above/below
    nnoremap <buffer><expr><silent>I
        \ ':above vsplit +edit\ ' . drvo#getline('.') . ' <Bar>wincmd p' . "\<CR>"
    nnoremap <buffer><expr><silent>A
        \ ':below vsplit +edit\ ' . drvo#getline('.') . ' <Bar>wincmd p' . "\<CR>"
    nnoremap <buffer><expr><silent>O
        \ ':above  split +edit\ ' . drvo#getline('.') . ' <Bar>wincmd p' . "\<CR>"
    nnoremap <buffer><expr><silent>o
        \ ':below  split +edit\ ' . drvo#getline('.') . ' <Bar>wincmd p' . "\<CR>"
    " the same for Visual selection
    xnoremap <buffer><silent>I :normal I<CR>
    xnoremap <buffer><silent>A :normal A<CR>
    xnoremap <buffer><silent>O :normal O<CR>
    xnoremap <buffer><silent>o :normal o<CR>
endif

let &cpo = s:save_cpo
unlet s:save_cpo
