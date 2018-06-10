" Vim global plugin for sql terminal functions
" Last Change: 2018 Jun 07
" Maintainer: NORA75
" Licence: MIT
" Add Command,Mapping and Autocommand

if exists('b:did_DatabaseTerminal')
    finish
endif
let b:did_DatabaseTerminal = 1
let s:savecpo = &cpo
set cpo&vim

nmap <silent><buffer> <Space>r <Plug>(DatabaseTerminal_runCom)
vmap <silent><buffer> <Space>r <Plug>(DatabaseTerminal_runCom)

let &cpo = s:savecpo
unlet s:savecpo
