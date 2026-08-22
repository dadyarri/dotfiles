function imgconvert --description 'Batch-convert image files to another format'
    argparse \
        --name=imgconvert \
        --strict-longopts \
        'h/help' \
        't/to=' \
        'f/from=+' \
        'q/quality=' \
        'o/output-dir=' \
        'r/recursive' \
        'k/keep-metadata' \
        -- $argv
    or return 2

    if set -q _flag_help
        printf '%s\n' \
            'Usage: imgconvert --to FORMAT [OPTIONS] FILE_OR_DIRECTORY...' \
            '' \
            'Convert images with ImageMagick. The source file is never deleted.' \
            'Without --output-dir, converted files are written beside each source.' \
            '' \
            'Options:' \
            '  -t, --to FORMAT        Output format (jpg, png, webp, avif, ...)' \
            '  -f, --from EXT         Only process this input extension; repeatable' \
            '  -q, --quality N        Output quality when applicable (1-100)' \
            '  -o, --output-dir DIR   Put converted files in DIR' \
            '  -r, --recursive        Recurse into directories' \
            '  -k, --keep-metadata    Preserve metadata; default is to strip it' \
            '  -h, --help             Show this help' \
            '' \
            'Examples:' \
            '  imgconvert --to webp *.png' \
            '  imgconvert --from jpg --to avif --quality 70 ./photos' \
            '  imgconvert -r --to webp --output-dir ./converted ./assets'
        return 0
    end

    if not type -q magick
        echo 'imgconvert requires ImageMagick (magick).' >&2
        return 127
    end
    if not set -q _flag_to
        echo 'imgconvert requires --to FORMAT.' >&2
        return 2
    end
    if test (count $argv) -eq 0
        echo 'imgconvert requires at least one file or directory.' >&2
        return 2
    end

    set -l to (string lower -- (string trim -c '.' -- $_flag_to))
    set -l quality
    if set -q _flag_quality
        set quality $_flag_quality
        string match -rq '^[0-9]+$' -- "$quality"; or begin
            echo "Invalid quality: $quality" >&2
            return 2
        end
        if test "$quality" -lt 1 -o "$quality" -gt 100
            echo 'Quality must be between 1 and 100.' >&2
            return 2
        end
    end

    set -l collector_opts
    if set -q _flag_recursive
        set -a collector_opts --recursive
    end
    if set -q _flag_from
        for ext in $_flag_from
            set -a collector_opts --ext "$ext"
        end
    end
    set -l files (__image_files $collector_opts $argv)

    if not set -q files[1]
        echo 'No supported image files found.' >&2
        return 1
    end

    if set -q _flag_output_dir
        mkdir -p -- "$_flag_output_dir"
        or return $status
    end

    set -l failures
    for file in $files
        set -l filename (basename "$file")
        set -l stem (string replace -r '\.[^.]+$' '' -- "$filename")
        set -l output
        if set -q _flag_output_dir
            set output "$_flag_output_dir/$stem.$to"
        else
            set output (string replace -r '\.[^.]+$' ".$to" -- "$file")
        end

        if test "$output" = "$file"
            echo "Skipping $file: input and output format are identical." >&2
            continue
        end

        set -l opts "$file" -auto-orient
        if not set -q _flag_keep_metadata
            set -a opts -strip
        end
        if test -n "$quality"
            set -a opts -quality "$quality"
        end
        set -a opts "$output"

        if magick $opts
            printf '%s -> %s\n' "$file" "$output"
        else
            echo "Failed to convert: $file" >&2
            set -a failures "$file"
        end
    end

    if set -q failures[1]
        return 1
    end
end
