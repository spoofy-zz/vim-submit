" ftplugin/jcl.vim - Buffer-local settings and mappings for JCL files

if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

setlocal noexpandtab
setlocal textwidth=80
setlocal commentstring=//* %s

" Convenient buffer-local mappings (override with b:vim_submit_no_maps=1)
if !get(b:, 'vim_submit_no_maps', get(g:, 'vim_submit_no_maps', 0))
  nnoremap <buffer> <LocalLeader>s :JCLSubmit<CR>
  nnoremap <buffer> <LocalLeader>o :JCLOutput<CR>
  nnoremap <buffer> <LocalLeader>j :JCLStatus<CR>
  nnoremap <buffer> <LocalLeader>l :JCLJobs<CR>
endif
