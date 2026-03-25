# vim-submit

A Vim plugin to submit JCL jobs directly to IBM z/OS mainframes using [Zowe CLI](https://zowe.org).

## Requirements

- Vim 8+ or Neovim (requires `json_decode` for response parsing)
- [Zowe CLI](https://docs.zowe.org/stable/user-guide/cli-installcli/) v2+

```sh
npm install -g @zowe/cli
```

- A configured z/OSMF profile:

```sh
zowe profiles create zosmf myprofile \
    --host mvs.example.com --port 443 \
    --user IBMUSER --password secret \
    --reject-unauthorized false
```

## Installation

**vim-plug:**
```vim
Plug 'spoofy-zz/vim-submit'
```

**Manual:** copy the directories (`plugin/`, `autoload/`, `ftdetect/`, `ftplugin/`, `syntax/`, `doc/`) into `~/.vim/` (or `~/.config/nvim/` for Neovim).

## Configuration

```vim
" ~/.vimrc
let g:zowe_profile = 'myprofile'   " z/OSMF profile name
let g:zowe_cmd     = 'zowe'        " path to Zowe executable
nnoremap <Leader>s :JCLSubmit<CR>
```

All options: see `:help vim-submit-config`.

## Usage

| Command | Description |
|---|---|
| `:JCLSubmit` | Submit current buffer as JCL |
| `:JCLSubmitFile [file]` | Submit a file (default: current file) |
| `:JCLStatus [jobid]` | Show job status |
| `:JCLOutput [jobid]` | Show all spool output |
| `:JCLJobs [prefix]` | List jobs (optionally filtered by name prefix) |
| `:JCLCancel [jobid]` | Cancel a job |

All commands that take an optional `jobid` default to the last submitted job (`g:vim_submit_last_jobid`).

### Key mappings (JCL files only)

| Key | Action |
|---|---|
| `<LocalLeader>s` | Submit buffer |
| `<LocalLeader>o` | View output |
| `<LocalLeader>j` | View status |
| `<LocalLeader>l` | List jobs |

Disable with `let g:vim_submit_no_maps = 1`.

### Wait for output

To automatically display spool output after a job completes:

```vim
let g:vim_submit_wait_for_output = 1
```

> Note: Vim will block until the job finishes. Suitable for short-running jobs.

## License

MIT

How to install on macOS machine:
                                                                                                                                        
  1 — Install prerequisites:                                                                                                            
  # Install Node.js if not present (via Homebrew)                                                                                       
  brew install node                                                                                                                     
                                                                                                                                        
  # Install Zowe CLI
  npm install -g @zowe/cli                                                                                                              
                                                               
  # Configure your MVS connection                                                                                                       
  zowe profiles create zosmf hercules \
      --host your-mvs-host --port 443 \                                                                                                 
      --user IBMUSER --password secret \                                                                                                
      --reject-unauthorized false       
                                                                                                                                        
  2 — Install vim-plug (if not already installed):                                                                                      
  curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim                                                                 
                                                                                                                                        
  3 — Add to ~/.vimrc:
  call plug#begin()                                                                                                                     
  Plug 'spoofy-zz/vim-submit'                                  
  call plug#end()                                                                                                                       
                                                               
  let g:zowe_profile = 'hercules'                                                                                                       
  nnoremap <Leader>s :JCLSubmit<CR>
                                                                                                                                        
  4 — Open Vim and install the plugin:                         
  :PlugInstall                                                                                                                          
              
  Plug 'spoofy-zz/vim-submit' tells vim-plug to download the plugin from https://github.com/spoofy-zz/vim-submit automatically.         
                                                                                                       
