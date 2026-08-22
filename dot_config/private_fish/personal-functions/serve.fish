function serve --description 'Serve a directory over HTTP on the first available unprivileged port'
    argparse --name=serve --strict-longopts --max-args=1 'h/help' 'p/port=' 'b/bind=' -- $argv
    or return 2

    if set -q _flag_help
        printf '%s\n' \
            'Usage: serve [OPTIONS] [DIRECTORY]' \
            '' \
            'Serve DIRECTORY (default: current directory) with Python HTTP server.' \
            'If no port is given, scan from 1024 upward and choose the first port that' \
            'can be bound.' \
            '' \
            'Options:' \
            '  -p, --port PORT  Use an explicit port' \
            '  -b, --bind ADDR  Bind address (default: 127.0.0.1)' \
            '  -h, --help       Show this help' \
            '' \
            'Examples:' \
            '  serve' \
            '  serve ~/Downloads' \
            '  serve --port 8080 --bind 0.0.0.0 ./public'
        return 0
    end

    if not type -q python
        echo 'serve requires Python.' >&2
        return 127
    end

    set -l directory .
    if set -q argv[1]
        set directory $argv[1]
    end
    if not test -d "$directory"
        echo "Not a directory: $directory" >&2
        return 2
    end

    set -l bind 127.0.0.1
    if set -q _flag_bind
        set bind $_flag_bind
    end

    set -l port
    if set -q _flag_port
        set port $_flag_port
        string match -rq '^[0-9]+$' -- "$port"; or begin
            echo "Invalid port: $port" >&2
            return 2
        end
        if test "$port" -lt 1 -o "$port" -gt 65535
            echo "Port out of range: $port" >&2
            return 2
        end
    else
        set port (python -c 'import socket, sys
host = sys.argv[1]
for port in range(1024, 65536):
    family = socket.AF_INET6 if ":" in host else socket.AF_INET
    sock = socket.socket(family, socket.SOCK_STREAM)
    try:
        sock.bind((host, port))
    except OSError:
        sock.close()
        continue
    sock.close()
    print(port)
    break
else:
    raise SystemExit(1)' "$bind")
        or begin
            echo 'Could not find an available unprivileged port.' >&2
            return 1
        end
    end

    set -l display_host $bind
    if test "$bind" = 0.0.0.0 -o "$bind" = '::'
        set display_host localhost
    else if string match -q '*:*' -- "$display_host"
        set display_host "[$display_host]"
    end

    echo "Serving "(realpath "$directory")" at http://$display_host:$port/"
    python -m http.server "$port" --bind "$bind" --directory "$directory"
end
