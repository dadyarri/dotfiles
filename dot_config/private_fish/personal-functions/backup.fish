function backup --description 'Create timestamped backup copies of files or directories'
    argparse --name=backup --strict-longopts 'h/help' 'd/dir=' -- $argv
    or return 2

    if set -q _flag_help
        printf '%s\n' \
            'Usage: backup [OPTIONS] PATH...' \
            '' \
            'Create timestamped copies using cp -a. By default each backup is created' \
            'beside its source as NAME.bak.YYYYMMDD-HHMMSS.' \
            '' \
            'Options:' \
            '  -d, --dir DIRECTORY  Put all backups in DIRECTORY' \
            '  -h, --help           Show this help' \
            '' \
            'Examples:' \
            '  backup ~/.config/app/config.toml' \
            '  backup --dir ~/Backups important.db project/'
        return 0
    end

    if test (count $argv) -eq 0
        echo 'backup requires at least one PATH.' >&2
        return 2
    end

    set -l timestamp (date +%Y%m%d-%H%M%S)
    if set -q _flag_dir
        mkdir -p -- "$_flag_dir"
        or return $status
    end

    set -l failures
    for source in $argv
        # Normalize trailing slashes so `backup project/` creates a sibling
        # `project.bak.*` instead of a hidden file inside project/.
        if test "$source" != /
            set source (string replace -r '/+$' '' -- "$source")
        end

        if not test -e "$source"
            echo "Not found: $source" >&2
            set -a failures "$source"
            continue
        end

        set -l dest
        if set -q _flag_dir
            set dest "$_flag_dir/"(basename "$source")".bak.$timestamp"
        else
            set dest "$source.bak.$timestamp"
        end

        if cp -a -- "$source" "$dest"
            echo "$dest"
        else
            set -a failures "$source"
        end
    end

    if set -q failures[1]
        return 1
    end
end
