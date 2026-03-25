" autoload/vimsubmit.vim - Core logic for vim-submit

let s:bufname = 'vim-submit-output'

" ---------------------------------------------------------------------------
" Internal helpers
" ---------------------------------------------------------------------------

function! s:CheckZowe() abort
  if !executable(g:zowe_cmd)
    echoerr '[vim-submit] zowe not found: ' . g:zowe_cmd
    echoerr '[vim-submit] Install with: npm install -g @zowe/cli'
    return 0
  endif
  return 1
endfunction

" Returns extra CLI args appended to every zos-jobs call.
function! s:ExtraArgs() abort
  let args = ' --rfj'
  if !empty(g:zowe_profile)
    let args .= ' --zosmf-profile ' . shellescape(g:zowe_profile)
  endif
  return args
endfunction

" Run a zos-jobs subcommand and return raw stdout (JSON).
function! s:Run(subcmd) abort
  return system(g:zowe_cmd . ' zos-jobs ' . a:subcmd . s:ExtraArgs())
endfunction

" Decode JSON response; returns {} on failure.
" Strips ANSI escape codes and locates the JSON object within the output,
" so stray warnings or color sequences printed by Zowe don't break parsing.
function! s:Decode(raw) abort
  if !has('json_decode')
    return {}
  endif
  " Strip ANSI/VT escape sequences
  let clean = substitute(a:raw, '\e\[[0-9;]*[a-zA-Z]', '', 'g')
  " Find outermost JSON object
  let start = match(clean, '{')
  if start < 0
    return {}
  endif
  let last = strridx(clean, '}')
  if last < start
    return {}
  endif
  try
    return json_decode(strpart(clean, start, last - start + 1))
  catch
    return {}
  endtry
endfunction

" Fallback: extract job info from Zowe's plain-text submit output.
function! s:ParseSubmitText(raw) abort
  let jobid = matchstr(a:raw, '\c\<jobid\>\s*:\s*\zs\S\+')
  if empty(jobid)
    let jobid = matchstr(a:raw, '\<JOB\d\+\>')
  endif
  if empty(jobid)
    return {}
  endif
  return {
        \ 'jobid':   jobid,
        \ 'jobname': matchstr(a:raw, '\c\<jobname\>\s*:\s*\zs\S\+'),
        \ 'status':  matchstr(a:raw, '\c\<status\>\s*:\s*\zs\S\+'),
        \ }
endfunction

" Resolve a job ID: use supplied value or fall back to last submitted job.
function! s:ResolveJobId(jobid) abort
  if !empty(a:jobid)
    return a:jobid
  endif
  let last = get(g:, 'vim_submit_last_jobid', '')
  if empty(last)
    echoerr '[vim-submit] No job ID given and no recent job on record'
    return ''
  endif
  return last
endfunction

" Open (or reuse) the shared output buffer and populate it.
function! s:ShowLines(title, lines) abort
  let bufnr = bufnr(s:bufname)
  if bufnr == -1
    execute g:vim_submit_split . ' ' . g:vim_submit_height . 'new'
    silent execute 'file ' . s:bufname
    setlocal buftype=nofile bufhidden=hide noswapfile nobuflisted
    nnoremap <buffer> q :close<CR>
  else
    let winnr = bufwinnr(bufnr)
    if winnr != -1
      execute winnr . 'wincmd w'
    else
      execute g:vim_submit_split . ' ' . g:vim_submit_height . 'split'
      execute 'buffer ' . bufnr
    endif
  endif
  let &l:statusline = '  vim-submit » ' . a:title . ' %=%l/%L  '
  setlocal modifiable
  silent %delete _
  call setline(1, a:lines)
  setlocal nomodifiable
  normal! gg
endfunction

" ---------------------------------------------------------------------------
" Public functions
" ---------------------------------------------------------------------------

" Submit the current buffer (writes to a temp file first).
function! vimsubmit#SubmitBuffer() abort
  let tmp = tempname() . '.jcl'
  call writefile(getline(1, '$'), tmp)
  call s:DoSubmit(tmp, 1)
endfunction

" Submit a file from disk.
function! vimsubmit#SubmitFile(filepath) abort
  if !filereadable(a:filepath)
    echoerr '[vim-submit] File not readable: ' . a:filepath
    return
  endif
  call s:DoSubmit(a:filepath, 0)
endfunction

function! s:DoSubmit(filepath, delete_after) abort
  if !s:CheckZowe() | return | endif

  echo '[vim-submit] Submitting...'
  redraw

  let wait_flag = g:vim_submit_wait_for_output ? ' --wfo' : ''
  let cmd = g:zowe_cmd . ' zos-jobs submit local-file '
        \ . shellescape(a:filepath) . wait_flag . s:ExtraArgs()
  let raw = system(cmd)

  if a:delete_after
    call delete(a:filepath)
  endif

  let resp = s:Decode(raw)
  if empty(resp)
    " JSON parse failed — try plain-text format before giving up
    let data = s:ParseSubmitText(raw)
    if !empty(data)
      let g:vim_submit_last_jobid = data.jobid
      echomsg printf('[vim-submit] Submitted %s (%s) — status: %s',
            \ data.jobid, get(data, 'jobname', ''), get(data, 'status', ''))
      return
    endif
    echoerr '[vim-submit] Could not parse Zowe response'
    call s:ShowLines('Submit Error', split(raw, "\n"))
    return
  endif

  if !get(resp, 'success', 0)
    let msg = get(resp, 'message', get(resp, 'stderr', 'Unknown error'))
    echoerr '[vim-submit] Submission failed: ' . msg
    call s:ShowLines('Submit Error', split(get(resp, 'stderr', raw), "\n"))
    return
  endif

  let data   = get(resp, 'data', {})
  let jobid  = get(data, 'jobid', '')
  let jname  = get(data, 'jobname', '')
  let status = get(data, 'status', '')

  if !empty(jobid)
    let g:vim_submit_last_jobid = jobid
    echomsg printf('[vim-submit] Submitted %s (%s) — status: %s', jobid, jname, status)
    if g:vim_submit_wait_for_output
      call vimsubmit#ViewOutput(jobid)
    endif
  else
    echo '[vim-submit] Job submitted (no jobid in response)'
    call s:ShowLines('Submit Output', split(get(resp, 'stdout', raw), "\n"))
  endif
endfunction

" Show structured status for a job.
function! vimsubmit#ViewStatus(jobid) abort
  if !s:CheckZowe() | return | endif
  let jobid = s:ResolveJobId(a:jobid)
  if empty(jobid) | return | endif

  echo '[vim-submit] Fetching status...'
  redraw
  let resp = s:Decode(s:Run('view job-status-by-jobid ' . shellescape(jobid)))

  if !get(resp, 'success', 0)
    echoerr '[vim-submit] ' . get(resp, 'message', 'Failed to get status')
    return
  endif

  let d = get(resp, 'data', {})
  let lines = [
        \ '  Job ID   : ' . get(d, 'jobid',      'N/A'),
        \ '  Job Name : ' . get(d, 'jobname',     'N/A'),
        \ '  Owner    : ' . get(d, 'owner',        'N/A'),
        \ '  Status   : ' . get(d, 'status',       'N/A'),
        \ '  Ret Code : ' . string(get(d, 'retcode', 'N/A')),
        \ '  Class    : ' . get(d, 'class',        'N/A'),
        \ '  Phase    : ' . get(d, 'phase-name',   'N/A'),
        \ '  Type     : ' . get(d, 'type',         'N/A'),
        \ ]
  call s:ShowLines('Status: ' . jobid, lines)
endfunction

" Show all spool content for a job.
function! vimsubmit#ViewOutput(jobid) abort
  if !s:CheckZowe() | return | endif
  let jobid = s:ResolveJobId(a:jobid)
  if empty(jobid) | return | endif

  echo '[vim-submit] Fetching spool output...'
  redraw

  " Plain-text output; skip --rfj so we get the raw spool directly.
  let profile_arg = empty(g:zowe_profile) ? '' :
        \ ' --zosmf-profile ' . shellescape(g:zowe_profile)
  let raw = system(g:zowe_cmd . ' zos-jobs view all-spool-content '
        \ . shellescape(jobid) . profile_arg)

  call s:ShowLines('Output: ' . jobid, split(raw, "\n"))
endfunction

" List jobs, optionally filtered by job-name prefix.
function! vimsubmit#ListJobs(prefix) abort
  if !s:CheckZowe() | return | endif

  let filter = empty(a:prefix) ? '' : ' --prefix ' . shellescape(a:prefix)
  let resp = s:Decode(s:Run('list jobs' . filter))

  if !get(resp, 'success', 0)
    echoerr '[vim-submit] ' . get(resp, 'message', 'Failed to list jobs')
    return
  endif

  let jobs = get(resp, 'data', [])
  if empty(jobs)
    echo '[vim-submit] No jobs found'
    return
  endif

  let header = printf('  %-12s %-12s %-10s %-15s %s',
        \ 'JOBID', 'JOBNAME', 'STATUS', 'RETCODE', 'OWNER')
  let sep    = '  ' . repeat('-', 63)
  let lines  = [header, sep]
  for j in jobs
    let lines += [printf('  %-12s %-12s %-10s %-15s %s',
          \ get(j, 'jobid',    ''),
          \ get(j, 'jobname',  ''),
          \ get(j, 'status',   ''),
          \ string(get(j, 'retcode', '')),
          \ get(j, 'owner',    ''))]
  endfor
  call s:ShowLines('Jobs', lines)
endfunction

" Cancel a job.
function! vimsubmit#CancelJob(jobid) abort
  if !s:CheckZowe() | return | endif
  let jobid = s:ResolveJobId(a:jobid)
  if empty(jobid) | return | endif

  let resp = s:Decode(s:Run('cancel job ' . shellescape(jobid)))
  if get(resp, 'success', 0)
    echomsg '[vim-submit] Job ' . jobid . ' cancelled'
  else
    echoerr '[vim-submit] Cancel failed: ' . get(resp, 'message', 'Unknown error')
  endif
endfunction
