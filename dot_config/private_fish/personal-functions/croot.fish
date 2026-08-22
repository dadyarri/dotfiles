function croot --description 'Change to the root of the current Git repository'
    argparse --name=croot --strict-longopts --max-args=0 'h/help' -- $argv
    or return 2

    if set -q _flag_help
        printf '%s\n' \
            'Usage: croot' \
            '' \
            'Change the current shell to the top-level directory of the current Git' \
            'working tree.' \
            '' \
            'Options:' \
            '  -h, --help  Show this help'
        return 0
    end

    set -l root (git rev-parse --show-toplevel 2>/dev/null)
    or begin
        echo 'Not inside a Git working tree.' >&2
        return 1
    end
    cd -- "$root"
end
