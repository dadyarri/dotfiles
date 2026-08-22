function __clipboard_paste --description 'Internal clipboard paste backend selected by current session type'
    set -l session_type (__clipboard_session_type)
    or return $status

    switch $session_type
        case wayland
            if not type -q wl-paste
                echo 'Wayland session detected, but wl-paste is not installed. Install wl-clipboard.' >&2
                return 127
            end

            wl-paste --no-newline

        case x11
            if type -q xclip
                xclip -selection clipboard -out
            else if type -q xsel
                xsel --clipboard --output
            else
                echo 'X11 session detected, but neither xclip nor xsel is installed.' >&2
                return 127
            end
    end
end
