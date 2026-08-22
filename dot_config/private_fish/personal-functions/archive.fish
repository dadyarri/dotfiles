function archive --description 'Create an archive from files or directories'
    argparse --name=archive --strict-longopts --exclusive f,s --exclusive f,l --exclusive s,l 'h/help' 'l/level=' 'f/fast' 's/slow' -- $argv
    or return 2

    if set -q _flag_help
        printf '%s\n' \
            'Usage: archive [OPTIONS] OUTPUT INPUT...' \
            '' \
            'Create OUTPUT with ouch. The archive/compression format is inferred' \
            'from OUTPUT, e.g. .zip, .tar.gz, .tar.zst or .7z.' \
            '' \
            'Options:' \
            '  -l, --level LEVEL  Compression level passed to ouch' \
            '  -f, --fast         Prefer fastest compression' \
            '  -s, --slow         Prefer smallest/best compression' \
            '  -h, --help         Show this help' \
            '' \
            'Examples:' \
            '  archive backup.tar.zst ./src ./README.md' \
            '  archive --slow photos.zip ./photos'
        return 0
    end

    if test (count $argv) -lt 2
        echo 'archive requires OUTPUT followed by at least one INPUT.' >&2
        return 2
    end

    if not type -q ouch
        echo 'archive requires ouch.' >&2
        return 127
    end

    set -l output $argv[1]
    set -e argv[1]
    set -l opts
    if set -q _flag_level
        set -a opts --level "$_flag_level"
    end
    if set -q _flag_fast
        set -a opts --fast
    end
    if set -q _flag_slow
        set -a opts --slow
    end

    ouch compress $opts $argv "$output"
end
