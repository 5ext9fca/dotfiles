local wezterm = require("wezterm")
local config = wezterm.config_builder()

local target = wezterm.target_triple

local is_windows = target:find("windows") ~= nil
local is_macos   = target:find("apple") ~= nil
local is_linux   = target:find("linux") ~= nil


config.font = wezterm.font_with_fallback({
  "JetBrains Mono",
})
config.font_size = 14.0
config.color_scheme = "Tokyo Night"
config.window_background_opacity = 0.9

config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true

config.window_padding = {
  left = 8,
  right = 8,
  top = 8,
  bottom = 8,
}

config.scrollback_lines = 10000
config.initial_cols = 120
config.initial_rows = 40
config.window_close_confirmation = "NeverPrompt"

if is_windows then
  config.default_domain = os.getenv("WEZTERM_WSL_DOMAIN") or "WSL:Arch"
end

if is_macos then
  config.macos_window_background_blur = 20
  config.default_prog = { '/opt/homebrew/bin/fish', '-l' }
end

return config
