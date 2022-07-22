# Shortcuts for standard commands
alias q="clear"
alias mkdir="mkdir -p"

# Fedora's package management'
alias dnfi="sudo dnf install"
alias dnfu="sudo dnf update"
alias dnfr="sudo dnf remove"

# Drop-in replacements

## Cat -> Bat
command bat &> /dev/null && alias cat="bat"

## Ls -> Exa
command exa &> /dev/null
if [ $? -eq 0 ]; then
    alias ls="exa --icons --color always"
    alias lsa="exa --icons -a --color always"
    alias lsl="exa --icons -lh --git --color always"
    alias lsal="exa --icons -alh --git --color always"
fi

