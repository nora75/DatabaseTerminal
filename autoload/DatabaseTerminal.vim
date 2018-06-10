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
    if msg =~? 'error'
        if a:0
            call s:startDB('server'.a:1)
        endif
        return
    endif
    echo 'end DbTerminal...'
    let pos = s:searchall()
    if len(pos) > 4
        let lines = pos[2][0].',"$"'
        exe 'call extend(s:lines,getline('.lines.'))'
    endif
    let s:called = 0
    unlet s:sqlb
    return
endfunc

func! s:startDB(...) abort
    echo 'start DbTerminal...'
    let dict = copy(s:dict)
    if a:0
        let args = join(a:000)
        if args =~ 'server'
            call s:startServ()
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
    let back_igc = &ignorecase
    let back_smc = &smartcase
    try
        call setpos(".", [0, line("$"), strlen(getline("$")), 0])
        while 1
            silent! let pos = searchpos(tolower(g:DatabaseTerminal_dbName), "w")
            if pos == [0, 0] || index(result, pos) != -1 || len(result) > 4
                break
            endif
            call add(result, pos)
        endwhile
    endtry
    let &ignorecase = back_igc
    let &smartcase = back_smc
    return result
endfunc

func! DatabaseTerminal#runcom(line1,line2) abort
    if !exists('s:sqlb')
        call s:startDB()
    elseif term_getstatus(s:sqlb) ==# 'normal'
        call term_sendkeys(s:sqlb,'i')
    endif
    for i in getline(a:line1,a:line2)
        call term_sendkeys(s:sqlb,i."\<CR>")
    endfor
    return
endfunc

if executable('pandoc') && exists('g:DatabaseTerminal_folder')
    func! s:conv() abort
        if !len(s:lines)
            echo 'no output lines'
            return
        endif
        echo 'execution result is outputed to '.s:output
        if filereadable(s:output)
            call system('pandoc -f docx '.g:DatabaseTerminal_outputFormat.' -t markdown -o '.s:txt.' '.s:output)
            call delete(s:output)
            call insert(s:lines,'')
        endif
        call map(s:lines,'v:val."  "')
        call writefile(s:lines,s:txt,'a')
        call system('pandoc -t docx -o '.s:output.' '.s:txt)
        call delete(s:txt)
        let s:lines = []
        return
    endfunc
else
    func! s:conv() abort
        echohl WarningMsg
        echo 'You Don''t meet the requirements to output file'
        echohl None
        return
    endfunc
endif

func! s:startServ() abort
    try
        call system(s:startcom)
    catch
    endtry
    return
endfunc

command! -nargs=* DbTerminal call s:startDB(<f-args>)

command! -nargs=0 DbTStart call s:startServ()

command! -nargs=0 DbTOutPut call s:conv()

if exists('g:DatabaseTerminal_dbRunCom') && exists('g:DatabaseTerminal_dbName')
    let s:lines = []
    let s:called = 0
    let s:dbrun = g:DatabaseTerminal_dbRunCom
    if exists('g:DatabaseTerminal_dbRunArgs')
        let s:dbrun .= ' '.g:DatabaseTerminal_dbRunArgs
    endif
    let s:dict = 
    \ { "term_name" : g:DatabaseTerminal_dbName, "norestore" : "1" ,
    \ "term_finish" : "close" ,
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
        au VimLeavePre * call <SID>conv()
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
        let s:date = strftime('%c')
        let s:date = strcharpart(s:date,match(s:date,'/')+1)
        let s:date = strcharpart(s:date,0,match(s:date,' '))
        let s:date = substitute(s:date,'/','','g')
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
endif

if exists('g:DatabaseTerminal_dontStop')
    let s:stopcom = ''
endif

let &cpo = s:savecpo
unlet s:savecpo
