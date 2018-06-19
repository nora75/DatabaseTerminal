" Vim global plugin for sql terminal functions
" Last Change: 2018 Jun 10
" Maintainer: NORA75
" Licence: MIT
" autoload

if exists('g:loaded_DatabaseTerminalAutoload')
    finish
endif
let g:loaded_DatabaseTerminalAutoload = 1
let s:savecpo = &cpo
set cpo&vim
let s:lines = []
let s:called = 0

if !has('terminal')
    call s:ech('Please update Vim to vim8.1 compiled with terminal window')
    finish
endif

func! s:rec(...) abort
    if exists('s:timer')
        call timer_stop(s:timer)
    endif
    let s:n = timer_start(10,function('<SID>getlines'))
    return
endfunc

func! s:endDB(...) abort
    if !exists('s:sqlb')
        return
    endif
    if s:called > 1
        call s:ech('Please run Database Server first')
        return
    endif
    let s:called += 1
    if !s:err()
        return
    endif
    echo 'end DbTerminal...'
    let s:called = 0
    call s:getlines()
    unlet s:sqlb
    return
endfunc

func! s:getlines(...) abort
    if !exists('s:sqlb')
        return
    endif
    let newline = getbufline('DbTerminal',1,"$")
    if len(newline) >= len(s:lines)
        if s:lines != newline
            let s:lines = newline
        endif
    endif
    return
endfunc

func! s:err() abort
    let msg = string(term_getline(s:sqlb,2))
    if msg =~? 'error' && msg =~? 'connect'
        unlet s:sqlb
        if a:0
            call DatabaseTerminal#startDB('server'.a:1)
        else
            call DatabaseTerminal#startDB('server')
        endif
        return
    endif
    return -1
endfunc

func! s:ech(ms) abort
    echohl WarningMsg
    echo a:ms
    echohl None
    return
endfunc

func! DatabaseTerminal#startDB(...) abort
    echo 'start DbTerminal...'
    try
        let dict = copy(s:dict)
    catch
        call s:ech('Please set variables first,See helpfile :help DatabaseTerminal-Intro')
    endtry
    if a:0
        let args = join(a:000)
        if args =~ 'server'
            call DatabaseTerminal#startServ()
        endif
        let args = ''
        if args =~? 'vs'
            let s:opencom = 'vnew'
            let args = 'vs'
        elseif args =~? 'sp'
            silent! call remove(dict,'vertical')
            let s:opencom = 'new'
            let args = 'sp'
        endif
        let dict['exit_cb'] = function('s:endDB',[args])
    endif
    nmap <silent><buffer> <Space>r <Plug>(DatabaseTerminal_runCom)
    vmap <silent><buffer> <Space>r <Plug>(DatabaseTerminal_runCom)
    exe s:opencom
    let s:sqlb = term_start(s:dbrun, dict)
    return
endfunc

func! DatabaseTerminal#runcom(line1,line2) abort
    if !exists('s:sqlb')
        call DatabaseTerminal#startDB()
        return
    elseif term_getstatus(s:sqlb) ==# 'normal'
        call term_sendkeys(s:sqlb,'i')
    endif
    for i in getline(a:line1,a:line2)
        call term_sendkeys(s:sqlb,i."\<CR>")
    endfor
    return
endfunc

func! DatabaseTerminal#conv() abort
    if !executable('pandoc')
        call s:ech('You Don''t meet the requirements to output file')
        return
    endif
    if !len(s:lines)
        echo 'no output lines'
        return
    endif
    call s:getlines()
    try
        echo 'execution result is outputed to '.s:output
    catch
        call s:ech('Please set variables first,See helpfile :help DatabaseTerminal-Intro')
    endtry
    if filereadable(s:output)
        call system('pandoc -f '.g:DatabaseTerminal_outputFormat.' -t markdown -o '.s:txt.' '.s:output)
        call delete(s:output)
        call insert(s:lines,'')
    endif
    call map(s:lines,'v:val."  "')
    call writefile(s:lines,s:txt,'a')
    call system('pandoc -t '.g:DatabaseTerminal_outputFormat.' -o '.s:output.' '.s:txt)
    call delete(s:txt)
    let s:lines = []
    return
endfunc

func! DatabaseTerminal#startServ() abort
    silent! call system(s:startcom)
    return
endfunc

if exists('g:DatabaseTerminal_dbRunCom')
    let s:dbrun = g:DatabaseTerminal_dbRunCom
    if exists('g:DatabaseTerminal_dbRunArgs')
        let s:dbrun .= ' '.g:DatabaseTerminal_dbRunArgs
    endif
    let s:dict = 
    \ { "term_name" : "DbTerminal" ,
    \ "curwin" : 1 ,
    \ "callback" : function('s:getlines') ,
    \ "exit_cb" : function('s:endDB') ,
    \ "term_finish" : "close" }
endif

aug DatabaseTerminal
    au!
    au VimLeavePre * if buflisted('s:sqlb')|exe 'silent! bw! '.s:sqlb|endif
aug END
if exists('g:DatabaseTerminal_autoOutput')
    aug DatabaseTerminal
        au VimLeavePre * call DatabaseTerminal#conv()
    aug END
endif

let s:folder = expand('~').'\'
let s:folder .= 'DBlog'
if exists('g:DatabaseTerminal_folder') && exists('g:DatabaseTerminal_fileName')
    let s:folder = g:DatabaseTerminal_folder
    if s:folder !~# '\M/$'
        let s:folder .= '/'
    endif
    let s:folder .= g:DatabaseTerminal_fileName
    let s:folder = expand(s:folder)
endif
if exists('g:DatabaseTerminal_autodate')
    let s:date = strftime('%m%d')
    let s:folder .= s:date
endif
let g:DatabaseTerminal_outputFormat = 'markdown'
let g:DatabaseTerminal_outputExtens = 'md'
let s:txt = s:folder.'.txt'
let s:output = s:folder.'.'.g:DatabaseTerminal_outputExtens

let s:startcom = ''
let s:stopcom = ''
if exists('g:DatabaseTerminal_dbName')
    if has('win32') || has('win64')
        let s:startcom = 'net start '.g:DatabaseTerminal_dbName
        let s:stopcom = 'call system(''net stop '.g:DatabaseTerminal_dbName.''')'
    endif
endif

if exists('g:DatabaseTerminal_dontStop')
    let s:stopcom = ''
endif

if exists('g:DatabaseTerminal_openCom')
    let s:opencom = g:DatabaseTerminal_openCom
else
    if exists('g:DatabaseTerminal_alwaysOpenVsplit')
        let s:opencom = 'vnew'
    else
        let s:opencom = 'new'
    endif
endif

let &cpo = s:savecpo
unlet s:savecpo
