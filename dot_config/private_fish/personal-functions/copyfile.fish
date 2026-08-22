function copyfile --description 'Copy file contents to the desktop clipboard'
    argparse --name=copyfile --strict-longopts 'h/help' -- $argv
    or return 2

    if set -q _flag_help
        printf '%s\n' \
            'Usage: copyfile FILE...' \
            '' \
            'Copy the contents of one or more files to the desktop clipboard.' \
            'Multiple files are concatenated in the supplied order.' \
            '' \
            'Options:' \
            '  -h, --help  Show this help'
        return 0
    end

    if test (count $argv) -eq 0
        echo 'copyfile requires at least one FILE.' >&2
        return 2
    end

    for file in $argv
        if not test -f "$file"
            echo "Not a regular file: $file" >&2
            return 2
        end
    end

    cat -- $argv | __clipboard_copy
end
