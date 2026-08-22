function copypath --description 'Copy canonical absolute paths to the desktop clipboard'
    argparse --name=copypath --strict-longopts 'h/help' -- $argv
    or return 2

    if set -q _flag_help
        printf '%s\n' \
            'Usage: copypath PATH...' \
            '' \
            'Resolve PATH arguments to canonical absolute paths and copy them to the' \
            'clipboard, one path per line.' \
            '' \
            'Options:' \
            '  -h, --help  Show this help'
        return 0
    end

    if test (count $argv) -eq 0
        echo 'copypath requires at least one PATH.' >&2
        return 2
    end

    set -l paths
    for item in $argv
        set -l resolved (realpath -- "$item" 2>/dev/null)
        or begin
            echo "Could not resolve: $item" >&2
            return 1
        end
        set -a paths "$resolved"
    end

    printf '%s\n' $paths | __clipboard_copy
end
