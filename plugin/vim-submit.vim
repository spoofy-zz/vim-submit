" vim-submit.vim - Submit JCL jobs to MVS via Zowe CLI
" Author: vim-submit contributors
" License: MIT

if exists('g:loaded_vim_submit')
  finish
endif
let g:loaded_vim_submit = 1

" Configuration defaults (override in vimrc before plugin loads)
let g:zowe_cmd                   = get(g:, 'zowe_cmd', 'zowe')
let g:zowe_profile               = get(g:, 'zowe_profile', '')
let g:vim_submit_split           = get(g:, 'vim_submit_split', 'botright')
let g:vim_submit_height          = get(g:, 'vim_submit_height', 15)
let g:vim_submit_wait_for_output = get(g:, 'vim_submit_wait_for_output', 0)

" Commands
command!          JCLSubmit     call vimsubmit#SubmitBuffer()
command! -nargs=? JCLSubmitFile call vimsubmit#SubmitFile(empty(<q-args>) ? expand('%:p') : <q-args>)
command! -nargs=? JCLStatus     call vimsubmit#ViewStatus(<q-args>)
command! -nargs=? JCLOutput     call vimsubmit#ViewOutput(<q-args>)
command! -nargs=? JCLJobs       call vimsubmit#ListJobs(<q-args>)
command! -nargs=? JCLCancel     call vimsubmit#CancelJob(<q-args>)
