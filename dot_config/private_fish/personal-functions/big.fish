function big --description 'Show the largest files and directories under a path'
    argparse --name=big --strict-longopts --max-args=1 'h/help' 'n/count=' 'a/all-filesystems' -- $argv
    or return 2

    if set -q _flag_help
        printf '%s\n' \
            'Usage: big [OPTIONS] [PATH]' \
            '' \
            'Show the largest files/directories under PATH (default: current directory)' \
            'using du, sorted by apparent disk usage.' \
            '' \
            'Options:' \
            '  -n, --count N          Number of entries (default: 30)' \
            '  -a, --all-filesystems  Allow crossing filesystem boundaries' \
            '  -h, --help             Show this help' \
            '' \
            'Examples:' \
            '  big' \
            '  big -n 50 ~' \
            '  sudo big /var'
        return 0
    end

    set -l count 30
    if set -q _flag_count
        set count $_flag_count
    end
    string match -rq '^[1-9][0-9]*$' -- "$count"; or begin
        echo "Invalid count: $count" >&2
        return 2
    end

    set -l target .
    if set -q argv[1]
        set target $argv[1]
    end
    if not test -e "$target"
        echo "Not found: $target" >&2
        return 1
    end

    set -l du_opts -a -h
    if not set -q _flag_all_filesystems
        set -a du_opts -x
    end

    command du $du_opts -- "$target" 2>/dev/null | sort -hr | head -n "$count"
end
