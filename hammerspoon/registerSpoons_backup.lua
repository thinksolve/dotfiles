-- local M = {}
-- hs already has a global 'spoon' table

-- Load SpoonInstall
hs.loadSpoon("SpoonInstall")

-- Define Spoons to register
local spoonList = {
	{ name = "EmmyLua", manual = true },
	{
		name = "PaperWM",
		url = "mogenson/PaperWM.spoon",
		branch = "release",
		config = { screen_margin = 16, window_gap = 2 },
	},
	-- { name = "WindowHalfsAndThirds", options = { hotkeys = "default" } },
	-- { name = "Caffeine", options = { start = true } },
	-- { name = "ReloadConfiguration", options = { start = true } },
}

-- Register and gather all Spoons
for _, spoonDef in ipairs(spoonList) do
	if spoonDef.manual then
		-- Manually load the Spoon
		hs.loadSpoon(spoonDef.name)
	else
		-- Use SpoonInstall
		if spoonDef.url then
			spoon.SpoonInstall.repos[spoonDef.name] = {
				url = "https://github.com/" .. spoonDef.url,
				desc = spoonDef.name .. " repository",
				branch = spoonDef.branch or "master",
			}
		end

		spoon.SpoonInstall:andUse(spoonDef.name, spoonDef.options or {})
	end

	-- Apply configuration if provided
	if spoonDef.config and spoon[spoonDef.name] then
		for k, v in pairs(spoonDef.config) do
			spoon[spoonDef.name][k] = v
		end
	end

	-- Add to our return table
	-- M[spoonDef.name] = spoon[spoonDef.name]
end

-- return M
--

-- spoon.PaperWM:bindHotkeys({
-- 	-- switch to a new focused window in tiled grid
-- 	focus_left = { { "alt", "cmd" }, "left" },
-- 	focus_right = { { "alt", "cmd" }, "right" },
-- 	focus_up = { { "alt", "cmd" }, "up" },
-- 	focus_down = { { "alt", "cmd" }, "down" },
--
-- 	-- move windows around in tiled grid
-- 	swap_left = { { "alt", "cmd", "shift" }, "left" },
-- 	swap_right = { { "alt", "cmd", "shift" }, "right" },
-- 	swap_up = { { "alt", "cmd", "shift" }, "up" },
-- 	swap_down = { { "alt", "cmd", "shift" }, "down" },
--
-- 	-- position and resize focused window
-- 	center_window = { { "alt", "cmd" }, "c" },
-- 	full_width = { { "alt", "cmd" }, "f" },
-- 	cycle_width = { { "alt", "cmd" }, "r" },
-- 	reverse_cycle_width = { { "ctrl", "alt", "cmd" }, "r" },
-- 	cycle_height = { { "alt", "cmd", "shift" }, "r" },
-- 	reverse_cycle_height = { { "ctrl", "alt", "cmd", "shift" }, "r" },
--
-- 	-- move focused window into / out of a column
-- 	slurp_in = { { "alt", "cmd" }, "i" },
-- 	barf_out = { { "alt", "cmd" }, "o" },
--
-- 	-- move the focused window into / out of the tiling layer
-- 	toggle_floating = { { "alt", "cmd", "shift" }, "escape" },
--
-- 	-- switch to a new Mission Control space
-- 	switch_space_l = { { "alt", "cmd" }, "," },
-- 	switch_space_r = { { "alt", "cmd" }, "." },
-- 	switch_space_1 = { { "alt", "cmd" }, "1" },
-- 	switch_space_2 = { { "alt", "cmd" }, "2" },
-- 	switch_space_3 = { { "alt", "cmd" }, "3" },
-- 	switch_space_4 = { { "alt", "cmd" }, "4" },
-- 	switch_space_5 = { { "alt", "cmd" }, "5" },
-- 	switch_space_6 = { { "alt", "cmd" }, "6" },
-- 	switch_space_7 = { { "alt", "cmd" }, "7" },
-- 	switch_space_8 = { { "alt", "cmd" }, "8" },
-- 	switch_space_9 = { { "alt", "cmd" }, "9" },
--
-- 	-- move focused window to a new space and tile
-- 	move_window_1 = { { "alt", "cmd", "shift" }, "1" },
-- 	move_window_2 = { { "alt", "cmd", "shift" }, "2" },
-- 	move_window_3 = { { "alt", "cmd", "shift" }, "3" },
-- 	move_window_4 = { { "alt", "cmd", "shift" }, "4" },
-- 	move_window_5 = { { "alt", "cmd", "shift" }, "5" },
-- 	move_window_6 = { { "alt", "cmd", "shift" }, "6" },
-- 	move_window_7 = { { "alt", "cmd", "shift" }, "7" },
-- 	move_window_8 = { { "alt", "cmd", "shift" }, "8" },
-- 	move_window_9 = { { "alt", "cmd", "shift" }, "9" },
-- })
-- spoon.PaperWM:start()
