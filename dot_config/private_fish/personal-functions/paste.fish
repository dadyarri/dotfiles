function paste --description 'Print the desktop clipboard to stdout'
    argparse --name=paste --strict-longopts --max-args=0 'h/help' 'n/newline' -- $argv
    or return 2

    if set -q _flag_help
        printf '%s\n' \
            'Usage: paste [OPTIONS]' \
            '' \
            'Print the current desktop clipboard contents to stdout.' \
            '' \
            'Options:' \
            '  -n, --newline  Append a newline after clipboard contents' \
            '  -h, --help     Show this help'
        return 0
    end

    __clipboard_paste
    set -l rc $status
    if set -q _flag_newline
        echo
    end
    return $rc
end
