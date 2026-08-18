set -gx EDITOR hx
set -gx VISUAL hx

set -gx PAGER less
set -gx MANPAGER "less -R"

if test -d /opt/homebrew/opt/dotnet/libexec
    set -gx DOTNET_ROOT /opt/homebrew/opt/dotnet/libexec
end
