function gcb --description 'Interactively delete local Git branches already merged into a base branch'
    argparse --name=gcb --strict-longopts --max-args=1 'h/help' 'n/dry-run' -- $argv
    or return 2

    if set -q _flag_help
        printf '%s\n' \
            'Usage: gcb [OPTIONS] [BASE]' \
            '' \
            'Find local branches already merged into BASE, select branches interactively,' \
            'then delete them with git branch -d.' \
            '' \
            'main, master, develop, BASE, and the currently checked-out branch are always' \
            'excluded.' \
            '' \
            'BASE defaults to origin/HEAD when configured; otherwise the current branch.' \
            '' \
            'Interactive selection uses tv, fzf, or gum filter in that order.' \
            'Confirmation uses gum when available, with a native Fish fallback.' \
            '' \
            'Options:' \
            '  -n, --dry-run  Print candidate branches without deleting anything' \
            '  -h, --help     Show this help' \
            '' \
            'Examples:' \
            '  gcb' \
            '  gcb master' \
            '  gcb --dry-run origin/main'
        return 0
    end

    git rev-parse --is-inside-work-tree >/dev/null 2>&1
    or begin
        echo 'Not inside a Git working tree.' >&2
        return 1
    end

    set -l current (git branch --show-current)
    set -l base

    if set -q argv[1]
        set base $argv[1]
    else
        set base \
            (git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)

        if test -z "$base"
            set base $current
        end
    end

    git rev-parse --verify "$base^{commit}" >/dev/null 2>&1
    or begin
        echo "Unknown base branch/ref: $base" >&2
        return 2
    end

    set -l candidates

    for branch in \
        (git for-each-ref --format='%(refname:short)' --merged "$base" refs/heads/)

        contains -- "$branch" main master develop "$current" "$base"
        and continue

        set -a candidates "$branch"
    end

    if not set -q candidates[1]
        echo "No merged local branches to delete from $base."
        return 0
    end

    if set -q _flag_dry_run
        printf '%s\n' $candidates
        return 0
    end

    set -l selected \
        (printf '%s\n' $candidates | __mine_selector --multi --prompt 'Delete branch> ')

    test $status -eq 0; or return $status
    test -n "$selected"; or return 0

    echo 'Selected branches:'
    printf '  %s\n' $selected
    echo

    __confirm "Delete "(count $selected)" selected merged branch(es)?"
    or begin
        echo 'Cancelled.'
        return 0
    end

    git branch -d -- $selected
end
