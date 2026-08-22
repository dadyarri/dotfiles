function __mine_selector --description 'Internal fuzzy selector used by personal Fish utilities'
    argparse --name=__mine_selector --strict-longopts 'm/multi' 'p/prompt=' -- $argv
    or return 2

    set -l prompt 'Select> '
    if set -q _flag_prompt
        set prompt $_flag_prompt
    end

    if type -q tv
        # Television accepts stdin directly and supports interactive selection.
        tv
    else if type -q fzf
        set -l opts \
            --height=80% \
            --layout=reverse \
            --border \
            --prompt="$prompt"

        if set -q _flag_multi
            set -a opts --multi
        end

        fzf $opts
    else if type -q gum
        set -l opts

        if set -q _flag_multi
            set -a opts --no-limit
        end

        gum filter $opts
    else
        echo 'No interactive selector found. Install television, fzf, or gum.' >&2
        return 127
    end
end
