let s:save_cpo = &cpo
set cpo&vim

" Prepare {{{1

let s:isWin = has('win32') || has('win64')
let s:isMac = has('unix') && substitute(system('uname'), '\n', '', '') =~# 'Darwin\|Mac' 
let s:isLinux = has('unix') && substitute(system('uname'), '\n', '', '') ==# 'Linux' 

" Check file whether is readable {{{2
function! s:CheckFileReadable(file)
    if !filereadable(a:file)
        silent! execute 'keepalt botright 1new'
        silent! execute 'edit ' . a:file
        silent! execute 'write!'
        silent! execute 'bwipeout!'
        silent! execute 'close!'
        if !filereadable(a:file)
            call s:EchoMsg(a:file." can't read!", 'warn')
            return
        endif
    endif
endfunction
" }}}2

" Check file whether is writable {{{2
function! s:CheckFileWritable(file)
    if !filewritable(a:file)
        call s:EchoMsg(a:file." can't write!", 'warn')
        return
    endif
endfunction
" }}}2

" echo message {{{2
function! s:EchoMsg(message,type)
    if a:type == 'warn'
        echohl WarningMsg | echo a:message | echohl None
    elseif a:type == 'error'
        echohl ErrorMsg | echo a:message | echohl None
    endif
endfunction
" }}}2

" }}}1

" Servers object {{{1

let s:server = {}

" new {{{2
function! s:server.new(servername)
    let newServer = copy(self)
    let newServer.servername = a:servername
    let newServer.isMaximized = 0
    let newServer.opacity = (s:isWin ? 255 : 0)
    let newServer.lines = 50
    let newServer.columns = 120
    let newServer.winposx = 0
    let newServer.winposy = 0
    let newServer.color = 'default'
    let newServer.bg = 'light'
    return newServer
endfunction
" }}}2

" save to file {{{2
function! s:server.saveToFile()
    let dic = {'servername': self.servername, 'isMaximized': self.isMaximized, 'opacity': self.opacity, 
                \'lines': self.lines, 'columns': self.columns, 'winposx': self.winposx, 
                \'winposy': self.winposy, 'color': self.color, 'bg': self.bg}
    call s:CheckFileReadable(g:serverInfoFile)
    call s:CheckFileWritable(g:serverInfoFile)
    let content = readfile(g:serverInfoFile)
    for line in content
        if eval(line)['servername'] == self.servername
            let idx = index(content, line)
        endif
    endfor
    call remove(content, idx)
    call add(content, string(dic))
    call writefile(content, g:serverInfoFile)
endfunction
" }}}2

" increase opacity {{{2
function! s:server.increaseOpacity()
    if s:isWin && self.opacity < 255
        let self.opacity = self.opacity+12.8>255 ? 255 : float2nr(self.opacity+12.8)
    elseif s:isMac && self.opacity > 0
        let self.opacity = self.opacity-5<0 ? 0 : (self.opacity-5)
    endif
    call self.applyParams()
endfunction
" }}}2

" decrease opacity {{{2
function! s:server.decreaseOpacity()
    if s:isWin && self.opacity > 0
        let self.opacity = self.opacity-12.8<0 ? 0 : float2nr(self.opacity-12.8)
    elseif s:isMac && self.opacity < 100
        let self.opacity = self.opacity+5>100 ? 100 : (self.opacity+5)
    endif
    call self.applyParams()
endfunction
" }}}2

" set dark color forward {{{2
function! s:server.setDarkColorForward()
    if exists('g:colors_name') && index(g:darkColors, g:colors_name) != -1
        if &background == 'light'
            let self.color = g:colors_name
        else
            let idx = index(g:darkColors, g:colors_name)
            let self.color = idx<(len(g:darkColors)-1) ? g:darkColors[idx+1] : g:darkColors[0]
        endif
    else
        let self.color = exists('s:lastDarkColor') ? s:lastDarkColor : g:darkColors[0]
    endif
    let self.bg = 'dark'
    call self.handleColor()
endfunction
" }}}2

" set dark color backward {{{2
function! s:server.setDarkColorBackward()
    if exists('g:colors_name') && index(g:darkColors, g:colors_name) != -1
        if &background == 'light'
            let self.color = g:colors_name
        else
            let idx = index(g:darkColors, g:colors_name)
            let self.color = (idx>0) ? g:darkColors[idx-1] : g:darkColors[-1]
        endif
    else
        let self.color = exists('s:lastDarkColor') ? s:lastDarkColor : g:darkColors[-1]
    endif
    let self.bg = 'dark'
    call self.handleColor()
endfunction
" }}}2

" set light color forward {{{2
function! s:server.setLightColorForard()
    if exists('g:colors_name') && index(g:lightColors, g:colors_name) != -1
        if &background == 'dark'
            let self.color = g:colors_name
        else
            let idx = index(g:lightColors, g:colors_name)
            let self.color = idx<(len(g:lightColors)-1) ? g:lightColors[idx+1] : g:lightColors[0]
        endif
    else
        let self.color = exists('s:lastLightColor') ? s:lastLightColor : g:lightColors[0]
    endif
    let self.bg = 'light'
    call self.handleColor()
endfunction
" }}}2

" set light color backward {{{2
function! s:server.setLightColorBackward()
    if exists('g:colors_name') && index(g:lightColors, g:colors_name) != -1
        if &background == 'dark'
            let self.color = g:colors_name
        else
            let idx = index(g:lightColors, g:colors_name)
            let self.color = (idx>0) ? g:lightColors[idx-1] : g:lightColors[-1]
        endif
    else
        let self.color = exists('s:lastLightColor') ? s:lastLightColor : g:lightColors[-1]
    endif
    let self.bg = 'light'
    call self.handleColor()
endfunction
" }}}2

" set color {{{2
function! s:server.setColor()
    if index(g:darkColors, self.color) != -1
        let self.bg = 'dark'
    elseif index(g:lightColors, self.color) != -1
        let self.bg = 'light'
    else
        silent! execute 'colorscheme default'
        let &background = 'light'
        return
    endif
    call self.handleColor()
endfunction
" }}}2

" check whether color is valid {{{2
function! s:server.isValidColor()
    let colorsPathList = globpath(&runtimepath, 'colors/*.vim', 1)
    let colorsList = map(split(colorsPathList, '\n'), "fnamemodify(v:val, ':t:r')")
    if index(colorsList, self.color) != -1
        return 1
    else
        return
    endif
endfunction
" }}}2

" handle color {{{2
function! s:server.handleColor()
    if !self.isValidColor()
        call s:EchoMsg('Color scheme: '.self.color.' is invalid.', 'error')
        return
    else
        silent! execute 'colorscheme '.self.color
    endif
    if self.bg == 'dark'
        let &background = 'dark'
        let s:lastDarkColor = self.color
    elseif self.bg == 'light'
        let &background = 'light'
        let s:lastLightColor = self.color
    endif
    redraw
    echo 'Current color scheme: '.self.color.'('.self.bg.')'
endfunction
" }}}2

" apply params {{{2
function! s:server.applyParams()
    if self.isMaximized+0
        if s:isWin
            call libcallnr("vimtweak.dll", "EnableMaximize", 1)
            call libcallnr("vimtweak.dll", "EnableCaption", 0)
        elseif s:isMac
            let &g:fullscreen = 1
        endif
    else
        silent! execute 'set lines=' . self.lines . ' columns=' . self.columns
        silent! execute 'winpos ' . self.winposx . ' ' .  self.winposy
        if s:isWin
            call libcallnr("vimtweak.dll", "EnableCaption", 1)
            call libcallnr("vimtweak.dll", "EnableMaximize", 0)
        elseif s:isMac
            let &g:fullscreen = 0
        endif
    endif
    if s:isWin
        call libcallnr("vimtweak.dll", "SetAlpha", self.opacity+0)
    elseif s:isMac
        let &g:transparency = self.opacity+0
    endif
    call self.setColor()
endfunction
" }}}2

" }}}1

" vim-exterior function {{{1

if !exists('g:serverInfoFile')
    let g:serverInfoFile = expand($HOME . '/.vimdb/.serverinfo', 1)
endif

let g:serverList = []

function! util#readParams()
    let server = s:server.new(v:servername)
    call s:CheckFileReadable(g:serverInfoFile)
    let content = readfile(g:serverInfoFile)
    for line in content
        if eval(line)['servername'] == v:servername
            let server = extend(server, eval(line), 'force')        
            break
        endif
    endfor
    call add(g:serverList, server)
    for server in g:serverList
        call server.applyParams()
    endfor
endfunction

function! util#writeParams()
    for server in g:serverList
        call server.saveToFile()
    endfor
endfunction

function! util#adjustColor(color, direction)
    for server in g:serverList
        if a:color =='dark' && a:direction == '+'
            call server.setDarkColorForward()
        endif
        if a:color == 'dark' && a:direction == '-'
            call server.setDarkColorBackward()
        endif
        if a:color == 'light' && a:direction == '+'
            call server.setLightColorForard()
        endif
        if a:color == 'light' && a:direction == '-'
            call server.setLightColorBackward()
        endif
    endfor
endfunction

function! util#adjustOpacity(direction)
    for server in g:serverList
        let server.lines = &lines
        let server.columns = &columns
        let server.winposx = (getwinposx()<0 ? 0 : getwinposx())
        let server.winposy = (getwinposy()<0 ? 0 : getwinposy())
        if a:direction == '+'
            call server.increaseOpacity()
        elseif a:direction == '-'
            call server.decreaseOpacity()
        endif
    endfor
endfunction

function! util#toggleMaximize()
    for server in g:serverList
        if !server.isMaximized
            let server.origLines = &lines
            let server.origColumns = &columns
            let server.origWinposx = (getwinposx()<0 ? 0 : getwinposx())
            let server.origWinposy = (getwinposy()<0 ? 0 : getwinposy())
            let server.isMaximized = 1
        else
            let server.lines = exists('server.origLines') ? server.origLines : server.lines
            let server.columns = exists('server.origColumns') ? server.origColumns : server.columns
            let server.winposx = exists('server.origWinposx') ? server.origWinposx : server.winposx
            let server.winposy = exists('server.origWinposy') ? server.origWinposy : server.winposy
            let server.isMaximized = 0
        endif
        call server.applyParams()
    endfor
endfunction

function! util#adjustSize()
    for server in g:serverList
        let server.lines = &lines
        let server.columns = &columns
        let server.winposx = (getwinposx()<0 ? 0 : getwinposx())
        let server.winposy = (getwinposy()<0 ? 0 : getwinposy())
        call server.applyParams()
    endfor
endfunction

nnoremap <silent> <C-F10> :<C-U>call util#adjustColor('dark', '+')<CR>
nnoremap <silent> <M-F10> :<C-U>call util#adjustColor('dark', '-')<CR>
nnoremap <silent> <C-F11> :<C-U>call util#adjustColor('light', '+')<CR>
nnoremap <silent> <M-F11> :<C-U>call util#adjustColor('light', '-')<CR>

if s:isWin && !empty(glob($VIMRUNTIME.'/vimtweak.dll')) || s:isMac
    nnoremap <silent> <C-F12> :<C-U>call util#toggleMaximize()<CR>
    nnoremap <silent> <C-Left> :<C-U>call util#adjustOpacity('-')<CR>
    nnoremap <silent> <C-Right> :<C-U>call util#adjustOpacity('+')<CR>
endif

" }}}1

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: set shiftwidth=4 tabstop=4 softtabstop=4 expandtab foldmethod=marker:
