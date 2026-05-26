local M = {}
-- local log = hs.logger.new("loopSafe", "info")

local termIDs = {
	["com.github.wez.wezterm"] = true,
	["com.mitchellh.ghostty"] = true,
	["com.googlecode.iterm2"] = true,
	["com.apple.Terminal"] = true,
	["net.kovidgoyal.kitty"] = true,
}

local function insideTerm()
	local app = hs.application.frontmostApplication()
	return app and termIDs[app:bundleID()]
end

-- update: single watcher for all bindings;
local hotkeys = {}
hs.application.watcher
	.new(function()
		local inTerm = insideTerm()
		for _, hk in ipairs(hotkeys) do
			if inTerm then
				hk:disable()
			else
				hk:enable()
			end
		end
	end)
	:start()

function M.bind(mods, key, launchCmd)
	local hk

	hk = hs.hotkey.new(mods, key, function()
		hk:disable()
		launchCmd()

		hs.timer.doAfter(0.3, function()
			if not insideTerm() then
				hk:enable()
			end
		end)
	end)

	if insideTerm() then
		hk:disable()
	end

	-- register with shared, hoisted watcher
	table.insert(hotkeys, hk)
	return hk
end

return M
