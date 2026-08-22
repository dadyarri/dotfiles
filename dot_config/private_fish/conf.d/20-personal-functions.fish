# Keep personal workflow utilities separate from Fisher/plugin functions while
# retaining Fish's normal lazy autoloading behavior.

set -l personal_functions_dir "$HOME/.config/fish/personal-functions"

if set -q XDG_CONFIG_HOME
    set personal_functions_dir "$XDG_CONFIG_HOME/fish/personal-functions"
end

if test -d "$personal_functions_dir"
    if not contains -- "$personal_functions_dir" $fish_function_path
        set -p fish_function_path "$personal_functions_dir"
    end
end
