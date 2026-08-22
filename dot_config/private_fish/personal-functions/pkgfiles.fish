function pkgfiles --description 'List files installed by a package'
    argparse --name=pkgfiles --strict-longopts 'h/help' -- $argv
    or return 2

    if set -q _flag_help
        printf '%s\n' \
            'Usage: pkgfiles PACKAGE...' \
            '' \
            'List files installed by each PACKAGE. Package backend is selected' \
            'automatically: pacman on Arch, rpm/dnf on Fedora/RHEL-family systems.' \
            '' \
            'Options:' \
            '  -h, --help  Show this help'
        return 0
    end

    if test (count $argv) -eq 0
        echo 'pkgfiles requires at least one PACKAGE.' >&2
        return 2
    end

    if type -q pacman
        for package in $argv
            pacman -Ql -- "$package"
        end
    else if type -q rpm
        for package in $argv
            rpm -ql -- "$package"
        end
    else if type -q dnf
        for package in $argv
            dnf repoquery --installed --files "$package"
        end
    else
        echo 'No supported package manager found (pacman or dnf/rpm).' >&2
        return 127
    end
end
