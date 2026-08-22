function trash --description 'Move files or directories to the desktop trash'
    argparse --name=trash --strict-longopts 'h/help' -- $argv
    or return 2

    if set -q _flag_help
        printf '%s\n' \
            'Usage: trash FILE_OR_DIRECTORY...' \
            '' \
            'Move files/directories to the freedesktop trash using trash-cli.' \
            'This is intentionally not an rm wrapper.' \
            '' \
            'Options:' \
            '  -h, --help  Show this help'
        return 0
    end

    if not type -q trash-put
        echo 'trash requires trash-cli (trash-put).' >&2
        return 127
    end
    if test (count $argv) -eq 0
        echo 'trash requires at least one path.' >&2
        return 2
    end

    trash-put -- $argv
end
