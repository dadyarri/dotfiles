function freep --description 'Interactively terminate processes using a network port'
    argparse --name=freep --strict-longopts --max-args=1 'h/help' 's/signal=' -- $argv
    or return 2

    if set -q _flag_help
        printf '%s\n' \
            'Usage: freep [OPTIONS] PORT' \
            '' \
            'Find processes using TCP or UDP PORT, show them, ask for confirmation,' \
            'then send a signal. Nothing is killed without confirmation.' \
            '' \
            'Uses gum for confirmation when available, otherwise falls back to a' \
            'native Fish prompt.' \
            '' \
            'Options:' \
            '  -s, --signal SIGNAL  Signal to send (default: TERM)' \
            '  -h, --help           Show this help' \
            '' \
            'Examples:' \
            '  freep 5000' \
            '  freep --signal KILL 8080'
        return 0
    end

    if test (count $argv) -ne 1
        echo 'freep requires exactly one PORT.' >&2
        return 2
    end

    if not type -q lsof
        echo 'freep requires lsof.' >&2
        return 127
    end

    set -l port $argv[1]

    string match -rq '^[0-9]+$' -- "$port"
    or begin
        echo "Invalid port: $port" >&2
        return 2
    end

    if test "$port" -lt 1 -o "$port" -gt 65535
        echo "Port out of range: $port" >&2
        return 2
    end

    set -l signal TERM
    if set -q _flag_signal
        set signal $_flag_signal
    end

    set -l pids \
        (lsof -nP -t -iTCP:"$port" -sTCP:LISTEN 2>/dev/null) \
        (lsof -nP -t -iUDP:"$port" 2>/dev/null)

    set pids (printf '%s\n' $pids | sort -nu)

    if not set -q pids[1]
        echo "No process is using port $port."
        return 0
    end

    ps -o pid,user,comm,args -p (string join ',' $pids)
    echo

    __confirm "Send SIG$signal to "(count $pids)" process(es) using port $port?"
    or begin
        echo 'Cancelled.'
        return 0
    end

    kill -s "$signal" $pids
end
