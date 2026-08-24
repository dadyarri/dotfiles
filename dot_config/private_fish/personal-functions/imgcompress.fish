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
            'Compress and optionally resize image files.' \
            '' \
            'Static images are processed with ImageMagick. Animated GIFs are processed' \
            'with gifsicle and remain animated.' \
            '' \
            'Directories are scanned one level deep by default. Without --in-place,' \
            'output is written beside the source as NAME.compressed.EXT.' \
            '' \
            'When --max is specified, static lossy formats search for the highest' \
            'quality that fits and then reduce dimensions if necessary.' \
            '' \
            'For GIFs, compression preserves dimensions as long as possible: it first' \
            'increases lossy compression, then reduces palette size, and only then' \
            'reduces dimensions. Automatic GIF resizing never goes below 50%.' \
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
            'Dependencies:' \
            '  ImageMagick          JPG, JPEG, PNG, WebP, AVIF, HEIC' \
            '  gifsicle             GIF' \
            '' \
            'Examples:' \
            '  imgcompress photo.jpg --max 1M' \
            '  imgcompress animation.gif --max 1M' \
            '  imgcompress animation.gif --width 800 --quality 85' \
            '  imgcompress ./photos --ext jpg --ext png --ext gif --max 800K' \
            '  imgcompress -r ./photos --width 1920 --max 1.5M' \
            '  imgcompress *.webp --quality 80 --in-place'
        return 0
    end

    if test (count $argv) -eq 0
        echo 'Usage: imgcompress [OPTIONS] FILE_OR_DIRECTORY...' >&2
        return 2
    end

    set -l quality 82

    if set -q _flag_quality
        set quality "$_flag_quality"
    end

    string match -rq '^[0-9]+$' -- "$quality"
    or begin
        echo "Invalid quality: $quality" >&2
        return 2
    end

    if test "$quality" -lt 1 -o "$quality" -gt 100
        echo 'Quality must be between 1 and 100.' >&2
        return 2
    end

    if set -q _flag_width
        string match -rq '^[1-9][0-9]*$' -- "$_flag_width"
        or begin
            echo "Invalid width: $_flag_width" >&2
            return 2
        end
    end

    if set -q _flag_height
        string match -rq '^[1-9][0-9]*$' -- "$_flag_height"
        or begin
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

    #
    # Check only dependencies actually needed by the selected files.
    #

    set -l needs_magick 0
    set -l needs_gifsicle 0

    for file in $files
        set -l ext (
            string lower -- (
                string replace -r '^.*\.([^.]+)$' '$1' -- "$file"
            )
        )

        switch $ext
            case jpg jpeg png webp avif heic
                set needs_magick 1

            case gif
                set needs_gifsicle 1
        end
    end

    if test $needs_magick -eq 1; and not type -q magick
        echo 'ImageMagick (magick) is required for static image compression.' >&2
        return 127
    end

    if test $needs_gifsicle -eq 1; and not type -q gifsicle
        echo 'gifsicle is required for GIF compression.' >&2
        echo 'Install it with: sudo pacman -S gifsicle' >&2
        return 127
    end

    set -l failures

    for file in $files
        set -l ext (
            string lower -- (
                string replace -r '^.*\.([^.]+)$' '$1' -- "$file"
            )
        )

        switch $ext
            case jpg jpeg png webp avif heic gif

            case '*'
                echo "Skipping unsupported compression format: $file" >&2
                continue
        end

        set -l stem (
            string replace -r '\.[^.]+$' '' -- "$file"
        )

        set -l output "$stem.compressed.$ext"

        set -l tmpdir (mktemp -d)
        or begin
            echo "Could not create temporary directory for: $file" >&2
            set -a failures "$file"
            continue
        end

        set -l candidate "$tmpdir/candidate.$ext"
        set -l best "$tmpdir/best.$ext"

        set -l success 0
        set -l scale 100

        set -l original_size (
            stat -c %s -- "$file"
        )

        if test $status -ne 0
            echo "Could not determine file size: $file" >&2
            set -a failures "$file"
            rm -rf -- "$tmpdir"
            continue
        end

        #
        # GIF
        #

        if test "$ext" = gif
            set -l gif_source "$file"

            #
            # Apply explicit maximum dimensions once.
            #
            # Later compression passes always use this resulting source rather
            # than repeatedly resizing already-compressed output.
            #

            if set -q _flag_width; or set -q _flag_height
                set -l resized_source "$tmpdir/resized-source.gif"

                set -l resize_args \
                    --resize-method mix \
                    --optimize=2

                if set -q _flag_width; and set -q _flag_height
                    set -a resize_args \
                        --resize-fit "$_flag_width"x"$_flag_height"

                else if set -q _flag_width
                    set -a resize_args \
                        --resize-fit-width "$_flag_width"

                else
                    set -a resize_args \
                        --resize-fit-height "$_flag_height"
                end

                if not set -q _flag_keep_metadata
                    set -a resize_args \
                        --no-comments \
                        --no-names
                end

                echo "GIF: applying maximum dimensions..."

                command gifsicle \
                    $resize_args \
                    --output "$resized_source" \
                    "$file"

                set -l resize_status $status

                if test $resize_status -ne 0
                    echo \
                        "gifsicle failed while resizing $file (exit $resize_status)." \
                        >&2

                    rm -rf -- "$tmpdir"

                    if test $resize_status -eq 130
                        return 130
                    end

                    set -a failures "$file"
                    continue
                end

                if not test -s "$resized_source"
                    echo "gifsicle produced an empty resized GIF: $file" >&2

                    rm -rf -- "$tmpdir"
                    set -a failures "$file"
                    continue
                end

                set gif_source "$resized_source"
            end

            #
            # Map the familiar quality scale to gifsicle lossiness:
            #
            #   quality 100 -> lossiness   0
            #   quality  82 -> lossiness  18
            #   quality  50 -> lossiness  50
            #

            set -l initial_lossiness (
                math "100 - $quality"
            )

            #
            # No target size: exactly one GIF encode.
            #

            if not set -q max_bytes
                set -l gif_args \
                    --optimize=2

                if test "$initial_lossiness" -gt 0
                    set -a gif_args \
                        "--lossy=$initial_lossiness"
                end

                if not set -q _flag_keep_metadata
                    set -a gif_args \
                        --no-comments \
                        --no-names
                end

                echo "GIF: optimizing..."

                command gifsicle \
                    $gif_args \
                    --output "$candidate" \
                    "$gif_source"

                set -l encode_status $status

                if test $encode_status -eq 0; and test -s "$candidate"
                    cp -- "$candidate" "$best"
                    set success 1
                else
                    echo \
                        "gifsicle failed for $file (exit $encode_status)." \
                        >&2

                    if test $encode_status -eq 130
                        rm -rf -- "$tmpdir"
                        return 130
                    end
                end

            #
            # Target-size GIF compression.
            #
            # Preserve dimensions first:
            #
            #   1. requested/default lossiness
            #   2. stronger lossiness
            #   3. reduce palette to 192 colors
            #   4. reduce palette to 128 colors
            #   5. resize to 85%
            #   6. resize to 72%
            #   7. resize to 60%
            #   8. resize to 50%
            #
            # We stop there instead of silently generating a tiny thumbnail.
            #

            else
                set -l max_gif_passes 8
                set -l smallest_size 0
                set -l smallest_scale 1

                set -l gif_scale 1
                set -l gif_lossiness "$initial_lossiness"
                set -l gif_colors 256

                for pass in (seq 1 $max_gif_passes)
                    rm -f -- "$candidate"

                    switch "$pass"
                        case 1
                            set gif_scale 1
                            set gif_lossiness "$initial_lossiness"
                            set gif_colors 256

                        case 2
                            set gif_scale 1
                            set gif_lossiness "$initial_lossiness"

                            if test "$gif_lossiness" -lt 80
                                set gif_lossiness 80
                            end

                            set gif_colors 256

                        case 3
                            set gif_scale 1
                            set gif_lossiness "$initial_lossiness"

                            if test "$gif_lossiness" -lt 110
                                set gif_lossiness 110
                            end

                            set gif_colors 192

                        case 4
                            set gif_scale 1
                            set gif_lossiness "$initial_lossiness"

                            if test "$gif_lossiness" -lt 140
                                set gif_lossiness 140
                            end

                            set gif_colors 128

                        case 5
                            set gif_scale 0.85
                            set gif_lossiness "$initial_lossiness"

                            if test "$gif_lossiness" -lt 150
                                set gif_lossiness 150
                            end

                            set gif_colors 128

                        case 6
                            set gif_scale 0.72
                            set gif_lossiness "$initial_lossiness"

                            if test "$gif_lossiness" -lt 160
                                set gif_lossiness 160
                            end

                            set gif_colors 96

                        case 7
                            set gif_scale 0.60
                            set gif_lossiness "$initial_lossiness"

                            if test "$gif_lossiness" -lt 170
                                set gif_lossiness 170
                            end

                            set gif_colors 80

                        case 8
                            set gif_scale 0.50
                            set gif_lossiness "$initial_lossiness"

                            if test "$gif_lossiness" -lt 180
                                set gif_lossiness 180
                            end

                            set gif_colors 64
                    end

                    set -l gif_args \
                        --optimize=2

                    if not set -q _flag_keep_metadata
                        set -a gif_args \
                            --no-comments \
                            --no-names
                    end

                    if test "$gif_lossiness" -gt 0
                        set -a gif_args \
                            "--lossy=$gif_lossiness"
                    end

                    if test "$gif_colors" -lt 256
                        set -a gif_args \
                            "--colors=$gif_colors"
                    end

                    if test "$gif_scale" -lt 1
                        set -a gif_args \
                            --resize-method mix \
                            --scale "$gif_scale"
                    end

                    set -l scale_percent (
                        math --scale=0 \
                            "$gif_scale * 100"
                    )

                    printf \
                        'GIF pass %d/%d: scale %s%%, lossiness %s, colors %s...\n' \
                        "$pass" \
                        "$max_gif_passes" \
                        "$scale_percent" \
                        "$gif_lossiness" \
                        "$gif_colors"

                    command gifsicle \
                        $gif_args \
                        --output "$candidate" \
                        "$gif_source"

                    set -l encode_status $status

                    if test $encode_status -ne 0
                        echo \
                            "gifsicle failed for $file during pass $pass/$max_gif_passes (exit $encode_status)." \
                            >&2

                        if test $encode_status -eq 130
                            rm -rf -- "$tmpdir"
                            return 130
                        end

                        break
                    end

                    if not test -s "$candidate"
                        echo \
                            "gifsicle produced an empty file during pass $pass/$max_gif_passes: $file" \
                            >&2
                        break
                    end

                    set -l size (
                        stat -c %s -- "$candidate"
                    )

                    if test $status -ne 0
                        echo \
                            "Could not determine GIF size during pass $pass/$max_gif_passes." \
                            >&2
                        break
                    end

                    printf \
                        '  result: %s bytes, target: %s bytes\n' \
                        "$size" \
                        "$max_bytes"

                    if test "$smallest_size" -eq 0; \
                            or test "$size" -lt "$smallest_size"

                        set smallest_size "$size"
                        set smallest_scale "$gif_scale"

                        cp -- "$candidate" "$best"
                    end

                    if test "$size" -le "$max_bytes"
                        set success 1
                        break
                    end
                end

                if test $success -ne 1
                    if test "$smallest_size" -gt 0
                        set -l over_bytes (
                            math \
                                "$smallest_size - $max_bytes"
                        )

                        set -l over_percent (
                            math --scale=1 \
                                "($smallest_size / $max_bytes - 1) * 100"
                        )

                        set -l smallest_scale_percent (
                            math --scale=0 \
                                "$smallest_scale * 100"
                        )

                        printf \
                            'Could not reach target without shrinking below the automatic 50%% dimension limit.\n%s\n%s\n' \
                            "Smallest result: $smallest_size bytes at $smallest_scale_percent% scale." \
                            "Target: $max_bytes bytes ($over_bytes bytes / $over_percent% over)." \
                            >&2
                    else
                        echo "Failed to compress GIF: $file" >&2
                    end
                end
            end

        #
        # Static formats
        #

        else
            set -l geometry

            if set -q _flag_width; and set -q _flag_height
                set geometry (
                    string join '' \
                        "$_flag_width" \
                        x \
                        "$_flag_height" \
                        '>'
                )

            else if set -q _flag_width
                set geometry (
                    string join '' \
                        "$_flag_width" \
                        'x>'
                )

            else if set -q _flag_height
                set geometry (
                    string join '' \
                        x \
                        "$_flag_height" \
                        '>'
                )
            end

            for shrink_round in (seq 1 12)
                set -l base_args \
                    "$file" \
                    -auto-orient

                if test -n "$geometry"
                    set -a base_args \
                        -resize "$geometry"
                end

                if test $scale -lt 100
                    set -a base_args \
                        -resize "$scale%"
                end

                if not set -q _flag_keep_metadata
                    set -a base_args -strip
                end

                #
                # PNG
                #

                if test "$ext" = png
                    magick \
                        $base_args \
                        -quality 90 \
                        "$candidate"

                    or break

                    cp -- "$candidate" "$best"

                    if not set -q max_bytes; \
                            or test (stat -c %s -- "$candidate") -le "$max_bytes"

                        set success 1
                        break
                    end

                #
                # Lossy static format without target size
                #

                else if not set -q max_bytes
                    magick \
                        $base_args \
                        -quality "$quality" \
                        "$candidate"

                    or break

                    cp -- "$candidate" "$best"

                    set success 1
                    break

                #
                # Lossy static format with target size
                #

                else
                    set -l low 10
                    set -l high "$quality"

                    set -l round_best 0
                    set -l encode_failed 0

                    while test "$low" -le "$high"
                        set -l mid (
                            math --scale=0 \
                                "($low + $high) / 2"
                        )

                        magick \
                            $base_args \
                            -quality "$mid" \
                            "$candidate"

                        or begin
                            set encode_failed 1
                            break
                        end

                        set -l size (
                            stat -c %s -- "$candidate"
                        )

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

                #
                # Quality alone was insufficient, or PNG is still too large.
                #

                set scale (
                    math --scale=0 \
                        "$scale * 0.9"
                )

                if test "$scale" -lt 20
                    break
                end
            end
        end

        #
        # Finalize
        #

        if test $success -ne 1; or not test -s "$best"
            echo "Failed to compress: $file" >&2
            set -a failures "$file"

            rm -rf -- "$tmpdir"
            continue
        end

        set -l new_size (
            stat -c %s -- "$best"
        )

        if set -q _flag_in_place
            mv -- "$best" "$file"
            set output "$file"
        else
            mv -- "$best" "$output"
        end

        rm -rf -- "$tmpdir"

        printf '%s -> %s  (%s -> %s bytes)\n' \
            "$file" \
            "$output" \
            "$original_size" \
            "$new_size"
    end

    if set -q failures[1]
        return 1
    end
end
