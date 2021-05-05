# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export THEMES_DIR='/home/dadyarri/.zsh/themes'
export PLUGINS_DIR='/home/dadyarri/.zsh/plugins'
export GPG_TTY=$(tty)
export EDITOR=$(where vim)

export PATH="$(/home/dadyarri/scripts/get-path 2>&1):$PATH"
export GTK_USE_PORTAL=1
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"

autoload -U promptinit; promptinit


unsetopt NO_BEEP
unsetopt NO_MATCH
setopt AUTO_CD
setopt BEEP
setopt NOMATCH
setopt NOTIFY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY
setopt HIST_BEEP
setopt INTERACTIVE_COMMENTS
setopt MAGIC_EQUAL_SUBST
setopt NULL_GLOB

HISTFILE="$HOME/.cache/zsh_history"
HIST_STAMPS=mm/dd/yyyy
HISTSIZE=5000
SAVEHIST=5000
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#ccc'
ZLE_RPROMPT_INDENT=0

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

for plugin in $(ls $PLUGINS_DIR)
do
warn='\033[33m[ ! ]\033[0m'
script_path="$PLUGINS_DIR/$plugin"
grep $plugin .ignore &> /dev/null
if [ $? -ne 0 ]; then
    if [ -f "$script_path/$plugin.zsh"  ]; then
        script="$script_path/$plugin.zsh"
    else
        script="$script_path/$plugin.plugin.zsh"
    fi
fi
source $script 2> /dev/null  || echo -e  "$warn $plugin not installed"
done

source $THEMES_DIR/powerlevel10k/powerlevel10k.zsh-theme

autoload compinit && compinit

# ZSH
alias zshconfig="vim ~/.zshrc && exec zsh"

# System
alias !="sudo"
alias cls="clear"
alias q="clear"
alias grep='grep --color=auto'
alias p='sudo pacman'
alias vi='vim'
alias pacman='pacman --color=always'
alias mkdir='mkdir -pv'
# Print full file path
alias path='readlink -e'

# Remove directories but ask nicely
alias rmm='rm -rvI'

# Copy directories but ask nicely
alias cpp='cp -R'

alias ...='cd ../..'

alias df='df -h'
alias du='du -ch'
alias free='free -m'

# Find utilities
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias diff='diff --color=auto'
alias tldr='tldr -L en'

# Postgres
alias pgc='sudo su - postgres'


# Xclip
alias xclip='xclip -selection c'

alias pascal="mono $HOME/.pascal/pabcnetc.exe"

alias tlmgr='/usr/share/texmf-dist/scripts/texlive/tlmgr.pl --usermode'

alias pm='sudo pacman-mirrors --fasttrack'

#  * `disks` command to List disks
#    - Clearly shows which disks are mounted temporary
#    - I always run this command before `dd` sd-card, to make 100% sure not to override system partition
alias disks='lsblk -o HOTPLUG,NAME,SIZE,MODEL,TYPE | awk "NR == 1 || /disk/"'
alias sizeof="du -hs"
# Lsd
command -v lsd &> /dev/null && alias ls='lsd --group-dirs first'
command -v lsd &> /dev/null && alias lst='lsd --tree --depth 2'
command -v lsd &> /dev/null && alias lsa='lsd -A'
command -v lsd &> /dev/null && alias last='lsd -A --tree --depth 2'
command -v lsd &> /dev/null && alias lsl='lsd -l --group-dirs first'
command -v lsd &> /dev/null && alias lasl='lsd -Al'

# Htop and others
command -v htop &> /dev/null && alias top='htop'
command -v gotop &> /dev/null && alias top='gotop -p'

# ViM
alias vimconfig='vim ~/.vimrc'

# cat
command -v bat &> /dev/null && alias cat='bat'

# Lazygit
command -v lazygit &> /dev/null && alias lg='lazygit'


#############
#
# Keybindings
#
#############

bindkey  "^[[H"   beginning-of-line
bindkey  "^[[F"   end-of-line
bindkey  "^[[3~"  delete-char

bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

##############
#
# ZSH's plugins' settings
#
##############
auto-ls-lsd () {
  lsd -a
}

ex () {
    if [ -f $1 ]; then
        case $1 in
            *.tar.bz2)  tar xjf $1      ;;
            *.tar.gz)   tar xzf $1      ;;
            *.bz2)      bunzip2 $1      ;;
            *.rar)      unrar x $1      ;;
            *.gz)       gunzip $1       ;;
            *.tar)      tar xf $1       ;;
            *.tbz2)     tar xjf $1      ;;
            *.tgz)      tar xzf $1      ;;
            *.zip)      unzip $1        ;;
            *.Z)        uncompress $1   ;;
            *.7z)       7z x $1         ;;
            *.deb)      ar x $1         ;;
            *.tar.xz)   tar xf $1       ;;
            *.tar.zst)  unzstd $1       ;;
            *) echo "'$1' can't be extracted";;
        esac
    else
        echo "'$1' isn't a valid file"
    fi
}

mkcd () {
    mkdir "$1"
    cd "$1"
}

vim() {
  if [ -w "$1" ]
  then
    /usr/bin/vim $*
  else
    sudo /usr/bin/vim $*
  fi
}

run() {
  chmod +x "$1"
  exec "./$1" &
}

bak () {
  mv "$1" "$(basename $1).bak"
}

launch () {
    eval "$1 >/dev/null 2>&1 &" & disown
}

qr () {
  if [ "$1" = "" ]; then
    qrencode --size 5 --background=FFFFFF --foreground=000000 -o - | display
  else
    printf "$1" | qrencode --size 5 --background=FFFFFF --foreground=000000 -o - | display
  fi
}

AUTO_LS_COMMANDS=(lsd)

##############
#
# Direnv's settings
#
##############

eval "$(direnv hook zsh)"

# show_virtual_env() {
# 	if [[ -n "$VIRTUAL_ENV" && -n "$DIRENV_DIR" ]]; then
#     	echo "($(basename $VIRTUAL_ENV))"
#     fi
# }

##############
#
# External apps' configs
#
##############

# thefuck alias loading
eval $(thefuck --alias)
#compdef _gh gh

function _gh {
  local -a commands

  _arguments -C \
    '--help[Show help for command]' \
    '--version[Show gh version]' \
    "1: :->cmnds" \
    "*::arg:->args"

  case $state in
  cmnds)
    commands=(
      "alias:Create command shortcuts"
      "api:Make an authenticated GitHub API request"
      "auth:Login, logout, and refresh your authentication"
      "completion:Generate shell completion scripts"
      "config:Manage configuration for gh"
      "gist:Create gists"
      "help:Help about any command"
      "issue:Manage issues"
      "pr:Manage pull requests"
      "repo:Create, clone, fork, and view repositories"
    )
    _describe "command" commands
    ;;
  esac

  case "$words[1]" in
  alias)
    _gh_alias
    ;;
  api)
    _gh_api
    ;;
  auth)
    _gh_auth
    ;;
  completion)
    _gh_completion
    ;;
  config)
    _gh_config
    ;;
  gist)
    _gh_gist
    ;;
  help)
    _gh_help
    ;;
  issue)
    _gh_issue
    ;;
  pr)
    _gh_pr
    ;;
  repo)
    _gh_repo
    ;;
  esac
}


function _gh_alias {
  local -a commands

  _arguments -C \
    '--help[Show help for command]' \
    "1: :->cmnds" \
    "*::arg:->args"

  case $state in
  cmnds)
    commands=(
      "delete:Delete an alias"
      "list:List your aliases"
      "set:Create a shortcut for a gh command"
    )
    _describe "command" commands
    ;;
  esac

  case "$words[1]" in
  delete)
    _gh_alias_delete
    ;;
  list)
    _gh_alias_list
    ;;
  set)
    _gh_alias_set
    ;;
  esac
}

function _gh_alias_delete {
  _arguments \
    '--help[Show help for command]'
}

function _gh_alias_list {
  _arguments \
    '--help[Show help for command]'
}

function _gh_alias_set {
  _arguments \
    '(-s --shell)'{-s,--shell}'[Declare an alias to be passed through a shell interpreter]' \
    '--help[Show help for command]'
}

function _gh_api {
  _arguments \
    '(*-F *--field)'{\*-F,\*--field}'[Add a parameter of inferred type]:' \
    '(*-H *--header)'{\*-H,\*--header}'[Add an additional HTTP request header]:' \
    '(-i --include)'{-i,--include}'[Include HTTP response headers in the output]' \
    '--input[The file to use as body for the HTTP request]:' \
    '(-X --method)'{-X,--method}'[The HTTP method for the request]:' \
    '--paginate[Make additional HTTP requests to fetch all pages of results]' \
    '(*-f *--raw-field)'{\*-f,\*--raw-field}'[Add a string parameter]:' \
    '--silent[Do not print the response body]' \
    '--help[Show help for command]'
}


function _gh_auth {
  local -a commands

  _arguments -C \
    '--help[Show help for command]' \
    "1: :->cmnds" \
    "*::arg:->args"

  case $state in
  cmnds)
    commands=(
      "login:Authenticate with a GitHub host"
      "logout:Log out of a GitHub host"
      "refresh:Refresh stored authentication credentials"
      "status:View authentication status"
    )
    _describe "command" commands
    ;;
  esac

  case "$words[1]" in
  login)
    _gh_auth_login
    ;;
  logout)
    _gh_auth_logout
    ;;
  refresh)
    _gh_auth_refresh
    ;;
  status)
    _gh_auth_status
    ;;
  esac
}

function _gh_auth_login {
  _arguments \
    '(-h --hostname)'{-h,--hostname}'[The hostname of the GitHub instance to authenticate with]:' \
    '--with-token[Read token from standard input]' \
    '--help[Show help for command]'
}

function _gh_auth_logout {
  _arguments \
    '(-h --hostname)'{-h,--hostname}'[The hostname of the GitHub instance to log out of]:' \
    '--help[Show help for command]'
}

function _gh_auth_refresh {
  _arguments \
    '(-h --hostname)'{-h,--hostname}'[The GitHub host to use for authentication]:' \
    '(*-s *--scopes)'{\*-s,\*--scopes}'[Additional authentication scopes for gh to have]:' \
    '--help[Show help for command]'
}

function _gh_auth_status {
  _arguments \
    '(-h --hostname)'{-h,--hostname}'[Check a specific hostname'\''s auth status]:' \
    '--help[Show help for command]'
}

function _gh_completion {
  _arguments \
    '(-s --shell)'{-s,--shell}'[Shell type: {bash|zsh|fish|powershell}]:' \
    '--help[Show help for command]'
}


function _gh_config {
  local -a commands

  _arguments -C \
    '--help[Show help for command]' \
    "1: :->cmnds" \
    "*::arg:->args"

  case $state in
  cmnds)
    commands=(
      "get:Print the value of a given configuration key"
      "set:Update configuration with a value for the given key"
    )
    _describe "command" commands
    ;;
  esac

  case "$words[1]" in
  get)
    _gh_config_get
    ;;
  set)
    _gh_config_set
    ;;
  esac
}

function _gh_config_get {
  _arguments \
    '(-h --host)'{-h,--host}'[Get per-host setting]:' \
    '--help[Show help for command]'
}

function _gh_config_set {
  _arguments \
    '(-h --host)'{-h,--host}'[Set per-host setting]:' \
    '--help[Show help for command]'
}


function _gh_gist {
  local -a commands

  _arguments -C \
    '--help[Show help for command]' \
    "1: :->cmnds" \
    "*::arg:->args"

  case $state in
  cmnds)
    commands=(
      "create:Create a new gist"
    )
    _describe "command" commands
    ;;
  esac

  case "$words[1]" in
  create)
    _gh_gist_create
    ;;
  esac
}

function _gh_gist_create {
  _arguments \
    '(-d --desc)'{-d,--desc}'[A description for this gist]:' \
    '(-p --public)'{-p,--public}'[List the gist publicly (default: private)]' \
    '--help[Show help for command]'
}

function _gh_help {
  _arguments \
    '--help[Show help for command]'
}


function _gh_issue {
  local -a commands

  _arguments -C \
    '(-R --repo)'{-R,--repo}'[Select another repository using the `[HOST/]OWNER/REPO` format]:' \
    '--help[Show help for command]' \
    "1: :->cmnds" \
    "*::arg:->args"

  case $state in
  cmnds)
    commands=(
      "close:Close issue"
      "create:Create a new issue"
      "list:List and filter issues in this repository"
      "reopen:Reopen issue"
      "status:Show status of relevant issues"
      "view:View an issue"
    )
    _describe "command" commands
    ;;
  esac

  case "$words[1]" in
  close)
    _gh_issue_close
    ;;
  create)
    _gh_issue_create
    ;;
  list)
    _gh_issue_list
    ;;
  reopen)
    _gh_issue_reopen
    ;;
  status)
    _gh_issue_status
    ;;
  view)
    _gh_issue_view
    ;;
  esac
}

function _gh_issue_close {
  _arguments \
    '--help[Show help for command]' \
    '(-R --repo)'{-R,--repo}'[Select another repository using the `[HOST/]OWNER/REPO` format]:'
}

function _gh_issue_create {
  _arguments \
    '(*-a *--assignee)'{\*-a,\*--assignee}'[Assign people by their `login`]:' \
    '(-b --body)'{-b,--body}'[Supply a body. Will prompt for one otherwise.]:' \
    '(*-l *--label)'{\*-l,\*--label}'[Add labels by `name`]:' \
    '(-m --milestone)'{-m,--milestone}'[Add the issue to a milestone by `name`]:' \
    '(*-p *--project)'{\*-p,\*--project}'[Add the issue to projects by `name`]:' \
    '(-t --title)'{-t,--title}'[Supply a title. Will prompt for one otherwise.]:' \
    '(-w --web)'{-w,--web}'[Open the browser to create an issue]' \
    '--help[Show help for command]' \
    '(-R --repo)'{-R,--repo}'[Select another repository using the `[HOST/]OWNER/REPO` format]:'
}

function _gh_issue_list {
  _arguments \
    '(-a --assignee)'{-a,--assignee}'[Filter by assignee]:' \
    '(-A --author)'{-A,--author}'[Filter by author]:' \
    '(*-l *--label)'{\*-l,\*--label}'[Filter by labels]:' \
    '(-L --limit)'{-L,--limit}'[Maximum number of issues to fetch]:' \
    '--mention[Filter by mention]:' \
    '(-m --milestone)'{-m,--milestone}'[Filter by milestone `number` or `title`]:' \
    '(-s --state)'{-s,--state}'[Filter by state: {open|closed|all}]:' \
    '(-w --web)'{-w,--web}'[Open the browser to list the issue(s)]' \
    '--help[Show help for command]' \
    '(-R --repo)'{-R,--repo}'[Select another repository using the `[HOST/]OWNER/REPO` format]:'
}

function _gh_issue_reopen {
  _arguments \
    '--help[Show help for command]' \
    '(-R --repo)'{-R,--repo}'[Select another repository using the `[HOST/]OWNER/REPO` format]:'
}

function _gh_issue_status {
  _arguments \
    '--help[Show help for command]' \
    '(-R --repo)'{-R,--repo}'[Select another repository using the `[HOST/]OWNER/REPO` format]:'
}

function _gh_issue_view {
  _arguments \
    '(-w --web)'{-w,--web}'[Open an issue in the browser]' \
    '--help[Show help for command]' \
    '(-R --repo)'{-R,--repo}'[Select another repository using the `[HOST/]OWNER/REPO` format]:'
}


function _gh_pr {
  local -a commands

  _arguments -C \
    '(-R --repo)'{-R,--repo}'[Select another repository using the `[HOST/]OWNER/REPO` format]:' \
    '--help[Show help for command]' \
    "1: :->cmnds" \
    "*::arg:->args"

  case $state in
  cmnds)
    commands=(
      "checkout:Check out a pull request in git"
      "close:Close a pull request"
      "create:Create a pull request"
      "diff:View changes in a pull request"
      "list:List and filter pull requests in this repository"
      "merge:Merge a pull request"
      "ready:Mark a pull request as ready for review"
      "reopen:Reopen a pull request"
      "review:Add a review to a pull request"
      "status:Show status of relevant pull requests"
      "view:View a pull request"
    )
    _describe "command" commands
    ;;
  esac

  case "$words[1]" in
  checkout)
    _gh_pr_checkout
    ;;
  close)
    _gh_pr_close
    ;;
  create)
    _gh_pr_create
    ;;
  diff)
    _gh_pr_diff
    ;;
  list)
    _gh_pr_list
    ;;
  merge)
    _gh_pr_merge
    ;;
  ready)
    _gh_pr_ready
    ;;
  reopen)
    _gh_pr_reopen
    ;;
  review)
    _gh_pr_review
    ;;
  status)
    _gh_pr_status
    ;;
  view)
    _gh_pr_view
    ;;
  esac
}

function _gh_pr_checkout {
  _arguments \
    '--recurse-submodules[Update all active submodules (recursively)]' \
    '--help[Show help for command]' \
    '(-R --repo)'{-R,--repo}'[Select another repository using the `[HOST/]OWNER/REPO` format]:'
}

function _gh_pr_close {
  _arguments \
    '(-d --delete-branch)'{-d,--delete-branch}'[Delete the local and remote branch after close]' \
    '--help[Show help for command]' \
    '(-R --repo)'{-R,--repo}'[Select another repository using the `[HOST/]OWNER/REPO` format]:'
}

function _gh_pr_create {
  _arguments \
    '(*-a *--assignee)'{\*-a,\*--assignee}'[Assign people by their `login`]:' \
    '(-B --base)'{-B,--base}'[The branch into which you want your code merged]:' \
    '(-b --body)'{-b,--body}'[Supply a body. Will prompt for one otherwise.]:' \
    '(-d --draft)'{-d,--draft}'[Mark pull request as a draft]' \
    '(-f --fill)'{-f,--fill}'[Do not prompt for title/body and just use commit info]' \
    '(*-l *--label)'{\*-l,\*--label}'[Add labels by `name`]:' \
    '(-m --milestone)'{-m,--milestone}'[Add the pull request to a milestone by `name`]:' \
    '(*-p *--project)'{\*-p,\*--project}'[Add the pull request to projects by `name`]:' \
    '(*-r *--reviewer)'{\*-r,\*--reviewer}'[Request reviews from people by their `login`]:' \
    '(-t --title)'{-t,--title}'[Supply a title. Will prompt for one otherwise.]:' \
    '(-w --web)'{-w,--web}'[Open the web browser to create a pull request]' \
    '--help[Show help for command]' \
    '(-R --repo)'{-R,--repo}'[Select another repository using the `[HOST/]OWNER/REPO` format]:'
}

function _gh_pr_diff {
  _arguments \
    '--color[Use color in diff output: {always|never|auto}]:' \
    '--help[Show help for command]' \
    '(-R --repo)'{-R,--repo}'[Select another repository using the `[HOST/]OWNER/REPO` format]:'
}

function _gh_pr_list {
  _arguments \
    '(-a --assignee)'{-a,--assignee}'[Filter by assignee]:' \
    '(-B --base)'{-B,--base}'[Filter by base branch]:' \
    '(*-l *--label)'{\*-l,\*--label}'[Filter by labels]:' \
    '(-L --limit)'{-L,--limit}'[Maximum number of items to fetch]:' \
    '(-s --state)'{-s,--state}'[Filter by state: {open|closed|merged|all}]:' \
    '(-w --web)'{-w,--web}'[Open the browser to list the pull requests]' \
    '--help[Show help for command]' \
    '(-R --repo)'{-R,--repo}'[Select another repository using the `[HOST/]OWNER/REPO` format]:'
}

function _gh_pr_merge {
  _arguments \
    '(-d --delete-branch)'{-d,--delete-branch}'[Delete the local and remote branch after merge]' \
    '(-m --merge)'{-m,--merge}'[Merge the commits with the base branch]' \
    '(-r --rebase)'{-r,--rebase}'[Rebase the commits onto the base branch]' \
    '(-s --squash)'{-s,--squash}'[Squash the commits into one commit and merge it into the base branch]' \
    '--help[Show help for command]' \
    '(-R --repo)'{-R,--repo}'[Select another repository using the `[HOST/]OWNER/REPO` format]:'
}

function _gh_pr_ready {
  _arguments \
    '--help[Show help for command]' \
    '(-R --repo)'{-R,--repo}'[Select another repository using the `[HOST/]OWNER/REPO` format]:'
}

function _gh_pr_reopen {
  _arguments \
    '--help[Show help for command]' \
    '(-R --repo)'{-R,--repo}'[Select another repository using the `[HOST/]OWNER/REPO` format]:'
}

function _gh_pr_review {
  _arguments \
    '(-a --approve)'{-a,--approve}'[Approve pull request]' \
    '(-b --body)'{-b,--body}'[Specify the body of a review]:' \
    '(-c --comment)'{-c,--comment}'[Comment on a pull request]' \
    '(-r --request-changes)'{-r,--request-changes}'[Request changes on a pull request]' \
    '--help[Show help for command]' \
    '(-R --repo)'{-R,--repo}'[Select another repository using the `[HOST/]OWNER/REPO` format]:'
}

function _gh_pr_status {
  _arguments \
    '--help[Show help for command]' \
    '(-R --repo)'{-R,--repo}'[Select another repository using the `[HOST/]OWNER/REPO` format]:'
}

function _gh_pr_view {
  _arguments \
    '(-w --web)'{-w,--web}'[Open a pull request in the browser]' \
    '--help[Show help for command]' \
    '(-R --repo)'{-R,--repo}'[Select another repository using the `[HOST/]OWNER/REPO` format]:'
}


function _gh_repo {
  local -a commands

  _arguments -C \
    '--help[Show help for command]' \
    "1: :->cmnds" \
    "*::arg:->args"

  case $state in
  cmnds)
    commands=(
      "clone:Clone a repository locally"
      "create:Create a new repository"
      "fork:Create a fork of a repository"
      "view:View a repository"
    )
    _describe "command" commands
    ;;
  esac

  case "$words[1]" in
  clone)
    _gh_repo_clone
    ;;
  create)
    _gh_repo_create
    ;;
  fork)
    _gh_repo_fork
    ;;
  view)
    _gh_repo_view
    ;;
  esac
}

function _gh_repo_clone {
  _arguments \
    '--help[Show help for command]'
}

function _gh_repo_create {
  _arguments \
    '(-y --confirm)'{-y,--confirm}'[Confirm the submission directly]' \
    '(-d --description)'{-d,--description}'[Description of repository]:' \
    '--enable-issues[Enable issues in the new repository]' \
    '--enable-wiki[Enable wiki in the new repository]' \
    '(-h --homepage)'{-h,--homepage}'[Repository home page URL]:' \
    '--internal[Make the new repository internal]' \
    '--private[Make the new repository private]' \
    '--public[Make the new repository public]' \
    '(-t --team)'{-t,--team}'[The name of the organization team to be granted access]:' \
    '(-p --template)'{-p,--template}'[Make the new repository based on a template repository]:' \
    '--help[Show help for command]'
}

function _gh_repo_fork {
  _arguments \
    '--clone[Clone the fork {true|false}]' \
    '--remote[Add remote for fork {true|false}]' \
    '--help[Show help for command]'
}

function _gh_repo_view {
  _arguments \
    '(-w --web)'{-w,--web}'[Open a repository in the browser]' \
    '--help[Show help for command]'
}


# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh


export PATH="$HOME/.poetry/bin:$PATH"
