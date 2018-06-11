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
    echohl WarningMsg
    echo 'Please update Vim to Vim8.1 or get vim8.1 compiled with terminal window'
    echohl None
    finish
endif

func! s:endDB(...) abort
    if s:called > 1
        if bufnr("%") == s:sqlb
            q!
        endif
        echohl WarningMsg
        echo 'Please run '.s:dbruncom.' Server first'
        echohl None
        return
    endif
    let s:called += 1
    if !exists('s:sqlb')
        return
    endif
    let msg = string(term_getline(s:sqlb,2))
    if msg =~? 'error' && msg =~? 'connect'
        if a:0
            call DatabaseTerminal#startDB('server'.a:1)
        endif
        return
    endif
    echo 'end DbTerminal...'
    call extend(s:lines,getline(1,"$"))
    let s:called = 0
    if bufnr("%") == s:sqlb
        q!
    endif
    unlet s:sqlb
    return
endfunc

func! DatabaseTerminal#startDB(...) abort
    echo 'start DbTerminal...'
    let dict = copy(s:dict)
    if a:0
        let args = join(a:000)
        if args =~ 'server'
            call DatabaseTerminal#startServ()
        endif
        let args = ''
        if args =~? 'vs'
            if has_key(dict,'vertical')
                call extend(dict,{'vertical':1})
            endif
            let args = 'vs'
        elseif args =~? 'sp'
            silent! call remove(dict,'vertical')
            let args = 'sp'
        endif
        let dict['exit_cb'] = function('s:endDB',[args])
    endif
    nmap <silent><buffer> <Space>r <Plug>(DatabaseTerminal_runCom)
    vmap <silent><buffer> <Space>r <Plug>(DatabaseTerminal_runCom)
    let s:sqlb = term_start(s:dbrun, dict)
    return
endfunc

func! s:searchall() abort
    let result = []
    try
        call setpos(".", [0, line("$"), strlen(getline("$")), 0])
        while 1
            silent! let pos = searchpos('\M>', "w")
            if pos == [0, 0]
                return [[1],2]
            elseif index(result, pos) != -1 || len(result) > 1
                break
            endif
            call add(result, pos)
        endwhile
    endtry
    return result
endfunc

func! DatabaseTerminal#runcom(line1,line2) abort
    if !exists('s:sqlb')
        call DatabaseTerminal#startDB()
    elseif term_getstatus(s:sqlb) ==# 'normal'
        call term_sendkeys(s:sqlb,'i')
    endif
    for i in getline(a:line1,a:line2)
        call term_sendkeys(s:sqlb,i."\<CR>")
    endfor
    return
endfunc

if executable('pandoc') && exists('g:DatabaseTerminal_folder')
    func! DatabaseTerminal#conv() abort
        if !len(s:lines)
            echo 'no output lines'
            return
        endif
        echo 'execution result is outputed to '.s:output
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
else
    func! DatabaseTerminal#conv() abort
        echohl WarningMsg
        echo 'You Don''t meet the requirements to output file'
        echohl None
        return
    endfunc
endif

func! DatabaseTerminal#startServ() abort
    try
        call system(s:startcom)
    catch
    endtry
    return
endfunc

if exists('g:DatabaseTerminal_dbRunCom')
    let s:dbrun = g:DatabaseTerminal_dbRunCom
    if exists('g:DatabaseTerminal_dbRunArgs')
        let s:dbrun .= ' '.g:DatabaseTerminal_dbRunArgs
    endif
    let s:dict = 
    \ { "term_name" : "DbTerminal", "norestore" : "1" ,
    \ "term_finish" : "open" ,
    \ "exit_cb" : function('s:endDB') , "stoponexit": "exit" }
else
    echohl WarningMsg
    echo 'Please set variables first,See helpfile :help DatabaseTerminal-Intro'
    echohl None
endif

if exists('g:DatabaseTerminal_alwaysOpenVsplit')
    call extend(s:dict,{"vertical":1})
endif

if exists('g:DatabaseTerminal_autoOutput')
    aug DatabaseTerminal
        au!
        au VimLeavePre * call DatabaseTerminal#conv()
    aug END
endif

if exists('g:DatabaseTerminal_folder') && exists('g:DatabaseTerminal_fileName')
    let s:folder = g:DatabaseTerminal_folder
    if s:folder !~# '\M/$'
        let s:folder .= '/'
    endif
    let s:folder .= g:DatabaseTerminal_fileName
    let s:folder = expand(s:folder)
    if exists('g:DatabaseTerminal_autodate')
        let s:date = strftime('%m%d')
        let s:folder .= s:date
    endif
    let s:txt = s:folder.'.txt'
    let s:output = s:folder.'.'.g:DatabaseTerminal_outputExtens
endif

if exists('g:DatabaseTerminal_dbName')
    if has('win32') || has('win64')
        let s:startcom = 'net start '.g:DatabaseTerminal_dbName
        let s:stopcom = 'call system(''net stop '.g:DatabaseTerminal_dbName.''')'
    elseif has('unix')
        if executable('systemctl')
            let s:startcom = 'systemctl start'.g:DatabaseTerminal_dbName
            let s:stopcom = 'call system(''systemctl stop'.g:DatabaseTerminal_dbName.''')'
        else
            let s:startcom = 'service '.g:DatabaseTerminal_dbName.' start'
            let s:stopcom = 'call system(''service '.g:DatabaseTerminal_dbName.' stop'')'
        endif
    endif
else
    let s:startcom = ''
    let s:stopcom = ''
endif

if exists('g:DatabaseTerminal_dontStop')
    let s:stopcom = ''
endif

let &cpo = s:savecpo
unlet s:savecpo
