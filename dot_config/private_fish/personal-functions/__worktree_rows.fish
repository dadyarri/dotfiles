function __worktree_rows --description 'Internal Git worktree row generator'
    set -l path
    set -l branch

    for line in (git worktree list --porcelain)
        if string match -q 'worktree *' -- "$line"
            if test -n "$path"
                printf '%s\t%s\n' "$path" "$branch"
            end
            set path (string replace 'worktree ' '' -- "$line")
            set branch '(detached)'
        else if string match -q 'branch refs/heads/*' -- "$line"
            set branch (string replace 'branch refs/heads/' '' -- "$line")
        end
    end

    if test -n "$path"
        printf '%s\t%s\n' "$path" "$branch"
    end
end
