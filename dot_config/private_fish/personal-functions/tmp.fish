function tmp --description 'Create a temporary directory and change into it'
    argparse --name=tmp --strict-longopts --max-args=1 'h/help' -- $argv
    or return 2

    if set -q _flag_help
        printf '%s\n' \
            'Usage: tmp [PREFIX]' \
            '' \
            'Create a temporary directory under $TMPDIR (or /tmp) and change the' \
            'current shell into it.' \
            '' \
            'Arguments:' \
            '  PREFIX  Optional human-readable prefix (default: fish)' \
            '' \
            'Options:' \
            '  -h, --help  Show this help'
        return 0
    end

    set -l root /tmp
    if set -q TMPDIR; and test -d "$TMPDIR"
        set root "$TMPDIR"
    end
    set -l prefix fish
    if set -q argv[1]
        set prefix (string replace -ra '[^A-Za-z0-9._-]' '-' -- "$argv[1]")
    end

    set -l dir (mktemp -d "$root/$prefix.XXXXXX")
    and cd -- "$dir"
end
