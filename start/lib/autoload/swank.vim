if exists("g:loaded_swank")
	finish
endif
let g:loaded_swank = 1

let s:save_cpoptions = &cpoptions
set cpoptions&vim

let s:swank_dir = expand('<sfile>:p:h:h')

function swank#GetPath()
	return simplify(s:swank_dir . "/start-swank.lisp")
endfunction

let &cpoptions = s:save_cpoptions
unlet s:save_cpoptions

