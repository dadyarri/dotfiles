function mine --description 'Browse personal Fish functions and show their help'
    argparse --name=mine --strict-longopts --max-args=0 'h/help' -- $argv
    or return 2

    if set -q _flag_help
        printf '%s\n' \
            'Usage: mine' \
            '' \
            'Dynamically discovers personal autoloaded Fish functions, lets you' \
            'choose one interactively, and runs the selected function with --help.' \
            '' \
            'Functions whose filenames start with _ are treated as internal.' \
            'No index or registry is maintained.' \
            '' \
            'Selection backend priority:' \
            '  1. tv' \
            '  2. fzf' \
            '  3. gum filter' \
            '' \
            'Options:' \
            '  -h, --help  Show this help'
        return 0
    end

    set -l function_dir (status dirname)

    if not test -d "$function_dir"
        echo "Personal functions directory not found: $function_dir" >&2
        return 1
    end

    set -l names
    set -l descriptions
    set -l max_name_length 0

    for file in "$function_dir"/*.fish
        test -e "$file"; or continue

        set -l name (path change-extension '' (path basename "$file"))

        # Internal helpers are deliberately hidden.
        string match -q '_*' -- "$name"; and continue

        # Read exactly one function declaration from the source file.
        set -l declaration (
            string match -r -m 1 \
                '^[[:space:]]*function[[:space:]].*' \
                < "$file"
        )

        set -l description 'No description'

        if test -n "$declaration"
            # Handle single-quoted descriptions.
            set -l parsed (
                string replace -r \
                    ".*--description[ =]+'([^']+)'.*" \
                    '$1' \
                    -- "$declaration"
            )

            if test "$parsed" != "$declaration"
                set description "$parsed"
            else
                # Handle double-quoted descriptions.
                set parsed (
                    string replace -r \
                        '.*--description[ =]+"([^"]+)".*' \
                        '$1' \
                        -- "$declaration"
                )

                if test "$parsed" != "$declaration"
                    set description "$parsed"
                end
            end
        end

        set -a names "$name"
        set -a descriptions "$description"

        set -l name_length (string length -- "$name")
        if test "$name_length" -gt "$max_name_length"
            set max_name_length "$name_length"
        end
    end

    if not set -q names[1]
        echo "No personal functions found in $function_dir." >&2
        return 1
    end

    # Align every description using the longest function name.
    # Spaces are used instead of tabs so alignment is independent of tab stops.
    set -l rows

    for i in (seq (count $names))
        set -a rows (
            printf "%-*s  %s" \
                "$max_name_length" \
                "$names[$i]" \
                "$descriptions[$i]"
        )
    end

    set -l selected (
        printf '%s\n' $rows \
            | __mine_selector --prompt 'Function> '
    )

    test $status -eq 0; or return $status
    test -n "$selected"; or return 0

    # Function names cannot contain spaces, so the first field is enough even
    # though the display column is padded dynamically.
    set -l name (string split -m 1 ' ' -- "$selected")[1]

    "$name" --help
end
