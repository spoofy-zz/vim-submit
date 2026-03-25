# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

`vim-submit` is a Vim plugin that submits JCL jobs to IBM z/OS mainframes via the Zowe CLI (`zowe zos-jobs ...`). There is no build step and no test framework — changes are validated by loading the plugin in Vim.

## Development

Reload the plugin during development without restarting Vim:
```vim
:source plugin/vim-submit.vim
:source autoload/vimsubmit.vim
```

Generate help tags after editing `doc/vim-submit.txt`:
```vim
:helptags doc/
```

Check Zowe is accessible and the profile works:
```sh
zowe zos-jobs list jobs --zosmf-profile <profile>
```

## Architecture

| Path | Purpose |
|---|---|
| `plugin/vim-submit.vim` | Plugin entry point — sets config defaults and defines all `:JCL*` commands. Loads once via the `g:loaded_vim_submit` guard. |
| `autoload/vimsubmit.vim` | All logic lives here and is lazy-loaded on first use. Public functions follow the `vimsubmit#FunctionName()` convention. |
| `ftdetect/jcl.vim` | Sets `filetype=jcl` for `*.jcl` / `*.JCL` files. |
| `ftplugin/jcl.vim` | `<LocalLeader>` mappings and JCL-specific buffer options (applied only to JCL buffers). |
| `syntax/jcl.vim` | JCL syntax highlighting rules. |
| `doc/vim-submit.txt` | Vim `:help` documentation. |

### Key design points

- All Zowe calls go through `s:Run(subcmd)` in `autoload/vimsubmit.vim`, which appends `--rfj` (JSON output) and the profile flag. The single exception is `vimsubmit#ViewOutput`, which calls Zowe directly without `--rfj` because spool content is plain text.
- Zowe responses are decoded with `s:Decode()` (`json_decode` wrapper). The outer envelope is `{success, data, message, stderr}`; `data` holds the actual result.
- All output is rendered in a single reusable scratch buffer (`vim-submit-output`). The buffer is re-opened in a split if it was closed; if already visible its window is reused.
- The last submitted job ID is stored in `g:vim_submit_last_jobid`. Commands that accept an optional `[jobid]` fall back to this via `s:ResolveJobId()`.
- Mappings are opt-out (`g:vim_submit_no_maps` / `b:vim_submit_no_maps`).

### Zowe CLI commands used

```
zowe zos-jobs submit local-file <file> [--wfo] --rfj
zowe zos-jobs view job-status-by-jobid <jobid> --rfj
zowe zos-jobs view all-spool-content <jobid>          # no --rfj
zowe zos-jobs list jobs [--prefix <pfx>] --rfj
zowe zos-jobs cancel job <jobid> --rfj
```
