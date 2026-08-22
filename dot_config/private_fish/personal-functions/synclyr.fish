function synclyr --description 'Run synclyr2metadata for discovered music folders'
    argparse \
        --strict-longopts \
        --max-args=0 \
        'h/help' \
        't/threads=!_validate_int --min 1 --max 16' \
        'r/root=!test -d "$_flag_value"' \
        'd/direct-only' \
        'p/prompt' \
        'f/force' \
        'c/clean-lrc' \
        -- $argv
    or return 2

    if set -q _flag_help
        printf '%s\n' \
            'Usage: synclyr [OPTIONS]' \
            '' \
            'Discover music-containing directories and run synclyr2metadata once' \
            'for each directory.' \
            '' \
            'By default, recursively finds folders containing supported audio files.' \
            'With --direct-only, processes every immediate subdirectory of ROOT.' \
            '' \
            'Options:' \
            '  -r, --root DIR       Root directory to scan (default: .)' \
            '  -t, --threads N      Download threads, 1-16 (default: 12)' \
            '  -d, --direct-only    Process immediate subdirectories only' \
            '  -p, --prompt         Confirm before each folder and after failures' \
            '  -f, --force          Overwrite already embedded lyrics' \
            '  -c, --clean-lrc      Delete .lrc sidecars after successful embedding' \
            '  -h, --help           Show this help'
        return 0
    end

    if not type -q synclyr2metadata
        echo 'synclyr2metadata is not installed.' >&2
        return 127
    end

    set -l threads 12
    set -q _flag_threads; and set threads $_flag_threads

    set -l root '.'
    set -q _flag_root; and set root $_flag_root

    set root (path resolve -- "$root")

    set -l dirs

    if set -q _flag_direct_only
        set dirs (
            command find "$root" \
                -mindepth 1 \
                -maxdepth 1 \
                -type d \
                -print0 \
                | command sort -z \
                | string split0
        )
    else
        set dirs (
            command find "$root" \
                -type f \
                \( \
                    -iname '*.mp3' \
                    -o -iname '*.flac' \
                    -o -iname '*.m4a' \
                    -o -iname '*.ogg' \
                    -o -iname '*.opus' \
                    -o -iname '*.wav' \
                    -o -iname '*.aac' \
                \) \
                -printf '%h\0' \
                | command sort -zu \
                | string split0
        )
    end

    if not set -q dirs[1]
        echo "No music folders found under: $root"
        return 1
    end

    set -l failures

    for dir in $dirs
        echo
        printf 'Folder: %s\n' "$dir"

        if set -q _flag_prompt
            if not __confirm 'Run synclyr2metadata for this folder?'
                echo "Skipped: $dir"
                continue
            end
        end

        set -l sync_args \
            --folder "$dir" \
            --threads "$threads" \
            --out-missing "$dir/missing.log"

        set -q _flag_force; and set -a sync_args --force
        set -q _flag_clean_lrc; and set -a sync_args --clean-lrc

        command synclyr2metadata $sync_args
        set -l code $status

        if test $code -eq 130
            echo 'Interrupted.' >&2
            return 130
        end

        if test $code -ne 0
            set -a failures "$dir ($code)"

            printf 'synclyr2metadata failed for %s (exit %d).\n' \
                "$dir" "$code" >&2

            if set -q _flag_prompt
                if not __confirm 'Continue with the next folder?'
                    echo 'Stopped after failure.' >&2
                    return $code
                end
            end
        end
    end

    if set -q failures[1]
        echo >&2
        echo 'Completed with failures:' >&2
        printf '  %s\n' $failures >&2
        return 1
    end
end
