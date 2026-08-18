# Homebrew is part of the macOS preset only.
if test (uname) = Darwin
    for brew_candidate in \
            /opt/homebrew/bin/brew \
            /usr/local/bin/brew
        if test -x $brew_candidate
            $brew_candidate shellenv fish | source
            break
        end
    end
end

# Build paths dynamically so Homebrew formula upgrades do not pin versions.
set -l managed_paths $HOME/.local/bin

if test (uname) = Darwin; and command -q brew
    for formula in openjdk rustup llvm
        set -l formula_prefix (brew --prefix $formula 2>/dev/null)
        if test $status -eq 0; and test -d $formula_prefix/bin
            set -a managed_paths $formula_prefix/bin
        end
    end

    set -l ruby_prefix (brew --prefix ruby 2>/dev/null)
    if test $status -eq 0; and test -d $ruby_prefix/bin
        set -a managed_paths $ruby_prefix/bin

        set -l ruby_gem_dir ($ruby_prefix/bin/gem environment gemdir 2>/dev/null)
        if test $status -eq 0; and test -d $ruby_gem_dir/bin
            set -a managed_paths $ruby_gem_dir/bin
        end
    end
end

set -a managed_paths \
    $HOME/.local/share/mise/shims \
    $HOME/development/flutter/bin

# Prepend in reverse so the list above remains the final priority order.
for candidate in $managed_paths[-1..1]
    if test -d $candidate
        fish_add_path --prepend $candidate
    end
end
