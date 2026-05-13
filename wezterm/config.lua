---
local wezterm = require("wezterm")
local config = wezterm.config_builder()

local themes = { "AdventureTime", "Catppuccin Mocha", "Tokyo Night Storm (Gogh)" }
config.color_scheme = themes[2]
config.debug_key_events = true
config.font_size = 15.5
config.hide_tab_bar_if_only_one_tab = true
config.initial_cols = 200 -- stty size yields '46 174'
config.initial_rows = 50
config.keys = {
	{
		key = "\\",
		mods = "ALT",
		action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "-",
		mods = "ALT",
		action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "w",
		mods = "ALT", -- or 'CMD' on macOS
		action = wezterm.action.CloseCurrentPane({ confirm = true }),
	},
}
config.macos_window_background_blur = 5
config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = false
config.use_fancy_tab_bar = false
config.window_background_opacity = 0.85
config.window_close_confirmation = "NeverPrompt"
config.window_decorations = "RESIZE"

return config
