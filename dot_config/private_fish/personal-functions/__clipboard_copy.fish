function __clipboard_copy --description 'Internal clipboard copy backend selected by current session type'
    set -l session_type (__clipboard_session_type)
    or return $status

    switch $session_type
        case wayland
            if not type -q wl-copy
                echo 'Wayland session detected, but wl-copy is not installed. Install wl-clipboard.' >&2
                return 127
            end

            wl-copy

        case x11
            if type -q xclip
                xclip -selection clipboard -in
            else if type -q xsel
                xsel --clipboard --input
            else
                echo 'X11 session detected, but neither xclip nor xsel is installed.' >&2
                return 127
            end
    end
end
