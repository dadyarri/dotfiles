status is-interactive; or exit

set -gx FNM_PATH "$HOME/.local/share/fnm"

if test -d "$FNM_PATH"
    set -gx PATH "$FNM_PATH" $PATH
    fnm env --use-on-cd --shell fish | source
end
