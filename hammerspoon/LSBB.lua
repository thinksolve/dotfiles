local M = {}
local log = hs.logger.new("loopSafe", "info")

local termIDs = {
	["com.mitchellh.ghostty"] = true,
	["com.googlecode.iterm2"] = true,
	["com.apple.Terminal"] = true,
	["net.kovidgoyal.kitty"] = true,
}

-- returns true  -> we are inside a terminal
-- returns false -> safe to let the hot-key fire
local function insideTerm()
	local app = hs.application.frontmostApplication()
	return app and termIDs[app:bundleID()]
end

function M.bind(mods, key, launchCmd, bundleID)
	bundleID = bundleID or "com.mitchellh.ghostty"

	local hk
	local function reEnable()
		-- re-check every 250 ms until we are *outside* a terminal
		if insideTerm() then
			hs.timer.doAfter(0.25, reEnable)
		else
			hk:enable()
		end
	end

	local function callback()
		-- 1.  do not fire again while we are launching
		hk:disable()

		-- 2.  run the user command
		launchCmd()

		-- 3.  wait a little for the new window to register, then start polling
		hs.timer.doAfter(0.2, reEnable)
	end

	hk = hs.hotkey.new(mods, key, callback)

	-- initial state
	if insideTerm() then
		hk:disable()
	end

	-- keep state in sync when user switches apps manually
	hs.application.watcher
		.new(function()
			if insideTerm() then
				hk:disable()
			else
				hk:enable()
			end
		end)
		:start()

	return hk
end

return M
