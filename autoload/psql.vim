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
let g:psql_default_conn.port='5432'

function! psql#connect()
  let b:psql_connection={}
	let b:psql_connection.host=input("Host: ", g:psql_default_conn.host)
  let b:psql_connection.port=input("Port: ", g:psql_default_conn.port)
	let b:psql_connection.database=input("DB Name: ", g:psql_default_conn.database)
  let b:psql_connection.user=input("User: ", g:psql_default_conn.user)
  let b:psql_connection.password=inputsecret("Password: ", g:psql_default_conn.password)
	call psql#setup(b:psql_connection)
  call feedkeys(":")
	echom "Connected!"
endfunction

function! psql#setup(conn)
	call psql#set_defaults(a:conn)
	nmap <silent> <buffer> g<CR> :call psql#run_buffer()<CR>
endfunction

function! psql#set_defaults(conn)
	let g:psql_default_conn.host=a:conn.host
	let g:psql_default_conn.database=a:conn.database
	let g:psql_default_conn.password=a:conn.password
  let g:psql_default_conn.user=a:conn.user
  let g:psql_default_conn.port=a:conn.port
endfunction

function! psql#run_buffer()
  call s:store_location()
  let query_file = psql#create_query_file()
	let result_lines = psql#run_query(query_file)
	call psql#display_result(result_lines)
endfunction

function! s:go_to_open_window(buffer)
  while bufnr('%') != a:buffer
    execute "norm! "
  endwhile
endfunction

function! s:store_location()
  let g:psql_old_location = {}
  let g:psql_old_location.buffer = bufnr("%")
  let g:psql_old_location.line = line(".")
endfunction

function! s:restore_location()
  call s:go_to_open_window(g:psql_old_location.buffer)
  execute "norm! " . g:psql_old_location.line . "gg"
endfunction

function! psql#display_result(result_lines)
	call psql#open_result_buffer()
	setlocal modifiable
	normal! ggVGd
	call append(0, a:result_lines)
	setlocal nomodifiable
  call s:restore_location()
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
      call s:go_to_open_window(bnum)
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
    let cmd = cmd . 'PGPASSWORD="' . conn.password . '"'
  endif
  let cmd = cmd . ' psql -h ' . conn.host . ' -p ' . conn.port . " -f " . a:query_file
  if len(conn.user) > 0
    let cmd = cmd . ' -U ' . conn.user
  endif
  let cmd = cmd . ' ' . conn.database
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
