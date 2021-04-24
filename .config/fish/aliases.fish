#############
#
# System
#
#############

## Common
alias ! 'sudo'                                      # ! to run sudo
alias q 'clear'                                     # shortcut to clear screen

## Directories / files
alias cpp 'cp -R'                                   # copy recursively
alias rmm 'rm -rvI'                                 # remove recursively with prompt
alias mkdir 'mkdir -pv'                             # verbose making directories
alias diff 'delta'                                  # replace default diff with delta (https://github.com/dandavison/delta)

## Manuals
alias tldr 'tldr -L en'                             # Force english in tldr (https://github.com/tldr-pages/tldr)

## Navigation
alias ... 'cd ../..'                                # Shortcut to go up twice
alias path 'readlink -e'                            # Get full path to directory

## Find utilities
alias grep 'grep --color auto'                      # Colorize grep
alias fgrep 'fgrep --color auto'
alias egrep 'egrep --color auto'

## Disk space
alias df 'df -h'                                    # Human-readable units
alias du 'du -ch'
alias free 'free -m'

## Disks
alias disks 'lsblk -o HOTPLUG,NAME,SIZE,MODEL,TYPE | awk "NR == 1 || /disk/"' # List disks
alias sizeof 'du -hs'

## Networking
alias wget 'wget -c'                                # Download with ability to continue if encountered an error
alias ping 'ping -c 5'                              # Limit ping to 5 tries
alias www 'python -m http.server 8000'              # Run HTTP in folder
alias ipe 'curl ipinfo.io/ip'                       # Get external IP

## List directory
if type -q exa
    alias ls 'exa --group-directories-first --icons'
    alias lst 'exa -T --L 2 --icons'
    alias lsa 'exa -a --icons'
    alias last 'exa -a -T --L 2 --icons'
    alias lsl 'exa -l --group-directories-first --icons'
    alias lslg 'exa --long --git --icons'
    alias lsla 'exa -al --icons'
end


#############
#
# Package management
#
#############

### System
alias pacman 'pacman --color always'                # Colorize pacman
alias p 'sudo pacman'                               # Shortcut to run pacman with sudo
alias pm 'sudo pacman-mirrors --fasttrack'          # Update mirrors

### TeX
alias tlmgr '/usr/share/texmf-dist/scripts/texlive/tlmgr.pl --usermode' # Shortcut to manage TeX packages


#############
#
# Applications
#
#############

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
