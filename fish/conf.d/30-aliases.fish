if command -q eza
    alias ls 'eza --icons=auto'
    alias ll 'eza -lah --icons=auto --group-directories-first'
    alias la 'eza -a --icons=auto'
    alias lt 'eza --tree --level=2 --icons=auto'
end

if command -q bat
    alias cat 'bat --paging=never'
    alias less bat
end

alias grep 'grep --color=auto'

if not command -q hx; and command -q helix
    alias hx helix
end

alias .. 'cd ..'
alias ... 'cd ../..'
alias .... 'cd ../../..'
