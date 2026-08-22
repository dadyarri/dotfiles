function cdf --description 'Change to a directory or to the parent directory of a file'
    argparse --name=cdf --strict-longopts --max-args=1 'h/help' -- $argv
    or return 2

    if set -q _flag_help
        printf '%s\n' \
            'Usage: cdf [PATH]' \
            '       COMMAND | cdf' \
            '' \
            'If PATH is a directory, change into it. If PATH is a file, change into' \
            'its containing directory. With no argument, read one path from stdin.' \
            '' \
            'Examples:' \
            '  cdf ./src/Program.cs' \
            '  fd Program.cs | head -n1 | cdf' \
            '  fzf | cdf' \
            '' \
            'Options:' \
            '  -h, --help  Show this help'
        return 0
    end

    set -l target
    if set -q argv[1]
        set target "$argv[1]"
    else if not isatty stdin
        set target (string collect | string trim)
    else
        echo 'cdf requires PATH as an argument or on stdin.' >&2
        return 2
    end

    if test -z "$target"
        echo 'cdf received an empty path.' >&2
        return 2
    end

    if test -d "$target"
        cd -- "$target"
    else if test -e "$target"
        cd -- (dirname -- "$target")
    else
        echo "Path does not exist: $target" >&2
        return 1
    end
end
