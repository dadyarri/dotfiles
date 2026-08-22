function imgcompress --description 'Compress and optionally resize images'
    argparse \
        --name=imgcompress \
        --strict-longopts \
        'h/help' \
        'm/max=' \
        'w/width=' \
        'H/height=' \
        'q/quality=' \
        'e/ext=+' \
        'r/recursive' \
        'i/in-place' \
        'k/keep-metadata' \
        -- $argv
    or return 2

    if set -q _flag_help
        printf '%s\n' \
            'Usage: imgcompress [OPTIONS] FILE_OR_DIRECTORY...' \
            '' \
            'Compress image files with ImageMagick. Directories are scanned one level' \
            'deep by default. Without --in-place, output is written beside the source' \
            'as NAME.compressed.EXT.' \
            '' \
            'When --max is specified, lossy formats use a quality search and, if that' \
            'is still insufficient, progressively reduce dimensions. PNG uses maximum' \
            'lossless compression and reduces dimensions only when needed.' \
            '' \
            'Options:' \
            '  -m, --max SIZE       Target maximum size, e.g. 500K, 2M, 2MiB' \
            '  -w, --width PX       Maximum width; never upscale' \
            '  -H, --height PX      Maximum height; never upscale' \
            '  -q, --quality N      Initial/default lossy quality (1-100; default 82)' \
            '  -e, --ext EXT        Only process this extension; may be repeated' \
            '  -r, --recursive      Recurse into directories' \
            '  -i, --in-place       Replace source files after successful conversion' \
            '  -k, --keep-metadata  Preserve metadata; default is to strip it' \
            '  -h, --help           Show this help' \
            '' \
            'Examples:' \
            '  imgcompress photo.jpg --max 1M' \
            '  imgcompress ./photos --ext jpg --ext png --max 800K' \
            '  imgcompress -r ./photos --width 1920 --max 1.5M' \
            '  imgcompress *.webp --quality 80 --in-place'
        return 0
    end

    if not type -q magick
        echo 'imgcompress requires ImageMagick (magick).' >&2
        return 127
    end
    if test (count $argv) -eq 0
        echo 'Usage: imgcompress [OPTIONS] FILE_OR_DIRECTORY...' >&2
        return 2
    end

    set -l quality 82
    if set -q _flag_quality
        set quality $_flag_quality
    end
    string match -rq '^[0-9]+$' -- "$quality"; or begin
        echo "Invalid quality: $quality" >&2
        return 2
    end
    if test "$quality" -lt 1 -o "$quality" -gt 100
        echo 'Quality must be between 1 and 100.' >&2
        return 2
    end

    if set -q _flag_width
        string match -rq '^[1-9][0-9]*$' -- "$_flag_width"; or begin
            echo "Invalid width: $_flag_width" >&2
            return 2
        end
    end
    if set -q _flag_height
        string match -rq '^[1-9][0-9]*$' -- "$_flag_height"; or begin
            echo "Invalid height: $_flag_height" >&2
            return 2
        end
    end

    set -l max_bytes
    if set -q _flag_max
        set max_bytes (__parse_size "$_flag_max")
        or return $status
    end

    set -l collector_opts
    if set -q _flag_recursive
        set -a collector_opts --recursive
    end
    if set -q _flag_ext
        for ext in $_flag_ext
            set -a collector_opts --ext "$ext"
        end
    end
    set -l files (__image_files $collector_opts $argv)

    if not set -q files[1]
        echo 'No supported image files found.' >&2
        return 1
    end

    set -l failures
    for file in $files
        set -l ext (string lower -- (string replace -r '^.*\.([^.]+)$' '$1' -- "$file"))
        switch $ext
            case jpg jpeg png webp avif heic
            case '*'
                echo "Skipping unsupported compression format: $file" >&2
                continue
        end

        set -l stem (string replace -r '\.[^.]+$' '' -- "$file")
        set -l output "$stem.compressed.$ext"
        set -l tmpdir (mktemp -d)
        set -l candidate "$tmpdir/candidate.$ext"
        set -l best "$tmpdir/best.$ext"
        set -l scale 100
        set -l success 0
        set -l original_size (stat -c %s -- "$file")

        set -l geometry
        if set -q _flag_width; and set -q _flag_height
            set geometry (string join '' $_flag_width x $_flag_height '>')
        else if set -q _flag_width
            set geometry (string join '' $_flag_width 'x>')
        else if set -q _flag_height
            set geometry (string join '' x $_flag_height '>')
        end

        for shrink_round in (seq 1 12)
            set -l base_args "$file" -auto-orient
            if test -n "$geometry"
                set -a base_args -resize "$geometry"
            end
            if test $scale -lt 100
                set -a base_args -resize "$scale%"
            end
            if not set -q _flag_keep_metadata
                set -a base_args -strip
            end

            if test "$ext" = png
                magick $base_args -quality 90 "$candidate"
                or break
                cp -- "$candidate" "$best"

                if not set -q max_bytes; or test (stat -c %s -- "$candidate") -le "$max_bytes"
                    set success 1
                    break
                end
            else if not set -q max_bytes
                magick $base_args -quality "$quality" "$candidate"
                or break
                cp -- "$candidate" "$best"
                set success 1
                break
            else
                set -l low 10
                set -l high $quality
                set -l round_best 0
                set -l encode_failed 0

                while test $low -le $high
                    set -l mid (math --scale=0 "($low + $high) / 2")
                    magick $base_args -quality "$mid" "$candidate"
                    or begin
                        set encode_failed 1
                        break
                    end
                    set -l size (stat -c %s -- "$candidate")

                    if test "$size" -le "$max_bytes"
                        cp -- "$candidate" "$best"
                        set round_best 1
                        set low (math "$mid + 1")
                    else
                        set high (math "$mid - 1")
                    end
                end

                if test $encode_failed -eq 1
                    break
                end
                if test $round_best -eq 1
                    set success 1
                    break
                end
            end

            # Quality alone was not enough (or PNG is still too large).
            # Reduce dimensions and retry. The source is always used as input so
            # repeated encoding losses do not accumulate.
            set scale (math --scale=0 "$scale * 0.9")
            if test $scale -lt 20
                break
            end
        end

        if test $success -ne 1; or not test -s "$best"
            echo "Failed to compress: $file" >&2
            set -a failures "$file"
            rm -rf -- "$tmpdir"
            continue
        end

        set -l new_size (stat -c %s -- "$best")
        if set -q _flag_in_place
            mv -- "$best" "$file"
            set output "$file"
        else
            mv -- "$best" "$output"
        end
        rm -rf -- "$tmpdir"

        printf '%s -> %s  (%s -> %s bytes)\n' "$file" "$output" "$original_size" "$new_size"
    end

    if set -q failures[1]
        return 1
    end
end
