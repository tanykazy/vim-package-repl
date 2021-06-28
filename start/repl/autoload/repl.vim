if exists("g:loaded_repl")
	finish
endif
let g:loaded_repl = 1

let s:save_cpoptions = &cpoptions
set cpoptions&vim

"let s:script_dir = expand('<sfile>:p:h')

"let b:repl = 'sbcl --load ~/.vim/pack/vim-package-repl/start-swank.lisp'
"let b:repl = 'clisp -i ~/.vim/pack/vim-package-repl/start-swank.lisp'
let b:impl = 'clisp'
let b:option = '-i'

"function s:Try()
"	echo swank#GetPath()
"endfunction

function repl#Repl() abort
	if !exists("b:handle")
		let l:cwd = getcwd(bufwinnr(bufnr("#")))
		call s:SetMap()
		let b:handle = s:StartImpl(l:cwd, join([b:impl, b:option, swank#GetPath()]))
	endif
	return b:handle
endfunction

function s:SetMap()
"	nmap <buffer> <script> <C-T> :call <SID>Try()<CR>
	nmap <buffer> <silent> <script> <C-L> :call <SID>EvalCurrentBlock()<CR>
	vmap <buffer> <silent> <script> <C-L> :call <SID>EvalSelection()<CR>
endfunction

function s:EvalCurrentBlock()
	let l:start = searchpairpos('(', '', ')', 'bW')
	let l:end = searchpairpos('(', '', ')', 'Wz')
	if l:start != [0, 0] && l:end != [0, 0]
		return s:SendText(s:GetLinePos(l:start, l:end))
	endif
endfunction

function s:EvalSelection() range
	return s:SendText(s:GetLine(a:firstline, a:lastline))
endfunction

function s:StartImpl(cwd, cmd)
	let l:buf = bufnr(a:cmd, v:true)
	let l:job = s:JobStart(a:cmd, {
				\ 'in_mode': 'nl',
				\ 'out_mode': 'nl',
				\ 'err_mode': 'nl',
				\ 'in_io': 'pipe',
				\ 'out_io': 'buffer',
				\ 'err_io': 'buffer',
				\ 'out_modifiable': 0,
				\ 'err_modifiable': 0,
				\ 'out_name': bufname(l:buf),
				\ 'err_name': bufname(l:buf),
				\ "callback": function('s:WaitStart'),
				\ "cwd": a:cwd})
	let b:start_timer = timer_start(100, function('s:AwaitConnectSwank'), {"repeat": 10})
	call s:ShowBuffer(l:buf)
	return l:buf
endfunction

function s:AwaitConnectSwank(id)
	if exists('b:port')
		call s:ConnectSwank('127.0.0.1', b:port)
		call timer_stop(a:id)
	endif
endfunction

function s:WaitStart(channel, msg)
	let l:matched = matchlist(a:msg, '^;; Swank started at port: \([[:digit:]]\+\)\.$')
	if len(l:matched) > 0
		let b:port = str2nr(l:matched[1])
	endif
endfunction

function s:ConnectSwank(host, port)
	let l:address = join([a:host, a:port], ':')
	let l:options = {
				\"mode": "json",
				\"callback": function('s:callbackhandler')}
	let l:channel = ch_open(l:address, l:options)
"	echo l:address
"	echo l:channel
	echo ch_info(l:channel)
	return l:channel
endfunction

function s:CreateRepl(cwd, cmd)
	let l:buf = bufnr(a:cmd, v:true)
	let l:job = s:JobStart(a:cmd, {
				\ 'in_mode': 'nl',
				\ 'out_mode': 'nl',
				\ 'err_mode': 'nl',
				\ 'in_io': 'pipe',
				\ 'out_io': 'buffer',
				\ 'err_io': 'buffer',
				\ 'out_modifiable': 0,
				\ 'err_modifiable': 0,
				\ 'out_name': bufname(l:buf),
				\ 'err_name': bufname(l:buf),
				\ "cwd": a:cwd})
"	echo job_info(l:job)
"	let l:channel = job_getchannel(l:job)
"	echo ch_info(l:channel)
	call s:ShowBuffer(l:buf)
"	return l:channel
	return l:job
endfunction

function s:ShowBuffer(buffer)
	let l:w = bufwinnr(bufnr("#"))
	execute "vertical rightbelow sbuffer" a:buffer
	execute l:w . "wincmd w"
	return a:buffer
endfunction

function s:JobStart(command, options)
	return job_start(a:command, extend({}, a:options))
endfunction

function s:TrimLines(line)
	return map(a:line, {_, val -> trim(val)})
endfunction

function s:SendText(line)
	return ch_sendraw(b:handle, join(s:TrimLines(a:line)) . "\n")
endfunction

function s:GetLinePos(start, end)
	let l:l = s:GetLine(a:start[0], a:end[0])
	let l:l[-1] = strpart(l:l[-1], 0, a:end[1])
	let l:l[0] = strpart(l:l[0], a:start[1] - 1)
	return l:l
endfunction

function s:GetLine(start, end)
	return getline(a:start, a:end)
endfunction

function s:callbackhandler(channel, msg)
"	echo a:channel
"	echo a:msg
endfunction


let &cpoptions = s:save_cpoptions
unlet s:save_cpoptions

