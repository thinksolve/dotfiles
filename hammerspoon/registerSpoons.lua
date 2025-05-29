hs.loadSpoon("SpoonInstall")
local spoonList = {
	{ name = "EmmyLua", manual = true },
	{
		name = "PaperWM",
		url = "mogenson/PaperWM.spoon",
		branch = "release",
		config = { screen_margin = 16, window_gap = 2 },
	},
	{
		name = "ClipboardTool",
		options = {
			start = false, --true,
			config = {
				hist_size = 100,
				show_in_menubar = false,
			},
			hotkeys = {
				toggle_clipboard = { { "cmd", "shift" }, "v" },
			},
		},
	},
}

for _, spoonDef in ipairs(spoonList) do
	if spoonDef.manual then
		hs.loadSpoon(spoonDef.name)
	else
		if spoonDef.url then
			spoon.SpoonInstall.repos[spoonDef.name] = {
				url = "https://github.com/" .. spoonDef.url,
				desc = spoonDef.name .. " repository",
				branch = spoonDef.branch or "master",
			}
		end
		spoon.SpoonInstall:andUse(spoonDef.name, spoonDef.options or {})
	end

	-- Apply config and start spoons
	if spoonDef.config and spoon[spoonDef.name] then
		for k, v in pairs(spoonDef.config) do
			spoon[spoonDef.name][k] = v
		end
	end

	-- Set up hotkeys
	if spoonDef.hotkeys and spoon[spoonDef.name] then
		spoon[spoonDef.name]:bindHotkeys(spoonDef.hotkeys)
	end

	-- Start if needed
	if spoonDef.start and spoon[spoonDef.name] and spoon[spoonDef.name].start then
		spoon[spoonDef.name]:start()
	end
end
