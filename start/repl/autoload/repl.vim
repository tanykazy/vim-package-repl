" if exists("g:loaded_repl")
"    finish
" endif
" let g:loaded_repl = 1

"let s:save_cpoptions = &cpoptions
"set cpoptions&vim

"let s:buftype = 'prompt'
"let s:prompt = '> '

"let b:handle
let b:repl = 'clisp'
let b:option = '-o '

function repl#Repl() abort
	if !exists("b:handle")
		call s:SetMap()
		let b:handle = s:CreateRepl(b:repl)
	endif
	return b:handle
endfunction

function s:SetMap()
	nmap <buffer> <silent> <script> <C-L> :call <SID>EvalCurrentBlock()<CR>
	vmap <buffer> <silent> <script> <C-L> :call <SID>EvalSelection()<CR>
endfunction

function s:EvalCurrentBlock()
	let l:start = searchpairpos('(', '', ')', 'bW')
	let l:end = searchpairpos('(', '', ')', 'Wz')
	call s:SendText(join(s:GetLinePos(l:start, l:end)))
endfunction

function s:EvalSelection() range
	call s:SendText(join(s:GetLine(a:firstline, a:lastline)))
endfunction

function s:CreateRepl(cmd)
	let l:b = term_start(a:cmd, {
		\ "hidden": 1,
		\ "term_finish": "close"})
	call s:ShowBuffer(l:b)
	let l:j = term_getjob(l:b)
	let l:c = job_getchannel(l:j)
	return l:c
endfunction

function s:ShowBuffer(buffer)
	let l:w = bufwinnr(bufnr("#"))
	execute "vertical rightbelow sbuffer" a:buffer
	execute l:w .. "wincmd w"
endfunction

function s:GetLinePos(start, end)
	let l:l = getline(a:start[0], a:end[0])
	let l:l[-1] = strpart(l:l[-1], 0, a:end[1])
	let l:l[0] = strpart(l:l[0], a:start[1] - 1)
	return s:TrimLines(l:l)
endfunction

function s:GetLine(start, end)
	return s:TrimLines(getline(a:start, a:end))
endfunction

function s:TrimLines(lines)
	return map(a:lines, {_, val -> trim(val)})
endfunction

function s:SendText(text)
	call ch_sendraw(b:handle, a:text .. "\n")
endfunction



"function repl#CallbackHandler(channel, msg)
"endfunction
"
"function repl#OutHandler(channel, msg)
"endfunction
"
"function repl#InHandler(channel, msg)
"endfunction
"
"function repl#ErrHandler(channel, msg)
"endfunction
"
"function repl#CloseHandler(channel, msg)
"endfunction
"
"function repl#ExitHandler(channel, msg)
"endfunction


"let &cpoptions = s:save_cpoptions
"unlet s:save_cpoptions

