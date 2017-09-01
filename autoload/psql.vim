if exists("g:done_psql_autoload")	
	finish
endif
let g:done_psql_autoload=1

let g:psql_buffer_name = "**PSQL Results**"

let g:psql_default_conn={}
let g:psql_default_conn.host=''
let g:psql_default_conn.database=''
let g:psql_default_conn.user=''
let g:psql_default_conn.password=''
let g:psql_default_conn.port='5432'

function! s:set_defaults(conn)
	let g:psql_default_conn.host=a:conn.host
	let g:psql_default_conn.database=a:conn.database
	let g:psql_default_conn.password=a:conn.password
  let g:psql_default_conn.user=a:conn.user
  let g:psql_default_conn.port=a:conn.port
endfunction

" RUNNING SQL QUERIES

function! s:query_file(lines)
  let query_file = tempname()
  call writefile(a:lines, query_file)
  return query_file
endfunction

function! s:build_cmd(query_file)
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

function! s:run_query(query_file)
  let lines = split(system(s:build_cmd(a:query_file)), "\n")
  return lines
endfunction

" DISPLAYING RESULTS

function! s:store_location()
  let g:psql_old_location = {}
  let g:psql_old_location.buffer = bufnr("%")
  let g:psql_old_location.line = line(".")
endfunction

function! s:restore_location()
  call s:go_to_open_window(g:psql_old_location.buffer)
  execute "norm! " . g:psql_old_location.line . "gg"
endfunction

function! s:is_visible(bnum)
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

function! s:go_to_open_window(buffer)
  while bufnr('%') != a:buffer
    execute "norm! "
  endwhile
endfunction

function! s:create_result_buffer()
	execute "new ".g:psql_buffer_name
	setlocal buftype=nofile
	setlocal bufhidden=hide
	setlocal noswapfile
	setlocal nomodifiable
endfunction

function! s:open_result_buffer()
	let bnum = bufnr(g:psql_buffer_name)
	if bnum == -1
		call s:create_result_buffer()
	else
		if s:is_visible(bnum) == 0
			execute "sbuffer " . bnum
		else
      call s:go_to_open_window(bnum)
		endif
	endif
endfunction

function! s:display_result(result_lines)
	call s:open_result_buffer()
	setlocal modifiable
	normal! ggVGd
	call append(0, a:result_lines)
	setlocal nomodifiable
endfunction

" PLUGIN OPERATIONS

function! s:execute_lines(lines)
  let query_file = s:query_file(a:lines)
  let result_lines = s:run_query(query_file)
	call s:display_result(result_lines)
endfunction

function! s:describe(table)
  let query_file = s:query_file(['\d ' . a:table])
  let result_lines = s:run_query(query_file)
  for line in result_lines
    echo line
  endfor
endfunction

function! psql#operator(type, ...)
  call s:store_location()
  let sel_save = &selection
  let &selection = "inclusive"
  let reg_save = @@
  if a:0  " Invoked from Visual mode, use gv command.
    silent exe "normal! gvy"
  elseif a:type == 'wholebuffer'
    silent exe "normal! ggVGy"
  elseif a:type == 'line'
    silent exe "normal! '[V']y"
  else
    silent exe "normal! `[v`]y"
  endif
  call s:execute_lines(split(@@, "\n"))
  let &selection = sel_save
  let @@ = reg_save
  call s:restore_location()
endfunction

function! psql#connect()
  let b:psql_connection = {}
	let b:psql_connection.host = input("Host: ", g:psql_default_conn.host)
  let b:psql_connection.port = input("Port: ", g:psql_default_conn.port)
	let b:psql_connection.database = input("DB Name: ", g:psql_default_conn.database)
  let b:psql_connection.user = input("User: ", g:psql_default_conn.user)
  let b:psql_connection.password = inputsecret("Password: ", g:psql_default_conn.password)
	call s:set_defaults(b:psql_connection)
	nnoremap <silent> <buffer> c<CR> :call psql#operator('wholebuffer')<CR>
  nnoremap <buffer> cp :set operatorfunc=psql#operator<CR>g@
  vnoremap <buffer> cp :<c-u> call psql#operator(visualmode(), 1)<CR>
  nmap <buffer> cpp Vcp
  nmap <silent> <buffer> K :call <SID>describe(expand("<cWORD>"))<CR>
  call feedkeys(":")
	echom "Connected!"
endfunction
