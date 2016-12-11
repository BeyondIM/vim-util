let s:save_cpo = &cpo
set cpo&vim

function! stl#refreshStatus()
    for wnum in range(1, winnr('$'))
        call s:RefreshCurStatus(wnum == winnr(), wnum)
    endfor
endfunction

function! s:RefreshCurStatus(active, ...)
    " color
    highlight ModeV     ctermfg=255 guifg=#eeeeee ctermbg=162 guibg=#d700b7
    highlight ModeS     ctermfg=255 guifg=#eeeeee ctermbg=98  guibg=#875fd7
    highlight ModeI     ctermfg=255 guifg=#eeeeee ctermbg=106 guibg=#87af00
    highlight ModeR     ctermfg=255 guifg=#eeeeee ctermbg=160 guibg=#d70000
    highlight ModeN     ctermfg=255 guifg=#eeeeee ctermbg=26  guibg=#005fd7
    highlight Path      ctermfg=255 guifg=#eeeeee ctermbg=104 guibg=#8787d7
    highlight RoMod     ctermfg=160 guifg=#d70000 ctermbg=242 guibg=#6c6c6c
    highlight FfFenc    ctermfg=255 guifg=#eeeeee ctermbg=242 guibg=#6c6c6c
    highlight FileType  ctermfg=255 guifg=#eeeeee ctermbg=244 guibg=#808080
    highlight Percent   ctermfg=16  guifg=#000000 ctermbg=246 guibg=#949494
    highlight Position  ctermfg=16  guifg=#000000 ctermbg=251 guibg=#c6c6c6
    " color for plugins
    highlight ALE ctermfg=255 guifg=#eeeeee ctermbg=166 guibg=#d75f00
    let wnum = a:0 ? a:1 : 0 
    call setwinvar(wnum, '&statusline', '%!Status(' . a:active . ',' . wnum . ')')
endfunction

function! Status(active, wnum)
    let m    = mode()
    let ro   = getwinvar(a:wnum, '&readonly')
    let mod  = getwinvar(a:wnum, '&modified')
    let ff   = getwinvar(a:wnum, '&fileformat')
    let fenc = getwinvar(a:wnum, '&fileencoding')
    let ft   = getwinvar(a:wnum, '&filetype')
    let name = bufname(winbufnr(a:wnum))

    if !a:active || name =~ '^\[.\+\]\|__.\+__\|NERD_tree_\|ControlP'
        let stat = s:Color(a:active, 'Path', ' %<%.99f ')
    else
        " mode
        if m =~# '\v(v|V|)'
            let stat = s:Color(a:active, 'ModeV', ' Visual ')
        elseif m =~# '\v(s|S|)'
            let stat = s:Color(a:active, 'ModeS', ' Select ')
        elseif m =~# '\vi'
            let stat = s:Color(a:active, 'ModeI', ' Insert ')
        elseif m =~# '\v(R|Rv)'
            let stat = s:Color(a:active, 'ModeR', ' Replace ')
        else
            let stat = s:Color(a:active, 'ModeN', ' Normal ')
        endif
        " path
        let stat .= s:Color(a:active, 'Path', ' %<%.99f ')
        " readonly and modified
        let ro_mod = ro ? (mod ? 'RO, +' : 'RO') : (mod ? '+' : '')
        let stat .= !empty(ro_mod) ? s:Color(a:active, 'RoMod', ' '.ro_mod.' ') : ''

        let stat .= '%='
        " ale
        let stat .= exists(':ALENext') ? s:Color(a:active, 'ALE', '%( %{ale#statusline#Status()} %)') : ''
        " fileformat and fileencoding
        let ff_fenc = (fenc != 'utf-8' && !empty(fenc)) ? (ff != 'unix' ? fenc.', '.ff : fenc) : (ff != 'unix' ? ff : '') 
        let stat .= !empty(ff_fenc) ? s:Color(a:active, 'FfFenc', ' '.ff_fenc.' ') : ''
        " filetype
        let stat .= !empty(ft) ? s:Color(a:active, 'FileType', ' '.ft.' ') : ''
        " percentage
        let stat .= s:Color(a:active, 'Percent', ' %p%% ')
        " line and column
        let stat .= s:Color(a:active, 'Position', ' %.5l:%-.3c ')
    endif
    return stat
endfunction

function! s:Color(active, name, content)
    if a:active
        return '%#' . a:name . '#' . a:content . '%*'
    else
        return a:content
    endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: set shiftwidth=4 tabstop=4 softtabstop=4 expandtab foldmethod=marker:
