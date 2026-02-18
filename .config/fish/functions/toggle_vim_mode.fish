function toggle_vim_mode
    if test "$fish_key_bindings" = "fish_vi_key_bindings"
        fish_default_key_bindings
        echo "Vi mode OFF"
    else
        fish_vi_key_bindings
        echo "Vi mode ON"
    end
end