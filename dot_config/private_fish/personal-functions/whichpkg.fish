function whichpkg --description 'Show the installed package that owns a file'
    argparse --name=whichpkg --strict-longopts 'h/help' -- $argv
    or return 2

    if set -q _flag_help
        printf '%s\n' \
            'Usage: whichpkg FILE...' \
            '' \
            'Show which installed package owns each FILE. Package backend is selected' \
            'automatically: pacman on Arch, rpm/dnf on Fedora/RHEL-family systems.' \
            '' \
            'Options:' \
            '  -h, --help  Show this help'
        return 0
    end

    if test (count $argv) -eq 0
        echo 'whichpkg requires at least one FILE.' >&2
        return 2
    end

    if type -q pacman
        pacman -Qo -- $argv
    else if type -q rpm
        rpm -qf -- $argv
    else if type -q dnf
        for file in $argv
            dnf repoquery --installed --file "$file"
        end
    else
        echo 'No supported package manager found (pacman or dnf/rpm).' >&2
        return 127
    end
end
