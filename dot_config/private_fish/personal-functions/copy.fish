function copy --description 'Copy stdin or arguments to the desktop clipboard'
    argparse --name=copy --strict-longopts 'h/help' -- $argv
    or return 2

    if set -q _flag_help
        printf '%s\n' \
            'Usage: COMMAND | copy' \
            '       copy TEXT...' \
            '' \
            'Copy stdin to the desktop clipboard. If arguments are supplied, copy' \
            'them joined by spaces instead.' \
            '' \
            'Options:' \
            '  -h, --help  Show this help' \
            '' \
            'Examples:' \
            '  pwd | copy' \
            '  copy hello world'
        return 0
    end

    if test (count $argv) -gt 0
        printf '%s' (string join ' ' -- $argv) | __clipboard_copy
    else if not isatty stdin
        __clipboard_copy
    else
        echo 'copy requires text as arguments or on stdin.' >&2
        return 2
    end
end
