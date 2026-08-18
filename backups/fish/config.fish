if status is-interactive
    fish_add_path "$HOME/.local/share/mise/shims"
    /opt/homebrew/bin/mise activate fish | source

    zoxide init fish | source
    starship init fish | source

    alias ls="eza --icons --group-directories-first"
    alias ll="eza -l --icons --git"
    alias cat="bat"
end
