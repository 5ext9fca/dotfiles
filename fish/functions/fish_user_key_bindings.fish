function fish_user_key_bindings
    fish_default_key_bindings

    bind \e\[A history-prefix-search-backward
    bind \e\[B history-prefix-search-forward
    bind \e\[1\;5D backward-word
    bind \e\[1\;5C forward-word
end
