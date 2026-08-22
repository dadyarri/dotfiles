function gwt --description 'Manage Git worktrees with sensible defaults and interactive navigation'
    if test (count $argv) -eq 0
        set argv --help
    end

    if contains -- $argv[1] -h --help help
        printf '%s\n' \
            'Usage: gwt COMMAND [ARGS]' \
            '' \
            'A small helper around git worktree.' \
            '' \
            'Mental model:' \
            '  One Git repository can have several working directories checked out at' \
            '  the same time. Each normal branch can be checked out in only one worktree.' \
            '' \
            '  repo/                  main worktree' \
            '  repo-feature-login/    feature/login worktree' \
            '  repo-hotfix-1.2/       hotfix/1.2 worktree' \
            '' \
            'Typical workflow:' \
            '  gwt add feature/login       create/check out a second worktree' \
            '  gwt cd feature/login        change this Fish shell into that worktree' \
            '  # work normally, commit, merge, etc.' \
            '  gwt remove feature/login    remove the extra working directory' \
            '  gwt prune                   clean stale worktree metadata' \
            '' \
            'Commands:' \
            '  add BRANCH [PATH]   Add a worktree. New branches are created automatically.' \
            '  cd [BRANCH]         Change into a worktree; interactively select if omitted.' \
            '  list                List worktrees.' \
            '  remove [TARGET]     Confirm and remove a worktree by branch/path.' \
            '  prune               Prune stale worktree administrative data.' \
            '  help                Show this help.' \
            '' \
            'Interactive selection uses tv, fzf, or gum filter in that order.' \
            'Destructive confirmation uses gum when available, with a native Fish fallback.' \
            '' \
            'Run `gwt COMMAND --help` for command-specific help.'
        return 0
    end

    set -l subcommand $argv[1]
    set -e argv[1]

    switch $subcommand
        case list ls
            if contains -- --help $argv; or contains -- -h $argv
                printf '%s\n' \
                    'Usage: gwt list' \
                    '' \
                    'List all worktrees using git worktree list.'
                return 0
            end

            __gwt_require_repo
            or return $status

            git worktree list

        case add
            argparse \
                --name='gwt add' \
                --strict-longopts \
                --max-args=2 \
                'h/help' \
                'f/from=' \
                -- $argv
            or return 2

            if set -q _flag_help
                printf '%s\n' \
                    'Usage: gwt add [OPTIONS] BRANCH [PATH]' \
                    '' \
                    'Add a worktree for BRANCH. If BRANCH exists locally, it is checked' \
                    'out. If origin/BRANCH exists, a local tracking branch is created.' \
                    'Otherwise a new branch is created from --from (default: HEAD).' \
                    '' \
                    'If PATH is omitted, use a sibling directory named REPO-BRANCH with' \
                    'slashes in the branch name replaced by dashes.' \
                    '' \
                    'Options:' \
                    '  -f, --from REF  Start point for a newly created branch (default: HEAD)' \
                    '  -h, --help      Show this help'
                return 0
            end

            if test (count $argv) -lt 1
                echo 'gwt add requires BRANCH.' >&2
                return 2
            end

            __gwt_require_repo
            or return $status

            set -l branch $argv[1]
            set -l common_dir \
                (git rev-parse --path-format=absolute --git-common-dir)

            set -l repo_root

            if test (basename "$common_dir") = .git
                set repo_root (dirname "$common_dir")
            else
                set repo_root (git rev-parse --show-toplevel)
            end

            set -l repo_name (basename "$repo_root")
            set -l safe_branch (string replace -a '/' '-' -- "$branch")
            set -l path (dirname "$repo_root")"/$repo_name-$safe_branch"

            if set -q argv[2]
                set path $argv[2]
            end

            if test -e "$path"
                echo "Target path already exists: $path" >&2
                return 1
            end

            if git show-ref --verify --quiet "refs/heads/$branch"
                git worktree add "$path" "$branch"
            else if git show-ref --verify --quiet "refs/remotes/origin/$branch"
                git worktree add --track -b "$branch" "$path" "origin/$branch"
            else
                set -l start HEAD

                if set -q _flag_from
                    set start $_flag_from
                end

                git worktree add -b "$branch" "$path" "$start"
            end

        case cd
            argparse \
                --name='gwt cd' \
                --strict-longopts \
                --max-args=1 \
                'h/help' \
                -- $argv
            or return 2

            if set -q _flag_help
                printf '%s\n' \
                    'Usage: gwt cd [BRANCH]' \
                    '' \
                    'Change the current Fish shell into an existing worktree.' \
                    'When BRANCH is omitted, choose interactively with tv, fzf,' \
                    'or gum filter.'
                return 0
            end

            __gwt_require_repo
            or return $status

            set -l rows (__worktree_rows)
            set -l path

            if set -q argv[1]
                for row in $rows
                    set -l fields \
                        (string split (printf '\t') -- "$row")

                    if test "$fields[2]" = "$argv[1]"
                        set path $fields[1]
                        break
                    end
                end

                if test -z "$path"
                    echo "No worktree for branch: $argv[1]" >&2
                    return 1
                end
            else
                set -l selected \
                    (printf '%s\n' $rows | __mine_selector --prompt 'Worktree> ')

                test $status -eq 0
                or return $status

                test -n "$selected"
                or return 0

                set path \
                    (string split (printf '\t') -- "$selected")[1]
            end

            cd -- "$path"

        case remove rm
            argparse \
                --name='gwt remove' \
                --strict-longopts \
                --max-args=1 \
                'h/help' \
                'f/force' \
                -- $argv
            or return 2

            if set -q _flag_help
                printf '%s\n' \
                    'Usage: gwt remove [OPTIONS] [BRANCH_OR_PATH]' \
                    '' \
                    'Remove an existing worktree. If no target is supplied, choose one' \
                    'interactively. Confirmation is always requested before removal.' \
                    '' \
                    'This removes the working directory but does not delete the branch.' \
                    '' \
                    'Options:' \
                    '  -f, --force  Pass --force to git worktree remove' \
                    '  -h, --help   Show this help'
                return 0
            end

            __gwt_require_repo
            or return $status

            set -l rows (__worktree_rows)
            set -l current_root (git rev-parse --show-toplevel)
            set -l path

            if set -q argv[1]
                if test -d "$argv[1]"
                    set path (realpath "$argv[1]")
                else
                    for row in $rows
                        set -l fields \
                            (string split (printf '\t') -- "$row")

                        if test "$fields[2]" = "$argv[1]"
                            set path $fields[1]
                            break
                        end
                    end
                end
            else
                set -l selectable

                for row in $rows
                    set -l fields \
                        (string split (printf '\t') -- "$row")

                    test "$fields[1]" = "$current_root"
                    and continue

                    set -a selectable "$row"
                end

                if not set -q selectable[1]
                    echo 'No removable secondary worktrees found.'
                    return 0
                end

                set -l selected \
                    (printf '%s\n' $selectable | __mine_selector --prompt 'Remove worktree> ')

                test $status -eq 0
                or return $status

                test -n "$selected"
                or return 0

                set path \
                    (string split (printf '\t') -- "$selected")[1]
            end

            if test -z "$path"
                echo 'Worktree not found.' >&2
                return 1
            end

            if test "$path" = "$current_root"
                echo 'Refusing to remove the worktree you are currently inside.' >&2
                return 1
            end

            set -l action 'Remove'
            if set -q _flag_force
                set action 'Force-remove'
            end

            __confirm "$action worktree $path?"
            or begin
                echo 'Cancelled.'
                return 0
            end

            set -l opts

            if set -q _flag_force
                set -a opts --force
            end

            git worktree remove $opts "$path"

        case prune
            if contains -- --help $argv; or contains -- -h $argv
                printf '%s\n' \
                    'Usage: gwt prune' \
                    '' \
                    'Remove stale administrative worktree records using git worktree prune.'
                return 0
            end

            __gwt_require_repo
            or return $status

            git worktree prune -v

        case '*'
            echo "Unknown gwt command: $subcommand" >&2
            echo "Run 'gwt --help' for usage." >&2
            return 2
    end
end
