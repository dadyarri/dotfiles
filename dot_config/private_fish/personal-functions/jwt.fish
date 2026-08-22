function jwt --description 'Decode and inspect a JWT without verifying its signature'
    argparse --name=jwt --strict-longopts --max-args=1 'h/help' 'r/raw' -- $argv
    or return 2

    if set -q _flag_help
        printf '%s\n' \
            'Usage: jwt [OPTIONS] [TOKEN]' \
            '' \
            'Decode a JSON Web Token header and payload. If TOKEN is omitted, read it' \
            'from stdin. This command does NOT validate the signature.' \
            '' \
            'Options:' \
            '  -r, --raw   Print only decoded JSON, without labels/timestamp summary' \
            '  -h, --help  Show this help' \
            '' \
            'Examples:' \
            '  jwt "$TOKEN"' \
            '  copy-token-command | jwt'
        return 0
    end

    if not type -q jq
        echo 'jwt requires jq.' >&2
        return 127
    end
    if not type -q base64
        echo 'jwt requires base64 (coreutils).' >&2
        return 127
    end

    set -l token
    if set -q argv[1]
        set token (string trim -- "$argv[1]")
    else if not isatty stdin
        set token (string collect | string trim)
    else
        echo 'jwt requires TOKEN as an argument or on stdin.' >&2
        return 2
    end

    set -l parts (string split '.' -- "$token")
    if test (count $parts) -lt 2
        echo 'Invalid JWT: expected at least header.payload.' >&2
        return 2
    end

    set -l decoded
    for index in 1 2
        set -l value (string replace -a '-' '+' -- $parts[$index])
        set value (string replace -a '_' '/' -- "$value")
        set -l remainder (math (string length -- "$value") % 4)
        if test $remainder -eq 2
            set value "$value=="
        else if test $remainder -eq 3
            set value "$value="
        else if test $remainder -eq 1
            echo 'Invalid base64url segment in JWT.' >&2
            return 2
        end

        # Let jq compact the decoded segment to one line. Besides avoiding Fish
        # command-substitution line splitting, jq also validates that the result is JSON.
        set -l json (printf '%s' "$value" | base64 -d 2>/dev/null | jq -c . 2>/dev/null)
        or begin
            echo 'Could not decode a JWT segment as base64url JSON.' >&2
            return 2
        end
        set -a decoded "$json"
    end

    if set -q _flag_raw
        printf '%s\n%s\n' "$decoded[1]" "$decoded[2]" | jq .
        return $status
    end

    echo 'Header:'
    printf '%s\n' "$decoded[1]" | jq .
    echo
    echo 'Payload:'
    printf '%s\n' "$decoded[2]" | jq .

    set -l claims iat nbf exp
    set -l printed 0
    for claim in $claims
        set -l value (printf '%s\n' "$decoded[2]" | jq -r --arg c "$claim" '.[$c] // empty')
        if string match -rq '^[0-9]+$' -- "$value"
            if test $printed -eq 0
                echo
                echo 'Times:'
                set printed 1
            end
            set -l human (date -d "@$value" --iso-8601=seconds 2>/dev/null)
            printf '  %-3s  %s  (%s)\n' "$claim" "$value" "$human"
        end
    end

    echo
    echo 'Signature: NOT VERIFIED'
end
