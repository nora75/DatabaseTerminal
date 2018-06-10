" Vim global plugin for sql terminal functions
" Last Change: 2018 Jun 8
" Maintainer: NORA75
" Licence: MIT
" autoload

if exists('g:loaded_DatabaseTerminal')
    finish
endif
let g:loaded_DatabaseTerminal = 1
let s:savecpo = &cpo
set cpo&vim

nnoremap <silent> <Plug>(DatabaseTerminal_runCom) :<C-u>call DatabaseTerminal#runcom(line('.'),line('.'))<CR>
vnoremap <silent> <Plug>(DatabaseTerminal_runCom) :<C-u>call DatabaseTerminal#runcom(line("'<"),line("'>"))<CR>

command! -nargs=* DbTerminal call DatabaseTerminal#startDB(<f-args>)

command! -nargs=0 DbTStart call DatabaseTerminal#startServ()

command! -nargs=0 DbTOutPut call DatabaseTerminal#conv()

let &cpo = s:savecpo
unlet s:savecpo
