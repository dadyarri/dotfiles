function __image_files --description 'Internal image file collector'
    argparse --name=__image_files --strict-longopts 'r/recursive' 'e/ext=+' -- $argv
    or return 2

    set -l extensions

    if set -q _flag_ext
        for ext in $_flag_ext
            set ext (string lower -- (string trim -c '.' -- "$ext"))
            set -a extensions "$ext"
        end
    end

    set -l found

    for item in $argv
        if test -f "$item"
            set -a found "$item"

        else if test -d "$item"
            if set -q _flag_recursive
                set -a found (
                    command find "$item" \
                        -type f \
                        -print0 \
                        | string split0
                )
            else
                set -a found (
                    command find "$item" \
                        -maxdepth 1 \
                        -type f \
                        -print0 \
                        | string split0
                )
            end

        else
            echo "Not found: $item" >&2
        end
    end

    for file in $found
        set -l ext (
            string lower -- (
                string replace -r '^.*\.([^.]+)$' '$1' -- "$file"
            )
        )

        if test "$ext" = "$file"
            continue
        end

        if set -q extensions[1]; and not contains -- "$ext" $extensions
            continue
        end

        switch $ext
            case jpg jpeg png webp avif heic gif tiff tif bmp
                printf '%s\n' "$file"
        end
    end
end
