function __parse_size --description 'Internal parser for human-readable byte sizes'
    if test (count $argv) -ne 1
        return 2
    end

    set -l raw (string lower -- (string trim -- $argv[1]))
    set -l match (string match -r '^([0-9]+(?:\.[0-9]+)?)(b|k|kb|kib|m|mb|mib|g|gb|gib)?$' -- $raw)
    if test $status -ne 0
        echo "Invalid size: $argv[1]" >&2
        return 2
    end

    set -l number (string replace -r '^([0-9]+(?:\.[0-9]+)?).*$' '$1' -- $raw)
    set -l suffix (string replace -r '^[0-9]+(?:\.[0-9]+)?' '' -- $raw)
    set -l factor 1

    switch $suffix
        case '' b
            set factor 1
        case k kb
            set factor 1000
        case kib
            set factor 1024
        case m mb
            set factor 1000000
        case mib
            set factor 1048576
        case g gb
            set factor 1000000000
        case gib
            set factor 1073741824
        case '*'
            return 2
    end

    math --scale=0 "$number * $factor"
end
