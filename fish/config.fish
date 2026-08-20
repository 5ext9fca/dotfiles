if status is-interactive
    set -g fish_greeting

    if command -q mise
        mise activate fish | source
    end

    if command -q starship
        starship init fish | source
    end

    if command -q zoxide
        zoxide init fish | source
    end

    if status is-interactive; and not set -q ZELLIJ; and command -q zellij
        zellij
    end
end
