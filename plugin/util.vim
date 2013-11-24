" Vim-util: A vim plugin to adjust opacity, size and colorscheme.
" Author: BeyondIM <lypdarling at gmail dot com>
" HomePage: https://github.com/BeyondIM/vim-util
" License: MIT license
" Version: 0.2

let s:save_cpo = &cpo
set cpo&vim

" auto command {{{1
autocmd VimEnter * call util#readParams()
autocmd VimLeavePre * call util#writeParams()
autocmd VimResized * call util#adjustSize()
" }}}1

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: set shiftwidth=4 tabstop=4 softtabstop=4 expandtab foldmethod=marker:
