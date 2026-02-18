function fish_prompt
    set -l last_status $status
    set -l cwd (prompt_pwd)

    # Git branch
    set -l git_branch ''
    if command git rev-parse --is-inside-work-tree &>/dev/null
        set git_branch (command git branch --show-current 2>/dev/null)
        set git_branch " ("(set_color purple)"$git_branch"(set_color normal)")"
    end

    # Status indicator
    set -l prompt_char '❯'
    set -l prompt_color (set_color green)
    if test $last_status -ne 0
        set prompt_color (set_color red)
    end

    echo -n (set_color blue)"$cwd"(set_color normal)"$git_branch $prompt_color$prompt_char"(set_color normal)" "
end