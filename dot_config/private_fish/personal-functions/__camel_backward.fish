function __camel_backward
    set -l buffer (commandline -b)
    set -l cursor (commandline -C)

    if test "$cursor" -le 0
        return
    end

    for i in (seq "$cursor" -1 2)
        set -l prev (string sub -s (math "$i - 1") -l 1 -- "$buffer")
        set -l curr (string sub -s "$i" -l 1 -- "$buffer")

        set -l next ''
        if test "$i" -lt (string length -- "$buffer")
            set next (string sub -s (math "$i + 1") -l 1 -- "$buffer")
        end

        if string match -rq '^[a-z0-9]$' -- "$prev"; \
                and string match -rq '^[A-Z]$' -- "$curr"

            commandline -C (math "$i - 1")
            return
        end

        if string match -rq '^[A-Z]$' -- "$prev"; \
                and string match -rq '^[A-Z]$' -- "$curr"; \
                and string match -rq '^[a-z]$' -- "$next"

            commandline -C (math "$i - 1")
            return
        end

        if not string match -rq '^[[:alnum:]]$' -- "$prev"; \
                and string match -rq '^[[:alnum:]]$' -- "$curr"

            commandline -C (math "$i - 1")
            return
        end

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

    commandline -C 0
end
