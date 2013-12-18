"====================================================================================
" Author:		Evgeny V. Podjachev <evNgeny.poOdjSacPhev@gAmail.cMom-NOSPAM>
"
" License:		This program is free software: you can redistribute it and/or modify
"				it under the terms of the GNU General Public License as published by
"				the Free Software Foundation, either version 3 of the License, or
"				any later version.
"				
"				This program is distributed in the hope that it will be useful,
"				but WITHOUT ANY WARRANTY; without even the implied warranty of
"				MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
"				GNU General Public License for more details
"				(http://www.gnu.org/copyleft/gpl.txt).
"
" Description:	FileFastSelector plugin tries to provide fast way to open
"				files using minimal number of keystrokes. It's inspired by
"				Command-T plugin but requires python support instead of ruby.
"
"				Files are selected by typing characters that appear in their paths, 
"				and are ordered by length of common substring with search string.
"
"				Root directory for search is current vim directory. Or if tags
"				file exists somewhere in parent directories its path will
"				be used as root.
"
"				Source code is also available on bitbucket: https://bitbucket.org/madevgeny/fastfileselector.
"
" Note:			FileFastSelector requires a version of VIM with Python support enabled.
"
" Installation:	Just drop this file in your plugin directory.
"				If you use Vundle (https://github.com/gmarik/vundle/), you could add 
"
"				Bundle('https://bitbucket.org/madevgeny/fastfileselector.git')
"
"				to you Vundle config to install FileFastSelector.
"
" Usage:		Command :FFS toggles visibility of fast file selector buffer.
" 				Parameter g:FFS_window_height sets height of search buffer. Default = 15.
" 				Parameter g:FFS_ignore_list sets list of dirs/files to ignore use Unix shell-style wildcards. Default = ['.*', '*.bak', '~*', '*~', '*.obj', '*.pdb', '*.res', '*.dll', '*.idb', '*.exe', '*.lib', '*.so', '*.a', '*.pyc', 'CMakeFiles'].
"				Parameter g:FFS_ignore_case, if set letters case will be ignored during search. On windows default = 1, on unix default = 0.
"				Parameter g:FFS_history_size sets the maximum number of
" 				stored search queries in history. Default = 10.
" 				Parameter g:FFS_be_silent_on_python_lack, if set error message
" 				on absence python support will be suppressed.
"
" 				To get queries history press <Ctrl-H> in insert or normal mode in
" 				search string. Autocompletion using history also works by
" 				<Ctrl-X><Ctrl-U>.
"
" Version:		0.3.3
"
" ChangeLog:	0.3.3:	Fixed work on some vim builds.
"				0.3.2:	Support of vim builds with enabled python3 support.
"
"				0.3.1:	Removed message "press any key to continue" in some cases. Thanks to Dmitry Frank.
"						Fixed error on closing FFS window in some cases. Thanks to Dmitry Frank.
"
"				0.3.0:	Fixed issue with TabBar plugin.
"						Added parameter g:FFS_be_silent_on_python_lack to suppress error message if vim doesn't have python support.
"
"				0.2.3:	Fixed opening files with spaces in path.
"						Fixed case sensitive search.
"						Removed fastfileselector buffer from buffers list.
"
"				0.2.2:	Fixed autocompletion by <Ctrl-X><Ctrl-U>.
" 						Fixed immediate opening of first file after closing
"						history menu.
"						Removed '\' and '/' from color highlighting as they
"						may produce errors.
"
" 				0.2.1:	Bug fixes and optimization of search.
"
" 				0.2.0:	Added support of GetLatestVimScripts.
"
"				0.1.0:	Initial version.
"
" GetLatestVimScripts: 4142 18299 :AutoInstall: fastfileselector.vim
"====================================================================================

if exists( "g:loaded_FAST_FILE_SELECTOR" )
	finish
endif

let g:loaded_FAST_FILE_SELECTOR = 1

" Check to make sure the Vim version 700 or greater.
if v:version < 700
  echo "Sorry, FastFileSelector only runs with Vim 7.0 and greater."
  finish
endif

if !has('python') && !has('python3')
	if !exists("g:FFS_be_silent_on_python_lack") || !g:FFS_be_silent_on_python_lack
	    echo "Error: Required vim compiled with +python, to suppress this message set variable g:FFS_be_silent_on_python_lack."
	endif
    finish
endif

if !exists("g:FFS_window_height")
	let g:FFS_window_height = 15
endif

if !exists("g:FFS_ignore_case")
	if has('win32') || has('win64')
		let g:FFS_ignore_case = 1
	else
		let g:FFS_ignore_case = 0
	endif
endif

if !exists("g:FFS_ignore_list")
	let g:FFS_ignore_list = ['.*', '*.bak', '~*', '*~', '*.obj', '*.pdb', '*.res', '*.dll', '*.idb', '*.exe', '*.lib', '*.suo', '*.sdf', '*.exp', '*.so', '*.a', '*.pyc', 'CMakeFiles']
endif

if !exists("s:file_list")
	let s:file_list = []
endif

if !exists("s:base_path_length")
	let s:base_path_length = 0
endif

if !exists("s:filtered_file_list")
	let s:filtered_file_list = s:file_list
endif

if !exists("s:user_line")
	let s:user_line = ''
endif

if !exists("g:FFS_history_size")
	let g:FFS_history_size = 10
endif

if !exists("s:ffs_history")
	let s:ffs_history = []
endif

if !exists("s:plugin_path")
	let s:plugin_path = expand('<sfile>:p:h')
endif

command! -bang FFS :call <SID>ToggleFastFileSelectorBuffer()

fun <SID>UpdateSyntax(str)
	" Apply color changes
	silent setlocal syntax=on

	hi def link FFS_matches Identifier
	hi def link FFS_base_path Comment	
	
	exe 'syn match FFS_base_path #^.\{'.s:base_path_length.'\}# nextgroup=Identifier'
	if a:str != ''
		let str = substitute(a:str, "[\\/]", "", "g")
		if str != ''
			if g:FFS_ignore_case == 0
				exe 'syn match FFS_matches #['.str.']#'
			else
				exe 'syn match FFS_matches #['.tolower(str).toupper(str).']#'
			endif
		else
			exe 'hi clear FFS_matches'
		endif
	else
		exe 'hi clear FFS_matches'
	endif
endfun

fun <SID>GenFileList()
	let py_file = s:plugin_path.'/fastfileselector/gen_file_list.py'
	if has('python')
		exe ':pyfile '.py_file
	else
		exe ':py3file '.py_file
	endif
	let s:filtered_file_list = s:file_list
	call <SID>UpdateSyntax('')
endfun

fun <SID>OnRefresh()
	autocmd! CursorMovedI <buffer>
	setlocal nocul
	setlocal ma

	" clear buffer
	exe 'normal ggdG'

	cal append(0,s:user_line)
	exe 'normal dd$'
	let fl = map(copy(s:filtered_file_list), 'v:val[1]')
	cal append(1, fl)
	exe 'normal! i'

	autocmd CursorMovedI <buffer> call <SID>OnCursorMoved(1, 0)
endfun

fun! CompleteFFSHistory(findstart, base)
 	if a:findstart
		return 0
	else
		let res = []
		for m in s:ffs_history
		  if m =~ '^' . a:base
			call add(res, m)
		  endif
		endfor
		return res
	endif
endfun

fun <SID>OnCursorMoved(ins_mode, force_update)
	if line('.') > 1
		setlocal cul
		setlocal noma

		setlocal completefunc=''
	else
		setlocal nocul
		setlocal ma

		setlocal completefunc=CompleteFFSHistory

		if a:ins_mode == 0
			return
		endif
		
		let str=getline('.')
		if s:user_line!=str || a:force_update
			let save_cursor = winsaveview()

			let py_file = s:plugin_path.'/fastfileselector/on_cursor_moved.py'
			
			if has('python')
				exe ':pyfile '.py_file
			else
				exe ':py3file '.py_file
			endif
			
			let s:user_line=str
			call <SID>OnRefresh()
			cal winrestview(save_cursor)
			call <SID>UpdateSyntax(str)
		endif
	endif
endfun

fun <SID>GotoFile()
	if !len(s:filtered_file_list)
		return
	endif
	
	let str=getline('.')
	if line('.') == 1
		let str=getline(2)
	endif

	if !count(s:ffs_history,s:user_line)
		if len(s:ffs_history)>=g:FFS_history_size
			call remove(s:ffs_history,-1)
		endif
		call insert(s:ffs_history,s:user_line)
	endif

	call <SID>GoToPrevWindow()
	
	exe ':'.s:tm_winnr.'bd!'
	let s:tm_winnr=-1
	exe ':e '.substitute(str, " ", "\\\\ ", "g")
endfun

fun <SID>OnBufLeave()
	" Enable acp.vim plugin.
	if exists(':AcpUnlock')
		exe 'AcpUnlock'
	endif

	if s:prev_mode != 'i'
		exe 'stopinsert'
	endif
endfun

fun <SID>OnBufEnter()
	" Disable acp.vim plugin as cursor callbacks doesn't work if popup menu is
	" shown.
	if exists(':AcpLock')
		exe 'AcpLock'
	endif

	let s:prev_mode = mode()
	exe 'startinsert'

	call <SID>OnRefresh()
endfun

fun! <SID>ShowHistory()
	if line('.') == 1
		call cursor(0,1024)
		call complete(1,s:ffs_history)
	endif
	return ''
endfun

" This function is taken from NERD_tree.vim
fun <SID>FirstUsableWindow()
	let i = 1
	while i <= winnr("$")
		let bnum = winbufnr(i)
		if bnum != -1 && getbufvar(bnum, '&buftype') ==# ''
					\ && !getwinvar(i, '&previewwindow')
					\ && (!getbufvar(bnum, '&modified') || &hidden)
			return i
		endif

		let i += 1
	endwhile
	return -1
endfun

" This function is taken from NERD_tree.vim
fun <SID>IsWindowUsable(winnumber)
	"gotta split if theres only one window (i.e. the NERD tree)
	if winnr("$") ==# 1
		return 0
	endif

	let oldwinnr = winnr()
	exe a:winnumber . "wincmd p"
	let specialWindow = getbufvar("%", '&buftype') != '' || getwinvar('%', '&previewwindow')
	let modified = &modified
	exe oldwinnr . "wincmd p"

	"if its a special window e.g. quickfix or another explorer plugin then we
	"have to split
	if specialWindow
		return 0
	endif

	if &hidden
		return 1
	endif

	return !modified || <SID>BufInWindows(winbufnr(a:winnumber)) >= 2
endfun

" This function is taken from NERD_tree.vim
fun <SID>BufInWindows(bnum)
	let cnt = 0
	let winnum = 1
	while 1
		let bufnum = winbufnr(winnum)
		if bufnum < 0
			break
		endif
		if bufnum ==# a:bnum
			let cnt = cnt + 1
		endif
		let winnum = winnum + 1
	endwhile

	return cnt
endfun

" This function is taken from NERD_tree.vim
fun <SID>GoToPrevWindow()
	if !<SID>IsWindowUsable(winnr("#"))
		exe <SID>FirstUsableWindow() . "wincmd w"
	else
		exe 'wincmd p'
	endif
endfun
fun! <SID>ToggleFastFileSelectorBuffer()
	if !exists("s:tm_winnr") || s:tm_winnr==-1
		exe "bo".g:FFS_window_height."sp FastFileSelector"

		exe "inoremap <expr> <buffer> <Enter> pumvisible() ? '<CR><Up><End><C-O>:call <SID>OnCursorMoved(1, 1)<CR>' : '<C-O>:cal <SID>GotoFile()<CR>'"
		exe "noremap <silent> <buffer> <Enter> :cal <SID>GotoFile()<CR>"
		exe "inoremap <silent> <buffer> <C-H> <C-R>=<SID>ShowHistory()<CR>"
		exe "noremap <silent> <buffer> <C-H> I<C-R>=<SID>ShowHistory()<CR>"		

		let s:tm_winnr=bufnr("FastFileSelector")
		
		setlocal buftype=nofile
		setlocal bufhidden=wipe
		setlocal nobuflisted		
		setlocal noswapfile
		setlocal nonumber

		let s:user_line=''
		
		autocmd BufUnload <buffer> exe 'let s:tm_winnr=-1'
		autocmd BufLeave <buffer> call <SID>OnBufLeave()
		autocmd CursorMoved <buffer> call <SID>OnCursorMoved(0, 0)
		autocmd CursorMovedI <buffer> call <SID>OnCursorMoved(1, 0)
		autocmd VimResized <buffer> call <SID>OnRefresh()
		autocmd BufEnter <buffer> call <SID>OnBufEnter()
	
		cal <SID>GenFileList()
		cal <SID>OnBufEnter()
	else
		exe ':wincmd p'
		exe ':'.s:tm_winnr.'bd!'
		let s:tm_winnr=-1
	endif
endfun
