---
---
local wezterm = require("wezterm")
local config = wezterm.config_builder()

local dark_themes = { "AdventureTime", "Catppuccin Mocha", "Tokyo Night Storm (Gogh)" }
local light_themes = { "One Light (Gogh)", "Tokyo Night Day" }
-- config.color_scheme = light_themes[2]
config.color_scheme = dark_themes[3]
config.debug_key_events = true
config.font_size = 15.5
config.hide_tab_bar_if_only_one_tab = true
config.initial_cols = 200 -- stty size yields '46 174'
config.initial_rows = 50
config.keys = {
	{
		key = "-",
		mods = "ALT",
		action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "=",
		mods = "ALT",
		action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "]", -- closing bracket evokes 'close pane'
		mods = "ALT",
		action = wezterm.action.CloseCurrentPane({ confirm = true }),
	},
	{
		key = "w",
		mods = "ALT",
		action = wezterm.action.CloseCurrentPane({ confirm = true }),
	},
	{
		key = "LeftArrow",
		mods = "ALT",
		action = wezterm.action({ ActivatePaneDirection = "Left" }),
	},
	{
		key = "DownArrow",
		mods = "ALT",
		action = wezterm.action({ ActivatePaneDirection = "Down" }),
	},
	{
		key = "UpArrow",
		mods = "ALT",
		action = wezterm.action({ ActivatePaneDirection = "Up" }),
	},
	{
		key = "RightArrow",
		mods = "ALT",
		action = wezterm.action({ ActivatePaneDirection = "Right" }),
	},
}
config.macos_window_background_blur = 5
config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = false
config.use_fancy_tab_bar = false
config.window_background_opacity = 0.85
config.window_close_confirmation = "NeverPrompt"
config.window_decorations = "RESIZE"
config.window_padding = {
	bottom = 0,
	top = 30,
	left = 10,
	right = 0,
}

----NOTE: theme related logic

-- Helper function to get file modification time since 'wezterm.stat' doesnt exist in wezterm's Lua API
local function get_mtime(filepath)
	local handle = io.popen("/usr/bin/stat -f %m " .. filepath)
	if not handle then
		return nil
	end
	local mtime = handle:read("*a")
	handle:close()
	if not mtime then
		return nil
	end
	mtime = mtime:gsub("[%s\n\r]+", "") -- Single backslash, not double
	return tonumber(mtime)
end

-- local wezterm_config = os.getenv("HOME") .. "/.wezterm.lua"
local wezterm_config = os.getenv("HOME") .. "/.dotfiles/wezterm/config.lua"
local theme_file = os.getenv("HOME") .. "/.cache/theme.txt"
-- local theme_file = wezterm.home_dir.. "/.cache/theme.txt"

-- Check if wezterm.lua is newer than cache
local wezterm_info = get_mtime(wezterm_config)
local cache_info = get_mtime(theme_file)

local should_recalculate = not cache_info or (wezterm_info and wezterm_info > cache_info)

-- Check which table this theme belongs to
local function is_in_list(theme, themes)
	for _, t in ipairs(themes) do
		if t == theme then
			return true
		end
	end
	return false
end

local function update_theme_cache()
	local is_light = is_in_list(config.color_scheme, light_themes)
	-- local mode = is_light and "light" or "dark"

	-- Write to cache
	local f = io.open(theme_file, "w")
	if f then
		f:write(is_light and "light\n" or "dark\n")
		f:close()
	end

	-- print(">>> THIS CODE RAN <<<")
	wezterm.log_warn("wezterm config file changed. Current theme: " .. config.color_scheme)
end

if should_recalculate then
	update_theme_cache()
end

return config
