## Vim
alias vimconfig 'vim ~/.vimrc'                      # Edit vim config

## File contents
command -v bat &> /dev/null && alias cat 'bat'      # Alias bat to cat if installed (https://github.com/sharkdp/bat)

## PostgreSQL
alias pgc 'sudo su - postgres'                      # Shortcut to open postres shell as postgres user

## Clipboard
alias xclip 'xclip -selection c'                    # Shortcut to copy content to X clipboard

## Pascal compiler
alias pascal 'mono $HOME/.pascal/pabcnetc.exe'      # Compile *.pas with pascal

## Docker-compose
alias dc 'docker-compose'
