function orphans --description 'List packages that are no longer required by anything'
    argparse --name=orphans --strict-longopts --max-args=0 'h/help' -- $argv
    or return 2

    if set -q _flag_help
        printf '%s\n' \
            'Usage: orphans' \
            '' \
            'List unneeded/orphaned installed packages. Package backend is selected' \
            'automatically: pacman on Arch or dnf on Fedora/RHEL-family systems.' \
            'This command only lists packages; it never removes them.' \
            '' \
            'Options:' \
            '  -h, --help  Show this help'
        return 0
    end

    if type -q pacman
        set -l result (pacman -Qtdq 2>/dev/null)
        if set -q result[1]
            printf '%s\n' $result
        else
            echo 'No orphan packages.'
        end
    else if type -q dnf
        set -l result (dnf repoquery --unneeded --quiet 2>/dev/null)
        if set -q result[1]
            printf '%s\n' $result
        else
            echo 'No unneeded packages (or this dnf lacks repoquery support).'
        end
    else
        echo 'No supported package manager found (pacman or dnf).' >&2
        return 127
    end
end
