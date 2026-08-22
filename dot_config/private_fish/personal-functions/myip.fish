function myip --description 'Show local, routed and public IP addresses'
    argparse --name=myip --strict-longopts --exclusive l,p --max-args=0 'h/help' 'l/local' 'p/public' -- $argv
    or return 2

    if set -q _flag_help
        printf '%s\n' \
            'Usage: myip [OPTIONS]' \
            '' \
            'Show useful local addresses, default routes and public IPv4/IPv6.' \
            '' \
            'Options:' \
            '  -l, --local   Show only local/routing information' \
            '  -p, --public  Show only public addresses' \
            '  -h, --help    Show this help'
        return 0
    end

    if not set -q _flag_public
        if type -q ip
            echo 'Local addresses:'
            ip -brief address show up scope global
            echo
            echo 'Default routes:'
            ip route show default
            ip -6 route show default 2>/dev/null
        else
            echo 'ip command not found; skipping local addresses.' >&2
        end
    end

    if not set -q _flag_local
        if not type -q curl
            echo 'curl not found; skipping public addresses.' >&2
            return 127
        end
        if not set -q _flag_public
            echo
        end
        echo 'Public addresses:'
        set -l ipv4 (curl -4 --fail --silent --show-error --max-time 5 https://api.ipify.org 2>/dev/null)
        set -l ipv6 (curl -6 --fail --silent --show-error --max-time 5 https://api6.ipify.org 2>/dev/null)
        test -n "$ipv4"; and echo "  IPv4: $ipv4"
        test -n "$ipv6"; and echo "  IPv6: $ipv6"
        if test -z "$ipv4" -a -z "$ipv6"
            echo '  unavailable'
            return 1
        end
    end
end
