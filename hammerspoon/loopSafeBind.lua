-- hs/loopSafeBind.lua
local M = {}
local log = hs.logger.new("loopSafe", "info")

-- bundle IDs that count as “terminal”
local termIDs = {
	["com.mitchellh.ghostty"] = true,
	["com.googlecode.iterm2"] = true,
	["com.apple.Terminal"] = true,
}

-- create a hot-key that is automatically disabled
--   a) while a terminal is front-most  (termGuard behaviour)
--   b) for 1 s after we ourselves launch that terminal (anti-race)
function M.bind(mods, key, launchCmd, bundleID)
	bundleID = bundleID or "com.mitchellh.ghostty"
	local hk

	local function antiLoop()
		-- 1.  termGuard part
		local app = hs.application.frontmostApplication()
		if app and termIDs[app:bundleID()] then
			hk:disable()
		else
			hk:enable()
		end
	end

	local function callback()
		-- 2.  anti-race part
		hk:disable() -- disarm
		launchCmd() -- open terminal
		hs.timer.doAfter(1, function()
			antiLoop()
		end) -- re-arm after grace
	end

	hk = hs.hotkey.bind(mods, key, callback)

	-- watch for future app switches
	hs.application.watcher.new(antiLoop):start()
	antiLoop() -- initial state
	return hk
end

return M
