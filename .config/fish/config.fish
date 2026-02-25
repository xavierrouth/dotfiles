if status is-interactive
    # Commands to run in interactive sessions can go here
    fish_vi_key_bindings
    bind -M insert jj "set fish_bind_mode default; commandline -f repaint-mode"
end

