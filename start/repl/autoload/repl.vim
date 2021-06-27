
if exists("g:loaded_repl")
	finish
endif
let g:loaded_repl = 1

let s:save_cpoptions = &cpoptions
set cpoptions&vim

let s:script_dir = expand('<sfile>:p:h')

let b:repl = 'clisp -i ~/.vim/pack/vim-package-repl/start-swank.lisp'
"let b:repl = 'clisp'
let b:option = '-o'

function repl#Repl() abort
	if !exists("b:handle")
		let l:cwd = getcwd(bufwinnr(bufnr("#")))
		call s:SetMap()
"		let b:handle = s:CreateRepl(l:cwd, join([b:repl, b:option, l:cwd]))
		let b:handle = s:CreateRepl(l:cwd, b:repl)

		call s:Connect("localhost", 4005)

	endif
	return b:handle
endfunction

function s:Connect(host, port)
	let l:address = join([a:host, a:port], ':')
	let l:options = {
				\"mode": "json",
				\"callback": function('s:callbackhandler')}
	let l:channel = ch_open(l:address, l:options)
	echo l:address
endfunction

function s:SetMap()
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

function s:CreateRepl(cwd, cmd)
	let l:b = term_start(a:cmd, {
				\ "hidden": 1,
				\ "cwd": a:cwd,
				\ "term_finish": "close"})

"	let l:j = job_start(a:cmd)
"	let l:c = job_getchannel(l:j)
"	let l:b = ch_getbufnr(l:c, "")

	call s:ShowBuffer(l:b)
	let l:j = term_getjob(l:b)
	let l:c = job_getchannel(l:j)

	call term_wait(l:b)

	return l:c
endfunction

function s:ShowBuffer(buffer)
	let l:w = bufwinnr(bufnr("#"))
	execute "vertical rightbelow sbuffer" a:buffer
	execute l:w . "wincmd w"
	return a:buffer
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

function s:TrimLines(line)
	return map(a:line, {_, val -> trim(val)})
endfunction

function s:SendText(line)
	return ch_sendraw(b:handle, join(s:TrimLines(a:line)) . "\n")
endfunction

function s:callbackhandler(channel, msg)
	echo a:channel
	echo a:msg
endfunction


let &cpoptions = s:save_cpoptions
unlet s:save_cpoptions

