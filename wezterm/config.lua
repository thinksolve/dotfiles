local wezterm = require("wezterm")
local config = wezterm.config_builder()
local act = wezterm.action
local act_callback = wezterm.action_callback

-- simple read/write helper
local function handle_file(filepath)
	local read = function(mode)
		local f = io.open(filepath, "r")
		if not f then
			return nil
		end
		local contents = f:read(mode or "*l")
		f:close()
		return contents
	end

	local write = function(contents)
		local f = io.open(filepath, "w")
		if not f then
			return nil
		end
		f:write(contents)
		f:close()
		return true
	end

	return read, write
end

-- local home_dir = wezterm.home_dir --or os.getenv("HOME")
-- local theme_file = home_dir .. "/.colorscheme"
-- wezterm.add_to_config_reload_watch_list(theme_file) --note: this reloads the entire config so its slow

local read_theme_file, write_theme_file = handle_file(wezterm.home_dir .. "/.colorscheme")

local light_themes = { "One Light (Gogh)", "Tokyo Night Day" }
local dark_themes = { "AdventureTime", "Catppuccin Mocha", "Tokyo Night Storm (Gogh)" }
local default_light_theme = light_themes[2] or "One Light (Gogh)"
local default_dark_theme = dark_themes[3] or "Catppuccin Mocha"

local function is_running(program)
	local ok, output, _ = wezterm.run_child_process({ "ps", "-o", "args" })
	if not ok then
		return false
	end

	local function matches(f)
		return f and (f == program or f:match("/" .. program .. "$"))
	end

	for line in output:gmatch("[^\n]+") do
		-- f1 = executable, f2 = first argument (e.g. script path when interpreter is f1, like `bash path/to/custom/script`)
		local f1, f2 = line:match("^(%S+)%s*(%S*)") --> equivalent regex: ^(\S+)\s*(\S*) --> i.e. "1+ non-WS from start, then 0+ WS, then 0+ non-WS"

		if matches(f1) or matches(f2) then
			return true
		end
	end
	return false
end

local function toggle_theme(window)
	local was_dark = read_theme_file("*l") == "dark"

	write_theme_file(was_dark and "light\n" or "dark\n")

	local overrides = window:get_config_overrides() or {}
	overrides.color_scheme = was_dark and default_light_theme or default_dark_theme
	window:set_config_overrides(overrides)
end

local modeDark = read_theme_file("*l") == "dark" --reads file on shell startup to initialize

config.color_scheme = modeDark and default_dark_theme or default_light_theme
config.debug_key_events = true
config.font_size = 15.5
config.hide_tab_bar_if_only_one_tab = true
config.initial_cols = 200 -- stty size yields '46 174'
config.initial_rows = 50
config.keys = {

	{
		key = "t",
		mods = "ALT",
		-- action = wezterm.action.ReloadConfiguration
		-- action = wezterm.action.EmitEvent("toggle-theme"), -- NOTE: need to define `wezterm.on("toggle-theme", toggle_theme)`
		action = act_callback(function(window, pane)
			toggle_theme(window)

			if is_running("fzf") then
				-- alt-` maps to refresh in my wrapped fzf (see ~/.local/bin/fzf)
				window:perform_action(act.SendString("\x1b`"), pane)
			end
		end),
	},
	{
		key = "-",
		mods = "ALT",
		action = act.SplitVertical({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "=",
		mods = "ALT",
		action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "]", -- closing bracket evokes 'close pane'
		mods = "ALT",
		action = act.CloseCurrentPane({ confirm = true }),
	},
	{
		key = "w",
		mods = "ALT",
		action = act.CloseCurrentPane({ confirm = true }),
	},
	{
		key = "LeftArrow",
		mods = "ALT",
		action = act({ ActivatePaneDirection = "Left" }),
	},
	{
		key = "DownArrow",
		mods = "ALT",
		action = act({ ActivatePaneDirection = "Down" }),
	},
	{
		key = "UpArrow",
		mods = "ALT",
		action = act({ ActivatePaneDirection = "Up" }),
	},
	{
		key = "RightArrow",
		mods = "ALT",
		action = act({ ActivatePaneDirection = "Right" }),
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
