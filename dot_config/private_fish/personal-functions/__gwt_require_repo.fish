function __gwt_require_repo --description 'Internal guard for Git worktree helpers'
    git rev-parse --is-inside-work-tree >/dev/null 2>&1
    or begin
        echo 'Not inside a Git working tree.' >&2
        return 1
    end
end
