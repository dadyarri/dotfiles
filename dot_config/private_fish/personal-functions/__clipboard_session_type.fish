function __clipboard_session_type --description 'Internal: detect clipboard backend family from the current graphical session'
    if set -q XDG_SESSION_TYPE; and test -n "$XDG_SESSION_TYPE"
        switch (string lower -- "$XDG_SESSION_TYPE")
            case wayland
                echo wayland
                return 0
            case x11
                echo x11
                return 0
        end
    end

    if set -q WAYLAND_DISPLAY; and test -n "$WAYLAND_DISPLAY"
        echo wayland
        return 0
    end

    if set -q DISPLAY; and test -n "$DISPLAY"
        echo x11
        return 0
    end

    echo 'Could not determine graphical session type (expected Wayland or X11).' >&2
    return 1
end
