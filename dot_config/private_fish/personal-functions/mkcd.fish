function mkcd --description 'Create a directory and change into it'
    argparse --name=mkcd --strict-longopts --max-args=1 'h/help' 'p/parents' -- $argv
    or return 2

    if set -q _flag_help
        printf '%s\n' \
            'Usage: mkcd [OPTIONS] DIRECTORY' \
            '' \
            'Create DIRECTORY and change the current shell into it.' \
            'Parent directories are created automatically.' \
            '' \
            'Options:' \
            '  -p, --parents  Accepted for mkdir familiarity; parents are always created' \
            '  -h, --help     Show this help'
        return 0
    end

    if test (count $argv) -ne 1
        echo 'mkcd requires exactly one DIRECTORY.' >&2
        return 2
    end

    mkdir -p -- "$argv[1]"
    and cd -- "$argv[1]"
end
