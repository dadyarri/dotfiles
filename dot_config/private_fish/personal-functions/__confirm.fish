function __confirm --description 'Internal confirmation prompt with Gum and native Fish fallback'
    set -l prompt (string join ' ' -- $argv)

    if test -z "$prompt"
        set prompt 'Continue?'
    end

    if type -q gum
        gum confirm "$prompt"
        return $status
    end

    read -l -P "$prompt [y/N] " answer
    string match -rqi '^(y|yes)$' -- "$answer"
end
