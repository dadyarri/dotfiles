#!/usr/bin/fish

function __cleanup_run
    set -l apply $argv[1]
    set -l label $argv[2]
    set -e argv[1..2]
    echo
    echo "$label..."
    printf '  %s\n' (string join ' ' -- (string escape -- $argv))
    if test "$apply" != yes
        echo '  Preview only; reclaimable size is not estimated for this command.'
        return 0
    end
    $argv
    set -l result $status
    if test $result -ne 0
        echo "$label failed with exit status $result." >&2
    end
    return $result
end

function __cleanup_size
    for path in $argv
        if test -d "$path"
            command du -shx -- "$path" 2>/dev/null
            or echo "  Size may be partial: some entries in $path could not be read." >&2
        end
    end
    return 0
end

function __cleanup_confirm
    if functions -q __confirm
        __confirm $argv
    else
        read -l -P "$argv[1] [y/N] " answer
        string match -rqi '^(y|yes)$' -- "$answer"
    end
end

function __cleanup_caches
    set -l apply $argv[1]
    set -l cache_root $argv[2]
    set -l paru_root $argv[3]
    set -l failures
    set -l operation -d
    if test "$apply" = yes
        set operation -r
    end

    if type -q paccache
        set -l runner
        if test "$apply" = yes
            set runner sudo
        end
        # paccache's own dry run computes eligible package archives.
        __cleanup_run yes 'Clear all Pacman package archives' $runner paccache $operation -k 0
        or set -a failures pacman
    else
        echo 'paccache not found; skipping Pacman package archives.'
    end

    if test -d "$paru_root"
        if type -q paru
            # Double --clean includes installed packages; --delete removes whole
            # cached package directories, including sources, VCS clones and edits.
            # --aur confines this operation to Paru's cache, without invoking Pacman.
            __cleanup_run "$apply" 'Clear full Paru build cache (including sources and local edits)' \
                paru -Scc --aur --delete --clonedir "$paru_root" --noconfirm
            or set -a failures paru
        else
            echo 'paru not found; skipping Paru build cache.'
        end
    end

    if type -q npm
        __cleanup_run "$apply" 'Verify npm cache and collect unneeded entries' npm cache verify
        or set -a failures npm
    end
    if type -q pip
        # Avoid asking pip to purge a nonexistent cache.
        if test -d "$cache_root/pip"
            __cleanup_run "$apply" 'Clear pip downloads (installed packages remain)' pip cache purge
            or set -a failures pip
        end
    end
    if type -q dotnet
        __cleanup_run "$apply" 'Clear NuGet HTTP cache (keep global packages)' dotnet nuget locals http-cache --clear
        or set -a failures NuGet
    end
    if type -q uv
        __cleanup_run "$apply" 'Prune dangling uv cache entries and cached environments' uv cache prune
        or set -a failures uv
    end
    if set -q failures[1]
        echo 'Cache failures: '(string join ', ' -- $failures) >&2
        return 1
    end
    return 0
end

function __cleanup_orphans
    set -l apply $argv[1]
    set -l packages (pacman -Qdtq)
    set -l query_status $status
    if not set -q packages[1]
        # Pacman returns 1 for an empty filtered query. Check the database is readable.
        if test $query_status -gt 1; or not pacman -Qq >/dev/null
            echo 'Could not query installed packages.' >&2
            return 1
        end
        echo 'No orphan packages.'
        return 0
    end
    if test $query_status -ne 0
        return $query_status
    end
    echo 'Orphan packages (review before removal):'
    printf '  %s\n' $packages
    # Keep normal dependency checks and Pacman's transaction confirmation.
    # Do not recursively remove additional packages or their backup config files.
    __cleanup_run "$apply" 'Remove listed orphan packages' sudo pacman -R -- $packages
end

function cleanup --description 'Preview system cleanup; clear caches and run selected cleanup tasks'
    argparse --name cleanup --strict-longopts --max-args 0 \
        --exclusive a,n \
        a/apply n/dry-run h/help \
        docker orphans flatpak trash only \
        'paru-cache=' \
        -- $argv
    or begin
        echo "Run 'cleanup --help' for usage." >&2
        return 2
    end

    if set -q _flag_help
        printf '%s\n' \
            'Usage: cleanup [--apply | --dry-run] [OPTIONS]' \
            '' \
            'Default: read-only report, Pacman archive dry run and planned commands.' \
            '--apply: clear all Pacman package archives and the full Paru build cache,' \
            'verify npm cache, clear pip downloads and NuGet HTTP cache, and prune uv cache.' \
            'Run outside package updates, builds and restores. Downloads may be needed again.' \
            '' \
            '  -a, --apply          Execute cleanup' \
            '  -n, --dry-run        Explicit read-only preview (the default)' \
            '      --docker        Prune unused Docker build cache older than 7 days' \
            '      --orphans       Review/remove orphan Arch packages with Pacman confirmation' \
            '      --flatpak       Review/remove unused system and user Flatpak runtimes' \
            '      --trash         Confirm emptying home Trash entries older than 30 days' \
            '      --only          Run only selected optional tasks; skip regular caches' \
            '      --paru-cache DIR Paru clone directory (default: $XDG_CACHE_HOME/paru/clone)' \
            '  -h, --help           Show this help' \
            '' \
            'Paru cleanup deletes cached sources, VCS clones, built packages and local edits.' \
            'Docker images, containers and volumes, IDE Local History, NuGet global packages,' \
            'SDKs and app data are retained.' \
            'No timers are changed. Commands without a dry run are printed, not executed.' \
            '' \
            'Examples:' \
            '  cleanup' \
            '  cleanup --apply' \
            '  cleanup --only --docker --dry-run' \
            '  cleanup --only --orphans --apply'
        return 0
    end

    if set -q _flag_only; and not set -q _flag_docker; and not set -q _flag_orphans; and not set -q _flag_flatpak; and not set -q _flag_trash
        echo '--only requires --docker, --orphans, --flatpak or --trash.' >&2
        return 2
    end
    set -l cache_root "$HOME/.cache"
    set -l data_root "$HOME/.local/share"
    if set -q XDG_CACHE_HOME; and test -n "$XDG_CACHE_HOME"
        set cache_root "$XDG_CACHE_HOME"
    end
    if set -q XDG_DATA_HOME; and test -n "$XDG_DATA_HOME"
        set data_root "$XDG_DATA_HOME"
    end
    set -l paru_root "$cache_root/paru/clone"
    if set -q _flag_paru_cache
        if not test -d "$_flag_paru_cache"; or test -z "$_flag_paru_cache"
            echo '--paru-cache must name an existing clone directory.' >&2
            return 2
        end
        set paru_root "$_flag_paru_cache"
    end

    set -l apply no
    if set -q _flag_apply
        set apply yes
        if test (id -u) -eq 0
            echo 'Run cleanup as your normal user; system steps invoke sudo themselves.' >&2
            return 2
        end
        if test -e /var/lib/pacman/db.lck
            echo 'Pacman is locked; finish package operations before cleanup.' >&2
            return 1
        end
    end
    set -l started_at (date +%s)
    set -l failures
    echo "Cleanup (apply: $apply)"
    echo 'Filesystem space before:'
    command df -h -- / "$HOME"
    or set -a failures 'initial disk report'

    if not set -q _flag_only
        echo
        echo 'Directory sizes (not guaranteed reclaimable space):'
        __cleanup_size /var/cache/pacman/pkg "$paru_root" "$cache_root/pip" \
            "$cache_root/uv" "$HOME/.npm" "$data_root/NuGet/http-cache"
        or set -a failures 'cache size report'
        __cleanup_caches "$apply" "$cache_root" "$paru_root"
        or set -a failures caches
    end

    if set -q _flag_docker
        if type -q docker
            __cleanup_run yes 'Docker storage report' docker system df
            or set -a failures 'Docker report'
            __cleanup_run "$apply" 'Docker build cache older than 7 days (interactive)' docker builder prune --filter until=168h
            or set -a failures 'Docker cache'
        else
            echo 'docker not found.' >&2
            set -a failures Docker
        end
    end
    if set -q _flag_orphans
        if type -q pacman
            __cleanup_orphans "$apply"
            or set -a failures orphans
        else
            echo 'pacman not found.' >&2
            set -a failures orphans
        end
    end
    if set -q _flag_flatpak
        if type -q flatpak
            __cleanup_run yes 'Installed Flatpak refs' flatpak list --columns=application,branch,size,installation
            or set -a failures 'Flatpak report'
            for scope in system user
                __cleanup_run "$apply" "Unused Flatpak runtimes ($scope, interactive)" flatpak uninstall --$scope --unused
                or set -a failures "Flatpak $scope"
            end
        else
            echo 'flatpak not found.' >&2
            set -a failures Flatpak
        end
    end
    if set -q _flag_trash
        if type -q trash-empty
            __cleanup_size "$data_root/Trash"
            or set -a failures 'Trash report'
            if test "$apply" != yes; or __cleanup_confirm 'Permanently empty home Trash entries deleted more than 30 days ago?'
                __cleanup_run "$apply" 'Home Trash older than 30 days' trash-empty --trash-dir "$data_root/Trash" 30
                or set -a failures Trash
            else
                echo 'Trash cleanup cancelled.'
            end
        else
            echo 'trash-empty not found; install trash-cli to use --trash.' >&2
            set -a failures Trash
        end
    end

    echo
    echo 'Filesystem space after (Btrfs reclamation may be delayed):'
    command df -h -- / "$HOME"
    or set -a failures 'final disk report'
    set -l elapsed (math (date +%s) - $started_at)
    if set -q failures[1]
        printf 'Cleanup completed with failures after %ss: %s\n' "$elapsed" (string join ', ' -- $failures) >&2
        return 1
    end
    if test "$apply" = yes
        printf 'Cleanup completed in %ss.\n' "$elapsed"
    else
        printf 'Preview completed in %ss. No cleanup performed.\n' "$elapsed"
    end
end
