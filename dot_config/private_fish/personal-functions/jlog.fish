function jlog --description 'Read systemd journal logs with convenient service/time shortcuts'
    argparse \
        --name=jlog \
        --strict-longopts \
        --max-args=2 \
        'h/help' \
        'f/follow' \
        'b/boot' \
        'u/user' \
        'n/lines=' \
        -- $argv
    or return 2

    if set -q _flag_help
        printf '%s\n' \
            'Usage: jlog [OPTIONS] [SERVICE] [SINCE]' \
            '' \
            'Convenience wrapper around journalctl. SERVICE is passed to -u. SINCE' \
            'accepts journalctl expressions or short forms such as 20m, 2h, 3d.' \
            '' \
            'Options:' \
            '  -f, --follow     Follow new log entries' \
            '  -b, --boot       Limit to current boot' \
            '  -u, --user       Read the user journal' \
            '  -n, --lines N    Show at most N recent entries' \
            '  -h, --help       Show this help' \
            '' \
            'Examples:' \
            '  jlog sshd' \
            '  jlog docker 20m' \
            '  jlog --follow my-service' \
            '  jlog --user pipewire today'
        return 0
    end

    if not type -q journalctl
        echo 'jlog requires journalctl/systemd.' >&2
        return 127
    end

    set -l opts --no-hostname
    if set -q _flag_follow
        set -a opts --follow
    end
    if set -q _flag_boot
        set -a opts --boot
    end
    if set -q _flag_user
        set -a opts --user
    end
    if set -q _flag_lines
        set -a opts --lines "$_flag_lines"
    end

    if set -q argv[1]; and test -n "$argv[1]"
        set -a opts --unit "$argv[1]"
    end

    if set -q argv[2]; and test -n "$argv[2]"
        set -l since $argv[2]
        if string match -rq '^[0-9]+[smhdw]$' -- "$since"
            set -l amount (string replace -r '[smhdw]$' '' -- "$since")
            set -l suffix (string replace -r '^[0-9]+' '' -- "$since")
            switch $suffix
                case s
                    set since "$amount seconds ago"
                case m
                    set since "$amount minutes ago"
                case h
                    set since "$amount hours ago"
                case d
                    set since "$amount days ago"
                case w
                    set since "$amount weeks ago"
            end
        end
        set -a opts --since "$since"
    end

    journalctl $opts
end
