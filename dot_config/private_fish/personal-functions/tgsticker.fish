function tgsticker --description 'Convert video/GIF to a Telegram-compatible VP9 WebM sticker'
    argparse \
        --strict-longopts \
        --max-args=1 \
        'h/help' \
        'o/output=' \
        'f/force' \
        -- $argv
    or return 2

    if set -q _flag_help
        printf '%s\n' \
            'Usage: tgsticker [OPTIONS] INPUT' \
            '' \
            'Convert INPUT to a Telegram video sticker:' \
            '  WebM / VP9' \
            '  no audio' \
            '  one side exactly 512 px, the other <= 512 px' \
            '  <= 30 FPS' \
            '  <= 3 seconds (longer inputs are sped up, never trimmed)' \
            '  <= 256 KiB' \
            '' \
            'Options:' \
            '  -o, --output FILE  Output path (default: INPUT with .webm extension)' \
            '  -f, --force        Overwrite an existing output without confirmation' \
            '  -h, --help         Show this help'
        return 0
    end

    if test (count $argv) -ne 1
        echo 'tgsticker requires exactly one INPUT file.' >&2
        echo "Run 'tgsticker --help' for usage." >&2
        return 2
    end

    for dependency in ffmpeg ffprobe stat mktemp
        if not type -q "$dependency"
            echo "Required command not found: $dependency" >&2
            return 127
        end
    end

    set -l input $argv[1]

    if not test -f "$input"
        echo "Input file not found: $input" >&2
        return 1
    end

    set -l out (path change-extension webm -- "$input")
    set -q _flag_output; and set out $_flag_output

    # ffmpeg cannot safely use the same file as input and output.
    if test "$out" = "$input"
        set out (
            string replace \
                -r '\.[Ww][Ee][Bb][Mm]$' \
                '-sticker.webm' \
                -- "$input"
        )
    end

    set -l output_dir (path dirname -- "$out")

    if not test -d "$output_dir"
        echo "Output directory does not exist: $output_dir" >&2
        return 1
    end

    if test -e "$out"; and not set -q _flag_force
        if not __confirm "Overwrite existing output $out?"
            echo 'Cancelled.'
            return 0
        end
    end

    set -l duration (
        command ffprobe \
            -v error \
            -show_entries format=duration \
            -of default=noprint_wrappers=1:nokey=1 \
            "$input" \
            2>/dev/null
    )

    if test -z "$duration"; \
            or test "$duration" = 'N/A'; \
            or not string match -rq '^[0-9]+([.][0-9]+)?$' -- "$duration"

        echo "Could not determine input duration: $input" >&2
        return 1
    end

    set -l input_codec (
        command ffprobe \
            -v error \
            -select_streams v:0 \
            -show_entries stream=codec_name \
            -of default=noprint_wrappers=1:nokey=1 \
            "$input" \
            2>/dev/null
    )

    # FFmpeg's native VP9 decoder does not expose VP9 alpha. Force libvpx only
    # for VP9 inputs; GIF/MOV/etc. must keep their normal decoder.
    set -l input_args

    if test "$input_codec" = 'vp9'
        set input_args -c:v libvpx-vp9
    end

    set -l final_duration $duration
    set -l filters

    if test "$duration" -gt 3
        set -l speed_multiplier (math --scale=8 "3 / $duration")
        set final_duration 3
        set -a filters "setpts=PTS*$speed_multiplier"
    end

    set -a filters \
        'fps=30' \
        'scale=512:512:force_original_aspect_ratio=decrease:flags=lanczos' \
        'setsar=1' \
        'format=yuva420p'

    set -l vf (string join ',' -- $filters)

    set -l max_bytes 262144
    set -l max_attempts 6
    set -l bitrate_factor 0.96

    set -l temp_dir (
        command mktemp -d -t tgsticker.XXXXXXXX
    )

    if test -z "$temp_dir"; or not test -d "$temp_dir"
        echo 'Could not create temporary directory.' >&2
        return 1
    end

    printf 'Converting: %s -> %s\n' "$input" "$out"
    printf 'Duration:   %ss -> %ss\n' "$duration" "$final_duration"

    for attempt in (seq $max_attempts)
        set -l target_bytes (
            math --scale=0 "$max_bytes * $bitrate_factor"
        )

        set -l target_bps (
            math --scale=0 \
                "max(1000, $target_bytes * 8 / $final_duration)"
        )

        set -l target_kbps (
            math --scale=0 "$target_bps / 1000"
        )

        printf 'Attempt %d/%d: target ~%d kbps\n' \
            "$attempt" \
            "$max_attempts" \
            "$target_kbps"

        command ffmpeg \
            -hide_banner \
            -loglevel error \
            -nostats \
            -y \
            $input_args \
            -i "$input" \
            -vf "$vf" \
            -an \
            -sn \
            -dn \
            -c:v libvpx-vp9 \
            -b:v "$target_bps" \
            -deadline good \
            -cpu-used 2 \
            -row-mt 1 \
            -auto-alt-ref 0 \
            -pix_fmt yuva420p \
            -pass 1 \
            -passlogfile "$temp_dir/pass" \
            -f null \
            /dev/null

        set -l pass1_status $status

        if test $pass1_status -ne 0
            command rm -rf -- "$temp_dir"
            echo "ffmpeg first pass failed (exit $pass1_status)." >&2
            return $pass1_status
        end

        command ffmpeg \
            -hide_banner \
            -loglevel error \
            -nostats \
            -y \
            $input_args \
            -i "$input" \
            -vf "$vf" \
            -an \
            -sn \
            -dn \
            -c:v libvpx-vp9 \
            -b:v "$target_bps" \
            -deadline good \
            -cpu-used 2 \
            -row-mt 1 \
            -auto-alt-ref 0 \
            -pix_fmt yuva420p \
            -pass 2 \
            -passlogfile "$temp_dir/pass" \
            "$out"

        set -l pass2_status $status

        if test $pass2_status -ne 0
            command rm -rf -- "$temp_dir"
            command rm -f -- "$out"

            echo "ffmpeg second pass failed (exit $pass2_status)." >&2
            return $pass2_status
        end

        set -l size_bytes (
            command stat -c '%s' -- "$out"
        )

        set -l size_kib (
            math --scale=2 "$size_bytes / 1024"
        )

        if test "$size_bytes" -gt 0; \
                and test "$size_bytes" -le "$max_bytes"

            command rm -rf -- "$temp_dir"

            printf 'Created: %s (%s KiB)\n' \
                "$out" \
                "$size_kib"

            return 0
        end

        if test "$attempt" -lt "$max_attempts"
            # Adjust from the actual overshoot instead of blindly subtracting
            # a fixed percentage on every iteration.
            set bitrate_factor (
                math --scale=6 \
                    "$bitrate_factor * $max_bytes / $size_bytes * 0.97"
            )
        else
            command rm -rf -- "$temp_dir"

            printf \
                'Could not reach <=256 KiB after %d attempts (last: %s KiB).\n' \
                "$max_attempts" \
                "$size_kib" \
                >&2

            return 1
        end
    end
end
