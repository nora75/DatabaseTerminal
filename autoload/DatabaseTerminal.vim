" Vim global plugin for sql terminal functions
" Last Change: 02-Jul-2018.
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

func! s:rec(...) abort
    if exists('s:timer')
        call timer_stop(s:timer)
    endif
    let s:n = timer_start(1500,function('s:gettermlines'))
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
    let s:errc += 1
    let errl = s:err()
    if errl == 1
        let s:lines = []
        unlet s:sqlb
        if !has('win32') || !has('win64')
            call s:ech('Please run Database Server first')
            return
        else
            echo 'Relaunch DbTerminal'
            call DatabaseTerminal#startServ()
            call DatabaseTerminal#startDB('current')
            return
        endif
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
    let s:errc = 0
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

func! s:getoutlines(...) abort
    if !exists('s:outb')
        return
    endif
    let s:outlines = getbufline(s:outb,1,'$')
    return
endfunc

func! s:err() abort
    let msg = string(term_getline(s:sqlb,2))
    if msg !~ 'welcome' || msg =~? 'error' || msg == ''
        if msg =~? 'connect'
            return 1
        endif
        return 2
    endif
    return 0
endfunc

func! s:ech(ms) abort
    echohl WarningMsg
    echo a:ms
    echohl None
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

func! s:setopen(...) abort
    let args = join(a:000)
    if args =~ 'current'
        let s:opencom = ''
    elseif args =~? 'vs'
        let s:opencom = 'vnew'
    elseif args =~? 'sp'
        let s:opencom = 'new'
    endif
    return
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

func! s:appendhide() abort
    exe 'sb '.s:outb
    call append(line('$'),s:lines)
    hide
    return
endfunc

func! s:getchar() abort

    return key
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
    echon msg
    let c = s:getChar()
    if c ==? 'y'
        return 1
    elseif c ==# 'en'
        return 1
    else
        return 0
    endif
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
    call s:getoutlines()
    if !len(s:outlines)
        echo 'no output lines'
        return
    endif
    try
        echo 'execution result is outputed to '.s:output
    catch
        call s:ech('Please set variables first,See helpfile :help DatabaseTerminal-Intro')
    endtry
    if filereadable(s:output)
        if !s:input(s:output.'is already exists.Do you want to override?')
            call system('pandoc -f '.g:DatabaseTerminal_outputFormat.' -t markdown -o '.s:txt.' '.s:output)
            call insert(s:outlines,'')
        endif
        call delete(s:output)
    endif
    call map(s:outlines,'v:val."  "')
    call writefile(s:outlines,s:txt,'a')
    call system('pandoc -t '.g:DatabaseTerminal_outputFormat.' -o '.s:output.' '.s:txt)
    call delete(s:txt)
    let s:lines = []
    return
endfunc

func! DatabaseTerminal#startServ() abort
    silent! call system(s:startcom)
    return
endfunc

func! DatabaseTerminal#clear() abort
    if bufnr('') == s:outb
        %delete_
    endif
    let buflist = []
    for i in range(tabpagenr('$'))
        call extend(buflist, tabpagebuflist(i + 1))
    endfor
    if index(buflist,s:outb) != -1
        exe 'au WinEnter <buffer='.s:outb.'> %delete_'
    endif
    let s:outlines = []
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
    exe com.'b '.s:outb
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
    " \ "term_opencmd" : "10split|buffer %d" }
endif

if !exists('#DatabaseTerminal')
    aug DatabaseTerminal
        au!
    aug END
endif
aug DatabaseTerminal
    au FileType DbTerminal let s:bufwin = win_getid(winnr())
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
if !exists('g:DatabaseTerminal_outputFormat') || !exists('g:DatabaseTerminal_outputExtens')
    let g:DatabaseTerminal_outputFormat = 'markdown'
    let g:DatabaseTerminal_outputExtens = 'md'
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

let &cpo = s:savecpo
unlet s:savecpo
