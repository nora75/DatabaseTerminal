" Vim global plugin for sql terminal functions
" Last Change: 05-Jul-2018.
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
let s:outlines = []
let s:errc = 0

if !has('terminal')
    call s:ech('Please update Vim to vim8.1 compiled with terminal window')
    finish
endif

func! s:appendhide() abort
    exe 'sb '.s:outb
    call append(line('$'),s:lines)
    hide
    return
endfunc

func! s:bufhide(...) abort
    exe 'aug DatabaseTerminal|au VimLeavePre * silent! bw! '.s:sqlb.'|aug END'
    return
endfunc

func! s:bufwip()
    exe 'silent! bw! '.s:sqlb
    unlet s:sqlb
    return
endfunc

func! s:clear() abort
    exe 'vs|silent! b '.s:outb
    silent! %delete_
    silent! q!
    let s:outlines = []
    return
endfunc

func! s:ech(ms) abort
    echohl WarningMsg
    echo a:ms
    echohl None
    return
endfunc

func! s:endDB(...) abort
    if !exists('s:sqlb')
        return
    endif
    if s:errc > 0
        call s:ech('Please run Database Server first')
        call s:bufwip()
        return
    endif
    let errl = s:err()
    if errl == 1
        let s:lines = []
        unlet s:sqlb
        call s:relaunch()
        return
    elseif errl == 2
        call s:bufwip()
        return
    endif
    echo 'Close DbTerminal'
    call s:gettermlines()
    call s:bufwip()
    if !exists('s:outb')
        call s:makehide()
    else
        call s:appendhide()
    endif
    let s:called = 1
    return
endfunc

func! s:err() abort
    let msg = string(term_getline(s:sqlb,2))
    if msg !~ 'welcome' || msg =~? 'error' || msg == ''
        if msg =~? 'connect'
            return 1
        endif
        return 2
        let s:errc += 1
    endif
    let s:errc = 0
    return 0
endfunc

func! s:getoutlines(...) abort
    if !exists('s:outb')
        return
    endif
    let s:outlines = getbufline(s:outb,1,'$')
    return
endfunc

func! s:gettermlines(...) abort
    if !exists('s:sqlb')
        return
    endif
    let l = []
    for i in range(1,line('$'))
        call add(l,term_getline(s:sqlb,i))
    endfor
    if len(l) >= len(s:lines)
        if l != s:lines
            let s:lines = l
        endif
    endif
    return
endfunc

func! s:getChar() abort
    try
        let c = getchar()
        if c =~ '^\d\+$'
            let c = nr2char(c)
        endif
        if c =~ "\<Esc>"
            throw 'Interrupt'
        elseif c =~ "\<Enter>"
            let c = 'en'
        endif
    catch
        let c = 'Er'
    endtry
    return c
endfunc

func! s:input(msg) abort
    let msg = a:msg.': '
    echo msg
    let c = s:getChar()
    if c ==? 'y'
        return 1
    elseif c ==# 'en'
        return 1
    else
        return 0
    endif
endfunc

func! s:makehide() abort
    new
    silent f DbTOutPut
    setl noswf
    setl bh=hide
    setl nobl
    setl bt=nofile
    set ft=DbTOut
    call append(line('$'),s:lines)
    1delete_
    let s:lines = []
    setl nomod
    let s:outb = bufnr('')
    hide
    return
endfunc

func! s:rec(...) abort
    if exists('s:timer')
        call timer_stop(s:timer)
    endif
    let s:n = timer_start(1500,function('s:gettermlines'))
    return
endfunc

func! s:relaunch() abort
    if !has('win32') || !has('win64')
        call s:ech('Please run Database Server first')
    else
        echo 'Relaunch DbTerminal'
        call DatabaseTerminal#startServ()
        call DatabaseTerminal#startDB('current')
    endif
    return
endfunc

func! s:setopen(...) abort
    let args = join(a:000)
    if args =~ 'current'
        let open = ''
    elseif args =~? 'vs'
        let open = 'vnew'
    elseif args =~? 'sp'
        let open = 'new'
    endif
    return open
endfunc

func! DatabaseTerminal#clear() abort
    call s:clear()
    echo 'Clear output lines'
    return
endfunc

func! DatabaseTerminal#conv() abort
    if !executable('pandoc')
        call s:ech('You Don''t meet the requirements to output file.See helpfile :help DatabaseTerminal-Intro')
        return
    endif
    call s:getoutlines()
    if len(s:outlines) == 0 
        if !exists('s:called')
            echo 'no output lines'
        endif
        return
    endif
    if !exists('s:output')
        call s:ech('Please set variables first.See helpfile :help DatabaseTerminal-Intro')
        return
    endif
    if filereadable(s:output)
        if !s:input(s:output.' is already exists.Override[y/Enter] Append[n / other keys]')
            call system('pandoc -f '.g:DatabaseTerminal_outputFormat.' -t markdown -o '.s:txt.' '.s:output)
            if len(s:outlines) > 0
                call insert(s:outlines,'')
            endif
        endif
        call delete(s:output)
    endif
    echo 'execution result is outputed to '.s:output
    call map(s:outlines,'v:val."  "')
    call writefile(s:outlines,s:txt,'a')
    call system('pandoc -t '.g:DatabaseTerminal_outputFormat.' -o '.s:output.' '.s:txt)
    call delete(s:txt)
    call s:clear()
    return
endfunc

func! DatabaseTerminal#delete() abort
    silnet! call delete(s:output)
    return
endfunc

func! DatabaseTerminal#edit(...) abort
    let com = ''
    if a:0
        if a:1 =~ 'v\%[split]'
            let com = 'vs|'
        else
            let com = 'sp|'
        endif
    endif
    if !exists('s:outb')
        call s:ech('Please run DbTerminal at first')
        return
    endif
    exe com.'silent! b '.s:outb
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

func! DatabaseTerminal#startDB(...) abort
    try
        let dict = copy(s:dict)
    catch
        call s:ech('Please set variables first,See helpfile :help DatabaseTerminal-Intro')
    endtry
    if a:0
        let open = s:setopen(a:000)
    else
        let open = s:opencom
    endif
    if open != ''
        echo 'Open DbTerminal'
    endif
    if exists('s:sqlb')
        exe 'tabn '.win_id2tabwin(s:bufwin)[0]
        call win_gotoid(s:bufwin)
        return
    endif
    nmap <silent><buffer> <Space>r <Plug>(DatabaseTerminal_runCom)
    vmap <silent><buffer> <Space>r <Plug>(DatabaseTerminal_runCom)
    if open != ''
        exe open
    endif
    silent! let s:sqlb = term_start(s:dbrun, dict)
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
    \ "exit_cb" : function('s:endDB') ,
    \ "callback" : function('s:rec') ,
    \ "term_finish" : "open" }
endif

if !exists('#DatabaseTerminal')
    aug DatabaseTerminal
        au!
    aug END
endif
aug DatabaseTerminal
    au FileType DbTerminal let s:bufwin = win_getid(winnr())
aug END

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
let s:txt = s:folder.'.txt'
let s:output = s:folder.'.'.g:DatabaseTerminal_outputExtens

let s:startcom = ''
if exists('g:DatabaseTerminal_dbName')
    if has('win32') || has('win64')
        let s:startcom = 'net start '.g:DatabaseTerminal_dbName
        if !exists('g:DatabaseTerminal_dontStop')
            aug DatabaseTerminal
                exe 'au VimLeavePre * call system("net stop '.g:DatabaseTerminal_dbName.'")'
            aug END
        endif
    endif
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

if exists('g:DatabaseTerminal_autoOutput')
    aug DatabaseTerminal
        au VimLeavePre * call DatabaseTerminal#conv()
    aug END
endif

let &cpo = s:savecpo
unlet s:savecpo
