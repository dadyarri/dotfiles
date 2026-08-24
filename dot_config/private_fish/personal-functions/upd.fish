#!/usr/bin/fish

function __upd_run
    set -l label $argv[1]
    set -e argv[1]

    echo "$label..."
    $argv

    set -l command_status $status
    if test $command_status -ne 0
        echo "$label failed with exit status $command_status." >&2
    end

    return $command_status
end

function __upd_update_mirrors
    if not type -q cachyos-rate-mirrors
        echo "cachyos-rate-mirrors not found; cannot update mirrors." >&2
        return 127
    end

    __upd_run "Updating Arch and CachyOS mirrors" sudo cachyos-rate-mirrors
end

function __upd_update_dotnet
    set -l installer "$HOME/.local/libexec/dotnet-install"

    if not test -x "$installer"
        echo "$installer not found or not executable; cannot update .NET SDKs." >&2
        return 127
    end

    set -l failures
    set -l sdk_versions (find "$DOTNET_ROOT/sdk" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; 2>/dev/null)
    set -l channels
    set -l ga_channels

    for sdk_version in $sdk_versions
        set -l channel (string match -r '^[0-9]+\.[0-9]+' -- "$sdk_version")

        if test $status -ne 0
            echo "Could not determine .NET channel for $sdk_version, skipping." >&2
            continue
        end

        if not contains -- "$channel" $channels
            set -a channels "$channel"
        end

        if not string match -rq -- '-' "$sdk_version"
            if not contains -- "$channel" $ga_channels
                set -a ga_channels "$channel"
            end
        end
    end

    # Install older channels first so the newest channel leaves its host binary
    # in place when several SDK generations share one installation directory.
    # Prefer GA when both GA and prerelease SDKs exist for the same channel.
    if set -q channels[1]
        set channels (printf '%s\n' $channels | sort -Vu)
    else
        echo "No .NET SDKs found in $DOTNET_ROOT/sdk."
    end

    for channel in $channels
        set -l quality preview
        if contains -- "$channel" $ga_channels
            set quality GA
        end

        if not __upd_run "Updating .NET channel $channel ($quality)" \
                "$installer" \
                --channel "$channel" \
                --quality "$quality" \
                --install-dir "$DOTNET_ROOT"
            set -a failures "SDK $channel ($quality)"
        end
    end

    set -l tool_list (dotnet tool list --global 2>/dev/null)
    set -l tool_list_status $status

    if test $tool_list_status -ne 0
        echo "Could not list global .NET tools." >&2
        set -a failures "global tool listing"
    else
        set -l global_tools (printf '%s\n' $tool_list | tail -n +3 | awk 'NF {print $1}')

        if not set -q global_tools[1]
            echo "No global .NET tools found."
        else if dotnet tool update --help 2>&1 | string match -q '*--all*'
            # --all is available in newer SDKs. Keep a fallback for older ones.
            if not __upd_run "Updating global .NET tools" dotnet tool update --global --all
                set -a failures "global tools"
            end
        else
            for tool_name in $global_tools
                if not __upd_run "Updating .NET tool $tool_name" dotnet tool update --global "$tool_name"
                    set -a failures "tool $tool_name"
                end
            end
        end
    end

    if set -q failures[1]
        echo ".NET update failures: "(string join ', ' -- $failures) >&2
        return 1
    end

    return 0
end

function __upd_aur_soname_blockers
    set -l logfile $argv[1]

    # Example:
    # :: installing boost-libs (1.92.0-1.1) breaks dependency
    #    'libboost_filesystem.so=1.91.0-64' required by syncthingtray-qt6
    #
    # Only recognize versioned shared-library dependencies. Do not treat
    # ordinary package-version conflicts as automatically recoverable.
    string replace -rf \
        ".*installing .+ breaks dependency '[^']+\\.so=[^']+' required by ([^[:space:]]+).*" \
        '$1' \
        < "$logfile" \
        | sort -u
end


function __upd_validate_aur_soname_blockers
    set -l blockers $argv

    if not set -q blockers[1]
        return 1
    end

    for pkg in $blockers
        # It must actually be installed.
        if not pacman -Q -- "$pkg" >/dev/null 2>&1
            echo "Cannot automatically rebuild $pkg: package is not installed." >&2
            return 1
        end

        # Never automatically remove an official repository package.
        if not pacman -Qm -- "$pkg" >/dev/null 2>&1
            echo "Cannot automatically rebuild $pkg: package is not foreign." >&2
            return 1
        end

        # Foreign is not necessarily AUR: it could be a manually installed
        # package. Verify that paru can actually obtain it from AUR.
        if not paru -Si --aur -- "$pkg" >/dev/null 2>&1
            echo "Cannot automatically rebuild $pkg: package is not available from AUR." >&2
            return 1
        end
    end

    # Prepare the exact removal transaction without performing it.
    #
    # No --nodeps/-d/-dd/-c/etc. If normal removal isn't valid, automatic
    # recovery must stop.
    if not pacman -R --print -- $blockers >/dev/null 2>&1
        echo "Cannot safely remove AUR ABI blockers automatically." >&2
        return 1
    end

    return 0
end


function __upd_recover_aur_soname_break
    set -l logfile $argv[1]
    set -l blockers (__upd_aur_soname_blockers "$logfile")

    if not set -q blockers[1]
        # Special return value: not a recognized recoverable failure.
        return 2
    end

    if not __upd_validate_aur_soname_blockers $blockers
        return 1
    end

    echo
    echo "Repository library update requires rebuilding AUR packages:"
    printf '  %s\n' $blockers
    echo

    # Remember their install reasons because `paru -S` will make them
    # explicit installation targets.
    set -l explicit_packages

    for pkg in $blockers
        if pacman -Qe -- "$pkg" >/dev/null 2>&1
            set -a explicit_packages "$pkg"
        end
    end

    if functions -q __confirm
        if not __confirm \
                "Temporarily remove "(string join ', ' -- $blockers)", upgrade, and rebuild?"
            echo "Automatic AUR rebuild cancelled."
            return 1
        end
    else
        read -l -P \
            "Temporarily remove "(string join ', ' -- $blockers)", upgrade, and rebuild? [y/N] " \
            answer

        if not string match -rqi '^(y|yes)$' -- "$answer"
            echo "Automatic AUR rebuild cancelled."
            return 1
        end
    end

    echo
    echo "Temporarily removing AUR packages..."

    sudo pacman -R --noconfirm -- $blockers
    or return $status

    echo
    echo "Retrying Arch/AUR upgrade..."

    paru -Syu
    set -l upgrade_status $status

    if test $upgrade_status -ne 0
        echo
        echo "Upgrade retry failed; attempting to restore removed packages..." >&2

        paru -S --needed -- $blockers
        set -l restore_status $status

        if test $restore_status -ne 0
            echo >&2
            echo "WARNING: could not restore some temporarily removed packages:" >&2
            printf '  %s\n' $blockers >&2
        else
            for pkg in $blockers
                if contains -- "$pkg" $explicit_packages
                    sudo pacman -D --asexplicit -- "$pkg"
                else
                    sudo pacman -D --asdeps -- "$pkg"
                end
            end
        end

        # Preserve the original upgrade failure.
        return $upgrade_status
    end

    echo
    echo "Rebuilding AUR packages against updated libraries..."

    paru -S --needed -- $blockers
    or begin
        set -l rebuild_status $status

        echo >&2
        echo "System upgrade succeeded, but these AUR packages could not be rebuilt:" >&2
        printf '  %s\n' $blockers >&2

        return $rebuild_status
    end

    # Restore original explicit/dependency state.
    for pkg in $blockers
        if contains -- "$pkg" $explicit_packages
            sudo pacman -D --asexplicit -- "$pkg"
        else
            sudo pacman -D --asdeps -- "$pkg"
        end

        or begin
            echo "Failed to restore install reason for $pkg." >&2
            return 1
        end
    end

    echo
    echo "AUR ABI rebuild completed successfully."
    return 0
end

function upd
    argparse \
        --name upd \
        --strict-longopts \
        --exclusive m,M \
        --max-args 0 \
        'm/update-mirrors' \
        'M/mirrors-only' \
        'h/help' \
        -- $argv
    or begin
        echo "Run 'upd --help' for usage." >&2
        return 2
    end

    if set -q _flag_help
        echo "Usage: upd [OPTIONS]"
        echo
        echo "Options:"
        echo "  -m, --update-mirrors  Update mirrors before all other updates"
        echo "  -M, --mirrors-only    Update mirrors and exit"
        echo "  -h, --help            Show this help"
        return 0
    end

    if set -q _flag_mirrors_only
        __upd_update_mirrors
        return $status
    end

    if set -q _flag_update_mirrors
        __upd_update_mirrors
        or return $status
    end

    echo "Starting updates..."
    set -l started_at (date +%s)
    set -l failures

    # Prefer paru on Arch so repo and AUR packages update in one pass.
    if type -q paru
        set -l upgrade_log (mktemp)
        set -l package_update_failed false

        if test -z "$upgrade_log"
            echo "Could not create temporary file for package-manager output." >&2
            set package_update_failed true
        else
            echo "Updating Arch and AUR packages with paru..."

            # Pacman diagnostics are parsed below, so force stable English,
            # non-colored output.
            env LC_ALL=C NO_COLOR=1 \
                paru -Syu --color never \
                2>&1 | tee "$upgrade_log"

            set -l package_status $pipestatus[1]

            if test $package_status -ne 0
                echo "Arch/AUR package update failed with exit status $package_status." >&2

                __upd_recover_aur_soname_break "$upgrade_log"

                switch $status
                    case 0
                        # Recognized ABI break and recovered successfully.

                    case 2
                        # Not the failure class we know how to recover.
                        set package_update_failed true

                    case '*'
                        # Recognized it, but safe recovery was impossible or failed.
                        set package_update_failed true
                end
            end

            rm -f -- "$upgrade_log"
        end

        if test "$package_update_failed" = true
            set -a failures "Arch/AUR packages"
        end

    else if type -q pacman
        if not __upd_run "Updating Arch packages with pacman" sudo pacman -Syu
            set -a failures "Arch packages"
        end
    else
        echo "No supported system package manager found, skipping system packages."
    end

    if type -q flatpak
        if not __upd_run "Updating Flatpak applications" flatpak update -y
            set -a failures "Flatpak applications"
        end
    else
        echo "Flatpak not found, skipping."
    end

    if type -q rustup
        if not __upd_run "Updating Rust toolchains" rustup update
            set -a failures "Rust toolchains"
        end
    else
        echo "rustup not found, skipping Rust toolchains."
    end

    if type -q cargo
        if type -q cargo-install-update
            if not __upd_run "Updating Cargo-installed binaries" cargo install-update -a
                set -a failures "Cargo-installed binaries"
            end
        else
            echo "cargo-install-update not found, skipping Cargo-installed binaries."
        end
    else
        echo "Cargo not found, skipping Cargo-installed binaries."
    end

    if set -q DOTNET_ROOT; and test -d "$DOTNET_ROOT/sdk"; and type -q dotnet
        if not __upd_update_dotnet
            set -a failures ".NET"
        end
    else
        echo "No dotnet-install based .NET installation found, skipping."
    end

    if functions -q fisher
        if not __upd_run "Updating Fisher plugins" fisher update
            set -a failures "Fisher plugins"
        end
    else
        echo "Fisher not found, skipping Fish plugins."
    end

    if type -q npm
        if not __upd_run "Updating global npm packages" npm update -g
            set -a failures "global npm packages"
        end
    else
        echo "npm not found, skipping global npm packages."
    end

    if type -q pipx
        if not __upd_run "Updating pipx packages" pipx upgrade-all
            set -a failures "pipx packages"
        end
    else
        echo "pipx not found, skipping pipx packages."
    end

    set -l finished_at (date +%s)
    set -l elapsed (math "$finished_at - $started_at")

    if set -q failures[1]
        echo
        printf 'Updates completed with failures after %ss: %s\n' \
            "$elapsed" \
            (string join ', ' -- $failures) >&2
        return 1
    end

    printf 'All updates completed successfully in %ss!\n' "$elapsed"
end
