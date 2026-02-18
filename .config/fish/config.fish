if status is-interactive
    # Commands to run in interactive sessions can go here
end

bind -M insert jj "set fish_bind_mode default; commandline -f repaint-mode"
