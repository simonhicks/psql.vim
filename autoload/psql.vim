if exists("g:done_psql_autoload")	
	finish
endif
let g:done_psql_autoload=1

" TODO
" - mapping to execute highlighted region (cp)
" - operator mapping to execute motion region (cp..)
" - mapping to run current line (cpp)

let g:psql_default_conn={}
let g:psql_default_conn.host=''
let g:psql_default_conn.database=''
let g:psql_default_conn.user=''
let g:psql_default_conn.password=''

function! psql#connect()
  let b:psql_connection={}
	let b:psql_connection.host=input("Host: ", g:psql_default_conn.host)
	let b:psql_connection.database=input("DB Name: ", g:psql_default_conn.database)
  let b:psql_connection.user=input("User: ", g:psql_default_conn.user)
  let b:psql_connection.password=input("Password: ", g:psql_default_conn.password)
	call psql#setup(b:psql_connection)
	echom "Connected!"
endfunction

function! psql#setup(conn)
	call psql#set_defaults(a:conn)
	nmap <buffer> g<CR> :call psql#run_buffer()<CR>
endfunction

function! psql#set_defaults(conn)
	let g:psql_default_conn.host=a:conn.host
	let g:psql_default_conn.database=a:conn.database
	let g:psql_default_conn.password=a:conn.password
  let g:psql_default_conn.user=a:conn.user
endfunction

function! psql#run_buffer()
  let query_file = psql#create_query_file()
	let result_lines = psql#run_query(query_file)
	call psql#display_result(result_lines)
endfunction

function! psql#display_result(result_lines)
	call psql#open_result_buffer()
	setlocal modifiable
	normal! ggVGd
	call append(0, a:result_lines)
	setlocal nomodifiable
endfunction

function! psql#create_query_file()
	let store_a = @a
	norm! ggVG"ay
	let query_file = tempname()
	call writefile(split(@a, "\n"), query_file)
	let @a = store_a
	return query_file
endfunction

let g:psql_buffer_name = "**PSQL Results**"

function! psql#open_result_buffer()
	let bnum = bufnr(g:psql_buffer_name)
	if bnum == -1
		call psql#create_result_buffer()
	else
		if psql#is_visible(bnum) == 0
			execute "sbuffer " . bnum
		else
			while bufnr('%') != bnum
				execute "norm! "
			endwhile
		endif
	endif
endfunction

function! psql#is_visible(bnum)
	let wnum = 1
	let max_wnum = winnr("$")
	while wnum <= max_wnum
		if winbufnr(wnum) == a:bnum
			return 1
		end
		let wnum += 1
	endwhile
	return 0
endfunction

function! psql#create_result_buffer()
	execute "new ".g:psql_buffer_name
	setlocal buftype=nofile
	setlocal bufhidden=hide
	setlocal noswapfile
	setlocal nomodifiable
endfunction

function! psql#build_cmd(query_file)
	let conn = b:psql_connection
  let cmd = ""
  if len(conn.password) > 0
    let cmd = cmd . 'PGPASSWORD=' . conn.password
  endif
  let cmd = cmd . ' psql -h ' . conn.host . " -f " . a:query_file
  if len(conn.user) > 0
    let cmd = cmd . ' -U ' . conn.user
  endif
  let cmd = cmd . ' ' . conn.database
  echom cmd
  return cmd
endfunction

function! psql#run_query(query_file)
  let lines = split(system(psql#build_cmd(a:query_file)), "\n")
  return lines
  " FIXME make this gibberish-filter configurable
	" let result_lines = []
	" let starlines = 0
	" for line in lines
		" if starlines == 4
			" call add(result_lines, line)
		" else
		" 	if match(line, "^[*][*]*$") != -1
		" 		let starlines +=1
		" 	endif
		" endif
	" endfor
	" return result_lines
endfunction
