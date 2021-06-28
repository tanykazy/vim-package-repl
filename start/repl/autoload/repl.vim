if exists("g:loaded_repl")
	finish
endif
let g:loaded_repl = 1

let s:save_cpoptions = &cpoptions
set cpoptions&vim


let b:impl = 'clisp'
let b:option = '-i'

let s:reSwankPort = '^;; Swank started at port: \([[:digit:]]\+\)\.$'
let s:swankHost = '127.0.0.1'

let s:repl = {}

function repl#Repl() abort
	if !exists("b:handle")
		call s:SetMap()
		let b:handle = s:repl.StartImpl([b:impl, b:option, swank#GetPath()], s:GetCwd())
	endif
endfunction

function s:SetMap()
	nmap <buffer> <silent> <script> <C-L> :call <SID>EvalCurrentBlock()<CR>
	vmap <buffer> <silent> <script> <C-L> :call <SID>EvalSelection()<CR>
endfunction

function s:EvalCurrentBlock()
	let l:start = searchpairpos('(', '', ')', 'bW')
	let l:end = searchpairpos('(', '', ')', 'Wz')
	if l:start != [0, 0] && l:end != [0, 0]
		return s:repl.SendText(s:GetLinePos(l:start, l:end))
	endif
endfunction

function s:EvalSelection() range
	return s:repl.SendText(s:GetLine(a:firstline, a:lastline))
endfunction

function s:repl.StartImpl(cmd, cwd) dict
	let l:buf = bufnr(join(a:cmd), v:true)
"	let b:id = s:Await(function('s:AwaitConnectSwank'))
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
				\ "callback": self.WaitStartedImpl,
				\ "cwd": a:cwd})
	call s:ShowBuffer(l:buf)
	let l:channel = job_getchannel(l:job)
"	echo ch_info(l:channel)
	return l:channel
endfunction

"function s:AwaitConnectSwank()
"	if exists('b:port')
"		call s:ConnectImpl('127.0.0.1', b:port)
"		return v:true
"	endif
"	return v:false
"endfunction

function s:repl.WaitStartedImpl(channel, msg) dict
	let l:matched = matchlist(a:msg, s:reSwankPort)
	"if len(l:matched) > 0
	if !empty(l:matched)
		"let b:port = str2nr(l:matched[1])
		let self.channel = self.ConnectImpl(s:swankHost, str2nr(l:matched[1]))
	endif
endfunction

function s:repl.ConnectImpl(host, port) dict
	let l:options = {
				\"mode": "json",
				\"callback": self.callbackhandler}
	let l:channel = s:ChOpen(a:host, a:port, l:options)
	"echo ch_info(l:channel)
	return l:channel
endfunction

function s:repl.callbackhandler(channel, msg) dict
	echo a:channel
	echo a:msg
endfunction

function s:repl.SendText(line) dict
	return ch_sendraw(self.channel, join(s:TrimLines(a:line)) . "\n")
endfunction

function s:ShowBuffer(buffer)
	let l:w = bufwinnr(bufnr("#"))
	execute "vertical rightbelow sbuffer" a:buffer
	execute l:w . "wincmd w"
	return a:buffer
endfunction

"function s:Await(callback)
"	return timer_start(
"				\ 10,
"				\ {id -> a:callback() ? timer_stop(id) : v:false},
"				\ {"repeat": -1})
"endfunction

function s:ChOpen(host, port, options)
	return ch_open(a:host . ':' . a:port, a:options)
endfunction

function s:JobStart(command, options)
	return job_start(a:command, extend({}, a:options))
endfunction

function s:TrimLines(line)
	return map(a:line, {_, val -> trim(val)})
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

function s:GetCwd()
	return getcwd(bufwinnr(bufnr("#")))
endfunction


let &cpoptions = s:save_cpoptions
unlet s:save_cpoptions

