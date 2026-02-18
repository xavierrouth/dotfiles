function fish_clipboard_copy
    set -l data (commandline --current-selection)
    if test -z "$data"
        set data (commandline)
    end
    set -l b64 (printf '%s' $data | base64 -w 0)
    # Wrap for tmux passthrough if inside tmux
    if set -q TMUX
        printf '\033Ptmux;\033\033]52;c;%s\007\033\\' $b64
    else
        printf '\033]52;c;%s\007' $b64
    end
end
