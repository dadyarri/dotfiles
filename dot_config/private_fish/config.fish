if type -q xdg-user-dir
    set -gx XDG_PROJECTS_DIR (xdg-user-dir PROJECTS)
end

if status is-interactive
    atuin init fish | source
    zoxide init fish | source
end
