-- lib/termGuard.lua  (or anywhere above your bindings)
local M = {}

-- default terminal list; caller can override
M.defaultIDs = {
	["com.mitchellh.ghostty"] = true,
	["com.googlecode.iterm2"] = true,
	["com.apple.Terminal"] = true,
}

-- enable/disable *one* hotkey object
M.toggle = function(hk, bundleSet)
	bundleSet = bundleSet or M.defaultIDs
	local app = hs.application.frontmostApplication()
	if app and bundleSet[app:bundleID()] then
		hk:disable()
	else
		hk:enable()
	end
end

local log = hs.logger.new("termGuard", "info")
-- wire up the watcher for a list of hotkeys
M.watch = function(hotkeys, bundleSet)
	bundleSet = bundleSet or M.defaultIDs
	local function check()
		-- for _, hk in ipairs(hotkeys) do
		-- 	M.toggle(hk, bundleSet)
		-- end
		-- NOTE: this pcall wrap useful when analyzing console to see if it crashed
		local ok, err = pcall(function()
			for _, hk in ipairs(hotkeys) do
				M.toggle(hk, bundleSet)
			end
		end)

		--
		-- log.i("Initializing")
		--
		if not ok then
			log.e(err)
		end
	end
	hs.application.watcher.new(check):start()
	check() -- initial state
end

return M
