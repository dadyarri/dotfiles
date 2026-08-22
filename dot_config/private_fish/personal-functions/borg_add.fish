function borg_add --description 'Create a dated Borg archive from a source directory'
    argparse \
        --strict-longopts \
        --max-args=2 \
        'h/help' \
        'r/repo=' \
        'e/exclude=' \
        'c/compression=' \
        'n/dry-run' \
        -- $argv
    or return 2

    if set -q _flag_help
        printf '%s\n' \
            'Usage: borg_add [OPTIONS] ARCHIVE_PREFIX SOURCE_DIRECTORY' \
            '' \
            'Create PREFIX-YYYY-MM-DD in a Borg repository.' \
            '' \
            'Defaults:' \
            '  repository   $BORG_ADD_REPO or ~/Projects/Archive.borg' \
            '  exclude file $BORG_ADD_EXCLUDE or ~/Projects/borg-archive.exclude' \
            '  compression  zstd,12' \
            '' \
            'Options:' \
            '  -r, --repo PATH          Borg repository' \
            '  -e, --exclude FILE       Borg exclude file' \
            '  -c, --compression SPEC   Borg compression specification' \
            '  -n, --dry-run            Show what Borg would archive without creating it' \
            '  -h, --help               Show this help' \
            '' \
            'Examples:' \
            '  borg_add melodytrack ~/Projects/MelodyTrack' \
            '  borg_add --dry-run dotfiles ~/.config'
        return 0
    end

    if test (count $argv) -ne 2
        echo 'borg_add requires ARCHIVE_PREFIX and SOURCE_DIRECTORY.' >&2
        echo "Run 'borg_add --help' for usage." >&2
        return 2
    end

    if not type -q borg
        echo 'borg is not installed.' >&2
        return 127
    end

    set -l archive_prefix $argv[1]
    set -l source_dir $argv[2]

    if not test -d "$source_dir"
        echo "Source directory does not exist: $source_dir" >&2
        return 1
    end

    set -l repo "$HOME/Projects/Archive.borg"

    if set -q BORG_ADD_REPO
        set repo "$BORG_ADD_REPO"
    end

    if set -q _flag_repo
        set repo "$_flag_repo"
    end

    set -l exclude_file "$HOME/Projects/borg-archive.exclude"

    if set -q BORG_ADD_EXCLUDE
        set exclude_file "$BORG_ADD_EXCLUDE"
    end

    if set -q _flag_exclude
        set exclude_file "$_flag_exclude"
    end

    set -l compression 'zstd,12'

    if set -q _flag_compression
        set compression "$_flag_compression"
    end

    if not test -f "$exclude_file"
        echo "Exclude file does not exist: $exclude_file" >&2
        return 1
    end

    set -l archive_name "$archive_prefix-"(date +%Y-%m-%d)
    set -l archive "$repo::$archive_name"

    set -l borg_args \
        create \
        --stats \
        --progress \
        --compression "$compression" \
        --exclude-from "$exclude_file"

    if set -q _flag_dry_run
        set -a borg_args --dry-run --list
    end

    printf 'Repository: %s\nArchive:    %s\nSource:     %s\n' \
        "$repo" \
        "$archive_name" \
        "$source_dir"

    command borg $borg_args "$archive" "$source_dir"
end
