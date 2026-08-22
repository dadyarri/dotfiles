function cert --description 'Inspect a remote TLS certificate'
    argparse --name=cert --strict-longopts --max-args=1 'h/help' 'p/port=' -- $argv
    or return 2

    if set -q _flag_help
        printf '%s\n' \
            'Usage: cert [OPTIONS] HOST[:PORT]' \
            '' \
            'Connect with OpenSSL using SNI and print the leaf certificate subject,' \
            'issuer, validity, serial, SHA-256 fingerprint and Subject Alternative Names.' \
            '' \
            'Options:' \
            '  -p, --port PORT  TLS port (default: 443; overrides HOST:PORT)' \
            '  -h, --help       Show this help' \
            '' \
            'Examples:' \
            '  cert example.com' \
            '  cert example.com:8443' \
            '  cert --port 6443 api.internal'
        return 0
    end

    if test (count $argv) -ne 1
        echo 'cert requires exactly one HOST[:PORT].' >&2
        return 2
    end

    if not type -q openssl
        echo 'cert requires openssl.' >&2
        return 127
    end

    set -l input $argv[1]
    set -l host $input
    set -l port 443

    if string match -rq '^\[[^]]+\]:[0-9]+$' -- "$input"
        set host (string replace -r '^\[([^]]+)\]:[0-9]+$' '$1' -- "$input")
        set port (string replace -r '^\[[^]]+\]:([0-9]+)$' '$1' -- "$input")
    else if string match -rq '^[^:]+:[0-9]+$' -- "$input"
        set host (string replace -r ':([0-9]+)$' '' -- "$input")
        set port (string replace -r '^.*:([0-9]+)$' '$1' -- "$input")
    end

    if set -q _flag_port
        set port $_flag_port
    end
    string match -rq '^[0-9]+$' -- "$port"; or begin
        echo "Invalid port: $port" >&2
        return 2
    end
    if test "$port" -lt 1; or test "$port" -gt 65535
        echo "Invalid port: $port (expected 1-65535)." >&2
        return 2
    end

    set -l connect_host "$host:$port"
    if string match -q '*:*' -- "$host"
        set connect_host "[$host]:$port"
    end

    printf '' | openssl s_client -connect "$connect_host" -servername "$host" -showcerts 2>/dev/null \
        | openssl x509 -noout \
            -subject \
            -issuer \
            -serial \
            -startdate \
            -enddate \
            -fingerprint -sha256 \
            -ext subjectAltName
end
