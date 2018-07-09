" Vim global plugin for sql terminal functions
" Last Change: 05-Jul-2018.
" Maintainer: NORA75
" Licence: MIT
" autoload

if exists('g:loaded_DatabaseTerminal') || !has('terminal')
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

command! -nargs=0 DbTOutPutClear call DatabaseTerminal#clear()

command! -nargs=0 DbTOutPutDelete call DatabaseTerminal#delete()

command! -nargs=* DbTOutPutEdit call DatabaseTerminal#edit(<f-args>)

if !exists('#DatabaseTerminal')
    aug DatabaseTerminal
        au!
    aug END
endif

aug DatabaseTerminal
    autocmd BufNew * call timer_start(0, function('s:ft'))
aug END
if !exists('g:DatabaseTerminal_outputFormat') || !exists('g:DatabaseTerminal_outputExtens')
    let g:DatabaseTerminal_outputFormat = 'markdown'
    let g:DatabaseTerminal_outputExtens = 'md'
endif

function! s:ft(...)
    if &buftype == 'terminal' && &filetype == '' && bufname('%') == 'DbTerminal'
        setl filetype=DbTerminal
    endif
endfunction

let &cpo = s:savecpo
unlet s:savecpo
