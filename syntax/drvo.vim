" Vim syntax file
" Language:     vim-drvo plugin
" Maintainer:   matveyt
" Last Change:  2021 Aug 22
" License:      https://unlicense.org
" URL:          https://github.com/matveyt/vim-drvo

if exists('b:current_syntax')
    finish
endif
let b:current_syntax = 'drvo'

let s:save_cpo = &cpo
set cpo&vim

function s:synmatch(group, pat, opts, arg = v:null) abort
    let l:arg = (type(a:arg) == v:t_list) ? join(a:arg, '\|') : a:arg
    let l:case = &fileignorecase ? 'c' : 'C'
    let l:slash = drvo#slash()
    let l:pat = substitute(a:pat, '$\(\a\+\)', '\=eval(submatch(1))', 'g')

    let l:cmd = printf('syntax match %s /%s/', a:group, l:pat)
    for [l:key, l:value] in items(a:opts)
        if !empty(l:value)
            let l:cmd .= ' ' . l:key
            if type(l:value) == v:t_string
                let l:cmd .= '=' . l:value
            endif
        endif
    endfor

    return execute(l:cmd)
endfunction

" drvoDir is {drvoDirRoot/}{drvoDirTrunk}{/}
call s:synmatch('drvoDir', '^.*[$slash]$', #{contains: 'drvoDirRoot'})
call s:synmatch('drvoDirRoot', '^.*[$slash]\ze.', #{nextgroup: 'drvoDirTrunk,drvoMark',
    \ contained: v:true, conceal: v:true, cchar: exists('g:drvo_glyph[0]') ?
    \ nr2char(g:drvo_glyph[0]) : 0})
call s:synmatch('drvoDirTrunk', '[^$slash]\+', #{nextgroup: 'drvoLastSlash',
    \ contained: v:true})
call s:synmatch('drvoLastSlash', '[$slash]', #{contained: v:true, conceal: v:true})
" drvoFile is {drvoFileRoot/}{drvoFileXXX}
call s:synmatch('drvoFile', '^.*[^$slash]$', #{contains: 'drvoFileRoot'})
call s:synmatch('drvoFileRoot', '^.*[$slash]', #{nextgroup:
    \ 'drvoFileExecutable,drvoFileIgnore,drvoFileSuffixes,drvoMark', contained: v:true,
    \ conceal: v:true, cchar: exists('g:drvo_glyph[1]') ? nr2char(g:drvo_glyph[1]) : 0})
if !empty(getenv('PATHEXT'))
    call s:synmatch('drvoFileExecutable', '.\+\$case\V\%($arg\)\$', #{contained: v:true},
        \ split($PATHEXT, ';'))
endif
if !empty(get(g:, 'ft_ignore_pat'))
    call s:synmatch('drvoFileIgnore', '.\+\$case$arg', #{contained: v:true},
        \ g:ft_ignore_pat)
endif
if !empty(&suffixes)
    call s:synmatch('drvoFileSuffixes', '.\+\$case\V\%($arg\)\$', #{contained: v:true},
        \ split(&suffixes, ','))
endif

" default colors
highlight default link drvoDirTrunk Directory
highlight default link drvoFileExecutable Macro
highlight default link drvoFileIgnore Special
highlight default link drvoFileSuffixes Comment
highlight default link drvoMark IncSearch

" reset all marks
call drvo#mark()

let &cpo = s:save_cpo
unlet s:save_cpo
