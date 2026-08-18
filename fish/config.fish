if status is-interactive
    set -g fish_greeting
    fish_vi_key_bindings

    if command -q mise
        mise activate fish | source
    end

    if command -q starship
        starship init fish | source
    end

    if command -q zoxide
        zoxide init fish | source
    end
end
