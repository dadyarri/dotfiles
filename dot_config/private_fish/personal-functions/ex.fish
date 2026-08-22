function ex --description 'Extract one or more archives'
    argparse --name=ex --strict-longopts 'h/help' 'd/dir=' -- $argv
    or return 2

    if set -q _flag_help
        printf '%s\n' \
            'Usage: ex [OPTIONS] ARCHIVE...' \
            '' \
            'Extract one or more archives using ouch. Archive formats are detected' \
            'from their extensions.' \
            '' \
            'Options:' \
            '  -d, --dir DIRECTORY  Extract into DIRECTORY' \
            '  -h, --help           Show this help' \
            '' \
            'Examples:' \
            '  ex package.tar.zst' \
            '  ex a.zip b.7z' \
            '  ex --dir ./out archive.tar.gz'
        return 0
    end

    if not type -q ouch
        echo 'ex requires ouch.' >&2
        return 127
    end
    if test (count $argv) -eq 0
        echo "Usage: ex [OPTIONS] ARCHIVE..." >&2
        return 2
    end

    set -l opts
    if set -q _flag_dir
        set -a opts --dir "$_flag_dir"
    end
    ouch decompress $opts $argv
end
