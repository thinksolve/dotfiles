local wezterm = require("wezterm")
local config = wezterm.config_builder()

local home_dir = wezterm.home_dir --or os.getenv("HOME")
local theme_file = home_dir .. "/.colorscheme"

local function is_dark()
	local f = io.open(theme_file, "r")
	if not f then
		return false
	end
	local mode = f:read("*l") --file only contains single line
	-- local mode = f:read("*a"):gsub("[\r\n%s]", "")
	f:close()

	-- i.e. darkmode is default
	return mode ~= "light"
end

local modeDark = is_dark()

-- the final solution but requires `printf "\033]1337;SetUserVar=theme=$(echo -n dark | base64)\007"`
-- say, to be fired form the terminal .. which works fine in hammerspoon as well
-- EDIT: actually only possible when fired from a terminal directly, not via hs spawns a sub shell
-- wezterm.on("user-var-changed", function(window, pane, name, value)
-- 	if name == "theme" then
-- 		window:set_config_overrides({
-- 			-- color_scheme = value == "dark" and "Catppuccin Mocha" or "One Light (Gogh)",
-- 			color_scheme = is_dark() and "Catppuccin Mocha" or "One Light (Gogh)",
-- 		})
-- 	end
-- end)
local function in_fzf(pane)
	local info = pane:get_foreground_process_info()
	if not info then
		return false
	end
	local name = info.executable and info.executable:match("([^/]+)$") or ""
	return name == "fzf"
end
--NOTE: this reloads the entire config so its slow
-- wezterm.add_to_config_reload_watch_list(theme_file)

---- NOTE: works but 1) writes to ~/.colorscheme; 2) requires wezterm keybinding to activate
local function toggle_theme(window)
	local overrides = window:get_config_overrides() or {}

	local dark = (overrides.color_scheme ~= "Catppuccin Mocha")
	-- local dark = is_dark()
	-- dark = not dark

	overrides.color_scheme = dark and "Catppuccin Mocha" or "One Light (Gogh)"

	window:set_config_overrides(overrides)

	-- mirror state outward
	local f = io.open(theme_file, "w")
	if f then
		f:write(dark and "dark\n" or "light\n")
		f:close()
	end
end
-- wezterm.on("toggle-theme",toggle_theme)

local dark_themes = { "AdventureTime", "Catppuccin Mocha", "Tokyo Night Storm (Gogh)" }
local light_themes = { "One Light (Gogh)", "Tokyo Night Day" }

config.color_scheme = modeDark and dark_themes[2] or light_themes[1]
config.debug_key_events = true
config.font_size = 15.5
config.hide_tab_bar_if_only_one_tab = true
config.initial_cols = 200 -- stty size yields '46 174'
config.initial_rows = 50
config.keys = {
	-- {
	-- 	key = "t",
	-- 	mods = "ALT",
	-- 	action = wezterm.action.EmitEvent("toggle-theme"),
	-- 	-- action = wezterm.action.ReloadConfiguration,
	-- },
	{
		key = "t",
		mods = "ALT",
		action = wezterm.action_callback(function(window, pane)
			-- -- wezterm.action.EmitEvent("toggle-theme")
			-- wezterm.emit("toggle-theme")

			----NOTE: debug block
			--local info = pane:get_foreground_process_info()
			--if info then
			--	wezterm.log_info("pid=" .. tostring(info.pid))
			--	wezterm.log_info("exe=" .. tostring(info.executable))
			--	wezterm.log_info("argv=" .. table.concat(info.argv or {}, " "))
			--else
			--	wezterm.log_info("no foreground process info")
			--end
			----NOTE: debug block

			toggle_theme(window)
			-- if in_fzf(pane) then
			window:perform_action(wezterm.action.SendString("\x1b`"), pane)
			-- end
		end),
	},
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
-- config.macos_window_background_blur = 5
config.macos_window_background_blur = modeDark and 5 or 50
config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = false
config.use_fancy_tab_bar = false
config.window_background_opacity = 0.85
-- config.window_background_opacity = modeDark and 0.9 or 1.0
config.window_close_confirmation = "NeverPrompt"
config.window_decorations = "RESIZE"
config.window_padding = {
	bottom = 0,
	top = 30,
	left = 10,
	right = 0,
}

----NOTE: instead of wezterm writing to ~/.colorscheme, now uptop it reads from it and its toggled outside using toggle_theme
-- Helper function to get file modification time since 'wezterm.stat' doesnt exist in wezterm's Lua API
-- local function get_mtime(filepath)
-- 	local handle = io.popen("/usr/bin/stat -f %m " .. filepath)
-- 	if not handle then
-- 		return nil
-- 	end
-- 	local mtime = handle:read("*a")
-- 	handle:close()
-- 	if not mtime then
-- 		return nil
-- 	end
-- 	mtime = mtime:gsub("[%s\n\r]+", "") -- Single backslash, not double
-- 	return tonumber(mtime)
-- end
--
-- local wezterm_config = os.getenv("HOME") .. "/.dotfiles/wezterm/config.lua"
-- local colorscheme_file = os.getenv("HOME") .. "/.colorscheme" -- alternate: wezterm.home_dir.. "/.colorscheme"
--
-- local wezterm_mtime = get_mtime(wezterm_config)
-- local cache_mtime = get_mtime(colorscheme_file)
--
-- local should_recalculate = not cache_mtime or (wezterm_mtime and wezterm_mtime > cache_mtime)

-- local function update_theme_cache()
-- 	-- -- only used by this function, so scoping it here
-- 	-- local function is_in_list(theme, themes)
-- 	-- 	for _, t in ipairs(themes) do
-- 	-- 		if t == theme then
-- 	-- 			return true
-- 	-- 		end
-- 	-- 	end
-- 	-- 	return false
-- 	-- end
-- 	-- local is_light = is_in_list(config.color_scheme, light_themes)
--
-- 	-- Write to cache
-- 	local f = io.open(colorscheme_file, "w")
-- 	if f then
-- 		f:write(modeDark and "dark\n" or "light\n")
-- 		f:close()
-- 	end
--
-- 	-- print(">>> THIS CODE RAN <<<")
-- 	wezterm.log_warn("wezterm config file changed. Current theme: " .. config.color_scheme)
-- end

-- if should_recalculate then
-- 	update_theme_cache()
-- end

return config
