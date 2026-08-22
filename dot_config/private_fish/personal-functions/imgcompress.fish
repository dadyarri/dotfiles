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
            'When --max is specified, lossy static formats use a quality search and,' \
            'if that is insufficient, progressively reduce dimensions. PNG uses' \
            'maximum lossless compression and reduces dimensions only when needed.' \
            '' \
            'GIF uses gifsicle optimization and a lossiness search before progressively' \
            'reducing dimensions. --quality controls its initial quality level; lower' \
            'quality permits more aggressive GIF compression.' \
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
            '  imgcompress animation.gif --max 2M' \
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
    # Check only dependencies actually required by the selected files.
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

        set -l stem (string replace -r '\.[^.]+$' '' -- "$file")
        set -l output "$stem.compressed.$ext"

        set -l tmpdir (mktemp -d)
        or begin
            echo "Could not create temporary directory for: $file" >&2
            set -a failures "$file"
            continue
        end

        set -l candidate "$tmpdir/candidate.$ext"
        set -l best "$tmpdir/best.$ext"

        set -l scale 100
        set -l success 0

        set -l original_size (stat -c %s -- "$file")
        or begin
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
            set -l resized_source "$tmpdir/source.gif"

            #
            # Apply the user-requested maximum dimensions once.
            #
            # Subsequent target-size rounds always start with this same source,
            # so repeated lossy/re-encoding damage does not accumulate.
            #

            if set -q _flag_width; or set -q _flag_height
                set -l resize_args \
                    --resize-method lanczos3

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

                gifsicle $resize_args "$file" > "$resized_source"

                if test $status -ne 0; or not test -s "$resized_source"
                    echo "Failed to resize GIF: $file" >&2
                    set -a failures "$file"
                    rm -rf -- "$tmpdir"
                    continue
                end

                set gif_source "$resized_source"
            end

            #
            # Map the familiar 1-100 quality scale onto gifsicle's lossiness.
            #
            # quality 100 -> lossiness 0
            # quality  82 -> lossiness 18
            # quality  50 -> lossiness 50
            #
            # With --max, this is the least-lossy value we try. If necessary,
            # compression may become progressively more aggressive up to 200
            # before dimensions are reduced.
            #

            set -l initial_lossiness (math "100 - $quality")

            for shrink_round in (seq 1 12)
                set -l transform_args \
                    --optimize=3

                if not set -q _flag_keep_metadata
                    # Preserve application extensions such as the Netscape loop
                    # extension. Only discard nonessential comments/frame names.
                    set -a transform_args \
                        --no-comments \
                        --no-names
                end

                #
                # Additional shrinking needed to satisfy --max.
                #
                # --scale is applied to the same pre-resized source on every
                # iteration, so scaling losses do not accumulate.
                #

                if test $scale -lt 100
                    set -l gif_scale (
                        math --scale=4 "$scale / 100"
                    )

                    set -a transform_args \
                        --resize-method lanczos3 \
                        --scale "$gif_scale"
                end

                #
                # No maximum target: one encode at requested/default quality.
                #

                if not set -q max_bytes
                    set -l encode_args $transform_args

                    if test "$initial_lossiness" -gt 0
                        set -a encode_args \
                            "--lossy=$initial_lossiness"
                    end

                    gifsicle $encode_args "$gif_source" > "$candidate"

                    if test $status -ne 0; or not test -s "$candidate"
                        break
                    end

                    cp -- "$candidate" "$best"
                    set success 1
                    break
                end

                #
                # Target-size mode.
                #
                # Search for the lowest gifsicle lossiness that fits. Lower
                # lossiness means better visual quality.
                #

                set -l low "$initial_lossiness"
                set -l high 200

                set -l round_best 0
                set -l encode_failed 0

                while test "$low" -le "$high"
                    set -l mid (
                        math --scale=0 "($low + $high) / 2"
                    )

                    set -l encode_args $transform_args

                    if test "$mid" -gt 0
                        set -a encode_args "--lossy=$mid"
                    end

                    gifsicle $encode_args "$gif_source" > "$candidate"

                    if test $status -ne 0; or not test -s "$candidate"
                        set encode_failed 1
                        break
                    end

                    set -l size (stat -c %s -- "$candidate")

                    if test "$size" -le "$max_bytes"
                        cp -- "$candidate" "$best"

                        set round_best 1

                        # It fits. Try less lossy compression.
                        set high (math "$mid - 1")
                    else
                        # Still too large. Permit more loss.
                        set low (math "$mid + 1")
                    end
                end

                if test $encode_failed -eq 1
                    break
                end

                if test $round_best -eq 1
                    set success 1
                    break
                end

                #
                # Even gifsicle --lossy=200 did not fit. Reduce dimensions and
                # search again.
                #

                set scale (
                    math --scale=0 "$scale * 0.9"
                )

                if test "$scale" -lt 20
                    break
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
                # PNG: lossless compression.
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
                # Lossy static formats without target size.
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
                # Lossy static formats with target size.
                #

                else
                    set -l low 10
                    set -l high "$quality"

                    set -l round_best 0
                    set -l encode_failed 0

                    while test "$low" -le "$high"
                        set -l mid (
                            math --scale=0 "($low + $high) / 2"
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
                # Quality alone was not enough, or a lossless PNG is still too
                # large. Retry from the original source at smaller dimensions.
                #

                set scale (
                    math --scale=0 "$scale * 0.9"
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
