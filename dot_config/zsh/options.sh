setopt auto_cd # treat command as directory and cd into it, if it can't be executed
setopt no_case_glob # case-insensitive globbing

# save history across sessions
setopt append_history
setopt share_history
setopt inc_append_history

# ignore duplicates in history (why so many options required for this behaviour?)
setopt hist_ignore_dups
setopt hist_ignore_all_dups
setopt hist_ignore_space
setopt hist_expire_dups_first
setopt hist_find_no_dups
setopt hist_save_no_dups

# allow to edit command when using !! snippet
setopt hist_verify

# suggest correction of mistyped commands
setopt correct
setopt correct_all

# allow comments in interactive session
setopt interactive_comments

HISTFILE=~/.local/cache/zsh/history # path to file with history
HISTSIZE=5000 # max size of history file
SAVEHIST=5000
