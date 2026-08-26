function __camel_forward
    set -l buffer (commandline -b)
    set -l cursor (commandline -C)
    set -l length (string length -- "$buffer")

    if test "$cursor" -ge "$length"
        return
    end

    # Fish cursor positions are zero-based, string indexes are one-based.
    for i in (seq (math "$cursor + 2") "$length")
        set -l prev (string sub -s (math "$i - 1") -l 1 -- "$buffer")
        set -l curr (string sub -s "$i" -l 1 -- "$buffer")

        set -l next ''
        if test "$i" -lt "$length"
            set next (string sub -s (math "$i + 1") -l 1 -- "$buffer")
        end

        # fooBar -> foo|Bar
        if string match -rq '^[a-z0-9]$' -- "$prev"; \
                and string match -rq '^[A-Z]$' -- "$curr"

            commandline -C (math "$i - 1")
            return
        end

        # HTTPServer -> HTTP|Server
        if string match -rq '^[A-Z]$' -- "$prev"; \
                and string match -rq '^[A-Z]$' -- "$curr"; \
                and string match -rq '^[a-z]$' -- "$next"

            commandline -C (math "$i - 1")
            return
        end

        # foo_bar / foo-bar / foo.bar -> foo_|bar etc.
        if not string match -rq '^[[:alnum:]]$' -- "$prev"; \
                and string match -rq '^[[:alnum:]]$' -- "$curr"

            commandline -C (math "$i - 1")
            return
        end

        # foo123 / 123foo
        if string match -rq '^[[:alpha:]]$' -- "$prev"; \
                and string match -rq '^[0-9]$' -- "$curr"

            commandline -C (math "$i - 1")
            return
        end

        if string match -rq '^[0-9]$' -- "$prev"; \
                and string match -rq '^[[:alpha:]]$' -- "$curr"

            commandline -C (math "$i - 1")
            return
        end
    end

    commandline -C "$length"
end
