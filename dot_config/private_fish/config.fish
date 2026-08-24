if type -q xdg-user-dir
    set -gx XDG_PROJECTS_DIR (xdg-user-dir PROJECTS)
end

if status is-interactive
    type -q atuin; and atuin init fish | source
    type -q zoxide; and zoxide init fish | source
    type -q starship; and starship init fish | source; and enable_transience
end
